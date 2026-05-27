-- ============================================================
-- log_payment 테이블 (명세서 반영)
--   - 명세상 BIGINT/DATETIME 은 Oracle 에서 NUMBER(19)/TIMESTAMP 로 매핑
--   - user_id 는 members.member_id 와 동일 (회원 테이블명은 members 유지)
--   - payment_result 에 'TAMPER' 추가 — payment_amount != actual_price 변조 탐지용
-- ============================================================

CREATE TABLE log_payment (
    log_id          NUMBER(19)      GENERATED AS IDENTITY  NOT NULL,
    user_id         NUMBER(19)                             NOT NULL,
    transaction_id  VARCHAR2(200)                          NOT NULL,
    payment_amount  NUMBER(19)                             NOT NULL,
    actual_price    NUMBER(19)                             NOT NULL,
    payment_result  VARCHAR2(10)                           NOT NULL,
    log_timestamp   TIMESTAMP       DEFAULT SYSTIMESTAMP   NOT NULL,
    CONSTRAINT pk_log_payment        PRIMARY KEY (log_id),
    CONSTRAINT fk_log_payment_member FOREIGN KEY (user_id)
        REFERENCES members (member_id),
    CONSTRAINT ck_log_payment_result CHECK (payment_result IN ('SUCCESS','FAIL','TAMPER'))
);

CREATE INDEX idx_log_payment_user ON log_payment(user_id);
CREATE INDEX idx_log_payment_tx   ON log_payment(transaction_id);
CREATE INDEX idx_log_payment_ts   ON log_payment(log_timestamp);

-- 명세상 컬럼명은 timestamp 지만 Oracle 예약어이므로 log_timestamp 로 명명
-- DAO/매퍼에서도 동일하게 처리됨
