-- ============================================================
-- Docker 컨테이너 자동 실행용 - PDB 전환 추가
-- ============================================================
ALTER SESSION SET CONTAINER = XEPDB1;
ALTER SESSION SET CURRENT_SCHEMA = TICKET_DEV;

/* =============================================================
 * Project   : 티켓팅 보안관제 (Ticketing Security Monitoring)
 * File      : 01_security_log_tables.sql
 * DB        : Oracle 21c
 * Purpose   : Splunk 인덱싱 대상 보안 로그 테이블 DDL
 * Note      :
 *   - 모든 log_* 테이블은 timestamp 기준 RANGE 파티셔닝
 *   - PK는 IDENTITY 컬럼 (시퀀스 자동)
 *   - 외부 노출되는 컬럼(transaction_id 등)은 인덱스 추가
 *   - Splunk DB Connect 가 5분 단위로 batch insert
 * ============================================================= */

-- 0) 보안 로그 전용 테이블스페이스 (선택)
-- CREATE TABLESPACE TS_SECLOG
--   DATAFILE '/u02/oradata/seclog01.dbf' SIZE 1G AUTOEXTEND ON NEXT 100M;

/* =============================================================
 * 1) log_auth : 로그인 이벤트
 *    - 매크로 / 크리덴셜 스터핑 탐지 1순위
 * ============================================================= */
CREATE TABLE log_auth (
    log_id        NUMBER(19)   GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id       NUMBER(19),                              -- 실패 시 NULL 가능
    src_ip        VARCHAR2(50)  NOT NULL,
    login_result  VARCHAR2(10)  NOT NULL,                  -- SUCCESS / FAIL
    event_time    TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT ck_log_auth_result CHECK (login_result IN ('SUCCESS','FAIL'))
)
PARTITION BY RANGE (event_time)
INTERVAL (NUMTODSINTERVAL(1,'DAY'))
(
    PARTITION p_init VALUES LESS THAN (TIMESTAMP '2026-01-01 00:00:00')
);

CREATE INDEX idx_log_auth_user_time ON log_auth(user_id, event_time) LOCAL;
CREATE INDEX idx_log_auth_ip_time   ON log_auth(src_ip,  event_time) LOCAL;
CREATE INDEX idx_log_auth_fail      ON log_auth(login_result, event_time) LOCAL;

/* =============================================================
 * 2) log_seat : 좌석 선택 이벤트
 *    - 매크로 좌석 휩쓸기, burst 탐지
 * ============================================================= */
CREATE TABLE log_seat (
    log_id          NUMBER(19)    GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id         NUMBER(19)    NOT NULL,
    concert_id      NUMBER(19)    NOT NULL,
    seat_id         NUMBER(19)    NOT NULL,
    request_result  VARCHAR2(10)  NOT NULL,                -- SUCCESS / FAIL
    elapsed_time    NUMBER(10),                            -- 처리시간 ms (옵션)
    event_time      TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT ck_log_seat_result CHECK (request_result IN ('SUCCESS','FAIL'))
)
PARTITION BY RANGE (event_time)
INTERVAL (NUMTODSINTERVAL(1,'DAY'))
(
    PARTITION p_init VALUES LESS THAN (TIMESTAMP '2026-01-01 00:00:00')
);

CREATE INDEX idx_log_seat_user_time    ON log_seat(user_id, event_time) LOCAL;
CREATE INDEX idx_log_seat_concert_time ON log_seat(concert_id, event_time) LOCAL;

/* =============================================================
 * 3) log_payment : 결제 이벤트
 *    - Replay Attack (transaction_id 중복)
 *    - TAMPER (요청금액 vs 실제금액 불일치)
 * ============================================================= */
CREATE TABLE log_payment (
    log_id          NUMBER(19)     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id         NUMBER(19)     NOT NULL,
    transaction_id  VARCHAR2(200)  NOT NULL,
    payment_amount  NUMBER(19)     NOT NULL,               -- 요청 금액
    actual_price    NUMBER(19)     NOT NULL,               -- 서버 기준 실제 금액
    payment_result  VARCHAR2(10)   NOT NULL,               -- SUCCESS / FAIL / TAMPER
    event_time      TIMESTAMP      DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT ck_log_payment_result CHECK (payment_result IN ('SUCCESS','FAIL','TAMPER'))
)
PARTITION BY RANGE (event_time)
INTERVAL (NUMTODSINTERVAL(1,'DAY'))
(
    PARTITION p_init VALUES LESS THAN (TIMESTAMP '2026-01-01 00:00:00')
);

