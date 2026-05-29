-- =====================================================================
-- 티켓팅 AI 보안관제 시스템 — Oracle 21c DDL (완전 통합 최종본)
-- 실행 환경 : TICKET_DEV 계정으로 XEPDB1 접속 후 실행 (Alt + X 권장)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. 객체 선 파괴 (존재하지 않아 에러 뜨면 'Skip all' 클릭)
-- ---------------------------------------------------------------------
DROP SEQUENCE QNA_NO_SEQ;
DROP SEQUENCE NOTICE_NO_SEQ;
DROP TABLE chatbot_logs       CASCADE CONSTRAINTS;
DROP TABLE qna_posts          CASCADE CONSTRAINTS;
DROP TABLE NOTICE             CASCADE CONSTRAINTS; -- ✨ 단수형 NOTICE 파괴 추가
DROP TABLE notices            CASCADE CONSTRAINTS; -- 혹시 모를 복수형 notices도 파괴
DROP TABLE attachments        CASCADE CONSTRAINTS;
DROP TABLE comments           CASCADE CONSTRAINTS;
DROP TABLE posts              CASCADE CONSTRAINTS;
DROP TABLE payments           CASCADE CONSTRAINTS;
DROP TABLE booking_items      CASCADE CONSTRAINTS;
DROP TABLE bookings           CASCADE CONSTRAINTS;
DROP TABLE seats              CASCADE CONSTRAINTS;
DROP TABLE concert_schedules  CASCADE CONSTRAINTS;
DROP TABLE concerts           CASCADE CONSTRAINTS;
DROP TABLE admins             CASCADE CONSTRAINTS;
DROP TABLE members            CASCADE CONSTRAINTS;

-- ---------------------------------------------------------------------
-- 2. 테이블 생성 (1~14)
-- ---------------------------------------------------------------------
CREATE TABLE members (
    member_id NUMBER(19) GENERATED AS IDENTITY NOT NULL,
    email VARCHAR2(200) NOT NULL,
    password_hash VARCHAR2(256) NOT NULL,
    name VARCHAR2(100) NOT NULL,
    phone VARCHAR2(20),
    birth_date DATE,
    role VARCHAR2(20) DEFAULT 'USER' NOT NULL,
    CONSTRAINT pk_members PRIMARY KEY (member_id),
    CONSTRAINT uk_members_email UNIQUE (email)
);

CREATE TABLE admins (
    admin_id NUMBER(19) GENERATED AS IDENTITY NOT NULL,
    admin_login_id VARCHAR2(20) NOT NULL,
    password_hash VARCHAR2(256) NOT NULL,
    CONSTRAINT pk_admins PRIMARY KEY (admin_id),
    CONSTRAINT uk_admins_login_id UNIQUE (admin_login_id)
);

CREATE TABLE concerts (
    concert_id NUMBER(19) GENERATED AS IDENTITY NOT NULL,
    title VARCHAR2(300) NOT NULL,
    artist VARCHAR2(200) NOT NULL,
    venue VARCHAR2(300) NOT NULL,
    description CLOB,
    thumbnail VARCHAR2(500),
    status VARCHAR2(20) DEFAULT 'UPCOMING' NOT NULL,
    CONSTRAINT pk_concerts PRIMARY KEY (concert_id)
);

CREATE TABLE concert_schedules (
    schedule_id NUMBER(19) GENERATED AS IDENTITY NOT NULL,
    concert_id NUMBER(19) NOT NULL,
    performance_date TIMESTAMP NOT NULL,
    booking_open_at TIMESTAMP NOT NULL,
    total_seats NUMBER(10) NOT NULL,
    available_seats NUMBER(10) NOT NULL,
    CONSTRAINT pk_concert_schedules PRIMARY KEY (schedule_id),
    CONSTRAINT fk_schedules_concert FOREIGN KEY (concert_id) REFERENCES concerts (concert_id)
);

CREATE TABLE seats (
    seat_id NUMBER(19) GENERATED AS IDENTITY NOT NULL,
    schedule_id NUMBER(19) NOT NULL,
    seat_row NUMBER(10) NOT NULL,
    seat_col NUMBER(10) NOT NULL,
    price NUMBER(19) NOT NULL,
    status VARCHAR2(20) DEFAULT 'AVAILABLE' NOT NULL,
    CONSTRAINT pk_seats PRIMARY KEY (seat_id),
    CONSTRAINT fk_seats_schedule FOREIGN KEY (schedule_id) REFERENCES concert_schedules (schedule_id),
    CONSTRAINT uk_seats_position UNIQUE (schedule_id, seat_row, seat_col)
);

