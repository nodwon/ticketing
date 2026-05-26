/** 
* ============================================================ * 
Project : 관제 티켓 (Ticketing System)

- Package : stu.payment
- FileName : LogPaymentVO.java *

* Developer : 이규왕 (feature/king)

* Created : 2026.05.22

- Modified : 2026.05.26 *
- Description :
 *   결제 컨트롤러 (API 명세서 반영, B안 슬림 유지).
 *
 *   1) REST API (명세서 준수):
 *      - POST   /api/payments                → requestPayment
 *      - POST   /api/payments/{id}/confirm   → confirmPayment (PG 콜백)
 *      - POST   /api/payments/{id}/refund    → refundPayment
 *      - GET    /api/payments/{id}           → getPaymentResult
 *
 *   2) JSP 화면 (기존 호환):
 *      - GET    /payment/form.do             → 결제 폼
 *      - POST   /payment/result.do           → 결제 처리 (REST 의 request+confirm 동시)
 *
 *   B안 원칙:
 *      - 검증 / 차단 X. 받은 값 그대로 처리.
 *      - 변조는 log_payment.payment_result='TAMPER' 로만 분류
* ============================================================ */

package stu.payment;

import java.util.HashMap;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import stu.common.logger.StructuredLogger;

import static stu.common.logger.StructuredLogger.kv;

@Controller
public class PaymentController {

    private static final StructuredLogger LOG = StructuredLogger.of(PaymentController.class);

    @Resource(name = "paymentService")
    private PaymentService paymentService;

    // ================================================================
    //  REST API (명세서 준수)
    // ================================================================

    /**
     * POST /api/payments
     *   파라미터: booking_id, amount, payment_method  (명세)
     *   반환: 201 Created / transaction_id
     */
    @RequestMapping(value = "/api/payments", method = RequestMethod.POST)
    @ResponseBody
    public ResponseEntity<Map<String, Object>> apiRequestPayment(
            @RequestBody(required = false) Map<String, Object> body,
            HttpServletRequest request,
            HttpSession session) throws Exception {

        // form-data 도 지원하기 위해 fallback
        Map<String, Object> params = body != null ? body : extractFormParams(request);

        Object sessionMember = session.getAttribute("memberId");

        LOG.event("api.payment.request",
                kv("body",           params),
                kv("session_member", sessionMember));

        // 명세 파라미터 — booking_id, amount, payment_method
        Long bookingId  = parseLongOrNull(params.get("booking_id"));
        Long memberId   = parseLongOrNull(params.get("member_id"));    // 보충: 명세엔 없으나 B안 변조 시나리오 수집용
        Long amount     = parseLongOrNull(params.get("amount"));
        String method   = params.get("payment_method") == null
                          ? null : params.get("payment_method").toString();

        // memberId 가 명시되지 않으면 세션에서 (운영 모드처럼)
        if (memberId == null && sessionMember != null) {
            memberId = parseLongOrNull(sessionMember);
        }

        PaymentVO vo = new PaymentVO();
        vo.setBookingId(bookingId);
        vo.setMemberId(memberId);
        vo.setRequestedAmount(amount);
        vo.setPayMethod(method);

        PaymentVO result = paymentService.requestPayment(vo);

        Map<String, Object> resp = new HashMap<>();
        resp.put("transaction_id", result.getTransactionId());
        resp.put("payment_id",     result.getPaymentId());
        resp.put("status",         result.getStatus());

        return new ResponseEntity<>(resp, HttpStatus.CREATED);
    }

    /**
     * POST /api/payments/{id}/confirm   (PG 콜백)
     *   path: {id} = transaction_id
     *   body: { "pg_result": "SUCCESS" | "FAILED" }
     *   반환: 200 OK / receipt
     */
    @RequestMapping(value = "/api/payments/{id}/confirm", method = RequestMethod.POST)
    @ResponseBody
    public ResponseEntity<Map<String, Object>> apiConfirmPayment(
            @PathVariable("id") String transactionId,
            @RequestBody(required = false) Map<String, Object> body,
            HttpServletRequest request) throws Exception {

        String pgResult = body == null || body.get("pg_result") == null
                          ? "SUCCESS"
                          : body.get("pg_result").toString();

        LOG.event("api.payment.confirm",
                kv("transaction_id", transactionId),
                kv("pg_result",      pgResult));

        PaymentVO updated = paymentService.confirmPayment(transactionId, pgResult);

        Map<String, Object> resp = new HashMap<>();
        if (updated == null) {
            resp.put("error", "transaction not found");
            return new ResponseEntity<>(resp, HttpStatus.NOT_FOUND);
        }
        resp.put("transaction_id", updated.getTransactionId());
        resp.put("status",         updated.getStatus());
        resp.put("requested_amount", updated.getRequestedAmount());

        return new ResponseEntity<>(resp, HttpStatus.OK);
    }

