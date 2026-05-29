/**
 * ============================================================
 * Project   : 관제 티켓 (Ticketing System)
 * Package   : stu.payment
 * FileName  : PaymentController.java
 *
 * Developer : 이규왕 (feature/king)
 * Modified  : 2026.05.26 - MacroDetectionLogger 통합
 *
 * Description :
 *   GET  /payment/form.do    결제 폼 진입 ★bookingCreate→payment 시간 로그★
 *   POST /payment/result.do  결제 처리 + TAMPER 탐지 + 전체 플로우 완료 로그
 * ============================================================
 */
package stu.payment;

import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;

import stu.common.logger.SecurityLogger;
import stu.common.logger.StructuredLogger;
import stu.common.logger.MacroDetectionLogger;

import static stu.common.logger.StructuredLogger.kv;

@Controller
@RequestMapping("/payment")
public class PaymentController {

    private static final StructuredLogger LOG = StructuredLogger.of(PaymentController.class);

    @Resource(name = "paymentService")
    private PaymentService paymentService;

    // ================================================================
    // GET /payment/form.do - 결제 폼 진입
    // ★ BookingController 에서 세션에 저장한 _booking_create_ts 로
    //   bookingCreate 완료 → payment/form.do 도착까지 시간 측정
    // ================================================================
    @RequestMapping(value = "/form.do", method = RequestMethod.GET)
    public String form(@RequestParam(value = "bookingId", required = false) String bookingIdRaw,
                       HttpServletRequest request,
                       HttpSession session,
                       Model model) throws Exception {

        long startTime = System.currentTimeMillis();

        Object sessionMember = session.getAttribute("SESSION_NO");
        Long bookingId = parseLongOrNull(bookingIdRaw);

        LOG.event("payment.form.view",
                kv("booking_id",        bookingId),
                kv("session_member_id", sessionMember));

        // ★ 결제 리다이렉트 시간 로그
        Object bookingCreateTsObj = session.getAttribute("_booking_create_ts");
        if (bookingCreateTsObj != null && sessionMember != null) {
            long bookingCreateTs   = (Long) bookingCreateTsObj;
            int  paymentElapsedMs  = (int)(startTime - bookingCreateTs);
            Long memberIdLong      = ((Number) sessionMember).longValue();

            MacroDetectionLogger.paymentRedirectTime(
                memberIdLong,
                getClientIp(request),
                bookingId,
                bookingCreateTs,
                paymentElapsedMs
            );

            // 사용 후 제거
            session.removeAttribute("_booking_create_ts");
        }

        Map<String, Object> booking = null;
        if (bookingId != null) {
            booking = paymentService.getBookingForPayment(bookingId);
        }

        model.addAttribute("bookingId", bookingId);
        model.addAttribute("booking",   booking);
        return "payment/form";
    }

