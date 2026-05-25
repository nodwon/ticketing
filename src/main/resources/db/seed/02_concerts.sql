-- =====================================================================
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
 '아이유 2026 월드투어. 신곡 무대와 기존 히트곡 메들리. 약 180분.',
 'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=800',
 'UPCOMING');

INSERT INTO concerts(title, artist, venue, description, thumbnail, status) VALUES
('BTS PERMISSION TO DANCE - ENCORE',
 'BTS',
 '인천 아시아드 주경기장',
 'BTS 완전체 컴백 콘서트. 3일간 진행되는 대규모 공연.',
 'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=800',
 'UPCOMING');

INSERT INTO concerts(title, artist, venue, description, thumbnail, status) VALUES
('잠비나이 10주년 기념 공연',
 '잠비나이',
 '블루스퀘어 마스터카드홀',
 '한국 포스트록의 정수. 10주년 기념 단독 공연.',
 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=800',
 'UPCOMING');

INSERT INTO concerts(title, artist, venue, description, thumbnail, status) VALUES
('NEWJEANS GET UP TOUR',
 '뉴진스',
 '고척 스카이돔',
 '뉴진스 첫 단독 투어. 현재 공연 중.',
 'https://images.unsplash.com/photo-1429962714451-bb934ecdc4ec?w=800',
 'ONGOING');

INSERT INTO concerts(title, artist, venue, description, thumbnail, status) VALUES
('성시경 단독 콘서트 2025 - 푸르른 날에',
 '성시경',
 '세종문화회관 대극장',
 '성시경 단독 콘서트. 종료.',
 'https://images.unsplash.com/photo-1415201364774-f6f0bb35f28f?w=800',
 'CLOSED');

COMMIT;

-- 확인
SELECT concert_id, title, artist, status FROM concerts ORDER BY concert_id;
