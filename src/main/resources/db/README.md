# 🗄️ DB Setup (DBeaver용)

티켓팅 프로젝트 DB 스키마 및 시드 데이터 — **DBeaver 호환 버전**

> 💡 SQL*Plus 전용 명령어(`SHOW`, `SET`, `/`)가 제거되어 DBeaver에서 바로 실행 가능합니다.

---

## 📁 구조

```
db/
├── 01_create_user.sql      TICKET_DEV 계정 생성 (최초 1회)
├── 02_ddl.sql              14개 테이블 생성
└── seed/
    ├── 01_members.sql      회원 5명
    ├── 02_concerts.sql     공연 5개
    ├── 03_concert_schedules.sql  일정 8회차
    ├── 04_seats.sql        좌석 4,000개 (회차당 500)
    ├── 05_bookings.sql     예매 4건
    └── reset.sql           초기화
```

---

## 🚀 빠른 시작

```bash
git pull
```

DBeaver에서 순서대로 실행:

```
SYSTEM 접속 → 01_create_user.sql           (최초 1회)
TICKET_DEV 접속 → 02_ddl.sql               (테이블 생성)
              → seed/01 ~ 05 순서대로      (더미 데이터)
```

### ⚠️ 실행 시 반드시 지킬 것

각 SQL 파일 실행할 때:

1. **TICKET_DEV 접속된 탭**에서 실행 (탭 상단에 `<XEPDB1 2>` 같은 표시 확인)
2. **Ctrl+A** 로 전체 선택
3. **Alt+X** 로 실행 (`Ctrl+Enter`만 누르면 일부만 실행됨)

> 💡 **왜 Alt+X인가**: DBeaver의 `Ctrl+Enter`는 빈 줄로 구분된 블록 중 커서가 있는 블록만 실행합니다. SQL 파일에는 INSERT 사이에 빈 줄이 있어서 일부만 실행되는 문제 발생. **반드시 전체 선택 후 Alt+X**.

---

## ✅ 검증

```sql
SELECT
    (SELECT COUNT(*) FROM members)            AS members,
    (SELECT COUNT(*) FROM concerts)           AS concerts,
    (SELECT COUNT(*) FROM concert_schedules)  AS schedules,
    (SELECT COUNT(*) FROM seats)              AS seats,
    (SELECT COUNT(*) FROM bookings)           AS bookings
FROM dual;
```

**결과**: `5 / 5 / 8 / 4000 / 4`

---

## 📘 자세한 가이드

- [개별 PC 테스트 DB 세팅 가이드](노션-링크)
- [서버 PC DB 쿼리 가이드](노션-링크)

---

## ⚠️ 주의

- 스키마 변경은 DB 담당자에게 요청 (직접 ALTER 금지)
- `reset.sql`은 로컬 DB에서만 사용
- **이 폴더의 SQL은 DBeaver 전용**입니다. SQL*Plus나 운영 서버 배포 시에는 별도 SQL*Plus용 버전을 사용하세요.

---

## 🔧 좌석 수/가격 변경

`seed/04_seats.sql` 상단 변수 영역 수정:

```sql
v_seats_per_show  CONSTANT NUMBER := 500;     -- 회차당 좌석 수
v_cols            CONSTANT NUMBER := 10;      -- 한 줄 좌석 수
v_price           CONSTANT NUMBER := 110000;  -- 가격
```
