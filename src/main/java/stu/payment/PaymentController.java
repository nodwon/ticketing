/**
 * ============================================================
 * Project   : 관제 티켓 (Ticketing System)
 * Package   : stu.payment
 * FileName  : PaymentController.java
 *
 * Developer : 이규왕 (feature/king)
 * Created   : 2026.05.22
 * Modified  : 2026.05.27 - SecurityLogger 통합 (TAMPER 자동 탐지)
 *
 * Description :
 *   B안 슬림 컨트롤러 (명세서 인터페이스 반영).
 *     - 검증 / 화이트리스트 / 세션 강제 X (취약점 유지)
 *     - 모든 진입 이벤트를 structured JSON 으로 기록
 *     - ★ 결제 변조 (TAMPER) / Replay Attack 자동 탐지 → log_payment.json
 *
 *   엔드포인트:
 *     GET  /payment/form.do    결제 폼 진입
 *     POST /payment/result.do  결제 처리 (request → mock PG → confirm 순차)
 * ============================================================ */

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

import stu.common.logger.SecurityLogger;             // ★★ 추가: 보안 로그
import stu.common.logger.StructuredLogger;

import static stu.common.logger.StructuredLogger.kv;

@Controller
@RequestMapping("/payment")
public class PaymentController {

    private static final StructuredLogger LOG = StructuredLogger.of(PaymentController.class);

    @Resource(name = "paymentService")
    private PaymentService paymentService;

    // ====================================================
    // /payment/form.do - 결제 폼 진입
    // ====================================================
    @RequestMapping(value = "/form.do", method = RequestMethod.GET)
    public String form(@RequestParam(value = "bookingId", required = false) String bookingIdRaw,
                       HttpServletRequest request,
                       HttpSession session,
                       Model model) throws Exception {

        Object sessionMember = session.getAttribute("SESSION_NO");
        Long bookingId = parseLongOrNull(bookingIdRaw);

        LOG.event("payment.form.view",
                kv("booking_id_raw",    bookingIdRaw),
                kv("booking_id",        bookingId),
                kv("session_member_id", sessionMember));

        Map<String, Object> booking = null;
        if (bookingId != null) {
            booking = paymentService.getBookingForPayment(bookingId);
            if (booking == null) {
                LOG.event("payment.form.booking_not_found",
                        kv("booking_id", bookingId));
            }
        }

        model.addAttribute("bookingId", bookingId);
        model.addAttribute("booking",   booking);
        return "payment/form";
    }

    // ====================================================
    // /payment/result.do - 결제 처리
    //   1) requestPayment (PENDING INSERT)
    //   2) mock PG 승인 판정
    //   3) confirmPayment (SUCCESS/FAILED UPDATE + booking 콜백)
    //   ★ 4) TAMPER 탐지 + log_payment.json 자동 기록
    // ====================================================
    @RequestMapping(value = "/result.do", method = RequestMethod.POST)
    public String result(@RequestParam(value = "bookingId", required = false) String bookingIdRaw,
                         @RequestParam(value = "amount",    required = false) String amountRaw,
                         @RequestParam(value = "memberId",  required = false) String memberIdRaw,
                         HttpServletRequest request,
                         HttpSession session,
                         Model model) throws Exception {

        Object sessionMember = session.getAttribute("SESSION_NO");

        LOG.event("payment.attempt",
                kv("booking_id_raw",       bookingIdRaw),
                kv("client_amount_raw",    amountRaw),
                kv("client_member_id_raw", memberIdRaw),
                kv("session_member_id",    sessionMember));

        // 검증 없이 그대로 VO 구성 (B안 — 변조 시나리오 수집용)
        PaymentVO vo = new PaymentVO();
        vo.setBookingId(parseLongOrNull(bookingIdRaw));
        vo.setMemberId(parseLongOrNull(memberIdRaw));
        vo.setRequestedAmount(parseLongOrNull(amountRaw));

        // ★★ 보안 로그용 변수 준비
        Long memberIdForLog = vo.getMemberId();
        if (memberIdForLog == null && sessionMember != null) {
            memberIdForLog = ((Number) sessionMember).longValue();
        }
        Long clientAmount = vo.getRequestedAmount();  // 클라이언트가 보낸 금액 (변조 가능)

        // ★★ 서버 기준 실제 금액 조회 (TAMPER 비교용)
        Long actualPrice = null;
        if (vo.getBookingId() != null) {
            try {
                Map<String, Object> booking = paymentService.getBookingForPayment(vo.getBookingId());
                if (booking != null) {
                    Object totalPriceObj = booking.get("TOTAL_PRICE");
                    if (totalPriceObj == null) totalPriceObj = booking.get("totalPrice");
                    if (totalPriceObj == null) totalPriceObj = booking.get("total_price");
                    if (totalPriceObj instanceof Number) {
                        actualPrice = ((Number) totalPriceObj).longValue();
                    }
                }
            } catch (Exception e) {
                LOG.event("payment.actual_price.fetch_failed",
                        kv("booking_id", vo.getBookingId()),
                        kv("error", e.getMessage()));
            }
        }

        // [1] 결제 요청 (PENDING)
        PaymentVO requested = paymentService.requestPayment(vo);

        // [2] mock PG 승인 판정
        String pgResult = PaymentServiceImpl.mockPgApprove(requested.getRequestedAmount());

        // [3] 결제 확정
        PaymentVO finalResult = paymentService.confirmPayment(requested.getTransactionId(), pgResult);

        // ====================================================
        // ★★★ 보안 로그: 결제 이벤트 기록 (TAMPER 자동 탐지)
        // ====================================================
        String paymentResult;
        if (actualPrice != null && clientAmount != null && !clientAmount.equals(actualPrice)) {
            // 클라이언트가 보낸 금액 ≠ 서버 실제 금액 → 변조!
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

        // ★★ log_payment.json 기록
        SecurityLogger.payment(
            memberIdForLog,
            finalResult.getTransactionId(),
            clientAmount,
            actualPrice != null ? actualPrice : clientAmount,
            paymentResult
        );

        // 결과 화면에 필요한 정보만 깔끔하게 전달 (DB 컬럼 기반)
        model.addAttribute("status",        finalResult.getStatus());          // SUCCESS / FAILED
        model.addAttribute("transactionId", finalResult.getTransactionId());
        model.addAttribute("bookingId",     finalResult.getBookingId());
        model.addAttribute("amount",        finalResult.getRequestedAmount());

        return "payment/result";
    }

    // ====================================================
    // 유틸리티
    // ====================================================
    private Long parseLongOrNull(String s) {
        if (s == null || s.trim().isEmpty()) return null;
        try {
            return Long.parseLong(s.trim());
        } catch (NumberFormatException e) {
            LOG.event("payment.param.parse_failed",
                    kv("raw_value",   s),
                    kv("target_type", "Long"));
            return null;
        }
    }
}
