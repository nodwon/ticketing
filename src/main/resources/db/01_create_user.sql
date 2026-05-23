-- =====================================================================
-- 티켓팅 AI 보안관제 시스템 — 개발용 계정 생성 스크립트
-- 실행 환경 : Oracle 21c XE
-- 접속 계정 : SYSTEM (SYSDBA 권한 불필요)
-- 접속 대상 : XEPDB1 (Pluggable DB)
-- =====================================================================

-- 현재 어디 붙어있는지 확인 (XEPDB1 이어야 함)
SELECT SYS_CONTEXT('USERENV','CON_NAME') AS current_container FROM dual;
-- 결과가 'XEPDB1' 이 아니면 아래 실행 후 다시 확인
-- ALTER SESSION SET CONTAINER = XEPDB1;


-- ---------------------------------------------------------------------
-- 1) 개발용 메인 계정 생성
-- ---------------------------------------------------------------------
CREATE USER ticket_dev
    IDENTIFIED BY "ticket_dev_2026"          -- ⚠️ 실제 비번으로 바꿔서 사용
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP
    QUOTA UNLIMITED ON USERS;

-- 기본 권한 부여
GRANT CONNECT, RESOURCE TO ticket_dev;       -- 접속 + 객체 생성
GRANT CREATE VIEW       TO ticket_dev;       -- 뷰 생성
GRANT CREATE SEQUENCE   TO ticket_dev;       -- 시퀀스 (혹시 모를 대비)
GRANT CREATE PROCEDURE  TO ticket_dev;       -- 프로시저
GRANT CREATE TRIGGER    TO ticket_dev;       -- 트리거
GRANT CREATE SYNONYM    TO ticket_dev;       -- 시노님

-- (선택) 다른 스키마 조회 권한 — TICKET_LOG 같은 다른 계정 만들 경우용
-- GRANT SELECT ANY TABLE TO ticket_dev;


-- ---------------------------------------------------------------------
-- 2) 검증
-- ---------------------------------------------------------------------
SELECT username, account_status, default_tablespace
FROM dba_users
WHERE username = 'TICKET_DEV';

-- 권한 확인
SELECT grantee, granted_role
FROM dba_role_privs
WHERE grantee = 'TICKET_DEV';


-- =====================================================================
-- 이후 절차:
--   1) DBeaver에서 새 연결 만들기
--      - Database/Service: XEPDB1
--      - Username:         ticket_dev
--      - Password:         ticket_dev_2026 (위에서 정한 값)
--   2) ticket_dev 로 접속한 상태에서 oracle21c_ddl.sql 실행
--      → 14개 테이블이 TICKET_DEV 스키마에 생성됨
-- =====================================================================
