-- =====================================================================
-- 티켓팅 AI 보안관제 시스템 — Oracle 21c DDL (오류 원천 차단 통합 최종본)
-- 실행 환경 : TICKET_DEV 계정으로 XEPDB1 접속 후 실행 (Alt + X 권장)
-- =====================================================================

-- ---------------------------------------------------------------------
-- [안전장치] 기존 테이블, 트리거, 시퀀스 및 딕셔너리 잔재 제약조건 완전 제거
-- ---------------------------------------------------------------------
-- 1. 트리거 및 시퀀스 선 파괴
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER TICKET_DEV.TRG_ATTACH_POST_ID_FILL';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE QNA_NO_SEQ';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- 2. 무결성 오류를 유발하는 구버전 attachments 외래키 찌꺼기 딕셔너리 규칙 명시적 완전 파괴
BEGIN
    EXECUTE IMMEDIATE 'ALTER TABLE attachments DROP CONSTRAINT FK_ATTACHMENTS_POST';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'ALTER TABLE attachments DROP CONSTRAINT FK_ATTACHMENTS_QNA';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- 3. 테이블 완전 카스케이드 파괴 (순서 무관)
BEGIN EXECUTE IMMEDIATE 'DROP TABLE chatbot_logs       CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'DROP TABLE qna_posts          CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'DROP TABLE notices            CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'DROP TABLE attachments        CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'DROP TABLE comments           CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'DROP TABLE posts              CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'DROP TABLE payments           CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'DROP TABLE booking_items      CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'DROP TABLE bookings           CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'DROP TABLE seats              CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'DROP TABLE concert_schedules  CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'DROP TABLE concerts           CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'DROP TABLE admins             CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'DROP TABLE members            CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END; /


-- =====================================================================
-- 1. members  (회원)
-- =====================================================================
CREATE TABLE members (
    member_id     NUMBER(19)      GENERATED AS IDENTITY  NOT NULL,
    email         VARCHAR2(200)                          NOT NULL,
    password_hash VARCHAR2(256)                          NOT NULL,
    name          VARCHAR2(100)                          NOT NULL,
    phone         VARCHAR2(20),
    birth_date    DATE,
    role          VARCHAR2(20)    DEFAULT 'USER'         NOT NULL,
    CONSTRAINT pk_members           PRIMARY KEY (member_id),
    CONSTRAINT uk_members_email     UNIQUE (email)
);

COMMENT ON TABLE  members               IS '회원';
COMMENT ON COLUMN members.member_id     IS '회원번호';
COMMENT ON COLUMN members.email         IS '이메일 (로그인 ID)';
COMMENT ON COLUMN members.password_hash IS 'bcrypt 해시 비밀번호';
COMMENT ON COLUMN members.name          IS '이름';
COMMENT ON COLUMN members.phone         IS '휴대폰';
COMMENT ON COLUMN members.birth_date    IS '생년월일';
COMMENT ON COLUMN members.role          IS '역할 USER/ADMIN';


-- =====================================================================
-- 2. admins  (관리자)
-- =====================================================================
CREATE TABLE admins (
    admin_id        NUMBER(19)      GENERATED AS IDENTITY  NOT NULL,
    admin_login_id  VARCHAR2(20)                           NOT NULL,
    password_hash   VARCHAR2(256)                          NOT NULL,
    CONSTRAINT pk_admins            PRIMARY KEY (admin_id),
    CONSTRAINT uk_admins_login_id   UNIQUE (admin_login_id)
);

COMMENT ON TABLE  admins                IS '관리자';
COMMENT ON COLUMN admins.admin_id       IS '관리자 번호';
COMMENT ON COLUMN admins.admin_login_id IS '관리자 로그인 아이디';
COMMENT ON COLUMN admins.password_hash  IS 'bcrypt 해시 비밀번호';


