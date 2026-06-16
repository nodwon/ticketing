#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
============================================================
 booking_bot_gui.py  —  행위 로그 시뮬레이터 GUI (Tkinter)
------------------------------------------------------------
 booking_bot_sim.py 를 모듈로 재사용한다.
 - 파라미터 조절 → 즉시 데이터 생성
 - 산점도(축 선택 가능)로 정상/단순봇/흉내봇 분리를 시각화
 - 표(Treeview)로 레코드 확인
 - JSONL / SQL / CSV 저장
 - (선택) Splunk HEC 로 전송  ※ stdlib urllib 사용, 추가 설치 없음
 실행:  python booking_bot_gui.py
 의존성: 없음 (파이썬 표준 라이브러리 tkinter)
============================================================
"""

import os
import sys
import json
import random
import ssl
import threading
import urllib.request

import tkinter as tk
from tkinter import ttk, filedialog, messagebox

# 같은 폴더의 시뮬레이터 모듈 임포트
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import booking_bot_sim as sim   # noqa: E402

PROFILE_COLORS = {
    "normal":     "#2e7d32",   # 초록
    "simple_bot": "#c62828",   # 빨강
    "mimic_bot":  "#ef6c00",   # 주황
}
PROFILE_KR = {"normal": "정상", "simple_bot": "단순봇", "mimic_bot": "흉내봇"}

# 산점도 축으로 쓸 수 있는 수치 피처
NUMERIC_FIELDS = [c for c in sim.SCHEMA_COLUMNS if c not in ("src_ip", "timestamp")]


class App:
    def __init__(self, root):
        self.root = root
        self.records = []
        root.title("티켓팅 행위 로그 시뮬레이터 (Tkinter)")
        root.geometry("1180x720")

        self._build_controls()
        self._build_live_controls()
        self._build_body()
        self._build_footer()
        self.generate()  # 초기 1회 생성

    # ---------------- 상단 파라미터 ----------------
    def _build_controls(self):
        bar = ttk.LabelFrame(self.root, text="파라미터")
        bar.pack(fill="x", padx=8, pady=6)

        self.v_normal = tk.IntVar(value=200)
        self.v_simple = tk.IntVar(value=90)
        self.v_mimic  = tk.IntVar(value=90)
        self.v_levels = tk.IntVar(value=3)
        self.v_window = tk.IntVar(value=60)
        self.v_seed   = tk.StringVar(value="42")

        def add(col, label, var, frm=0, to=100000, inc=10, w=8):
            ttk.Label(bar, text=label).grid(row=0, column=col*2, padx=(10, 2), pady=6, sticky="e")
            ttk.Spinbox(bar, from_=frm, to=to, increment=inc, textvariable=var, width=w)\
                .grid(row=0, column=col*2+1, padx=(0, 6), pady=6, sticky="w")

        add(0, "정상", self.v_normal)
        add(1, "단순봇", self.v_simple)
        add(2, "흉내봇", self.v_mimic)
        add(3, "난도 N단계", self.v_levels, frm=1, to=10, inc=1, w=5)
        add(4, "시간창(분)", self.v_window, frm=1, to=1440, inc=10, w=6)
        ttk.Label(bar, text="시드").grid(row=0, column=10, padx=(10, 2), sticky="e")
        ttk.Entry(bar, textvariable=self.v_seed, width=7).grid(row=0, column=11, padx=(0, 6), sticky="w")

        ttk.Button(bar, text="▶ 생성", command=self.generate)\
            .grid(row=0, column=12, padx=10, pady=6)

    # ---------------- 라이브 공격 패널 ----------------
    def _build_live_controls(self):
        box = ttk.LabelFrame(self.root, text="라이브 공격 (실제 서버에 요청 → 결과를 표·차트에 추가)")
        box.pack(fill="x", padx=8, pady=(0, 6))

        self.lv_url     = tk.StringVar(value="http://yanus.com")
        self.lv_id      = tk.StringVar(value="kim@test.com")
        self.lv_pw      = tk.StringVar(value="test1234")
        self.lv_no      = tk.StringVar(value="1")
        self.lv_sched   = tk.StringVar(value="1")
        self.lv_profile = tk.StringVar(value="simple_bot")
        self.lv_level   = tk.IntVar(value=1)
        self.lv_socks   = tk.StringVar(value="")
        self.lv_repeat  = tk.IntVar(value=1)

        def lab(row, c, t):
            ttk.Label(box, text=t).grid(row=row, column=c, padx=(10, 2), pady=4, sticky="e")

        lab(0, 0, "base-url"); ttk.Entry(box, textvariable=self.lv_url, width=20).grid(row=0, column=1, sticky="w")
        lab(0, 2, "계정");     ttk.Entry(box, textvariable=self.lv_id, width=16).grid(row=0, column=3, sticky="w")
        lab(0, 4, "pw");       ttk.Entry(box, textvariable=self.lv_pw, width=10).grid(row=0, column=5, sticky="w")
        lab(0, 6, "회원no");   ttk.Entry(box, textvariable=self.lv_no, width=5).grid(row=0, column=7, sticky="w")

        lab(1, 0, "scheduleId"); ttk.Entry(box, textvariable=self.lv_sched, width=6).grid(row=1, column=1, sticky="w")
        lab(1, 2, "프로파일");   ttk.Combobox(box, textvariable=self.lv_profile,
                                              values=["normal", "simple_bot", "mimic_bot"],
                                              width=12, state="readonly").grid(row=1, column=3, sticky="w")
        lab(1, 4, "레벨");       ttk.Spinbox(box, from_=1, to=10, textvariable=self.lv_level, width=4).grid(row=1, column=5, sticky="w")
        lab(1, 6, "반복");       ttk.Spinbox(box, from_=1, to=200, textvariable=self.lv_repeat, width=5).grid(row=1, column=7, sticky="w")

        lab(2, 0, "SOCKS"); ttk.Entry(box, textvariable=self.lv_socks, width=20).grid(row=2, column=1, sticky="w")
        ttk.Label(box, text="(예: 127.0.0.1:1080 — Kali 터널 경유 / 비우면 직접)", foreground="#888")\
            .grid(row=2, column=2, columnspan=4, sticky="w")
        self.lv_btn = ttk.Button(box, text="▶ 라이브 공격 실행", command=self.run_live_attack)
        self.lv_btn.grid(row=2, column=6, columnspan=2, padx=8, pady=4)

        self.lv_book = tk.BooleanVar(value=False)
        self.lv_bookseats = tk.IntVar(value=2)
        ttk.Checkbutton(box, text="실제 예매 완료 (bookingCreate→payment · 좌석 RESERVED 소진)",
                        variable=self.lv_book).grid(row=3, column=0, columnspan=4, padx=10, sticky="w")
        ttk.Label(box, text="예매 좌석수").grid(row=3, column=4, sticky="e", padx=(10, 2))
        ttk.Spinbox(box, from_=1, to=2, textvariable=self.lv_bookseats, width=4).grid(row=3, column=5, sticky="w")

        self.lv_status = ttk.Label(box, text="대기 중 (SOCKS 사용 시 ssh -D 터널을 먼저 여세요)",
                                   foreground="#777")
        self.lv_status.grid(row=4, column=0, columnspan=8, padx=10, pady=(0, 4), sticky="w")

    # ---------------- 본문: 좌(차트) / 우(표) ----------------
    def _build_body(self):
        body = ttk.Frame(self.root)
        body.pack(fill="both", expand=True, padx=8, pady=4)

        # 좌: 산점도
        left = ttk.LabelFrame(body, text="산점도 (정상=초록 / 단순봇=빨강 / 흉내봇=주황)")
        left.pack(side="left", fill="both", expand=True, padx=(0, 4))

        axes = ttk.Frame(left)
        axes.pack(fill="x", padx=6, pady=4)
        ttk.Label(axes, text="X").pack(side="left")
        self.v_x = tk.StringVar(value="requests_per_second")
        ttk.Combobox(axes, textvariable=self.v_x, values=NUMERIC_FIELDS, width=22,
                     state="readonly").pack(side="left", padx=4)
        ttk.Label(axes, text="Y").pack(side="left", padx=(10, 0))
        self.v_y = tk.StringVar(value="click_interval_std")
        ttk.Combobox(axes, textvariable=self.v_y, values=NUMERIC_FIELDS, width=22,
                     state="readonly").pack(side="left", padx=4)
        self.v_x.trace_add("write", lambda *a: self.draw_scatter())
        self.v_y.trace_add("write", lambda *a: self.draw_scatter())

        self.canvas = tk.Canvas(left, bg="white", highlightthickness=1,
                                highlightbackground="#ccc")
        self.canvas.pack(fill="both", expand=True, padx=6, pady=6)
        self.canvas.bind("<Configure>", lambda e: self.draw_scatter())

        # 우: 표
        right = ttk.LabelFrame(body, text="레코드 (표는 최대 1000행 표시 · 저장은 전체)")
        right.pack(side="right", fill="both", expand=True, padx=(4, 0))

        cols = ("profile", "level", "user_id", "src_ip", "rps", "click_iv",
                "click_std", "fail", "jb", "psim", "token", "time")
        heads = ("프로파일", "Lv", "user", "src_ip", "rps", "click_iv", "click_std",
                 "fail", "jb", "p_sim", "tok", "time")
        self.tree = ttk.Treeview(right, columns=cols, show="headings", height=20)
        widths = (70, 30, 40, 110, 50, 70, 70, 50, 30, 50, 35, 130)
        for c, h, w in zip(cols, heads, widths):
            self.tree.heading(c, text=h)
            self.tree.column(c, width=w, anchor="center")
        for prof, color in PROFILE_COLORS.items():
            self.tree.tag_configure(prof, foreground=color)
        vsb = ttk.Scrollbar(right, orient="vertical", command=self.tree.yview)
        self.tree.configure(yscrollcommand=vsb.set)
        self.tree.pack(side="left", fill="both", expand=True, padx=(6, 0), pady=6)
        vsb.pack(side="right", fill="y", pady=6)

    # ---------------- 하단: 요약 + 저장 + Splunk ----------------
    def _build_footer(self):
        foot = ttk.Frame(self.root)
        foot.pack(fill="x", padx=8, pady=(0, 8))

        self.summary = ttk.Label(foot, text="", foreground="#333")
        self.summary.pack(side="left", padx=4)

        ttk.Button(foot, text="JSONL 저장", command=lambda: self.save("jsonl")).pack(side="right", padx=3)
        ttk.Button(foot, text="SQL 저장", command=lambda: self.save("sql")).pack(side="right", padx=3)
        ttk.Button(foot, text="CSV 저장", command=lambda: self.save("csv")).pack(side="right", padx=3)
        ttk.Button(foot, text="Splunk HEC 전송…", command=self.open_hec).pack(side="right", padx=10)

    # ---------------- 동작 ----------------
    def generate(self):
        seed = self.v_seed.get().strip()
        rng = random.Random(int(seed)) if seed.lstrip("-").isdigit() else random.Random()
        counts = {"normal": self.v_normal.get(),
                  "simple_bot": self.v_simple.get(),
                  "mimic_bot": self.v_mimic.get()}
        self.records = sim.generate_dataset(rng, counts, self.v_levels.get(), self.v_window.get())
        self.refresh_table()
        self.draw_scatter()
        self.update_summary()

    def update_summary(self):
        from collections import Counter
        by = Counter(r["_profile"] for r in self.records)
        parts = [f"{PROFILE_KR[p]} {by.get(p,0)}" for p in ("normal", "simple_bot", "mimic_bot")]
        self.summary.config(text=f"총 {len(self.records)}건  |  " + "  ·  ".join(parts))

    # ---------------- 라이브 공격 실행 ----------------
    def run_live_attack(self):
        self.lv_btn.config(state="disabled")
        self.lv_status.config(text="공격 준비 중…", foreground="#555")
        p = dict(
            base_url=self.lv_url.get().strip(),
            member_id=self.lv_id.get().strip(),
            passwd=self.lv_pw.get().strip(),
            member_no=self.lv_no.get().strip(),
            schedule_id=self.lv_sched.get().strip(),
            profile=self.lv_profile.get(),
            level=self.lv_level.get(),
            n_levels=self.v_levels.get(),
            socks=(self.lv_socks.get().strip() or None),
            repeat=max(1, self.lv_repeat.get()),
            book=self.lv_book.get(),
            book_seats=self.lv_bookseats.get(),
        )
        threading.Thread(target=self._live_worker, args=(p,), daemon=True).start()

    def _live_worker(self, p):
        new = []
        for i in range(p["repeat"]):
            self.root.after(0, lambda i=i: self.lv_status.config(
                text=f"공격 중… {i+1}/{p['repeat']}", foreground="#555"))
            try:
                rec = sim.run_live(
                    p["base_url"], p["member_id"], p["passwd"], p["schedule_id"],
                    p["member_no"], p["profile"], random.Random(),
                    n_levels=p["n_levels"], level=p["level"], socks=p["socks"],
                    book=p["book"], book_seats=p["book_seats"])
            except Exception as e:
                msg = str(e)
                self.root.after(0, lambda m=msg: self.lv_status.config(
                    text=f"오류: {m}", foreground="#c62828"))
                rec = None
                break
            if rec:
                new.append(rec)
        self.root.after(0, lambda: self._live_done(new, p["repeat"]))

    def _live_done(self, new, total):
        self.lv_btn.config(state="normal")
        if not new:
            self.lv_status.config(
                text="실패: 0건 (PySocks 미설치 / 터널 미연결 / 로그인·좌석 실패 가능)",
                foreground="#c62828")
            return
        self.records.extend(new)
        self.refresh_table(); self.draw_scatter(); self.update_summary()
        rps = [r["requests_per_second"] for r in new]
        booked = sum(1 for r in new if r.get("_booking_ok"))
        book_txt = f"  ·  예매완료 {booked}건" if any("_booking_id" in r for r in new) else ""
        self.lv_status.config(
            text=f"완료: {len(new)}/{total}건 추가  ·  실측 rps {min(rps):.1f}~{max(rps):.1f}{book_txt}  ·  표의 src_ip=(live) 행 확인",
            foreground="#2e7d32")

    def refresh_table(self):
        self.tree.delete(*self.tree.get_children())
        for r in self.records[:1000]:
            self.tree.insert("", "end", tags=(r["_profile"],), values=(
                PROFILE_KR[r["_profile"]], r["_level"], r["user_id"], r["src_ip"],
                f"{r['requests_per_second']:.1f}", f"{r['avg_click_interval']:.0f}",
                f"{r['click_interval_std']:.1f}", f"{r['failed_select_ratio']:.2f}",
                r["jailbreak_keyword_count"], f"{r['prompt_similarity']:.2f}",
                r["excessive_token_request"], r["timestamp"][11:],
            ))

    def draw_scatter(self):
        c = self.canvas
        c.delete("all")
        if not self.records:
            return
        xf, yf = self.v_x.get(), self.v_y.get()
        W = c.winfo_width() or 560
        H = c.winfo_height() or 460
        pad = 48
        xs = [r[xf] for r in self.records]
        ys = [r[yf] for r in self.records]
        xmin, xmax = min(xs), max(xs)
        ymin, ymax = min(ys), max(ys)
        if xmax == xmin: xmax = xmin + 1
        if ymax == ymin: ymax = ymin + 1

        def px(v): return pad + (v - xmin) / (xmax - xmin) * (W - 2 * pad)
        def py(v): return H - pad - (v - ymin) / (ymax - ymin) * (H - 2 * pad)

        # 축
        c.create_line(pad, H - pad, W - pad, H - pad, fill="#888")
        c.create_line(pad, pad, pad, H - pad, fill="#888")
        c.create_text(W / 2, H - 14, text=xf, fill="#444")
        c.create_text(14, H / 2, text=yf, fill="#444", angle=90)
        for i in range(5):
            xv = xmin + (xmax - xmin) * i / 4
            yv = ymin + (ymax - ymin) * i / 4
            c.create_text(px(xv), H - pad + 12, text=f"{xv:.0f}", fill="#999", font=("", 7))
            c.create_text(pad - 18, py(yv), text=f"{yv:.0f}", fill="#999", font=("", 7))

        # 점
        for r in self.records:
            x, y = px(r[xf]), py(r[yf])
            col = PROFILE_COLORS[r["_profile"]]
            c.create_oval(x - 3, y - 3, x + 3, y + 3, fill=col, outline="")

        # 범례
        for i, (prof, col) in enumerate(PROFILE_COLORS.items()):
            yy = pad + 4 + i * 16
            c.create_rectangle(W - pad - 92, yy, W - pad - 82, yy + 10, fill=col, outline="")
            c.create_text(W - pad - 36, yy + 5, text=PROFILE_KR[prof], fill="#333", font=("", 8))

    def save(self, fmt):
        if not self.records:
            return
        ext = {"jsonl": ".jsonl", "sql": ".sql", "csv": ".csv"}[fmt]
        path = filedialog.asksaveasfilename(defaultextension=ext,
                                            initialfile=f"behavior_logs{ext}",
                                            filetypes=[(fmt.upper(), "*" + ext)])
        if not path:
            return
        {"jsonl": sim.write_jsonl, "sql": sim.write_sql, "csv": sim.write_csv}[fmt](self.records, path)
        messagebox.showinfo("저장 완료", f"{len(self.records)}건 저장:\n{path}")

    # ---------------- Splunk HEC ----------------
    def open_hec(self):
        if not self.records:
            return
        win = tk.Toplevel(self.root)
        win.title("Splunk HEC 전송")
        win.geometry("460x230")
        v_url   = tk.StringVar(value="https://10.0.200.201:8088")
        v_token = tk.StringVar(value="")
        v_index = tk.StringVar(value="ticketing_mltk")
        v_st    = tk.StringVar(value="ticketing:log_behavior_feature")

        for i, (lab, var) in enumerate([("HEC URL", v_url), ("Token", v_token),
                                        ("index", v_index), ("sourcetype", v_st)]):
            ttk.Label(win, text=lab).grid(row=i, column=0, padx=8, pady=6, sticky="e")
            ttk.Entry(win, textvariable=var, width=44).grid(row=i, column=1, padx=8, pady=6)

        status = ttk.Label(win, text="자체서명 인증서 허용(검증 생략)", foreground="#777")
        status.grid(row=4, column=0, columnspan=2, pady=4)

        def send():
            status.config(text="전송 중…")
            win.update_idletasks()
            threading.Thread(target=self._hec_send,
                             args=(v_url.get(), v_token.get(), v_index.get(),
                                   v_st.get(), status, win),
                             daemon=True).start()

        ttk.Button(win, text="전송", command=send).grid(row=5, column=1, sticky="e", padx=8, pady=8)

    def _hec_send(self, url, token, index, sourcetype, status, win):
        try:
            body = "".join(
                json.dumps({"index": index, "sourcetype": sourcetype,
                            "event": {k: r[k] for k in sim.SCHEMA_COLUMNS}},
                           ensure_ascii=False) + "\n"
                for r in self.records
            ).encode("utf-8")
            req = urllib.request.Request(
                url.rstrip("/") + "/services/collector/event",
                data=body, headers={"Authorization": f"Splunk {token}"})
            ctx = ssl.create_default_context()
            ctx.check_hostname = False
            ctx.verify_mode = ssl.CERT_NONE
            with urllib.request.urlopen(req, context=ctx, timeout=15) as resp:
                ok = resp.status
            self.root.after(0, lambda: status.config(
                text=f"전송 완료: {len(self.records)}건 (HTTP {ok})", foreground="#2e7d32"))
        except Exception as e:
            msg = str(e)
            self.root.after(0, lambda: status.config(text=f"실패: {msg}", foreground="#c62828"))


def main():
    root = tk.Tk()
    try:
        ttk.Style().theme_use("clam")
    except tk.TclError:
        pass
    App(root)
    root.mainloop()


if __name__ == "__main__":
    main()
