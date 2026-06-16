#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
============================================================
 booking_bot_sim.py
 티켓팅 가상환경 행위(behavior) 로그 시뮬레이터 / 자동 예매 봇
------------------------------------------------------------
 목적 : 우리가 구축한 실습(SOC) 가상환경의 탐지 모델(MLTK) 학습·검증용
        합성 행위 로그를 생성한다. 출력 스키마는 log_behavior_feature.
 용도 : 인가된 자체 랩 전용 (Authorized lab / log-simulation only).

 프로파일(ground-truth):
   - normal      : 정상 사용자          requests_per_second 5 ~ 11
   - simple_bot  : 단순 봇(기계적)       requests_per_second 13 ~ 20
   - mimic_bot   : 흉내 봇(N단계 회피)    레벨↑ → 사람 흉내 → RPS를 정상 대역으로 낮춤

 모드:
   - sim   (기본) : 서버 없이 통계적으로 일관된 로그 생성
   - live         : 실제 홈페이지에 로그인→좌석→예매 플로우를 수행하고 실측

 출력:
   - JSONL  (스키마 필드 + _label/_profile/_level 메타)
   - SQL    (log_behavior_feature INSERT, 스키마 컬럼만)
============================================================
"""

import argparse
import csv
import json
import random
import sys
from dataclasses import dataclass, field, asdict
from datetime import datetime, timedelta

# ------------------------------------------------------------
# 0) 스키마 정의 (log_behavior_feature)
#    이미지 명세 기준. timestamp 는 명세서 첨부 시 포맷만 맞추면 됨.
# ------------------------------------------------------------
SCHEMA_COLUMNS = [
    "user_id",                 # BIGINT  FK  N  (behavior는 NOT NULL → 항상 채움)
    "src_ip",                  # VARCHAR(50) N  요청 IP
    "avg_click_interval",      # FLOAT   평균 클릭 간격 (ms)
    "click_interval_std",      # FLOAT   클릭 간격 표준편차
    "click_count",             # INT     총 클릭 횟수
    "requests_per_second",     # FLOAT   초당 요청 수
    "requests_per_minute",     # FLOAT   분당 요청 수
    "burst_request_count",     # INT     집중 요청 횟수
    "seat_change_count",       # INT     좌석 변경 횟수
    "unique_seat_count",       # INT     조회 좌석 종류 수
    "failed_select_ratio",     # FLOAT   좌석 선택 실패 비율
    "avg_action_interval",     # FLOAT   평균 행동 간격 (ms)
    "page_transition_time",    # FLOAT   페이지 이동 시간 (ms)
    "login_fail_ratio",        # FLOAT   로그인 실패 비율
    "target_account_count",    # INT     공격 대상 계정 수
    "repeated_fail_count",     # INT     반복 실패 횟수
    "repeated_prompt_pattern", # TINYINT(1) 동일 Prompt 반복 (0/1)
    "prompt_similarity",       # FLOAT   Prompt 유사도 (0~1)
    "jailbreak_keyword_count", # INT     우회 키워드 횟수
    "excessive_token_request", # TINYINT(1) 과도한 토큰 요청 (0/1)
    "timestamp",               # DATETIME 이벤트 시각
]

# RPS 밴드 (사용자 제공 기준)
RPS_NORMAL = (5.0, 11.0)
RPS_MACRO  = (13.0, 20.0)


# ------------------------------------------------------------
# 1) 보조 함수
# ------------------------------------------------------------
def lerp(a, b, t):
    """선형 보간: t=0 → a, t=1 → b"""
    return a + (b - a) * t


def jitter(rng, value, frac):
    """value 에 ±frac 비율의 흔들림을 준다."""
    return value * (1.0 + rng.uniform(-frac, frac))


def clamp(v, lo, hi):
    return max(lo, min(hi, v))


# ------------------------------------------------------------
# 2) IP / 계정 풀
#    - 정상 사용자 : 사내/사용자망에서 분산
#    - 봇          : 공격자존(10.44.44.x) 소수 IP에 집중 (집중도 자체가 신호)
# ------------------------------------------------------------
def normal_ip(rng):
    # 다양한 출발지 (사용자망 + 일반대역 흉내)
    pools = [
        lambda: f"10.0.100.{rng.randint(10, 200)}",
        lambda: f"10.0.150.{rng.randint(10, 200)}",
        lambda: f"203.0.113.{rng.randint(2, 254)}",
        lambda: f"118.235.{rng.randint(0,255)}.{rng.randint(2,254)}",
    ]
    return rng.choice(pools)()


def bot_ip(rng, evasive=False):
    if evasive:
        # 흉내 봇: 출발지도 분산시켜 회피
        return f"10.44.44.{rng.randint(40, 60)}" if rng.random() < 0.5 \
               else f"203.0.113.{rng.randint(2, 254)}"
    # 단순 봇: 소수 IP 집중
    return f"10.44.44.{rng.choice([44, 45, 46])}"


# ------------------------------------------------------------
# 3) 프로파일별 피처 생성기
#    각 함수는 SCHEMA(메타 제외) 피처 dict 를 반환한다.
# ------------------------------------------------------------
def feat_normal(rng):
    """정상 사용자: 느리고 변동 큰 사람다운 행동, 실패/스캔 적음."""
    rps = rng.uniform(*RPS_NORMAL)
    return {
        "user_id": rng.randint(1, 50),
        "src_ip": normal_ip(rng),
        # 클릭(사람: 느리고 변동 큼 → std 높음)
        "avg_click_interval": rng.uniform(300, 1500),
        "click_interval_std": rng.uniform(60, 400),
        "click_count": rng.randint(5, 40),
        "requests_per_second": rps,
        # 사람은 잠깐 몰렸다 쉬므로 분당 환산이 rps*60 보다 낮다
        "requests_per_minute": rps * 60 * rng.uniform(0.35, 0.7),
        "burst_request_count": rng.randint(1, 5),
        "seat_change_count": rng.randint(0, 3),
        "unique_seat_count": rng.randint(1, 6),
        "failed_select_ratio": rng.uniform(0.0, 0.15),
        "avg_action_interval": rng.uniform(700, 2500),   # ms, 느림+변동
        "page_transition_time": rng.uniform(800, 4000),  # ms, 읽는 시간
        "login_fail_ratio": rng.uniform(0.0, 0.10),
        "target_account_count": 1,
        "repeated_fail_count": rng.randint(0, 1),
        # LLM/chatbot (정상: 반복/우회 없음)
        "repeated_prompt_pattern": 0,
        "prompt_similarity": rng.uniform(0.05, 0.45),
        "jailbreak_keyword_count": 0,
        "excessive_token_request": 0,
    }


def feat_simple_bot(rng, level, n_levels):
    """단순 봇: 기계적(간격 짧고 일정), 스캔/실패 많음. 레벨↑ = 공격성↑."""
    a = (level - 1) / max(1, n_levels - 1) if n_levels > 1 else 0.0  # 0..1 공격성
    rps = rng.uniform(*RPS_MACRO) * (1.0 + 0.05 * a)
    return {
        "user_id": rng.randint(1, 50),
        "src_ip": bot_ip(rng, evasive=False),
        # 클릭(봇: 빠르고 일정 → ClickIntervalController 임계 avg<100, std<10)
        "avg_click_interval": rng.uniform(15, 90),
        "click_interval_std": rng.uniform(1, 9),
        "click_count": int(lerp(50, 300, a)),
        "requests_per_second": rps,
        "requests_per_minute": rps * 60 * rng.uniform(0.9, 1.0),  # 지속적
        "burst_request_count": int(lerp(15, 45, a) + rng.uniform(-3, 3)),
        "seat_change_count": int(lerp(8, 25, a)),
        "unique_seat_count": int(lerp(20, 60, a)),
        "failed_select_ratio": clamp(lerp(0.4, 0.85, a) + rng.uniform(-0.05, 0.05), 0, 1),
        "avg_action_interval": rng.uniform(10, 120),     # ms, 빠르고 일정
        "page_transition_time": rng.uniform(20, 200),    # ms, 즉시 이동
        "login_fail_ratio": clamp(lerp(0.2, 0.75, a), 0, 1),
        "target_account_count": int(lerp(3, 25, a)),
        "repeated_fail_count": int(lerp(5, 35, a)),
        # LLM/chatbot (봇: 동일 프롬프트 반복·우회 키워드)
        "repeated_prompt_pattern": 1,
        "prompt_similarity": rng.uniform(0.8, 1.0),
        "jailbreak_keyword_count": int(lerp(0, 6, a)),
        "excessive_token_request": 1 if rng.random() < lerp(0.4, 0.9, a) else 0,
    }


def feat_mimic_bot(rng, level, n_levels):
    """흉내 봇: 레벨↑ = 사람 흉내 강화(회피). 고레벨은 정상 대역으로 잠입.
       e(회피강도) 0→1 에 따라 모든 피처가 정상 쪽으로 수렴한다."""
    e = (level - 1) / max(1, n_levels - 1) if n_levels > 1 else 0.0
    # RPS: 레벨1 ≈ 18(매크로), 레벨N ≈ 11.5(정상 상단으로 잠입)
    rps = jitter(rng, lerp(18.0, 11.5, e), 0.08)
    return {
        "user_id": rng.randint(1, 50),
        "src_ip": bot_ip(rng, evasive=True),
        # 클릭: 레벨↑ 일수록 사람처럼 느리고 변동(std) 커짐
        "avg_click_interval": jitter(rng, lerp(80, 600, e), 0.2),
        "click_interval_std": jitter(rng, lerp(8, 120, e), 0.2),
        "click_count": int(lerp(80, 15, e)),
        "requests_per_second": rps,
        "requests_per_minute": rps * 60 * rng.uniform(0.6, 0.85),
        "burst_request_count": int(lerp(12, 4, e) + rng.uniform(-1, 1)),
        "seat_change_count": int(lerp(8, 2, e)),
        "unique_seat_count": int(lerp(25, 6, e)),
        "failed_select_ratio": clamp(lerp(0.40, 0.08, e) + rng.uniform(-0.03, 0.03), 0, 1),
        # 간격: 레벨↑ 일수록 사람처럼 느리고 흔들리게
        "avg_action_interval": jitter(rng, lerp(150, 1200, e), 0.25),
        "page_transition_time": jitter(rng, lerp(200, 1600, e), 0.25),
        "login_fail_ratio": clamp(lerp(0.30, 0.05, e), 0, 1),
        "target_account_count": max(1, int(round(lerp(5, 1, e)))),
        "repeated_fail_count": max(0, int(round(lerp(8, 1, e)))),
        # LLM/chatbot: 고레벨 = 회피(반복/유사도/우회 ↓)
        "repeated_prompt_pattern": 1 if e < 0.5 else 0,
        "prompt_similarity": lerp(0.85, 0.30, e),
        "jailbreak_keyword_count": max(0, int(round(lerp(2, 0, e)))),
        "excessive_token_request": 1 if e < 0.5 and rng.random() < 0.5 else 0,
    }


# ------------------------------------------------------------
# 4) 타입 정규화 (스키마에 맞춤)
# ------------------------------------------------------------
INT_FIELDS = {
    "user_id", "click_count", "burst_request_count", "seat_change_count",
    "unique_seat_count", "target_account_count", "repeated_fail_count",
    "jailbreak_keyword_count",
}
FLOAT_FIELDS = {
    "avg_click_interval", "click_interval_std", "prompt_similarity",
    "requests_per_second", "requests_per_minute", "failed_select_ratio",
    "avg_action_interval", "page_transition_time", "login_fail_ratio",
}
TINYINT_FIELDS = {"repeated_prompt_pattern", "excessive_token_request"}


def finalize(features, ts):
    rec = {}
    for k in SCHEMA_COLUMNS:
        if k == "timestamp":
            rec[k] = ts.strftime("%Y-%m-%d %H:%M:%S")
            continue
        if k == "src_ip":
            rec[k] = features[k]
            continue
        v = features[k]
        if k in TINYINT_FIELDS:
            rec[k] = 1 if (v and round(v) >= 1) else 0
        elif k in INT_FIELDS:
            rec[k] = int(max(0, round(v)))
        elif k in FLOAT_FIELDS:
            rec[k] = round(float(max(0.0, v)), 3)
        else:
            rec[k] = v
    return rec


# ------------------------------------------------------------
# 5) 시뮬레이션 모드: 레코드 묶음 생성
# ------------------------------------------------------------
def generate_dataset(rng, counts, n_levels, window_minutes):
    """
    counts = {"normal": int, "simple_bot": int, "mimic_bot": int}
    n_levels: 단순봇/흉내봇 난도 단계 수
    return: list[dict]  (스키마 필드 + _label/_profile/_level 메타)
    """
    base = datetime.now() - timedelta(minutes=window_minutes)
    out = []

    def stamp():
        # 윈도우 내 임의 시각 분산
        return base + timedelta(seconds=rng.uniform(0, window_minutes * 60))

    # 정상
    for _ in range(counts.get("normal", 0)):
        rec = finalize(feat_normal(rng), stamp())
        rec.update(_label="normal", _profile="normal", _level=0)
        out.append(rec)

    # 단순 봇 (레벨 균등 분배)
    for i in range(counts.get("simple_bot", 0)):
        lv = (i % n_levels) + 1
        rec = finalize(feat_simple_bot(rng, lv, n_levels), stamp())
        rec.update(_label="macro", _profile="simple_bot", _level=lv)
        out.append(rec)

    # 흉내 봇 (레벨 균등 분배)
    for i in range(counts.get("mimic_bot", 0)):
        lv = (i % n_levels) + 1
        rec = finalize(feat_mimic_bot(rng, lv, n_levels), stamp())
        rec.update(_label="macro", _profile="mimic_bot", _level=lv)
        out.append(rec)

    out.sort(key=lambda r: r["timestamp"])
    return out


# ------------------------------------------------------------
# 6) 출력기 (JSONL / SQL / CSV)
# ------------------------------------------------------------
def write_jsonl(records, path):
    with open(path, "w", encoding="utf-8") as f:
        for r in records:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")


def _sql_val(col, v):
    if col in ("src_ip", "timestamp"):
        return "'" + str(v).replace("'", "''") + "'"
    return str(v)


def write_sql(records, path, table="log_behavior_feature"):
    cols = ", ".join(SCHEMA_COLUMNS)
    with open(path, "w", encoding="utf-8") as f:
        f.write(f"-- log_behavior_feature 합성 데이터 ({len(records)}건)\n")
        f.write("-- 인가된 자체 랩 전용 / 탐지모델 학습용\n\n")
        for r in records:
            vals = ", ".join(_sql_val(c, r[c]) for c in SCHEMA_COLUMNS)
            f.write(f"INSERT INTO {table} ({cols}) VALUES ({vals});\n")


def write_csv(records, path):
    fields = SCHEMA_COLUMNS + ["_label", "_profile", "_level"]
    with open(path, "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        for r in records:
            w.writerow({k: r.get(k, "") for k in fields})


# ------------------------------------------------------------
# 7) 라이브 모드: 실제 홈페이지에 예매 플로우 수행 후 실측
#    엔드포인트/파라미터는 stu 프로젝트 컨트롤러 기준(필요시 PARAMS 조정).
# ------------------------------------------------------------
LIVE_PARAMS = {
    "login_url":   "/loginAction.do",
    "concert_url": "/concert/list.do",
    "seat_page":   "/seat/select.do",
    "seat_list":   "/seat/list.do",
    "seat_zone":   "/seat/zone.do",
    "seat_hold":   "/seat/hold.do",
    "seat_release":"/seat/release.do",
    "booking":     "/bookingCreate.do",
    "payment_form":"/payment/form.do",
    "payment":     "/payment/result.do",
    # POST 파라미터명 (CommandMap 기준)
    "p_id": "MEMBER_ID", "p_pw": "MEMBER_PASSWD",
}


def run_live(base_url, member_id, passwd, schedule_id, member_no, profile, rng,
             n_levels=3, level=1, max_actions=40, socks=None,
             book=False, book_seats=2, amount=None, seat_price=110000):
    """
    실제 서버에 행동을 수행하며 타임스탬프/성공·실패를 누적해 피처를 실측한다.
    profile: 'normal' | 'simple_bot' | 'mimic_bot'  (행동 페이싱 결정)
    member_no: 로그인 계정의 숫자 회원번호 (좌석 hold/release 의 필수 memberId 파라미터)
    socks: 'host:port' 형태 SOCKS5 프록시 (예: 127.0.0.1:1080).
           ssh -D 로 뚫은 Kali 터널을 가리키면 요청이 Kali(공격자 IP)에서 나간다.
    book: True 면 좌석 스캔 대신 실제 예매 완료(bookingCreate→payment)까지 수행.
          → 좌석이 RESERVED 로 소진되고 booking/payment 행이 생성된다 (테스트 계정 권장).
    book_seats: 예매할 좌석 수(앱 정책상 최대 2).
    amount: 결제 금액(미지정 시 좌석수×seat_price). 실제가격과 다르면 서버가 TAMPER 로 탐지.
    반환: finalize() 된 1건 레코드 (없으면 None)
    """
    try:
        import time
        import requests
    except ImportError:
        print("[live] 'requests' 모듈이 필요합니다:  pip install requests", file=sys.stderr)
        return None

    # 프로파일별 페이싱(요청 간 sleep 초)
    if profile == "normal":
        pace = lambda: rng.uniform(0.7, 2.5)
    elif profile == "simple_bot":
        pace = lambda: rng.uniform(0.01, 0.12)
    else:  # mimic_bot: 레벨↑ → 사람처럼 느려짐
        e = (level - 1) / max(1, n_levels - 1)
        pace = lambda: jitter(rng, lerp(0.15, 1.2, e), 0.25)

    s = requests.Session()

    # SOCKS5 프록시(Kali ssh -D 터널) 경유 설정
    if socks:
        try:
            import socks as _pysocks  # noqa: F401  (PySocks 설치 여부 확인)
        except ImportError:
            print("[live] SOCKS 사용에는 PySocks 필요:  pip install requests[socks]",
                  file=sys.stderr)
            return None
        # socks5h = DNS도 프록시(Kali) 쪽에서 해석 (DNS 누수 방지)
        s.proxies = {"http":  f"socks5h://{socks}",
                     "https": f"socks5h://{socks}"}
        print(f"[live] SOCKS5 경유: {socks} (요청이 Kali에서 송신됨)", file=sys.stderr)

    t_req = []          # 요청 시각들
    intervals = []      # 행동 간격(ms)
    seats_seen = set()
    seat_changes = 0
    sel_attempts = 0
    sel_fails = 0
    login_attempts = 0
    login_fails = 0

    def hit(method, path, **kw):
        nonlocal t_req
        url = base_url.rstrip("/") + path
        try:
            r = s.request(method, url, timeout=8, **kw)
        except Exception:
            r = None
        t_req.append(time.time())
        if len(t_req) >= 2:
            intervals.append((t_req[-1] - t_req[-2]) * 1000.0)
        return r

    def ok_of(r):
        return r is not None and getattr(r, "status_code", 999) < 400

    # 1) 로그인
    login_attempts += 1
    if not ok_of(hit("POST", LIVE_PARAMS["login_url"],
                     data={LIVE_PARAMS["p_id"]: member_id, LIVE_PARAMS["p_pw"]: passwd})):
        login_fails += 1
    time.sleep(pace())

    # 2) 콘서트 목록 + 좌석 페이지
    hit("GET", LIVE_PARAMS["concert_url"]); time.sleep(pace())
    hit("GET", LIVE_PARAMS["seat_page"], params={"scheduleId": schedule_id})
    time.sleep(pace())

    # 3) 좌석 단계 — 모드 분기
    booking_ok = False
    booking_id = None

    if book:
        # [실제 예매 모드] 실제 AVAILABLE 좌석을 조회해 선택
        # (무작위 ID는 점유석/타스케줄 좌석이라 hold 실패 → 예매 실패의 원인)
        r = hit("GET", LIVE_PARAMS["seat_list"], params={"scheduleId": schedule_id})
        avail = []
        total_seats = 0
        status_counts = {}
        try:
            data = r.json() if r is not None else []
            total_seats = len(data)
            for x in data:
                st = str(x.get("status", "")).upper()
                status_counts[st] = status_counts.get(st, 0) + 1
                if st == "AVAILABLE":
                    avail.append(str(x.get("seatId")))
        except Exception as ex:
            print(f"[live] 좌석목록 파싱 실패: {ex} "
                  f"(HTTP {getattr(r, 'status_code', '?')} · 응답이 JSON이 아닐 수 있음)",
                  file=sys.stderr)
        # 진단: 그 스케줄의 좌석 총수와 상태 분포 출력
        print(f"[live] scheduleId={schedule_id}: 좌석 {total_seats}개, 상태={status_counts}",
              file=sys.stderr)
        rng.shuffle(avail)
        picks = avail[:max(1, book_seats)]
        if not picks:
            print("[live] 예매 실패: 예매 가능한 좌석 0개 "
                  "→ 총 0개면 다른 --schedule-id 시도 / 전석 점유면 reset.sql 실행", file=sys.stderr)

        held = []
        for seat_id in picks:
            seats_seen.add(seat_id); sel_attempts += 1
            r = hit("POST", LIVE_PARAMS["seat_hold"],
                    data={"seatId": seat_id, "memberId": member_no,
                          "scheduleId": schedule_id,
                          "seat_page_load_ts": int(time.time() * 1000)})
            if ok_of(r):
                held.append(seat_id); seat_changes += 1
            else:
                sel_fails += 1
            time.sleep(pace())

        if held:
            seat_ids = ",".join(str(x) for x in held)
            # bookingCreate → 성공 시 /payment/form.do?bookingId=X 로 302 리다이렉트
            r = hit("POST", LIVE_PARAMS["booking"],
                    data={"scheduleId": schedule_id, "seatIds": seat_ids,
                          "seat_page_load_ts": int(time.time() * 1000)})
            if r is not None and getattr(r, "url", "") and "bookingId=" in r.url:
                booking_id = r.url.split("bookingId=")[1].split("&")[0]
            if booking_id:
                hit("GET", LIVE_PARAMS["payment_form"], params={"bookingId": booking_id})
                time.sleep(pace())
                pay_amount = amount if amount is not None else len(held) * seat_price
                r = hit("POST", LIVE_PARAMS["payment"],
                        data={"bookingId": booking_id, "amount": pay_amount,
                              "memberId": member_no})
                booking_ok = ok_of(r)
            print(f"[live] 예매 {'완료' if booking_ok else '실패'} "
                  f"(bookingId={booking_id}, seats={seat_ids}, "
                  f"amount={amount if amount is not None else len(held)*seat_price})",
                  file=sys.stderr)
        else:
            print("[live] 예매 실패: 좌석 hold 0건 (이미 점유/로그인 실패 가능)", file=sys.stderr)
    else:
        # [스캔 모드] 좌석 hold → 즉시 release 반복 (매크로 행동만, 예약 안 함)
        n_scan = max_actions if profile != "normal" else rng.randint(2, 6)
        for _ in range(n_scan):
            seat_id = rng.randint(1, 500)
            seats_seen.add(seat_id); sel_attempts += 1
            r = hit("POST", LIVE_PARAMS["seat_hold"],
                    data={"seatId": seat_id, "memberId": member_no,
                          "scheduleId": schedule_id,
                          "seat_page_load_ts": int(time.time() * 1000)})
            if ok_of(r):
                seat_changes += 1
                hit("POST", LIVE_PARAMS["seat_release"],
                    data={"seatId": seat_id, "memberId": member_no,
                          "scheduleId": schedule_id})
            else:
                sel_fails += 1
            time.sleep(pace())

    # 4) 피처 계산
    duration = max(0.001, (t_req[-1] - t_req[0])) if len(t_req) >= 2 else 1.0
    total = len(t_req)
    rps = total / duration
    avg_iv = (sum(intervals) / len(intervals)) if intervals else 0.0
    import statistics
    iv_std = statistics.pstdev(intervals) if len(intervals) > 1 else 0.0
    feat = {
        "user_id": rng.randint(1, 50),         # behavior는 NOT NULL
        "src_ip": "(live)",  # 실제 출발지는 서버측 로그가 기록
        "avg_click_interval": avg_iv,          # 실측 행동 간격을 클릭 간격으로 사용
        "click_interval_std": iv_std,
        "click_count": total,
        "requests_per_second": rps,
        "requests_per_minute": rps * 60,
        "burst_request_count": total,
        "seat_change_count": seat_changes,
        "unique_seat_count": len(seats_seen),
        "failed_select_ratio": (sel_fails / sel_attempts) if sel_attempts else 0.0,
        "avg_action_interval": avg_iv,
        "page_transition_time": avg_iv,
        "login_fail_ratio": (login_fails / login_attempts) if login_attempts else 0.0,
        "target_account_count": 1,
        "repeated_fail_count": sel_fails,
        # 예매 플로우는 챗봇 미사용 → LLM 피처는 0/저값
        "repeated_prompt_pattern": 0,
        "prompt_similarity": 0.0,
        "jailbreak_keyword_count": 0,
        "excessive_token_request": 1 if (profile != "normal" and rps > 12) else 0,
    }
    rec = finalize(feat, datetime.now())
    rec.update(_label=("normal" if profile == "normal" else "macro"),
               _profile=profile, _level=level,
               _booking_ok=booking_ok, _booking_id=booking_id)
    return rec


# ------------------------------------------------------------
# 8) CLI
# ------------------------------------------------------------
def main(argv=None):
    p = argparse.ArgumentParser(
        description="티켓팅 행위 로그 시뮬레이터 / 자동 예매 봇 (인가된 랩 전용)")
    p.add_argument("--mode", choices=["sim", "live"], default="sim")
    p.add_argument("--levels", type=int, default=3, help="단순봇/흉내봇 난도 단계 수 N")
    p.add_argument("--seed", type=int, default=None, help="재현용 시드")
    p.add_argument("--window-min", type=int, default=60, help="타임스탬프 분산 윈도우(분)")
    # sim 개수
    p.add_argument("--normal", type=int, default=200)
    p.add_argument("--simple-bot", type=int, default=90)
    p.add_argument("--mimic-bot", type=int, default=90)
    # 출력
    p.add_argument("--out", default="behavior_logs", help="출력 파일 접두사")
    p.add_argument("--format", default="jsonl,sql",
                   help="jsonl,sql,csv 중 콤마구분")
    # live 전용
    p.add_argument("--base-url", default="http://yanus.com")
    p.add_argument("--member-id", default="kim@test.com")
    p.add_argument("--passwd", default="test1234")
    p.add_argument("--member-no", default="1", help="로그인 계정의 숫자 회원번호(좌석 memberId)")
    p.add_argument("--schedule-id", type=int, default=1)
    p.add_argument("--live-profile", choices=["normal", "simple_bot", "mimic_bot"],
                   default="simple_bot")
    p.add_argument("--live-level", type=int, default=1)
    p.add_argument("--socks", default=None,
                   help="SOCKS5 프록시 host:port (예: 127.0.0.1:1080) — Kali ssh -D 터널 경유")
    p.add_argument("--book", action="store_true",
                   help="좌석 스캔 대신 실제 예매 완료(bookingCreate→payment) 수행")
    p.add_argument("--book-seats", type=int, default=2, help="예매 좌석 수(최대 2)")
    p.add_argument("--amount", type=int, default=None,
                   help="결제 금액(미지정 시 좌석수×seat-price). 실제가와 다르면 TAMPER 테스트")
    p.add_argument("--seat-price", type=int, default=110000, help="좌석 단가(기본 110000)")
    args = p.parse_args(argv)

    rng = random.Random(args.seed)
    fmts = [x.strip() for x in args.format.split(",") if x.strip()]

    if args.mode == "sim":
        counts = {"normal": args.normal,
                  "simple_bot": args.simple_bot,
                  "mimic_bot": args.mimic_bot}
        records = generate_dataset(rng, counts, args.levels, args.window_min)
    else:
        rec = run_live(args.base_url, args.member_id, args.passwd,
                       args.schedule_id, args.member_no, args.live_profile, rng,
                       n_levels=args.levels, level=args.live_level, socks=args.socks,
                       book=args.book, book_seats=args.book_seats,
                       amount=args.amount, seat_price=args.seat_price)
        records = [rec] if rec else []

    if not records:
        print("생성된 레코드가 없습니다.", file=sys.stderr)
        return 1

    if "jsonl" in fmts:
        write_jsonl(records, args.out + ".jsonl")
    if "sql" in fmts:
        write_sql(records, args.out + ".sql")
    if "csv" in fmts:
        write_csv(records, args.out + ".csv")

    # 요약
    from collections import Counter
    by = Counter(r["_profile"] for r in records)
    rps_by = {}
    for prof in ("normal", "simple_bot", "mimic_bot"):
        vals = [r["requests_per_second"] for r in records if r["_profile"] == prof]
        if vals:
            rps_by[prof] = (round(min(vals), 1), round(max(vals), 1))
    print(f"[OK] {len(records)}건 생성  →  {args.out}.({'/'.join(fmts)})")
    print(f"     프로파일 분포: {dict(by)}")
    print(f"     RPS 범위     : {rps_by}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