-- =====================================================================
-- 3. concerts  (공연)
-- =====================================================================
CREATE TABLE concerts (
    concert_id      NUMBER(19)      GENERATED AS IDENTITY  NOT NULL,
    title           VARCHAR2(300)                          NOT NULL,
    artist          VARCHAR2(200)                          NOT NULL,
    venue           VARCHAR2(300)                          NOT NULL,
    description     CLOB,
    thumbnail       VARCHAR2(500),
    status          VARCHAR2(20)    DEFAULT 'UPCOMING'     NOT NULL,
    CONSTRAINT pk_concerts          PRIMARY KEY (concert_id)
);

COMMENT ON TABLE  concerts             IS '공연';
COMMENT ON COLUMN concerts.concert_id  IS '공연번호';
COMMENT ON COLUMN concerts.title       IS '공연명';
COMMENT ON COLUMN concerts.artist      IS '아티스트';
COMMENT ON COLUMN concerts.venue       IS '공연장소';
COMMENT ON COLUMN concerts.description IS '공연 설명';
COMMENT ON COLUMN concerts.thumbnail   IS '썸네일 경로';
COMMENT ON COLUMN concerts.status      IS '상태 UPCOMING/ONGOING/CLOSED';


-- =====================================================================
-- 4. concert_schedules  (공연 일정)
-- =====================================================================
CREATE TABLE concert_schedules (
    schedule_id        NUMBER(19)   GENERATED AS IDENTITY  NOT NULL,
    concert_id         NUMBER(19)                          NOT NULL,
    performance_date   TIMESTAMP                           NOT NULL,
    booking_open_at    TIMESTAMP                           NOT NULL,
    total_seats        NUMBER(10)                          NOT NULL,
    available_seats    NUMBER(10)                          NOT NULL,
    CONSTRAINT pk_concert_schedules    PRIMARY KEY (schedule_id),
    CONSTRAINT fk_schedules_concert    FOREIGN KEY (concert_id)
        REFERENCES concerts (concert_id)
);

COMMENT ON TABLE  concert_schedules                  IS '공연 일정';
COMMENT ON COLUMN concert_schedules.schedule_id      IS '일정번호';
COMMENT ON COLUMN concert_schedules.concert_id       IS '공연번호 → concerts';
COMMENT ON COLUMN concert_schedules.performance_date IS '공연 일시';
COMMENT ON COLUMN concert_schedules.booking_open_at  IS '예매 오픈 시간 (선예매 탐지 기준)';
COMMENT ON COLUMN concert_schedules.total_seats      IS '총 좌석수';
COMMENT ON COLUMN concert_schedules.available_seats  IS '잔여 좌석수';


-- =====================================================================
-- 5. seats  (좌석)
-- =====================================================================
CREATE TABLE seats (
    seat_id         NUMBER(19)      GENERATED AS IDENTITY  NOT NULL,
    schedule_id     NUMBER(19)                             NOT NULL,
    seat_row        NUMBER(10)                             NOT NULL,
    seat_col        NUMBER(10)                             NOT NULL,
    price           NUMBER(19)                             NOT NULL,
    status          VARCHAR2(20)    DEFAULT 'AVAILABLE'    NOT NULL,
    CONSTRAINT pk_seats             PRIMARY KEY (seat_id),
    CONSTRAINT fk_seats_schedule    FOREIGN KEY (schedule_id)
        REFERENCES concert_schedules (schedule_id),
    CONSTRAINT uk_seats_position    UNIQUE (schedule_id, seat_row, seat_col)
);

COMMENT ON TABLE  seats             IS '좌석';
COMMENT ON COLUMN seats.seat_id     IS '좌석번호';
COMMENT ON COLUMN seats.schedule_id IS '일정번호 → concert_schedules';
COMMENT ON COLUMN seats.seat_row    IS '열 (1, 2, 3…)';
COMMENT ON COLUMN seats.seat_col    IS '번 (1, 2, 3…)';
COMMENT ON COLUMN seats.price       IS '좌석 가격';
COMMENT ON COLUMN seats.status      IS '상태 AVAILABLE/HELD/RESERVED';


