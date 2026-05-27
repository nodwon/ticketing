-- ============================================================
-- Project   : 티켓팅 보안관제
-- File      : 01_user.sql
-- DB        : Oracle XE 21c
-- Purpose   : 티켓팅 전용 사용자 계정 생성
-- Note      :
--   - Docker 컨테이너 기동 시 자동 실행됨
--   - 위치: /opt/oracle/scripts/startup/01_user.sql
--   - docker-compose.yml 의 volumes 로 마운트됨
-- ============================================================

-- PDB(Pluggable DB) 로 전환
ALTER SESSION SET CONTAINER = XEPDB1;

-- 1. 사용자 생성
CREATE USER TICKET_DEV IDENTIFIED BY "TicketDev2026!";

-- 2. 권한 부여
GRANT CONNECT, RESOURCE TO TICKET_DEV;
GRANT UNLIMITED TABLESPACE TO TICKET_DEV;
GRANT CREATE SESSION TO TICKET_DEV;
GRANT CREATE TABLE TO TICKET_DEV;
GRANT CREATE SEQUENCE TO TICKET_DEV;
GRANT CREATE VIEW TO TICKET_DEV;
GRANT CREATE PROCEDURE TO TICKET_DEV;
GRANT CREATE TRIGGER TO TICKET_DEV;

-- 3. 확인
SELECT username, account_status FROM dba_users WHERE username = 'TICKET_DEV';

COMMIT;
