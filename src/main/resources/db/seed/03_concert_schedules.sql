-- =====================================================================
-- 03_concert_schedules.sql  — 공연 일정 더미 데이터 (확장판 v2)
-- 실행 전 필요 : 02_concerts.sql 실행 완료
-- 일정 수      : 약 28회차 (공연별 1~5회차)
-- 시간 기준    : SYSTIMESTAMP 기준 상대 시각
-- 프로젝트 기한: 2027-07-31 까지 → 미래 일정 넉넉하게 분포
--
-- [수정 사항] ORA-01873 (간격 선행 정밀도) 회피
--   - INTERVAL 'N' DAY → NUMTODSINTERVAL(N, 'DAY')
--   - 3자리 이상 일수(120, 180 등)도 안전하게 사용 가능
--
-- ★ 핵심 보장 사항 ★
--   - ONGOING 공연(NEWJEANS/AURORA/재즈페스/베토벤)의 모든 회차가 미래
--   - ONGOING 공연은 booking_open_at 이 이미 오픈됨 (과거 시각)
--   - ONGOING 공연은 available_seats > 0 (예매 가능)
--   - CLOSED 공연은 모든 회차가 과거
--   - UPCOMING 공연은 booking_open_at 이 미래 (예매 대기 상태)
-- =====================================================================

-- =====================================================================
-- 1) IU 2026 WORLD TOUR (UPCOMING)
--    예매오픈: 90일 후 / 공연: 120~123일 후 / 4회차 / 100석
-- =====================================================================
INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP + NUMTODSINTERVAL(120, 'DAY'), SYSTIMESTAMP + NUMTODSINTERVAL(90, 'DAY'), 100, 100
FROM concerts WHERE title LIKE 'IU 2026%';

INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP + NUMTODSINTERVAL(121, 'DAY'), SYSTIMESTAMP + NUMTODSINTERVAL(90, 'DAY'), 100, 100
FROM concerts WHERE title LIKE 'IU 2026%';

INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP + NUMTODSINTERVAL(122, 'DAY'), SYSTIMESTAMP + NUMTODSINTERVAL(90, 'DAY'), 100, 100
FROM concerts WHERE title LIKE 'IU 2026%';

INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP + NUMTODSINTERVAL(123, 'DAY'), SYSTIMESTAMP + NUMTODSINTERVAL(90, 'DAY'), 100, 100
FROM concerts WHERE title LIKE 'IU 2026%';


-- =====================================================================
-- 2) BTS PERMISSION TO DANCE - ENCORE (UPCOMING)
--    예매오픈: 30일 후 / 공연: 120~122일 후 / 3회차 / 200석
-- =====================================================================
INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP + NUMTODSINTERVAL(120, 'DAY'), SYSTIMESTAMP + NUMTODSINTERVAL(30, 'DAY'), 200, 200
FROM concerts WHERE title LIKE 'BTS%';

INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP + NUMTODSINTERVAL(121, 'DAY'), SYSTIMESTAMP + NUMTODSINTERVAL(30, 'DAY'), 200, 200
FROM concerts WHERE title LIKE 'BTS%';

INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP + NUMTODSINTERVAL(122, 'DAY'), SYSTIMESTAMP + NUMTODSINTERVAL(30, 'DAY'), 200, 200
FROM concerts WHERE title LIKE 'BTS%';


-- =====================================================================
-- 3) 잠비나이 10주년 (UPCOMING - 예매 곧 오픈)
--    예매오픈: 7일 후 / 공연: 45~46일 후 / 2회차 / 80석
-- =====================================================================
INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP + NUMTODSINTERVAL(45, 'DAY'), SYSTIMESTAMP + NUMTODSINTERVAL(7, 'DAY'), 80, 80
FROM concerts WHERE title LIKE '잠비나이%';

INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP + NUMTODSINTERVAL(46, 'DAY'), SYSTIMESTAMP + NUMTODSINTERVAL(7, 'DAY'), 80, 80
FROM concerts WHERE title LIKE '잠비나이%';