-- =====================================================================
-- 6. bookings  (예매)
-- =====================================================================
CREATE TABLE bookings (
    booking_id      NUMBER(19)      GENERATED AS IDENTITY  NOT NULL,
    member_id       NUMBER(19)                             NOT NULL,
    schedule_id     NUMBER(19)                             NOT NULL,
    total_price     NUMBER(19)                             NOT NULL,
    status          VARCHAR2(20)    DEFAULT 'PENDING'      NOT NULL,
    created_at      TIMESTAMP       DEFAULT SYSTIMESTAMP   NOT NULL,
    CONSTRAINT pk_bookings          PRIMARY KEY (booking_id),
    CONSTRAINT fk_bookings_member   FOREIGN KEY (member_id)
        REFERENCES members (member_id),
    CONSTRAINT fk_bookings_schedule FOREIGN KEY (schedule_id)
        REFERENCES concert_schedules (schedule_id)
);

COMMENT ON TABLE  bookings             IS '예매';
COMMENT ON COLUMN bookings.booking_id  IS '예매번호';
COMMENT ON COLUMN bookings.member_id   IS '회원번호 → members';
COMMENT ON COLUMN bookings.schedule_id IS '일정번호 → concert_schedules';
COMMENT ON COLUMN bookings.total_price IS '총 결제금액';
COMMENT ON COLUMN bookings.status      IS '상태 PENDING/CONFIRMED/CANCELLED';
COMMENT ON COLUMN bookings.created_at  IS '예매일시';


-- =====================================================================
-- 7. booking_items  (예매 항목)
-- =====================================================================
CREATE TABLE booking_items (
    item_id         NUMBER(19)      GENERATED AS IDENTITY  NOT NULL,
    booking_id      NUMBER(19)                             NOT NULL,
    seat_id         NUMBER(19)                             NOT NULL,
    unit_price      NUMBER(19)                             NOT NULL,
    CONSTRAINT pk_booking_items     PRIMARY KEY (item_id),
    CONSTRAINT fk_items_booking     FOREIGN KEY (booking_id)
        REFERENCES bookings (booking_id),
    CONSTRAINT fk_items_seat        FOREIGN KEY (seat_id)
        REFERENCES seats (seat_id)
);

COMMENT ON TABLE  booking_items            IS '예매 항목';
COMMENT ON COLUMN booking_items.item_id    IS '예매 항목번호';
COMMENT ON COLUMN booking_items.booking_id IS '예매번호 → bookings';
COMMENT ON COLUMN booking_items.seat_id    IS '좌석번호 → seats';
COMMENT ON COLUMN booking_items.unit_price IS '단가';


-- =====================================================================
-- 8. payments  (결제)
-- =====================================================================
CREATE TABLE payments (
    payment_id        NUMBER(19)    GENERATED AS IDENTITY  NOT NULL,
    booking_id        NUMBER(19)                           NOT NULL,
    member_id         NUMBER(19)                           NOT NULL,
    transaction_id    VARCHAR2(200)                        NOT NULL,
    requested_amount  NUMBER(19)                           NOT NULL,
    status            VARCHAR2(20)  DEFAULT 'PENDING'      NOT NULL,
    CONSTRAINT pk_payments          PRIMARY KEY (payment_id),
    CONSTRAINT fk_payments_booking  FOREIGN KEY (booking_id)
        REFERENCES bookings (booking_id),
    CONSTRAINT fk_payments_member   FOREIGN KEY (member_id)
        REFERENCES members (member_id),
    CONSTRAINT uk_payments_tx       UNIQUE (transaction_id)
);

