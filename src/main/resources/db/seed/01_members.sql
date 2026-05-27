-- =====================================================================
-- 01_members.sql  — 회원 더미 데이터
-- 실행 전 필요 : oracle21c_ddl_fixed.sql 로 테이블 생성된 상태
-- 회원 수      : 일반 4명 + 관리자 1명 = 총 5명
-- 비밀번호     : 모두 평문 'test1234' (개발용)
--               ⚠️ 실제 bcrypt 적용은 회원가입 코드(Java)에서 처리
--               여기서는 자리표시용 더미 해시
-- =====================================================================

INSERT INTO members(email, password_hash, name, phone, birth_date, role) VALUES
('kim@test.com',   '$2a$10$dummyhashforuserkim01xxxxxxxxxxxxxxxxxxxxxxxxxx', '김철수', '010-1111-1111', DATE '1990-01-15', 'USER');

INSERT INTO members(email, password_hash, name, phone, birth_date, role) VALUES
('lee@test.com',   '$2a$10$dummyhashforuserlee02xxxxxxxxxxxxxxxxxxxxxxxxxx', '이영희', '010-2222-2222', DATE '1995-05-20', 'USER');

INSERT INTO members(email, password_hash, name, phone, birth_date, role) VALUES
('park@test.com',  '$2a$10$dummyhashforuserpark03xxxxxxxxxxxxxxxxxxxxxxxxx', '박지민', '010-3333-3333', DATE '1988-08-08', 'USER');

INSERT INTO members(email, password_hash, name, phone, birth_date, role) VALUES
('choi@test.com',  '$2a$10$dummyhashforuserchoi04xxxxxxxxxxxxxxxxxxxxxxxxx', '최수영', '010-4444-4444', DATE '2000-11-30', 'USER');

INSERT INTO members(email, password_hash, name, phone, birth_date, role) VALUES
('admin@test.com', '$2a$10$dummyhashforadmin05xxxxxxxxxxxxxxxxxxxxxxxxxxxx', '관리자',  '010-9999-9999', DATE '1985-12-25', 'ADMIN');

COMMIT;

-- 확인
SELECT member_id, email, name, role FROM members ORDER BY member_id;
