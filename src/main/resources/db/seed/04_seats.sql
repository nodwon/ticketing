-- =====================================================================
-- 04_seats.sql  — 좌석 더미 데이터
-- 실행 전 필요 : 03_concert_schedules.sql 실행 완료
--
-- 좌석 구조    : 모든 공연 일정 동일
--               50열(seat_row) × 10번(seat_col) = 500석
-- 가격         : 110,000원 통일
-- 상태         : 전부 'AVAILABLE'
--
-- ⚠️ DBeaver 실행 방법:
--    1) 파일 전체 내용을 TICKET_DEV 접속 SQL Editor에 붙여넣기
--    2) Ctrl+A (전체 선택)
--    3) Alt+X (스크립트 전체 실행) — Ctrl+Enter 만 누르면 일부만 실행됨
--
-- ⚠️ 좌석 수 / 한 줄 좌석 수 / 가격을 바꾸려면
--    아래 [수정 가능 영역] 의 상수 값만 변경하세요.
-- =====================================================================

DECLARE
    -- ┌────────────────────────────────────────────────┐
    -- │ 🔧 [수정 가능 영역] — 여기 값만 바꾸세요        │
    -- └────────────────────────────────────────────────┘
    v_seats_per_show  CONSTANT NUMBER := 500;       -- 회차당 총 좌석 수 (예: 300, 500, 800)
    v_cols            CONSTANT NUMBER := 10;        -- 한 줄(seat_row) 좌석 수
    v_price           CONSTANT NUMBER := 110000;    -- 좌석 가격 (원)
    -- ─────────────────────────────────────────────────

    v_rows   NUMBER := v_seats_per_show / v_cols;   -- 자동 계산: 열 수 = 총좌석 ÷ 한줄
    v_total  NUMBER := 0;
BEGIN
    -- 사전 검증: 총 좌석 수가 한 줄로 딱 나누어 떨어져야 함
    IF MOD(v_seats_per_show, v_cols) != 0 THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'v_seats_per_show(' || v_seats_per_show || ')는 v_cols(' || v_cols || ')의 배수여야 합니다.'
        );
    END IF;

    -- 모든 일정의 total_seats / available_seats 일괄 갱신
    UPDATE concert_schedules
       SET total_seats     = v_seats_per_show,
           available_seats = v_seats_per_show;

    -- 일정별로 좌석 자동 생성
    FOR sched IN (
        SELECT schedule_id FROM concert_schedules ORDER BY schedule_id
    ) LOOP
        FOR r IN 1..v_rows LOOP
            FOR c IN 1..v_cols LOOP
                INSERT INTO seats(schedule_id, seat_row, seat_col, price, status)
                VALUES (sched.schedule_id, r, c, v_price, 'AVAILABLE');
                v_total := v_total + 1;
            END LOOP;
        END LOOP;

        DBMS_OUTPUT.PUT_LINE(
            'schedule_id=' || sched.schedule_id ||
            ' → ' || v_seats_per_show || ' seats (' || v_rows || ' rows × ' || v_cols || ' cols)'
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('=============================================');
    DBMS_OUTPUT.PUT_LINE('TOTAL SEATS INSERTED: ' || v_total);
    DBMS_OUTPUT.PUT_LINE('PRICE PER SEAT      : ' || TO_CHAR(v_price, 'FM999,999') || ' 원');
END;

COMMIT;


-- ─────────────────────────────────────────────────────────────
-- 확인
-- ─────────────────────────────────────────────────────────────
SELECT
    s.schedule_id,
    c.title,
    COUNT(*)         AS seat_count,
    MIN(seat_row)    AS min_row,
    MAX(seat_row)    AS max_row,
    MIN(seat_col)    AS min_col,
    MAX(seat_col)    AS max_col,
    MIN(price)       AS price
FROM seats s
JOIN concert_schedules cs ON s.schedule_id = cs.schedule_id
JOIN concerts c           ON cs.concert_id = c.concert_id
GROUP BY s.schedule_id, c.title
ORDER BY s.schedule_id;