CREATE TABLE bookings (
    booking_id NUMBER(19) GENERATED AS IDENTITY NOT NULL,
    member_id NUMBER(19) NOT NULL,
    schedule_id NUMBER(19) NOT NULL,
    total_price NUMBER(19) NOT NULL,
    status VARCHAR2(20) DEFAULT 'PENDING' NOT NULL,
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT pk_bookings PRIMARY KEY (booking_id),
    CONSTRAINT fk_bookings_member FOREIGN KEY (member_id) REFERENCES members (member_id),
    CONSTRAINT fk_bookings_schedule FOREIGN KEY (schedule_id) REFERENCES concert_schedules (schedule_id)
);

CREATE TABLE booking_items (
    item_id NUMBER(19) GENERATED AS IDENTITY NOT NULL,
    booking_id NUMBER(19) NOT NULL,
    seat_id NUMBER(19) NOT NULL,
    unit_price NUMBER(19) NOT NULL,
    CONSTRAINT pk_booking_items PRIMARY KEY (item_id),
    CONSTRAINT fk_items_booking FOREIGN KEY (booking_id) REFERENCES bookings (booking_id),
    CONSTRAINT fk_items_seat FOREIGN KEY (seat_id) REFERENCES seats (seat_id)
);

CREATE TABLE payments (
    payment_id NUMBER(19) GENERATED AS IDENTITY NOT NULL,
    booking_id NUMBER(19) NOT NULL,
    member_id NUMBER(19) NOT NULL,
    transaction_id VARCHAR2(200) NOT NULL,
    requested_amount NUMBER(19) NOT NULL,
    status VARCHAR2(20) DEFAULT 'PENDING' NOT NULL,
    CONSTRAINT pk_payments PRIMARY KEY (payment_id),
    CONSTRAINT fk_payments_booking FOREIGN KEY (booking_id) REFERENCES bookings (booking_id),
    CONSTRAINT fk_payments_member FOREIGN KEY (member_id) REFERENCES members (member_id),
    CONSTRAINT uk_payments_tx UNIQUE (transaction_id)
);

CREATE TABLE posts (
    post_id NUMBER(19) GENERATED AS IDENTITY NOT NULL,
    member_id NUMBER(19) NOT NULL,
    post_type VARCHAR2(20) NOT NULL,
    title VARCHAR2(300) NOT NULL,
    content CLOB NOT NULL,
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT pk_posts PRIMARY KEY (post_id),
    CONSTRAINT fk_posts_member FOREIGN KEY (member_id) REFERENCES members (member_id)
);

CREATE TABLE comments (
    comment_id NUMBER(19) GENERATED AS IDENTITY NOT NULL,
    post_id NUMBER(19) NOT NULL,
    member_id NUMBER(19) NOT NULL,
    content CLOB NOT NULL,
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT pk_comments PRIMARY KEY (comment_id),
    CONSTRAINT fk_comments_post FOREIGN KEY (post_id) REFERENCES posts (post_id),
    CONSTRAINT fk_comments_member FOREIGN KEY (member_id) REFERENCES members (member_id)
);

CREATE TABLE qna_posts (
    QNA_ID NUMBER(19,0) NOT NULL,
    MEMBER_ID NUMBER(19,0),
    TITLE VARCHAR2(300) NOT NULL,
    CONTENT CLOB NOT NULL,
    CREATED_AT TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    QNA_NAME VARCHAR2(100),
    QNA_AN VARCHAR2(4000),
    IS_SECRET NUMBER(1,0) DEFAULT 0 NOT NULL,
    CONSTRAINT pk_qna_posts PRIMARY KEY (QNA_ID),
    CONSTRAINT fk_qna_member FOREIGN KEY (MEMBER_ID) REFERENCES members (member_id)
);

