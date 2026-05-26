-- =====================================================================
-- 02_concerts.sql — 공연 더미 데이터 (확장판)
-- 02_concerts.sql  — 공연 더미 데이터 (확장판)
-- 실행 전 필요 : 01_members.sql 실행 완료 권장
-- 공연 수      : 10개 (장르/상태 다양화)
--               UPCOMING (예매 예정/오픈) : 3개  (1, 2, 3)
--               ONGOING  (현재 예매중)    : 4개  (4, 5, 6, 7)  ★강화
--               CLOSED   (종료)           : 3개  (8, 9, 10)
-- 장르         : K-POP / 발라드 / 록 / 인디 / 재즈 / 클래식 / 페스티벌
-- =====================================================================

-- ---------------------------------------------------------------------
-- UPCOMING (예매 예정/오픈 임박) - 3건
-- ---------------------------------------------------------------------
=======
-- 02_concerts.sql  — 공연 더미 데이터
-- 실행 전 필요 : 01_members.sql 실행 완료 권장
-- 공연 수      : 5개 (다양한 장르/상태 분포)
--               UPCOMING (예매 예정/오픈) 3개
--               ONGOING (공연 중) 1개
--               CLOSED (종료) 1개
-- =====================================================================

INSERT INTO concerts(title, artist, venue, description, thumbnail, status) VALUES
('IU 2026 WORLD TOUR : THE WINNING',
 '아이유',
 '서울 올림픽공원 KSPO DOME',
 '아이유 2026 월드투어 서울 공연. 신곡 무대와 기존 히트곡 메들리로 약 180분간 진행됩니다. 전석 지정석이며, VIP 패키지에는 단독 사인회 참여 기회가 포함됩니다.',
=======
 '아이유 2026 월드투어. 신곡 무대와 기존 히트곡 메들리. 약 180분.',
 'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=800',
 'UPCOMING');

INSERT INTO concerts(title, artist, venue, description, thumbnail, status) VALUES
('BTS PERMISSION TO DANCE - ENCORE',
 'BTS',
 '인천 아시아드 주경기장',
 'BTS 완전체 컴백 콘서트. 3일간 진행되는 대규모 공연이며, 특별 게스트와 콜라보 무대가 준비되어 있습니다.',
 'BTS 완전체 컴백 콘서트. 3일간 진행되는 대규모 공연.',
 'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=800',
 'UPCOMING');

INSERT INTO concerts(title, artist, venue, description, thumbnail, status) VALUES
('잠비나이 10주년 기념 공연',
 '잠비나이',
 '블루스퀘어 마스터카드홀',
 '한국 포스트록의 정수, 잠비나이의 데뷔 10주년 기념 단독 공연. 해금 / 거문고 / 일렉기타의 융합 사운드를 만나보세요.',
 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=800',
 'UPCOMING');

-- ---------------------------------------------------------------------
-- ONGOING (현재 예매중) - 4건  ★ 메인 테스트 대상
-- ---------------------------------------------------------------------
<<<<<<< HEAD
=======
 '한국 포스트록의 정수. 10주년 기념 단독 공연.',
 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=800',
 'UPCOMING');

>>>>>>> origin/main
INSERT INTO concerts(title, artist, venue, description, thumbnail, status) VALUES
('NEWJEANS GET UP TOUR',
 '뉴진스',
 '고척 스카이돔',
 '뉴진스 첫 단독 월드투어 서울 공연. 약 150분간 진행되며 신곡 무대와 팬미팅 코너가 함께 마련됩니다.',
<<<<<<< HEAD
=======
 '뉴진스 첫 단독 투어. 현재 공연 중.',
>>>>>>> feature/sungwoo
>>>>>>> origin/main
 'https://images.unsplash.com/photo-1429962714451-bb934ecdc4ec?w=800',
 'ONGOING');

INSERT INTO concerts(title, artist, venue, description, thumbnail, status) VALUES
('AURORA WORLD TOUR 2026 in SEOUL',
 'AURORA',
 '예스24 라이브홀',
 '북유럽 출신 싱어송라이터 AURORA의 첫 단독 내한. 몽환적인 사운드와 환상적인 무대 연출로 잊지 못할 밤을 선사합니다.',
 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800',
 'ONGOING');

INSERT INTO concerts(title, artist, venue, description, thumbnail, status) VALUES
('서울재즈페스티벌 2026',
 'Various Artists',
 '올림픽공원 88잔디마당',
 '국내외 정상급 재즈 아티스트가 총출동하는 페스티벌. 3일간 펼쳐지는 재즈의 향연.',
 'https://images.unsplash.com/photo-1415201364774-f6f0bb35f28f?w=800',
 'ONGOING');

INSERT INTO concerts(title, artist, venue, description, thumbnail, status) VALUES
('베토벤 교향곡 전곡 연주회',
 '서울 필하모닉',
 '롯데콘서트홀',
 '베토벤 탄생 256주년 기념 프로젝트. 교향곡 1번부터 9번까지 전곡을 9일에 걸쳐 연주합니다.',
 'https://images.unsplash.com/photo-1465847899084-d164df4dedc6?w=800',
 'ONGOING');

-- ---------------------------------------------------------------------
-- CLOSED (종료) - 3건
-- ---------------------------------------------------------------------
INSERT INTO concerts(title, artist, venue, description, thumbnail, status) VALUES
('성시경 단독 콘서트 2025 - 푸르른 날에',
 '성시경',
 '세종문화회관 대극장',
 '성시경 단독 콘서트 2025 시즌 공연. 모든 회차 종료.',
 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800',
 'CLOSED');

INSERT INTO concerts(title, artist, venue, description, thumbnail, status) VALUES
('ROCK LEGEND TRIBUTE 2025',
 'The Echo',
 '한국대중음악박물관 라이브홀',
 '70-80년대 록 명곡 트리뷰트 공연. 2025년 시즌 종료.',
 'https://images.unsplash.com/photo-1429962714451-bb934ecdc4ec?w=800',
 'CLOSED');

INSERT INTO concerts(title, artist, venue, description, thumbnail, status) VALUES
('INDIE SOUND FESTIVAL 2025',
 '인디 아티스트 연합',
 '홍대 롤링홀',
 '국내 인디 신을 이끌어가는 신예 아티스트들의 합동 공연. 2025년 시즌 종료.',
 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=800',
<<<<<<< HEAD
=======
=======
('성시경 단독 콘서트 2025 - 푸르른 날에',
 '성시경',
 '세종문화회관 대극장',
 '성시경 단독 콘서트. 종료.',
 'https://images.unsplash.com/photo-1415201364774-f6f0bb35f28f?w=800',
>>>>>>> origin/main
 'CLOSED');

COMMIT;

-- =====================================================================
-- 확인
-- =====================================================================
SELECT concert_id, title, artist, status FROM concerts ORDER BY concert_id;

SELECT status, COUNT(*) AS cnt
FROM concerts
GROUP BY status
<<<<<<< HEAD
ORDER BY status;
=======
ORDER BY status;
=======
-- 확인
SELECT concert_id, title, artist, status FROM concerts ORDER BY concert_id;
>>>>>>> origin/main
