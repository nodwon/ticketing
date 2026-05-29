/**
 * ============================================================
 * Project   : 관제 티켓 (Ticketing System)
 * Package   : stu.common.logger
 * FileName  : MacroDetectionLogger.java
 * Developer : feature/dw
 * Created   : 2026.05.26
 *
 * Description :
 *   매크로/봇 탐지 전용 로거
 *
 *   [기록 이벤트]
 *   1. booking.redirect         - GET /seat/select.do 로드 ~ POST /seat/hold.do 호출까지 시간
 *   2. booking.seat_hold        - /seat/hold.do 서버 처리 + 페이지 체류 시간
 *   3. booking.create           - /bookingCreate.do 처리 + 좌석→예매 총 시간
 *   4. booking.payment_redirect - bookingCreate 완료 → /payment/form.do 도착 시간
 *   5. booking.complete         - 전체 플로우 완료 (행동 분석)
 *   6. behavior.click_interval  - JS 클릭 간격 분석
 *
 *   [매크로 판단 기준]
 *   - redirect_ms (seat/select 로드 ~ hold.do 호출) < 500ms  : 비정상
 *   - seat_select_ms                                 < 500ms  : 비정상
 *   - total_seat_to_create_ms                        < 2000ms : 비정상
 *   - booking_to_payment_ms                          < 1000ms : 비정상
 *   - avg_click_interval_ms                          < 100ms  : 봇 의심
 *   - std_click_interval                             < 10     : 봇 의심
 * ============================================================
 */
package stu.common.logger;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import net.logstash.logback.marker.Markers;

import java.util.LinkedHashMap;
import java.util.Map;

public final class MacroDetectionLogger {

    private static final Logger SEAT  = LoggerFactory.getLogger("SECURITY.SEAT");
    private static final Logger BEHAV = LoggerFactory.getLogger("SECURITY.BEHAVIOR");

    private MacroDetectionLogger() {}