CREATE TABLE attachments (
    ATTACHMENT_ID NUMBER(19,0) GENERATED BY DEFAULT AS IDENTITY NOT NULL,
    POST_ID NUMBER(19,0),   
    ORIGINAL_NAME VARCHAR2(500) NOT NULL,
    SAVED_NAME VARCHAR2(500) NOT NULL,
    EXTENSION VARCHAR2(20) NOT NULL,
    FILE_SIZE NUMBER(19,0) NOT NULL,
    UPLOADED_AT TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT pk_attachments PRIMARY KEY (ATTACHMENT_ID)
);

-- 13. [수정] 자바 마이바티스(Notice_SQL.xml) 명세와 100% 동기화된 단수형 NOTICE 테이블
CREATE TABLE NOTICE (
    NOTICE_NO      NUMBER(19,0)          NOT NULL,
    NOTICE_TITLE   VARCHAR2(300)         NOT NULL,
    NOTICE_CONTENT CLOB                  NOT NULL,
    NOTICE_GUBUN   VARCHAR2(20)          DEFAULT '0' NOT NULL,
    NOTICE_DATE    TIMESTAMP             DEFAULT SYSTIMESTAMP NOT NULL,
    MEMBER_NO      NUMBER(19,0),
    CONSTRAINT PK_NOTICE PRIMARY KEY (NOTICE_NO)
);

COMMENT ON TABLE  NOTICE IS '공지사항';
COMMENT ON COLUMN NOTICE.NOTICE_NO IS '공지번호';
COMMENT ON COLUMN NOTICE.NOTICE_TITLE IS '제목';
COMMENT ON COLUMN NOTICE.NOTICE_CONTENT IS '내용';
COMMENT ON COLUMN NOTICE.NOTICE_GUBUN IS '게시판 구분';
COMMENT ON COLUMN NOTICE.NOTICE_DATE IS '등록일시';
COMMENT ON COLUMN NOTICE.MEMBER_NO IS '작성자 회원번호';

CREATE TABLE chatbot_logs (
    log_id NUMBER(19) GENERATED AS IDENTITY NOT NULL,
    member_id NUMBER(19),
    src_ip VARCHAR2(50) NOT NULL,
    session_id VARCHAR2(100) NOT NULL,
    prompt_text CLOB NOT NULL,
    response_text CLOB,
    prompt_length NUMBER(10) NOT NULL,
    response_length NUMBER(10),
    blocked_keyword_detected NUMBER(1) DEFAULT 0 NOT NULL,
    model_response_status VARCHAR2(20) NOT NULL,
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT pk_chatbot_logs PRIMARY KEY (log_id),
    CONSTRAINT fk_chatbot_member FOREIGN KEY (member_id) REFERENCES members (member_id)
);

-- ---------------------------------------------------------------------
-- 3. 고속화 인덱스 생성
-- ---------------------------------------------------------------------
CREATE INDEX idx_bookings_member       ON bookings (member_id);
CREATE INDEX idx_bookings_schedule     ON bookings (schedule_id);
CREATE INDEX idx_bookings_created      ON bookings (created_at);
CREATE INDEX idx_seats_schedule        ON seats (schedule_id);
CREATE INDEX idx_payments_member       ON payments (member_id);
CREATE INDEX idx_payments_booking      ON payments (booking_id);
CREATE INDEX idx_posts_member          ON posts (member_id);
CREATE INDEX idx_posts_type            ON posts (post_type);
CREATE INDEX idx_comments_post         ON comments (post_id);
CREATE INDEX idx_qna_posts_member      ON qna_posts (MEMBER_ID);
CREATE INDEX INDEX_ATTACHMENTS_POST_ID ON attachments (POST_ID);
CREATE INDEX idx_chatbot_logs_member   ON chatbot_logs (member_id);
CREATE INDEX idx_chatbot_logs_created  ON chatbot_logs (created_at);

-- ---------------------------------------------------------------------
-- 4. 수동 시퀀스 객체 생성 영역
-- ---------------------------------------------------------------------
CREATE SEQUENCE QNA_NO_SEQ START WITH 1 INCREMENT BY 1 NOMAXVALUE NOCACHE NOCYCLE;

-- 자바 코드 맞춤형 공지사항 시퀀스 1번부터 완전 초기화
CREATE SEQUENCE NOTICE_NO_SEQ START WITH 1 INCREMENT BY 1 NOMAXVALUE NOCACHE NOCYCLE;

COMMIT;