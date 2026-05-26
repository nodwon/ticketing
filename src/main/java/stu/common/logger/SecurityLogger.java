/**
 * ============================================================
 * Project   : 티켓팅 보안관제 (Ticketing Security Monitoring)
 * Package   : stu.common.logger
 * FileName  : SecurityLogger.java
 * Purpose   : 명세서(log_*) 컬럼 → JSON 키 매핑을 강제하는 헬퍼
 * Note      : SLF4J 가변인자 호환 처리 (Object[] 명시)
 * ============================================================
 */
package stu.common.logger;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import net.logstash.logback.argument.StructuredArguments;

public final class SecurityLogger {

    private static final Logger AUTH     = LoggerFactory.getLogger("SECURITY.AUTH");
    private static final Logger SEAT     = LoggerFactory.getLogger("SECURITY.SEAT");
    private static final Logger PAYMENT  = LoggerFactory.getLogger("SECURITY.PAYMENT");
    private static final Logger ADMIN    = LoggerFactory.getLogger("SECURITY.ADMIN");
    private static final Logger BOARD    = LoggerFactory.getLogger("SECURITY.BOARD");
    private static final Logger BEHAVIOR = LoggerFactory.getLogger("SECURITY.BEHAVIOR");

    private SecurityLogger() {}

    /* ============================================================
     * log_auth : 로그인 이벤트
     * ============================================================ */
    public static void auth(Long userId, String srcIp, String result) {
        AUTH.info("auth_event", new Object[] {
            StructuredArguments.kv("user_id",      userId),
            StructuredArguments.kv("src_ip",       srcIp),
            StructuredArguments.kv("login_result", result)
        });
    }

    /* ============================================================
     * log_seat : 좌석 선택 이벤트
     * ============================================================ */
    public static void seat(Long userId, Long concertId, Long seatId,
                            String result, Integer elapsedMs) {
        SEAT.info("seat_event", new Object[] {
            StructuredArguments.kv("user_id",        userId),
            StructuredArguments.kv("concert_id",     concertId),
            StructuredArguments.kv("seat_id",        seatId),
            StructuredArguments.kv("request_result", result),
            StructuredArguments.kv("elapsed_time",   elapsedMs)
        });
    }

    /* ============================================================
     * log_payment : 결제 이벤트 (TAMPER 탐지)
     * ============================================================ */
    public static void payment(Long userId, String transactionId,
                               Long paymentAmount, Long actualPrice,
                               String result) {
        PAYMENT.info("payment_event", new Object[] {
            StructuredArguments.kv("user_id",        userId),
            StructuredArguments.kv("transaction_id", transactionId),
            StructuredArguments.kv("payment_amount", paymentAmount),
            StructuredArguments.kv("actual_price",   actualPrice),
            StructuredArguments.kv("payment_result", result)
        });
    }

    /* ============================================================
     * log_admin_access : 관리자 접근 시도
     * ============================================================ */
    public static void adminAccess(String accessUrl, Long userId,
                                   String srcIp, int statusCode) {
        ADMIN.info("admin_access_event", new Object[] {
            StructuredArguments.kv("access_url",  accessUrl),
            StructuredArguments.kv("user_id",     userId),
            StructuredArguments.kv("src_ip",      srcIp),
            StructuredArguments.kv("status_code", statusCode)
        });
    }

    /* ============================================================
     * log_board : 게시판 이벤트
     * ============================================================ */
    public static void board(Long userId, String boardType, String content,
                             String attachmentName, String attachmentExt) {
        BOARD.info("board_event", new Object[] {
            StructuredArguments.kv("user_id",              userId),
            StructuredArguments.kv("board_type",           boardType),
            StructuredArguments.kv("content",              content),
            StructuredArguments.kv("attachment_name",      attachmentName),
            StructuredArguments.kv("attachment_extension", attachmentExt)
        });
    }

    /* ============================================================
     * log_behavior_feature : MLTK 행동 Feature
     * ============================================================ */
    public static BehaviorBuilder behavior(Long userId, String srcIp) {
        return new BehaviorBuilder(userId, srcIp);
    }

    public static final class BehaviorBuilder {
        private final Long userId;
        private final String srcIp;
        private Double  requestsPerSecond, requestsPerMinute;
        private Integer burstRequestCount, seatChangeCount, uniqueSeatCount;
        private Double  failedSelectRatio, avgActionInterval, pageTransitionTime;
        private Double  loginFailRatio;
        private Integer targetAccountCount, repeatedFailCount, jailbreakKeywordCount;
        private Integer excessiveTokenRequest;

        private BehaviorBuilder(Long userId, String srcIp) {
            this.userId = userId;
            this.srcIp  = srcIp;
        }
        public BehaviorBuilder requestsPerSecond(double v) { this.requestsPerSecond = v; return this; }
        public BehaviorBuilder requestsPerMinute(double v) { this.requestsPerMinute = v; return this; }
        public BehaviorBuilder burstRequestCount(int v)    { this.burstRequestCount = v; return this; }
        public BehaviorBuilder seatChangeCount(int v)      { this.seatChangeCount   = v; return this; }
        public BehaviorBuilder uniqueSeatCount(int v)      { this.uniqueSeatCount   = v; return this; }
        public BehaviorBuilder failedSelectRatio(double v) { this.failedSelectRatio = v; return this; }
        public BehaviorBuilder avgActionInterval(double v) { this.avgActionInterval = v; return this; }
        public BehaviorBuilder pageTransitionTime(double v){ this.pageTransitionTime= v; return this; }
        public BehaviorBuilder loginFailRatio(double v)    { this.loginFailRatio    = v; return this; }
        public BehaviorBuilder targetAccountCount(int v)   { this.targetAccountCount= v; return this; }
        public BehaviorBuilder repeatedFailCount(int v)    { this.repeatedFailCount = v; return this; }
        public BehaviorBuilder jailbreakKeywordCount(int v){ this.jailbreakKeywordCount = v; return this; }
        public BehaviorBuilder excessiveTokenRequest(boolean v) {
            this.excessiveTokenRequest = v ? 1 : 0; return this;
        }

        public void emit() {
            BEHAVIOR.info("behavior_feature", new Object[] {
                StructuredArguments.kv("user_id",                 userId),
                StructuredArguments.kv("src_ip",                  srcIp),
                StructuredArguments.kv("requests_per_second",     requestsPerSecond),
                StructuredArguments.kv("requests_per_minute",     requestsPerMinute),
                StructuredArguments.kv("burst_request_count",     burstRequestCount),
                StructuredArguments.kv("seat_change_count",       seatChangeCount),
                StructuredArguments.kv("unique_seat_count",       uniqueSeatCount),
                StructuredArguments.kv("failed_select_ratio",     failedSelectRatio),
                StructuredArguments.kv("avg_action_interval",     avgActionInterval),
                StructuredArguments.kv("page_transition_time",    pageTransitionTime),
                StructuredArguments.kv("login_fail_ratio",        loginFailRatio),
                StructuredArguments.kv("target_account_count",    targetAccountCount),
                StructuredArguments.kv("repeated_fail_count",     repeatedFailCount),
                StructuredArguments.kv("jailbreak_keyword_count", jailbreakKeywordCount),
                StructuredArguments.kv("excessive_token_request", excessiveTokenRequest)
            });
        }
    }
}