    // ================================================================
    // 1. 리다이렉트 시간 로그
    //    GET /seat/select.do 페이지 로드 ~ POST /seat/hold.do 호출까지 전체 소요 시간
    //    측정: SeatController.holdSeat() 에서 클라이언트가 보낸 seat_page_load_ts 활용
    // ================================================================
    public static void redirectTime(Long userId, String srcIp,
                                    Long concertId, Long scheduleId,
                                    int redirectMs) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("event",        "booking.redirect");
        m.put("user_id",      userId);
        m.put("src_ip",       srcIp);
        m.put("concert_id",   concertId);
        m.put("schedule_id",  scheduleId);
        m.put("redirect_ms",  redirectMs);
        m.put("is_fast",      redirectMs < 500 ? 1 : 0);
        SEAT.info(Markers.appendEntries(m), "booking_redirect");
    }

    // ================================================================
    // 2. 좌석 선점 시간 로그
    //    seat/select.do 로드 ~ seat/hold.do 호출까지
    //    측정: SeatController.holdSeat()
    // ================================================================
    public static void seatHoldTime(Long userId, String srcIp,
                                     Long concertId, Long seatId,
                                     long pageLoadTs,
                                     int  holdElapsedMs,
                                     String result) {
        long now = System.currentTimeMillis();
        long seatSelectMs = now - pageLoadTs;

        Map<String, Object> m = new LinkedHashMap<>();
        m.put("event",            "booking.seat_hold");
        m.put("user_id",          userId);
        m.put("src_ip",           srcIp);
        m.put("concert_id",       concertId);
        m.put("seat_id",          seatId);
        m.put("seat_select_ms",   seatSelectMs);
        m.put("hold_elapsed_ms",  holdElapsedMs);
        m.put("request_result",   result);
        m.put("is_fast_select",   seatSelectMs < 500 ? 1 : 0);
        SEAT.info(Markers.appendEntries(m), "seat_hold_time");
    }

    // ================================================================
    // 3. 예매 생성 소요 시간 로그
    //    측정: BookingController.bookingCreate()
    // ================================================================
    public static void bookingCreateTime(Long userId, String srcIp,
                                          Long scheduleId, String seatIds,
                                          long seatPageTs,
                                          int  createElapsedMs,
                                          String result) {
        long now = System.currentTimeMillis();
        long totalSeatToCreateMs = (seatPageTs > 0) ? (now - seatPageTs) : createElapsedMs;

        Map<String, Object> m = new LinkedHashMap<>();
        m.put("event",                   "booking.create");
        m.put("user_id",                 userId);
        m.put("src_ip",                  srcIp);
        m.put("schedule_id",             scheduleId);
        m.put("seat_ids",                seatIds);
        m.put("total_seat_to_create_ms", totalSeatToCreateMs);
        m.put("create_elapsed_ms",       createElapsedMs);
        m.put("request_result",          result);
        m.put("is_fast_booking",         totalSeatToCreateMs < 2000 ? 1 : 0);
        SEAT.info(Markers.appendEntries(m), "booking_create_time");
    }

    // ================================================================
    // 4. 결제 폼 리다이렉트 시간 로그
    //    bookingCreate 완료 → /payment/form.do 도착
    //    측정: PaymentController.form()
    // ================================================================
    public static void paymentRedirectTime(Long userId, String srcIp,
                                            Long bookingId,
                                            long bookingCreateTs,
                                            int  paymentFormElapsedMs) {
        long now = System.currentTimeMillis();
        long bookingToPaymentMs = (bookingCreateTs > 0) ? (now - bookingCreateTs) : paymentFormElapsedMs;

        Map<String, Object> m = new LinkedHashMap<>();
        m.put("event",                   "booking.payment_redirect");
        m.put("user_id",                 userId);
        m.put("src_ip",                  srcIp);
        m.put("booking_id",              bookingId);
        m.put("booking_to_payment_ms",   bookingToPaymentMs);
        m.put("payment_form_elapsed_ms", paymentFormElapsedMs);
        m.put("is_fast_payment",         bookingToPaymentMs < 1000 ? 1 : 0);
        SEAT.info(Markers.appendEntries(m), "payment_redirect_time");
    }

    // ================================================================
    // 5. 전체 플로우 완료 로그
    //    concert/detail ~ 결제 완료까지 전체 흐름
    //    측정: PaymentController.result()
    // ================================================================
    public static void fullFlowComplete(Long userId, String srcIp,
                                         Long concertId, Long bookingId,
                                         long detailPageTs,
                                         int  seatChangeCount,
                                         int  uniqueSeatCount,
                                         double requestsPerSecond) {
        long now = System.currentTimeMillis();
        long totalFlowMs = (detailPageTs > 0) ? (now - detailPageTs) : -1;

        Map<String, Object> m = new LinkedHashMap<>();
        m.put("event",               "booking.complete");
        m.put("user_id",             userId);
        m.put("src_ip",              srcIp);
        m.put("concert_id",          concertId);
        m.put("booking_id",          bookingId);
        m.put("total_flow_ms",       totalFlowMs);
        m.put("seat_change_count",   seatChangeCount);
        m.put("unique_seat_count",   uniqueSeatCount);
        m.put("requests_per_second", requestsPerSecond);
        m.put("is_macro_suspect",    isMacroSuspect(totalFlowMs, seatChangeCount, requestsPerSecond) ? 1 : 0);
        BEHAV.info(Markers.appendEntries(m), "booking_complete_behavior");
    }

    // ================================================================
    // 6. 클릭 간격 로그 (JS → /log/clickInterval.do → 여기 호출)
    // ================================================================
    public static void clickInterval(Long userId, String srcIp,
                                      double avgClickIntervalMs,
                                      double stdClickInterval,
                                      int    totalClicks,
                                      Long   concertId) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("event",                 "behavior.click_interval");
        m.put("user_id",               userId);
        m.put("src_ip",                srcIp);
        m.put("concert_id",            concertId);
        m.put("avg_click_interval_ms", avgClickIntervalMs);
        m.put("std_click_interval",    stdClickInterval);
        m.put("total_clicks",          totalClicks);
        m.put("is_bot_suspect",        (avgClickIntervalMs < 100 || stdClickInterval < 10) ? 1 : 0);
        BEHAV.info(Markers.appendEntries(m), "click_interval_behavior");
    }

    // ── 내부: 매크로 의심 판단 ──────────────────────────
    private static boolean isMacroSuspect(long totalFlowMs, int seatChangeCount, double rps) {
        if (totalFlowMs > 0 && totalFlowMs < 2000) return true;
        if (seatChangeCount == 0)                  return true;
        if (rps > 10)                              return true;
        return false;
    }
}
