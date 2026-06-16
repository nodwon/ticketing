/**
 * ============================================================
 * Project   : 티켓팅 보안관제 (Ticketing Security Monitoring)
 * Package   : stu.common.logger
 * FileName  : SecurityLogger.java
 * Purpose   : 명세서(log_*) 컬럼 → JSON 키 매핑을 강제하는 헬퍼
 * Note      : logstash-logback-encoder Marker 방식
 *             - {} 자리표시자 없이 키-값을 JSON으로 출력
 *             - 기존 Object[] 방식이 빈 출력을 만드는 문제 해결
 * ============================================================
 */
package stu.common.logger;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import net.logstash.logback.marker.Markers;
import net.logstash.logback.marker.LogstashMarker;

import java.util.LinkedHashMap;
import java.util.Map;

public final class SecurityLogger {

    private static final Logger AUTH     = LoggerFactory.getLogger("SECURITY.AUTH");
    private static final Logger SEAT     = LoggerFactory.getLogger("SECURITY.SEAT");
    private static final Logger PAYMENT  = LoggerFactory.getLogger("SECURITY.PAYMENT");
    private static final Logger ADMIN    = LoggerFactory.getLogger("SECURITY.ADMIN");
    private static final Logger BOARD    = LoggerFactory.getLogger("SECURITY.BOARD");
    private static final Logger BEHAVIOR = LoggerFactory.getLogger("SECURITY.BEHAVIOR");

    private SecurityLogger() {}

    /* ============================================================
     * 공통 헬퍼 - Map을 만들어서 Markers.appendEntries() 로 변환
     * 이렇게 하면 logstash-encoder가 각 키를 JSON 필드로 출력
     * ============================================================ */
    private static LogstashMarker marker(Object... kv) {
        Map<String, Object> map = new LinkedHashMap<>();
        for (int i = 0; i < kv.length; i += 2) {
            map.put(String.valueOf(kv[i]), kv[i + 1]);
        }
        return Markers.appendEntries(map);
    }

    /* ============================================================
     * log_auth : 로그인 이벤트
     * ============================================================ */
    public static void auth(Long userId, String srcIp, String result) {
        AUTH.info(marker(
            "user_id",      userId,
            "src_ip",       srcIp,
            "login_result", result
        ), "auth_event");
    }

    /* ============================================================
     * log_seat : 좌석 선택 이벤트
     * ============================================================ */
    public static void seat(Long userId, Long concertId, Long seatId,
                            String result, Integer elapsedMs) {
        SEAT.info(marker(
            "user_id",        userId,
            "concert_id",     concertId,
            "seat_id",        seatId,
            "request_result", result,
            "elapsed_time",   elapsedMs
        ), "seat_event");
    }

    /* ============================================================
     * log_payment : 결제 이벤트 (TAMPER 탐지 포함)
     * ============================================================ */
    public static void payment(Long userId, String transactionId,
                               Long paymentAmount, Long actualPrice,
                               String result) {
        PAYMENT.info(marker(
            "user_id",        userId,
            "transaction_id", transactionId,
            "payment_amount", paymentAmount,
            "actual_price",   actualPrice,
            "payment_result", result
        ), "payment_event");
    }

    /* ============================================================
     * log_admin_access : 관리자 접근 시도
     * ============================================================ */
    public static void adminAccess(String accessUrl, Long userId,
                                   String srcIp, Integer statusCode) {
        ADMIN.info(marker(
            "access_url",  accessUrl,
            "user_id",     userId,
            "src_ip",      srcIp,
            "status_code", statusCode
        ), "admin_access_event");
    }

    /* ============================================================
     * log_board : 게시판 이벤트
     * ============================================================ */
    public static void board(Long userId, String boardType, String content,
                             String attachmentName, String attachmentExt) {
        BOARD.info(marker(
            "user_id",              userId,
            "board_type",           boardType,
            "content",              content,
            "attachment_name",      attachmentName,
            "attachment_extension", attachmentExt
        ), "board_event");
    }

    /* ============================================================
     * log_behavior_feature : MLTK 행동 Feature (Builder 패턴)
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
        // ★ 명세서 확장 필드 (클릭 행동 + LLM 프롬프트)
        private Double  avgClickInterval, clickIntervalStd, promptSimilarity;
        private Integer clickCount, repeatedPromptPattern;

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
        public BehaviorBuilder avgClickInterval(double v)       { this.avgClickInterval = v; return this; }
        public BehaviorBuilder clickIntervalStd(double v)       { this.clickIntervalStd = v; return this; }
        public BehaviorBuilder clickCount(int v)                { this.clickCount = v; return this; }
        public BehaviorBuilder promptSimilarity(double v)       { this.promptSimilarity = v; return this; }
        public BehaviorBuilder repeatedPromptPattern(boolean v) { this.repeatedPromptPattern = v ? 1 : 0; return this; }

        public void emit() {
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("user_id",                 userId);
            map.put("src_ip",                  srcIp);
            map.put("avg_click_interval",      avgClickInterval);
            map.put("click_interval_std",      clickIntervalStd);
            map.put("click_count",             clickCount);
            map.put("requests_per_second",     requestsPerSecond);
            map.put("requests_per_minute",     requestsPerMinute);
            map.put("burst_request_count",     burstRequestCount);
            map.put("seat_change_count",       seatChangeCount);
            map.put("unique_seat_count",       uniqueSeatCount);
            map.put("failed_select_ratio",     failedSelectRatio);
            map.put("avg_action_interval",     avgActionInterval);
            map.put("page_transition_time",    pageTransitionTime);
            map.put("login_fail_ratio",        loginFailRatio);
            map.put("target_account_count",    targetAccountCount);
            map.put("repeated_fail_count",     repeatedFailCount);
            map.put("repeated_prompt_pattern", repeatedPromptPattern);
            map.put("prompt_similarity",       promptSimilarity);
            map.put("jailbreak_keyword_count", jailbreakKeywordCount);
            map.put("excessive_token_request", excessiveTokenRequest);

            BEHAVIOR.info(Markers.appendEntries(map), "behavior_feature");
        }
    }
}
