-- =====================================================================
-- reset.sql  — 더미 데이터 초기화
-- 용도         : DB를 깨끗한 상태로 되돌리고 싶을 때
-- 효과         : 모든 데이터 삭제 + 시퀀스(IDENTITY) 1부터 재시작
-- 보존         : 테이블 구조는 그대로 유지
-- 실행 후      : 01~05 SQL 다시 순서대로 실행하면 동일 상태 복원
--
-- ⚠️ 주의: 본인 DB의 모든 데이터가 삭제됩니다.
--          공유 DB가 아닌 본인 로컬 DB에서만 사용하세요.
--
-- ⚠️ DBeaver 실행 방법:
--    1) 파일 전체 내용을 TICKET_DEV 접속 SQL Editor에 붙여넣기
--    2) Ctrl+A (전체 선택)
--    3) Alt+X (스크립트 전체 실행)
-- =====================================================================

-- 1단계: FK 의존성 역순으로 데이터 삭제
DELETE FROM payments;
DELETE FROM booking_items;
DELETE FROM bookings;
DELETE FROM seats;
DELETE FROM concert_schedules;
DELETE FROM concerts;
DELETE FROM attachments;
DELETE FROM comments;
DELETE FROM posts;
DELETE FROM qna_posts;
DELETE FROM chatbot_logs;
DELETE FROM notices;
DELETE FROM members;
DELETE FROM admins;

COMMIT;

-- 2단계: IDENTITY 컬럼 1번부터 재시작
-- 동적 SQL로 모든 테이블의 IDENTITY 재설정
BEGIN
    FOR t IN (
        SELECT table_name, column_name
        FROM user_tab_identity_cols
    ) LOOP
        EXECUTE IMMEDIATE
            'ALTER TABLE ' || t.table_name ||
            ' MODIFY ' || t.column_name ||
            ' GENERATED AS IDENTITY (START WITH 1)';
    END LOOP;
END;

-- 3단계: 확인
SELECT table_name, (
    SELECT COUNT(*) FROM user_tables WHERE table_name = ut.table_name
) AS exists_flag
FROM user_tables ut
ORDER BY table_name;