    // ================================================================
    // POST /payment/result.do - 결제 처리
    //   1) requestPayment  (PENDING INSERT)
    //   2) mock PG 승인
    //   3) confirmPayment  (SUCCESS/FAILED UPDATE)
    //   ★ TAMPER 탐지 + log_payment.json 기록
    //   ★ 전체 플로우 완료 로그 (booking.complete)
    // ================================================================
    @RequestMapping(value = "/result.do", method = RequestMethod.POST)
    public String result(@RequestParam(value = "bookingId", required = false) String bookingIdRaw,
                         @RequestParam(value = "amount",    required = false) String amountRaw,
                         @RequestParam(value = "memberId",  required = false) String memberIdRaw,
                         HttpServletRequest request,
                         HttpSession session,
                         Model model) throws Exception {

        Object sessionMember = session.getAttribute("SESSION_NO");

        LOG.event("payment.attempt",
                kv("booking_id_raw",    bookingIdRaw),
                kv("client_amount_raw", amountRaw),
                kv("session_member_id", sessionMember));

        PaymentVO vo = new PaymentVO();
        vo.setBookingId(parseLongOrNull(bookingIdRaw));
        vo.setMemberId(parseLongOrNull(memberIdRaw));
        vo.setRequestedAmount(parseLongOrNull(amountRaw));

        Long memberIdForLog = vo.getMemberId();
        if (memberIdForLog == null && sessionMember != null) {
            memberIdForLog = ((Number) sessionMember).longValue();
        }
        Long clientAmount = vo.getRequestedAmount();

        // 서버 기준 실제 금액 조회 (TAMPER 비교용)
        Long actualPrice = null;
        if (vo.getBookingId() != null) {
            try {
                Map<String, Object> booking = paymentService.getBookingForPayment(vo.getBookingId());
                if (booking != null) {
                    Object tp = booking.get("TOTAL_PRICE");
                    if (tp == null) tp = booking.get("totalPrice");
                    if (tp == null) tp = booking.get("total_price");
                    if (tp instanceof Number) actualPrice = ((Number) tp).longValue();
                }
            } catch (Exception e) {
                LOG.event("payment.actual_price.fetch_failed", kv("error", e.getMessage()));
            }
        }

        // [1] 결제 요청
        PaymentVO requested = paymentService.requestPayment(vo);

        // [2] mock PG 승인
        String pgResult = PaymentServiceImpl.mockPgApprove(requested.getRequestedAmount());

        // [3] 결제 확정
        PaymentVO finalResult = paymentService.confirmPayment(requested.getTransactionId(), pgResult);

        // ★ TAMPER 판단
        String paymentResult;
        if (actualPrice != null && clientAmount != null && !clientAmount.equals(actualPrice)) {
            paymentResult = "TAMPER";
            LOG.event("payment.TAMPER_DETECTED",
                    kv("client_amount", clientAmount),
                    kv("actual_price",  actualPrice),
                    kv("difference",    clientAmount - actualPrice));
        } else if ("SUCCESS".equals(finalResult.getStatus())) {
            paymentResult = "SUCCESS";
        } else {
            paymentResult = "FAIL";
        }

        // ★ log_payment.json 기록
        SecurityLogger.payment(
            memberIdForLog,
            finalResult.getTransactionId(),
            clientAmount,
            actualPrice != null ? actualPrice : clientAmount,
            paymentResult
        );

        // ★ 전체 플로우 완료 로그 (booking.complete)
        Object seatPageTsObj = session.getAttribute("_booking_seat_page_ts");
        long seatPageTs = (seatPageTsObj != null) ? (Long) seatPageTsObj : 0;

        if ("SUCCESS".equals(paymentResult) && memberIdForLog != null) {
            MacroDetectionLogger.fullFlowComplete(
                memberIdForLog,
                getClientIp(request),
                null,                        // concertId (필요 시 세션에 저장해서 전달)
                vo.getBookingId(),
                seatPageTs,
                0,                           // seatChangeCount (JS에서 수집 시 세션 저장 후 전달)
                0,                           // uniqueSeatCount
                0.0                          // requestsPerSecond
            );
            session.removeAttribute("_booking_seat_page_ts");
        }

        model.addAttribute("status",        finalResult.getStatus());
        model.addAttribute("transactionId", finalResult.getTransactionId());
        model.addAttribute("bookingId",     finalResult.getBookingId());
        model.addAttribute("amount",        finalResult.getRequestedAmount());

        return "payment/result";
    }

    // ── 헬퍼 ────────────────────────────────────────────
    private Long parseLongOrNull(String s) {
        if (s == null || s.trim().isEmpty()) return null;
        try { return Long.parseLong(s.trim()); }
        catch (NumberFormatException e) { return null; }
    }

    private String getClientIp(HttpServletRequest request) {
        String ip = request.getHeader("X-Forwarded-For");
        if (ip == null || ip.isEmpty()) ip = request.getRemoteAddr();
        return ip.split(",")[0].trim();
    }
}