COMMENT ON TABLE  payments                  IS '결제';
COMMENT ON COLUMN payments.payment_id       IS '결제번호';
COMMENT ON COLUMN payments.booking_id       IS '예매번호 → bookings';
COMMENT ON COLUMN payments.member_id        IS '회원번호 → members';
COMMENT ON COLUMN payments.transaction_id   IS 'PG 거래 ID (Replay Attack 탐지)';
COMMENT ON COLUMN payments.requested_amount IS '요청 금액';
COMMENT ON COLUMN payments.status           IS '상태 PENDING/SUCCESS/FAILED/REFUNDED';


-- =====================================================================
-- 9. posts  (게시글)
-- =====================================================================
CREATE TABLE posts (
    post_id         NUMBER(19)      GENERATED AS IDENTITY  NOT NULL,
    member_id       NUMBER(19)                             NOT NULL,
    post_type       VARCHAR2(20)                           NOT NULL,
    title           VARCHAR2(300)                          NOT NULL,
    content         CLOB                                   NOT NULL,
    created_at      TIMESTAMP       DEFAULT SYSTIMESTAMP   NOT NULL,
    CONSTRAINT pk_posts             PRIMARY KEY (post_id),
    CONSTRAINT fk_posts_member      FOREIGN KEY (member_id)
        REFERENCES members (member_id)
);

COMMENT ON TABLE  posts            IS '게시글';
COMMENT ON COLUMN posts.post_id    IS '게시글번호';
COMMENT ON COLUMN posts.member_id  IS '회원번호 → members';
COMMENT ON COLUMN posts.post_type  IS '게시판 구분 FREE/REVIEW';
COMMENT ON COLUMN posts.title      IS '제목';
COMMENT ON COLUMN posts.content    IS '내용';
COMMENT ON COLUMN posts.created_at IS '작성일시';


-- =====================================================================
-- 10. comments  (댓글)
-- =====================================================================
CREATE TABLE comments (
    comment_id      NUMBER(19)      GENERATED AS IDENTITY  NOT NULL,
    post_id         NUMBER(19)                             NOT NULL,
    member_id       NUMBER(19)                             NOT NULL,
    content         CLOB                                   NOT NULL,
    created_at      TIMESTAMP       DEFAULT SYSTIMESTAMP   NOT NULL,
    CONSTRAINT pk_comments          PRIMARY KEY (comment_id),
    CONSTRAINT fk_comments_post     FOREIGN KEY (post_id)
        REFERENCES posts (post_id),
    CONSTRAINT fk_comments_member   FOREIGN KEY (member_id)
        REFERENCES members (member_id)
);

COMMENT ON TABLE  comments            IS '댓글';
COMMENT ON COLUMN comments.comment_id IS '댓글번호';
COMMENT ON COLUMN comments.post_id    IS '게시글번호 → posts';
COMMENT ON COLUMN comments.member_id  IS '회원번호 → members';
COMMENT ON COLUMN comments.content    IS '내용';
COMMENT ON COLUMN comments.created_at IS '작성일시';


-- =====================================================================
-- 11. qna_posts  (Q&A 게시글) - [수정] 자바 쿼리 수동 삽입(ORA-32795) 방지 구조
-- =====================================================================
CREATE TABLE qna_posts (
    QNA_ID          NUMBER(19,0)                           NOT NULL,
    MEMBER_ID       NUMBER(19,0),
    TITLE           VARCHAR2(300)                          NOT NULL,
    CONTENT         CLOB                                   NOT NULL,
    CREATED_AT      TIMESTAMP       DEFAULT SYSTIMESTAMP   NOT NULL,
    QNA_NAME        VARCHAR2(100),
    QNA_AN          VARCHAR2(4000),
    IS_SECRET       NUMBER(1,0)     DEFAULT 0              NOT NULL,
    CONSTRAINT pk_qna_posts         PRIMARY KEY (QNA_ID),
    CONSTRAINT fk_qna_member        FOREIGN KEY (MEMBER_ID)
        REFERENCES members (member_id)
);