    /**
     * POST /api/payments/{id}/refund
     *   body: { "refund_reason": "..." }
     */
    @RequestMapping(value = "/api/payments/{id}/refund", method = RequestMethod.POST)
    @ResponseBody
    public ResponseEntity<Map<String, Object>> apiRefundPayment(
            @PathVariable("id") String transactionId,
            @RequestBody(required = false) Map<String, Object> body) throws Exception {

        String reason = body == null || body.get("refund_reason") == null
                        ? "unknown"
                        : body.get("refund_reason").toString();

        LOG.event("api.payment.refund",
                kv("transaction_id", transactionId),
                kv("reason",         reason));

        PaymentVO updated = paymentService.refundPayment(transactionId, reason);

        Map<String, Object> resp = new HashMap<>();
        if (updated == null) {
            resp.put("error", "transaction not found");
            return new ResponseEntity<>(resp, HttpStatus.NOT_FOUND);
        }
        resp.put("transaction_id", updated.getTransactionId());
        resp.put("status",         updated.getStatus());
        return new ResponseEntity<>(resp, HttpStatus.OK);
    }

    /**
     * GET /api/payments/{id}
     */
    @RequestMapping(value = "/api/payments/{id}", method = RequestMethod.GET)
    @ResponseBody
    public ResponseEntity<Map<String, Object>> apiGetPayment(
            @PathVariable("id") String transactionId) throws Exception {

        PaymentVO vo = paymentService.getPaymentResult(transactionId);

        Map<String, Object> resp = new HashMap<>();
        if (vo == null) {
            resp.put("error", "transaction not found");
            return new ResponseEntity<>(resp, HttpStatus.NOT_FOUND);
        }
        resp.put("payment_id",       vo.getPaymentId());
        resp.put("booking_id",       vo.getBookingId());
        resp.put("member_id",        vo.getMemberId());
        resp.put("transaction_id",   vo.getTransactionId());
        resp.put("requested_amount", vo.getRequestedAmount());
        resp.put("status",           vo.getStatus());
        return new ResponseEntity<>(resp, HttpStatus.OK);
    }

    // ================================================================
    //  JSP 화면 (기존 호환 + 단독 테스트용)
    // ================================================================

    /** GET /payment/form.do — 결제 폼 진입 */
    @RequestMapping(value = "/payment/form.do", method = RequestMethod.GET)
    public String form(@RequestParam(value = "bookingId", required = false) String bookingIdRaw,
                       HttpServletRequest request,
                       HttpSession session,
                       Model model) throws Exception {

        Object sessionMember = session.getAttribute("memberId");
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

    /**
     * POST /payment/result.do — 결제 처리
     *  JSP 화면 흐름은 요청+확정을 한번에 처리 (REST의 request + confirm 결합)
     */
    @RequestMapping(value = "/payment/result.do", method = RequestMethod.POST)
    public String result(@RequestParam(value = "bookingId", required = false) String bookingIdRaw,
                         @RequestParam(value = "amount",    required = false) String amountRaw,
                         @RequestParam(value = "memberId",  required = false) String memberIdRaw,
                         @RequestParam(value = "payMethod", required = false) String payMethod,
                         HttpServletRequest request,
                         HttpSession session,
                         Model model) throws Exception {

        Object sessionMember = session.getAttribute("memberId");

        LOG.event("payment.attempt",
                kv("booking_id_raw",       bookingIdRaw),
                kv("client_amount_raw",    amountRaw),
                kv("client_member_id_raw", memberIdRaw),
                kv("pay_method",           payMethod),
                kv("session_member_id",    sessionMember));

        // 1) request — payments(PENDING) + log_payment
        PaymentVO vo = new PaymentVO();
        vo.setBookingId(parseLongOrNull(bookingIdRaw));
        vo.setMemberId(parseLongOrNull(memberIdRaw));
        vo.setRequestedAmount(parseLongOrNull(amountRaw));
        vo.setPayMethod(payMethod);

        PaymentVO requested = paymentService.requestPayment(vo);

        // 2) confirm — PG 호출은 mock 으로 즉시 SUCCESS (학습용)
        PaymentVO confirmed = paymentService.confirmPayment(
                requested.getTransactionId(), mockPgResult(vo));

        // 3) JSP 표시용 (B안: ${msg} 그대로 출력)
        String msg = "bookingId="  + bookingIdRaw
                   + ", amount="   + amountRaw
                   + ", memberId=" + memberIdRaw
                   + ", payMethod="+ payMethod
                   + ", txId="     + confirmed.getTransactionId()
                   + ", status="   + confirmed.getStatus();
        model.addAttribute("msg",    msg);
        model.addAttribute("status", confirmed.getStatus());

        return "payment/result";
    }

    // ---------- 내부 헬퍼 ----------

    private String mockPgResult(PaymentVO vo) {
        if (vo.getRequestedAmount() == null || vo.getRequestedAmount() <= 0) {
            return "FAILED";
        }
        return "SUCCESS";
    }

    private Map<String, Object> extractFormParams(HttpServletRequest req) {
        Map<String, Object> out = new HashMap<>();
        @SuppressWarnings("unchecked")
        java.util.Enumeration<String> names = req.getParameterNames();
        while (names.hasMoreElements()) {
            String n = names.nextElement();
            out.put(n, req.getParameter(n));
        }
        return out;
    }

    private Long parseLongOrNull(Object obj) {
        if (obj == null) return null;
        String s = obj.toString().trim();
        if (s.isEmpty()) return null;
        try { return Long.parseLong(s); }
        catch (NumberFormatException e) {
            LOG.event("payment.param.parse_failed",
                    kv("raw_value", s),
                    kv("target_type", "Long"));
            return null;
        }
    }
}
