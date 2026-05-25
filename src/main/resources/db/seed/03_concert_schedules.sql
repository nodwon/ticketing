-- =====================================================================
-- 03_concert_schedules.sql  — 공연 일정 더미 데이터
-- 실행 전 필요 : 02_concerts.sql 실행 완료
-- 일정 수      : 공연별 1~3회차 = 총 8회차
-- 시간 기준    : SYSTIMESTAMP 기준 상대 시각 (재현성 위해 절대 시각 권장이지만,
--               더미 데이터 특성상 "오늘 기준 N일 후" 형식이 더 자연스러움)
-- =====================================================================

-- 1) IU 콘서트 — 2회차 (예매 오픈은 일주일 후, 공연은 30일 후)
INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP + INTERVAL '30' DAY, SYSTIMESTAMP + INTERVAL '7' DAY, 100, 100
FROM concerts WHERE title LIKE 'IU 2026%';

INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP + INTERVAL '31' DAY, SYSTIMESTAMP + INTERVAL '7' DAY, 100, 100
FROM concerts WHERE title LIKE 'IU 2026%';

-- 2) BTS 콘서트 — 3회차 (예매 오픈은 14일 후, 공연은 60일 후)
INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP + INTERVAL '60' DAY, SYSTIMESTAMP + INTERVAL '14' DAY, 150, 150
FROM concerts WHERE title LIKE 'BTS%';

INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP + INTERVAL '61' DAY, SYSTIMESTAMP + INTERVAL '14' DAY, 150, 150
FROM concerts WHERE title LIKE 'BTS%';

INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP + INTERVAL '62' DAY, SYSTIMESTAMP + INTERVAL '14' DAY, 150, 150
FROM concerts WHERE title LIKE 'BTS%';

-- 3) 잠비나이 — 1회차 (예매 이미 오픈됨, 공연은 21일 후)
INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP + INTERVAL '21' DAY, SYSTIMESTAMP - INTERVAL '3' DAY, 50, 50
FROM concerts WHERE title LIKE '잠비나이%';

-- 4) NEWJEANS — 1회차 (이미 시작된 공연, 어제 회차)
INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP - INTERVAL '1' DAY, SYSTIMESTAMP - INTERVAL '30' DAY, 200, 0
FROM concerts WHERE title LIKE 'NEWJEANS%';

-- 5) 성시경 — 1회차 (지난 공연)
INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP - INTERVAL '60' DAY, SYSTIMESTAMP - INTERVAL '90' DAY, 80, 0
FROM concerts WHERE title LIKE '성시경%';

COMMIT;

-- 확인
SELECT s.schedule_id, c.title, TO_CHAR(s.performance_date, 'YYYY-MM-DD HH24:MI') AS perf_date,
       TO_CHAR(s.booking_open_at, 'YYYY-MM-DD HH24:MI') AS open_at,
       s.total_seats, s.available_seats
FROM concert_schedules s
JOIN concerts c ON s.concert_id = c.concert_id
ORDER BY s.schedule_id;