-- =====================================================================
-- ★ 4) NEWJEANS GET UP TOUR (ONGOING) — 메인 예매 테스트 대상
--    예매오픈: 30일 전 / 공연: 10~13일 후
--    잔여좌석 다양: 충분 / 거의매진 / 매진 / 충분
-- =====================================================================
INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP + NUMTODSINTERVAL(10, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(30, 'DAY'), 200, 142
FROM concerts WHERE title LIKE 'NEWJEANS%';

INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP + NUMTODSINTERVAL(11, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(30, 'DAY'), 200, 35
FROM concerts WHERE title LIKE 'NEWJEANS%';  -- 거의 매진

INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP + NUMTODSINTERVAL(12, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(30, 'DAY'), 200, 0
FROM concerts WHERE title LIKE 'NEWJEANS%';  -- 매진

INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP + NUMTODSINTERVAL(13, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(30, 'DAY'), 200, 178
FROM concerts WHERE title LIKE 'NEWJEANS%';


-- =====================================================================
-- ★ 5) AURORA WORLD TOUR (ONGOING)
--    예매오픈: 20일 전 / 공연: 25~26일 후 / 2회차 / 120석
-- =====================================================================
INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP + NUMTODSINTERVAL(25, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(20, 'DAY'), 120, 88
FROM concerts WHERE title LIKE 'AURORA%';

INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP + NUMTODSINTERVAL(26, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(20, 'DAY'), 120, 95
FROM concerts WHERE title LIKE 'AURORA%';


-- =====================================================================
-- ★ 6) 서울재즈페스티벌 2026 (ONGOING) - 3일짜리 페스티벌
--    예매오픈: 45일 전 / 공연: 35~37일 후 / 3회차 / 500석
-- =====================================================================
INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP + NUMTODSINTERVAL(35, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(45, 'DAY'), 500, 312
FROM concerts WHERE title LIKE '서울재즈페스티벌%';

INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP + NUMTODSINTERVAL(36, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(45, 'DAY'), 500, 218
FROM concerts WHERE title LIKE '서울재즈페스티벌%';

INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP + NUMTODSINTERVAL(37, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(45, 'DAY'), 500, 405
FROM concerts WHERE title LIKE '서울재즈페스티벌%';


-- =====================================================================
-- ★ 7) 베토벤 교향곡 전곡 연주회 (ONGOING)
--    예매오픈: 60일 전 / 공연: 90~98일 후 (5회차, 격일) / 150석
-- =====================================================================
INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP + NUMTODSINTERVAL(90, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(60, 'DAY'), 150, 134
FROM concerts WHERE title LIKE '베토벤%';

INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP + NUMTODSINTERVAL(92, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(60, 'DAY'), 150, 142
FROM concerts WHERE title LIKE '베토벤%';

INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP + NUMTODSINTERVAL(94, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(60, 'DAY'), 150, 128
FROM concerts WHERE title LIKE '베토벤%';

INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP + NUMTODSINTERVAL(96, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(60, 'DAY'), 150, 149
FROM concerts WHERE title LIKE '베토벤%';

INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP + NUMTODSINTERVAL(98, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(60, 'DAY'), 150, 137
FROM concerts WHERE title LIKE '베토벤%';


-- =====================================================================
-- 8) 성시경 (CLOSED) — 모든 회차 과거
--    공연: 59~60일 전 / 예매오픈: 120일 전
-- =====================================================================
INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP - NUMTODSINTERVAL(60, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(120, 'DAY'), 80, 0
FROM concerts WHERE title LIKE '성시경%';

INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP - NUMTODSINTERVAL(59, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(120, 'DAY'), 80, 0
FROM concerts WHERE title LIKE '성시경%';


-- =====================================================================
-- 9) ROCK LEGEND TRIBUTE (CLOSED)
--    공연: 89~90일 전 / 예매오픈: 150일 전
-- =====================================================================
INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP - NUMTODSINTERVAL(90, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(150, 'DAY'), 60, 0
FROM concerts WHERE title LIKE 'ROCK LEGEND%';

INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP - NUMTODSINTERVAL(89, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(150, 'DAY'), 60, 0
FROM concerts WHERE title LIKE 'ROCK LEGEND%';


-- =====================================================================
-- 10) INDIE SOUND FESTIVAL (CLOSED)
--    공연: 120일 전 / 예매오픈: 180일 전
-- =====================================================================
INSERT INTO concert_schedules(concert_id, performance_date, booking_open_at, total_seats, available_seats)
SELECT concert_id, SYSTIMESTAMP - NUMTODSINTERVAL(120, 'DAY'), SYSTIMESTAMP - NUMTODSINTERVAL(180, 'DAY'), 40, 0
FROM concerts WHERE title LIKE 'INDIE SOUND%';

COMMIT;


-- =====================================================================
-- 확인 쿼리
-- =====================================================================

-- 1) 공연별 회차 수와 상태
SELECT c.concert_id, c.title, c.status,
       COUNT(s.schedule_id) AS schedule_count
FROM concerts c
LEFT JOIN concert_schedules s ON c.concert_id = s.concert_id
GROUP BY c.concert_id, c.title, c.status
ORDER BY c.concert_id;

-- 2) ONGOING 공연 회차 점검 (모두 future=O, booking_open=O, has_seat=대부분 O)
SELECT c.title AS concert,
       TO_CHAR(s.performance_date, 'YYYY-MM-DD HH24:MI') AS perf_date,
       TO_CHAR(s.booking_open_at,  'YYYY-MM-DD HH24:MI') AS open_at,
       s.available_seats || '/' || s.total_seats AS seats,
       CASE WHEN s.performance_date > SYSTIMESTAMP THEN 'O' ELSE 'X' END AS future,
       CASE WHEN s.booking_open_at <= SYSTIMESTAMP THEN 'O' ELSE 'X' END AS booking_open,
       CASE WHEN s.available_seats > 0 THEN 'O' ELSE 'X' END AS has_seat
FROM concerts c
JOIN concert_schedules s ON c.concert_id = s.concert_id
WHERE c.status = 'ONGOING'
ORDER BY c.concert_id, s.performance_date;

-- 3) 전체 회차 요약
SELECT s.schedule_id, c.title,
       TO_CHAR(s.performance_date, 'YYYY-MM-DD HH24:MI') AS perf_date,
       TO_CHAR(s.booking_open_at,  'YYYY-MM-DD HH24:MI') AS open_at,
       s.available_seats || '/' || s.total_seats AS seats,
       c.status
FROM concert_schedules s
JOIN concerts c ON s.concert_id = c.concert_id
ORDER BY s.schedule_id;
