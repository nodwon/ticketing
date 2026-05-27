/** 
* ============================================================ * 
Project : 관제 티켓 (Ticketing System)

- Package : stu.payment
- FileName : PaymentController.java *

* Developer : 이규왕 (feature/king)

* Created : 2026.05.22

- Modified : 2026.05.26 *
- Description :
 *   B안 슬림 컨트롤러 (명세서 인터페이스 반영).
 *     - 검증 / 화이트리스트 / 세션 강제 X (취약점 유지)
 *     - 모든 진입 이벤트를 structured JSON 으로 기록
 *
 *   엔드포인트:
 *     GET  /payment/form.do    결제 폼 진입
 *     POST /payment/result.do  결제 처리 (request → mock PG → confirm 순차)
 *
 *   환불은 마이페이지팀이 자체 처리. 본 컨트롤러에 환불 엔드포인트 없음.
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

        // [1] 결제 요청 (PENDING)
        PaymentVO requested = paymentService.requestPayment(vo);

        // [2] mock PG 승인 판정
        String pgResult = PaymentServiceImpl.mockPgApprove(requested.getRequestedAmount());

        // [3] 결제 확정
        PaymentVO finalResult = paymentService.confirmPayment(requested.getTransactionId(), pgResult);

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