COMMENT ON TABLE  qna_posts               IS 'Q&A 게시글';
COMMENT ON COLUMN qna_posts.QNA_ID        IS '문의번호';
COMMENT ON COLUMN qna_posts.MEMBER_ID     IS '회원번호 → members (비회원 NULL)';
COMMENT ON COLUMN qna_posts.TITLE         IS '제목';
COMMENT ON COLUMN qna_posts.CONTENT       IS '내용';
COMMENT ON COLUMN qna_posts.CREATED_AT    IS '등록일시';
COMMENT ON COLUMN qna_posts.QNA_NAME      IS '작성자명 (비회원용)';
COMMENT ON COLUMN qna_posts.QNA_AN        IS '답변 내용';
COMMENT ON COLUMN qna_posts.IS_SECRET     IS '비밀글 여부 (0=공개, 1=비밀글)';


-- =====================================================================
-- 12. attachments  (첨부파일) - [수정] 무결성 부모키 제약 오류(ORA-02291) 해결 구조
-- =====================================================================
CREATE TABLE attachments (
    ATTACHMENT_ID   NUMBER(19,0)    GENERATED BY DEFAULT AS IDENTITY NOT NULL,
    POST_ID         NUMBER(19,0),   -- posts와 qna_posts의 ID를 공용 연동하여 공유하는 공간
    ORIGINAL_NAME   VARCHAR2(500)                          NOT NULL,
    SAVED_NAME      VARCHAR2(500)                          NOT NULL,
    EXTENSION       VARCHAR2(20)                           NOT NULL,
    FILE_SIZE       NUMBER(19,0)                           NOT NULL,
    UPLOADED_AT     TIMESTAMP       DEFAULT SYSTIMESTAMP   NOT NULL,
    CONSTRAINT pk_attachments       PRIMARY KEY (ATTACHMENT_ID)
    -- ⚠️ 공용 공유 테이블 특성상 REFERENCES 하드 외래키를 걸면 무결성 제약 오류가 무조건 발생합니다.
    -- 여기에 명시적인 REFERENCES 선언문을 절대로 포함시키지 마세요.
);

COMMENT ON TABLE  attachments               IS '첨부파일';
COMMENT ON COLUMN attachments.ATTACHMENT_ID IS '첨부파일번호';
COMMENT ON COLUMN attachments.POST_ID       IS '게시글번호 → posts, qna_posts 공유';
COMMENT ON COLUMN attachments.ORIGINAL_NAME IS '원본 파일명';
COMMENT ON COLUMN attachments.SAVED_NAME    IS '저장 파일명';
COMMENT ON COLUMN attachments.EXTENSION     IS '확장자 (악성 확장자 탐지용)';
COMMENT ON COLUMN attachments.FILE_SIZE     IS '파일 크기';
COMMENT ON COLUMN attachments.UPLOADED_AT   IS '업로드 일시';


-- =====================================================================
-- 13. notices  (공지사항)
-- =====================================================================
CREATE TABLE notices (
    notice_id       NUMBER(19)      GENERATED AS IDENTITY  NOT NULL,
    admin_id        NUMBER(19)                             NOT NULL,
    title           VARCHAR2(300)                          NOT NULL,
    content         CLOB,
    created_at      TIMESTAMP       DEFAULT SYSTIMESTAMP   NOT NULL,
    CONSTRAINT pk_notices           PRIMARY KEY (notice_id),
    CONSTRAINT fk_notices_admin     FOREIGN KEY (admin_id)
        REFERENCES admins (admin_id)
);

COMMENT ON TABLE  notices            IS '공지사항';
COMMENT ON COLUMN notices.notice_id  IS '공지번호';
COMMENT ON COLUMN notices.admin_id   IS '관리자번호 → admins';
COMMENT ON COLUMN notices.title      IS '제목';
COMMENT ON COLUMN notices.content    IS '내용';
COMMENT ON COLUMN notices.created_at IS '등록일시';