-- transaction_id 중복 탐지를 위해 일반 인덱스 (UNIQUE 아님: 일부러 중복 허용)
CREATE INDEX idx_log_payment_txid    ON log_payment(transaction_id) LOCAL;
CREATE INDEX idx_log_payment_user    ON log_payment(user_id, event_time) LOCAL;
CREATE INDEX idx_log_payment_tamper  ON log_payment(payment_result, event_time) LOCAL;

/* =============================================================
 * 4) log_admin_access : 관리자 접근 시도
 *    - 권한 우회 / 비인가 접근 탐지
 * ============================================================= */
CREATE TABLE log_admin_access (
    log_id       NUMBER(19)     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    access_url   VARCHAR2(500)  NOT NULL,
    user_id      NUMBER(19),                               -- 비인증 시 NULL
    src_ip       VARCHAR2(50)   NOT NULL,
    status_code  NUMBER(5)      NOT NULL,
    event_time   TIMESTAMP      DEFAULT SYSTIMESTAMP NOT NULL
)
PARTITION BY RANGE (event_time)
INTERVAL (NUMTODSINTERVAL(1,'DAY'))
(
    PARTITION p_init VALUES LESS THAN (TIMESTAMP '2026-01-01 00:00:00')
);

CREATE INDEX idx_log_admin_user_time ON log_admin_access(user_id, event_time) LOCAL;
CREATE INDEX idx_log_admin_ip_time   ON log_admin_access(src_ip,  event_time) LOCAL;
CREATE INDEX idx_log_admin_status    ON log_admin_access(status_code, event_time) LOCAL;

/* =============================================================
 * 5) log_board : 게시판 이벤트
 *    - 첨부파일 확장자 화이트리스트 위반 / XSS 페이로드 탐지
 * ============================================================= */
CREATE TABLE log_board (
    log_id                NUMBER(19)     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id               NUMBER(19)     NOT NULL,
    board_type            VARCHAR2(20)   NOT NULL,         -- NOTICE / QNA / FREE 등
    content               CLOB           NOT NULL,
    attachment_name       VARCHAR2(500),
    attachment_extension  VARCHAR2(20),
    event_time            TIMESTAMP      DEFAULT SYSTIMESTAMP NOT NULL
)
PARTITION BY RANGE (event_time)
INTERVAL (NUMTODSINTERVAL(1,'DAY'))
(
    PARTITION p_init VALUES LESS THAN (TIMESTAMP '2026-01-01 00:00:00')
);

CREATE INDEX idx_log_board_user_time ON log_board(user_id, event_time) LOCAL;
CREATE INDEX idx_log_board_ext       ON log_board(attachment_extension) LOCAL;

/* =============================================================
 * 6) log_behavior_feature : MLTK 행동 Feature
 *    - 집계된 행동 지표 (초/분당 요청 등)
 *    - 5초 ~ 1분 단위로 사용자별 1행 적재
 *    - Splunk MLTK 학습 입력
 * ============================================================= */
CREATE TABLE log_behavior_feature (
    log_id                   NUMBER(19)   GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id                  NUMBER(19)   NOT NULL,
    src_ip                   VARCHAR2(50) NOT NULL,
    requests_per_second      NUMBER(10,3),
    requests_per_minute      NUMBER(10,3),
    burst_request_count      NUMBER(10),
    seat_change_count        NUMBER(10),
    unique_seat_count        NUMBER(10),
    failed_select_ratio      NUMBER(5,4),
    avg_action_interval      NUMBER(10,3),                 -- ms
    page_transition_time     NUMBER(10,3),                 -- ms
    login_fail_ratio         NUMBER(5,4),
    target_account_count     NUMBER(10),
    repeated_fail_count      NUMBER(10),
    jailbreak_keyword_count  NUMBER(10),
    excessive_token_request  NUMBER(1),                    -- 0/1 (TINYINT 대용)
    event_time               TIMESTAMP    DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT ck_behavior_token CHECK (excessive_token_request IN (0,1))
)
PARTITION BY RANGE (event_time)
INTERVAL (NUMTODSINTERVAL(1,'DAY'))
(
    PARTITION p_init VALUES LESS THAN (TIMESTAMP '2026-01-01 00:00:00')
);

CREATE INDEX idx_log_behavior_user_time ON log_behavior_feature(user_id, event_time) LOCAL;
CREATE INDEX idx_log_behavior_ip_time   ON log_behavior_feature(src_ip,  event_time) LOCAL;

/* =============================================================
 * 7) 보관기간 정책 (예: 90일 이상 파티션 자동 삭제)
 *    - 운영 시 DBMS_SCHEDULER 잡으로 등록
 * ============================================================= */
-- 예시 (배치 잡에서 호출):
-- ALTER TABLE log_auth DROP PARTITION FOR (TIMESTAMP '2026-02-25 00:00:00');

COMMIT;
