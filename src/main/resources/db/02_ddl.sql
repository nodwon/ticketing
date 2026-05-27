-- =====================================================================
-- 티켓팅 AI 보안관제 시스템 — Oracle 21c DDL (수정본)
-- 기반        : 사용자 제공 ERD export DDL
-- 수정사항    :
--   ① 모든 PK에 GENERATED AS IDENTITY 추가
--   ② 큰따옴표("") 식별자 제거 → Oracle 표준 (대소문자 무관)
--   ③ FK 제약조건 전체 추가
--   ④ 컬럼명 통일: user_id → member_id (members 테이블 PK와 일치)
--   ⑤ UNIQUE 제약 추가 (email, admin_login_id, transaction_id)
--   ⑥ 인덱스 추가 (자주 조회되는 FK 컬럼)
-- =====================================================================
-- 실행 환경 : TICKET_DEV 계정으로 XEPDB1 접속 후 실행
-- =====================================================================


-- ---------------------------------------------------------------------
-- (선택) 기존 테이블 제거 — 처음 실행 시 주석 처리
-- ---------------------------------------------------------------------
-- DROP TABLE chatbot_logs       CASCADE CONSTRAINTS;
-- DROP TABLE qna_posts          CASCADE CONSTRAINTS;
-- DROP TABLE notices            CASCADE CONSTRAINTS;
-- DROP TABLE attachments        CASCADE CONSTRAINTS;
-- DROP TABLE comments           CASCADE CONSTRAINTS;
-- DROP TABLE posts              CASCADE CONSTRAINTS;
-- DROP TABLE payments           CASCADE CONSTRAINTS;
-- DROP TABLE booking_items      CASCADE CONSTRAINTS;
-- DROP TABLE bookings           CASCADE CONSTRAINTS;
-- DROP TABLE seats              CASCADE CONSTRAINTS;
-- DROP TABLE concert_schedules  CASCADE CONSTRAINTS;
-- DROP TABLE concerts           CASCADE CONSTRAINTS;
-- DROP TABLE admins             CASCADE CONSTRAINTS;
-- DROP TABLE members            CASCADE CONSTRAINTS;


-- =====================================================================
-- 1. members  (회원)
-- =====================================================================
CREATE TABLE members (
    member_id       NUMBER(19)      GENERATED AS IDENTITY  NOT NULL,
    email           VARCHAR2(200)                          NOT NULL,
    password_hash   VARCHAR2(256)                          NOT NULL,
    name            VARCHAR2(100)                          NOT NULL,
    phone           VARCHAR2(20),
    birth_date      DATE,
    role            VARCHAR2(20)    DEFAULT 'USER'         NOT NULL,
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
-- 11. attachments  (첨부파일)
-- =====================================================================
CREATE TABLE attachments (
    attachment_id   NUMBER(19)      GENERATED AS IDENTITY  NOT NULL,
    post_id         NUMBER(19),
    original_name   VARCHAR2(500)                          NOT NULL,
    saved_name      VARCHAR2(500)                          NOT NULL,
    extension       VARCHAR2(20)                           NOT NULL,
    file_size       NUMBER(19)                             NOT NULL,
    uploaded_at     TIMESTAMP       DEFAULT SYSTIMESTAMP   NOT NULL,
    CONSTRAINT pk_attachments       PRIMARY KEY (attachment_id),
    CONSTRAINT fk_attachments_post  FOREIGN KEY (post_id)
        REFERENCES posts (post_id)
);

COMMENT ON TABLE  attachments               IS '첨부파일';
COMMENT ON COLUMN attachments.attachment_id IS '첨부파일번호';
COMMENT ON COLUMN attachments.post_id       IS '게시글번호 → posts';
COMMENT ON COLUMN attachments.original_name IS '원본 파일명';
COMMENT ON COLUMN attachments.saved_name    IS '저장 파일명';
COMMENT ON COLUMN attachments.extension     IS '확장자 (악성 확장자 탐지용)';
COMMENT ON COLUMN attachments.file_size     IS '파일 크기';
COMMENT ON COLUMN attachments.uploaded_at   IS '업로드 일시';


-- =====================================================================
-- 12. notices  (공지사항)
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
-- 13. qna_posts  (Q&A)
-- =====================================================================
CREATE TABLE qna_posts (
    qna_id          NUMBER(19)      GENERATED AS IDENTITY  NOT NULL,
    member_id       NUMBER(19),
    title           VARCHAR2(300)                          NOT NULL,
    content         CLOB                                   NOT NULL,
    is_secret       NUMBER(1)       DEFAULT 0              NOT NULL,
    created_at      TIMESTAMP       DEFAULT SYSTIMESTAMP   NOT NULL,
    CONSTRAINT pk_qna_posts         PRIMARY KEY (qna_id),
    CONSTRAINT fk_qna_member        FOREIGN KEY (member_id)
        REFERENCES members (member_id)
);

COMMENT ON TABLE  qna_posts               IS 'Q&A 게시글';
COMMENT ON COLUMN qna_posts.qna_id        IS '문의번호';
COMMENT ON COLUMN qna_posts.member_id     IS '회원번호 → members (비회원 NULL)';
COMMENT ON COLUMN qna_posts.title         IS '제목';
COMMENT ON COLUMN qna_posts.content       IS '내용';
COMMENT ON COLUMN qna_posts.is_secret     IS '비밀글 여부 (0=공개, 1=관리자만 열람)';
COMMENT ON COLUMN qna_posts.created_at    IS '등록일시';

-- ※ 기존 DB에 컬럼 추가 시 아래 ALTER TABLE 실행 필요
-- ALTER TABLE QNA_POSTS ADD IS_SECRET NUMBER(1) DEFAULT 0 NOT NULL;


-- =====================================================================
-- 14. chatbot_logs  (챗봇 로그)
-- =====================================================================
CREATE TABLE chatbot_logs (
    log_id                      NUMBER(19)      GENERATED AS IDENTITY  NOT NULL,
    member_id                   NUMBER(19),
    src_ip                      VARCHAR2(50)                           NOT NULL,
    session_id                  VARCHAR2(100)                          NOT NULL,
    prompt_text                 CLOB                                   NOT NULL,
    response_text               CLOB,
    prompt_length               NUMBER(10)                             NOT NULL,
    response_length             NUMBER(10),
    blocked_keyword_detected    NUMBER(1)       DEFAULT 0              NOT NULL,
    model_response_status       VARCHAR2(20)                           NOT NULL,
    created_at                  TIMESTAMP       DEFAULT SYSTIMESTAMP   NOT NULL,
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
COMMENT ON COLUMN chatbot_logs.model_response_status   IS '응답 상태 SUCCESS/FAILED/BLOCKED';
COMMENT ON COLUMN chatbot_logs.created_at               IS '요청일시';


-- =====================================================================
-- 인덱스 (FK 컬럼 + 자주 조회 컬럼)
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
CREATE INDEX idx_chatbot_logs_member   ON chatbot_logs (member_id);
CREATE INDEX idx_chatbot_logs_created  ON chatbot_logs (created_at);

COMMIT;

-- =====================================================================
-- 검증 쿼리 (실행 후 확인용)
-- =====================================================================
-- SELECT table_name FROM user_tables ORDER BY table_name;
-- SELECT constraint_name, table_name, constraint_type
-- FROM user_constraints WHERE constraint_type = 'R' ORDER BY table_name;