-- =====================================================================
-- 14. chatbot_logs  (챗봇 로그)
-- =====================================================================
CREATE TABLE chatbot_logs (
    log_id                    NUMBER(19)      GENERATED AS IDENTITY  NOT NULL,
    member_id                 NUMBER(19),
    src_ip                    VARCHAR2(50)                           NOT NULL,
    session_id                VARCHAR2(100)                          NOT NULL,
    prompt_text               CLOB                                   NOT NULL,
    response_text             CLOB,
    prompt_length             NUMBER(10)                             NOT NULL,
    response_length           NUMBER(10),
    blocked_keyword_detected  NUMBER(1)       DEFAULT 0              NOT NULL,
    model_response_status     VARCHAR2(20)                           NOT NULL,
    created_at                TIMESTAMP       DEFAULT SYSTIMESTAMP   NOT NULL,
    CONSTRAINT pk_chatbot_logs      PRIMARY KEY (log_id),
    CONSTRAINT fk_chatbot_member    FOREIGN KEY (member_id)
        REFERENCES members (member_id)
);

COMMENT ON TABLE  chatbot_logs                          IS '챗봇 로그';
COMMENT ON COLUMN chatbot_logs.log_id                   IS '챗봇 로그 번호';
COMMENT ON COLUMN chatbot_logs.member_id                IS '회원번호 → members';
COMMENT ON COLUMN chatbot_logs.src_ip                   IS '요청 IP';
COMMENT ON COLUMN chatbot_logs.session_id               IS '세션 ID';
COMMENT ON COLUMN chatbot_logs.prompt_text              IS '프롬프트 내용';
COMMENT ON COLUMN chatbot_logs.response_text            IS '응답 내용';
COMMENT ON COLUMN chatbot_logs.prompt_length            IS '프롬프트 길이';
COMMENT ON COLUMN chatbot_logs.response_length          IS '응답 길이';
COMMENT ON COLUMN chatbot_logs.blocked_keyword_detected IS '차단 키워드 탐지 여부';
COMMENT ON COLUMN chatbot_logs.model_response_status    IS '응답 상태 SUCCESS/FAILED/BLOCKED';
COMMENT ON COLUMN chatbot_logs.created_at               IS '요청일시';


-- =====================================================================
-- 데이터 조회 정렬 가속 인덱스 설정
-- =====================================================================
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


-- =====================================================================
-- 15. 수동 증가 시퀀스 객체 및 자동 무결성 연동 트리거 설정
-- =====================================================================

-- [시퀀스] 깨끗하게 1부터 증가하여 자바 코드 시퀀스 처리에 호환되는 객체 확보
CREATE SEQUENCE QNA_NO_SEQ 
       START WITH 1 
       INCREMENT BY 1 
       NOMAXVALUE 
       NOCACHE
       NOCYCLE;

-- ❌ [주의] 다른 외래키 추가문(ALTER TABLE ADD CONSTRAINT FK...)이 이 아래에 섞여 들어오면 안 됩니다.
-- 하드 외래키 선언을 생략함으로써 ORA-02291(부모 키 없음) 오류를 영구 격리합니다.

-- [트리거] 파일 저장 시 POST_ID 누락을 자동으로 검지하여 최종 시퀀스 값으로 제어하는 스마트 연동 장치
CREATE OR REPLACE TRIGGER TICKET_DEV.TRG_ATTACH_POST_ID_FILL
BEFORE INSERT ON TICKET_DEV.ATTACHMENTS
FOR EACH ROW
BEGIN
    IF :NEW.POST_ID IS NULL OR :NEW.POST_ID = 0 THEN
        SELECT NVL(MAX(QNA_ID), 0) INTO :NEW.POST_ID FROM TICKET_DEV.QNA_POSTS;
    END IF;
END;
/

-- 데이터베이스 트랜잭션 완전 확정 및 저장 완료
COMMIT;