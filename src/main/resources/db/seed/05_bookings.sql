-- =====================================================================
-- 05_bookings.sql  — 예매 더미 데이터
-- 실행 전 필요 : 04_seats.sql 실행 완료
-- 예매 시나리오 :
--   - 김철수: 잠비나이 콘서트 1석 (CONFIRMED)
--   - 이영희: 잠비나이 콘서트 2석 (PENDING)
--   - 박지민: 성시경 콘서트 (지난 공연, CANCELLED)
--   - 최수영: NEWJEANS 1석 (CONFIRMED)
--
-- ⚠️ DBeaver 실행 방법:
--    1) 파일 전체 내용을 TICKET_DEV 접속 SQL Editor에 붙여넣기
--    2) Ctrl+A (전체 선택)
--    3) Alt+X (스크립트 전체 실행)
-- =====================================================================

-- ─────────────────────────────────────────────────────────────
-- 1. 김철수 → 잠비나이 1석 (CONFIRMED)
-- ─────────────────────────────────────────────────────────────
DECLARE
    v_member_id   members.member_id%TYPE;
    v_schedule_id concert_schedules.schedule_id%TYPE;
    v_seat_id     seats.seat_id%TYPE;
    v_price       seats.price%TYPE;
    v_booking_id  bookings.booking_id%TYPE;
BEGIN
    SELECT member_id INTO v_member_id FROM members WHERE email = 'kim@test.com';

    SELECT s.schedule_id INTO v_schedule_id
    FROM concert_schedules s JOIN concerts c ON s.concert_id = c.concert_id
    WHERE c.title LIKE '잠비나이%' AND ROWNUM = 1;

    SELECT seat_id, price INTO v_seat_id, v_price
    FROM seats WHERE schedule_id = v_schedule_id AND seat_row = 1 AND seat_col = 1;

    INSERT INTO bookings(member_id, schedule_id, total_price, status)
    VALUES (v_member_id, v_schedule_id, v_price, 'CONFIRMED')
    RETURNING booking_id INTO v_booking_id;

    INSERT INTO booking_items(booking_id, seat_id, unit_price)
    VALUES (v_booking_id, v_seat_id, v_price);

    UPDATE seats SET status = 'RESERVED' WHERE seat_id = v_seat_id;
    UPDATE concert_schedules SET available_seats = available_seats - 1 WHERE schedule_id = v_schedule_id;
END;
/

-- ─────────────────────────────────────────────────────────────
-- 2. 이영희 → 잠비나이 2석 (PENDING, 결제 대기)
-- ─────────────────────────────────────────────────────────────
DECLARE
    v_member_id   members.member_id%TYPE;
    v_schedule_id concert_schedules.schedule_id%TYPE;
    v_seat_id1    seats.seat_id%TYPE;
    v_seat_id2    seats.seat_id%TYPE;
    v_price       seats.price%TYPE;
    v_booking_id  bookings.booking_id%TYPE;
BEGIN
    SELECT member_id INTO v_member_id FROM members WHERE email = 'lee@test.com';

    SELECT s.schedule_id INTO v_schedule_id
    FROM concert_schedules s JOIN concerts c ON s.concert_id = c.concert_id
    WHERE c.title LIKE '잠비나이%' AND ROWNUM = 1;

    SELECT seat_id, price INTO v_seat_id1, v_price
    FROM seats WHERE schedule_id = v_schedule_id AND seat_row = 2 AND seat_col = 1;
    SELECT seat_id INTO v_seat_id2
    FROM seats WHERE schedule_id = v_schedule_id AND seat_row = 2 AND seat_col = 2;

    INSERT INTO bookings(member_id, schedule_id, total_price, status)
    VALUES (v_member_id, v_schedule_id, v_price * 2, 'PENDING')
    RETURNING booking_id INTO v_booking_id;

    INSERT INTO booking_items(booking_id, seat_id, unit_price) VALUES (v_booking_id, v_seat_id1, v_price);
    INSERT INTO booking_items(booking_id, seat_id, unit_price) VALUES (v_booking_id, v_seat_id2, v_price);

    UPDATE seats SET status = 'HELD' WHERE seat_id IN (v_seat_id1, v_seat_id2);
END;
/

-- ─────────────────────────────────────────────────────────────
-- 3. 박지민 → 성시경 (지난 공연, CANCELLED)
-- ─────────────────────────────────────────────────────────────
DECLARE
    v_member_id   members.member_id%TYPE;
    v_schedule_id concert_schedules.schedule_id%TYPE;
    v_seat_id     seats.seat_id%TYPE;
    v_price       seats.price%TYPE;
    v_booking_id  bookings.booking_id%TYPE;
BEGIN
    SELECT member_id INTO v_member_id FROM members WHERE email = 'park@test.com';

    SELECT s.schedule_id INTO v_schedule_id
    FROM concert_schedules s JOIN concerts c ON s.concert_id = c.concert_id
    WHERE c.title LIKE '성시경%' AND ROWNUM = 1;

    SELECT seat_id, price INTO v_seat_id, v_price
    FROM seats WHERE schedule_id = v_schedule_id AND seat_row = 1 AND seat_col = 1;

    INSERT INTO bookings(member_id, schedule_id, total_price, status, created_at)
    VALUES (v_member_id, v_schedule_id, v_price, 'CANCELLED', SYSTIMESTAMP - INTERVAL '70' DAY)
    RETURNING booking_id INTO v_booking_id;

    INSERT INTO booking_items(booking_id, seat_id, unit_price)
    VALUES (v_booking_id, v_seat_id, v_price);
END;
/

-- ─────────────────────────────────────────────────────────────
-- 4. 최수영 → NEWJEANS 1석 (CONFIRMED)
-- ─────────────────────────────────────────────────────────────
DECLARE
    v_member_id   members.member_id%TYPE;
    v_schedule_id concert_schedules.schedule_id%TYPE;
    v_seat_id     seats.seat_id%TYPE;
    v_price       seats.price%TYPE;
    v_booking_id  bookings.booking_id%TYPE;
BEGIN
    SELECT member_id INTO v_member_id FROM members WHERE email = 'choi@test.com';

    SELECT s.schedule_id INTO v_schedule_id
    FROM concert_schedules s JOIN concerts c ON s.concert_id = c.concert_id
    WHERE c.title LIKE 'NEWJEANS%' AND ROWNUM = 1;

    SELECT seat_id, price INTO v_seat_id, v_price
    FROM seats WHERE schedule_id = v_schedule_id AND seat_row = 3 AND seat_col = 5;

    INSERT INTO bookings(member_id, schedule_id, total_price, status, created_at)
    VALUES (v_member_id, m.member_id, v_price, 'CONFIRMED', SYSTIMESTAMP - INTERVAL '15' DAY)
    RETURNING booking_id INTO v_booking_id;

    INSERT INTO booking_items(booking_id, seat_id, unit_price)
    VALUES (v_booking_id, v_seat_id, v_price);

    UPDATE seats SET status = 'RESERVED' WHERE seat_id = v_seat_id;
END;
/

COMMIT;

-- 확인
SELECT b.booking_id, m.name AS booker, c.title AS concert,
       b.total_price, b.status,
       TO_CHAR(b.created_at, 'YYYY-MM-DD HH24:MI') AS created
FROM bookings b
JOIN members m ON b.member_id = m.member_id
JOIN concert_schedules s ON b.schedule_id = s.schedule_id
JOIN concerts c ON s.concert_id = c.concert_id
ORDER BY b.booking_id;