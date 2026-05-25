/** 
* ============================================================ * 
Project : 관제 티켓 (Ticketing System)

- Package : stu.payment
- FileName : PaymentController.java *

* Developer : 이규왕 (feature/king)

* Created : 2026.05.22

- Modified : 2026.05.24 *
- Description :
 * B안 슬림 컨트롤러 (ERD 반영).
 *  - 검증 / 화이트리스트 / 세션 강제 X (취약점 유지)
 *  - 받은 값을 그대로 Service 에 전달
 *  - 모든 진입 이벤트를 structured JSON 으로 기록
 *
 * 좌석팀과의 인터페이스:
 *  좌석 선택 확정 시 좌석팀이 bookings INSERT 후
 *  /payment/form.do?bookingId=xxx 로 redirect 한다.
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

    /** /payment/form.do — 결제 폼 진입 */
    @RequestMapping(value = "/form.do", method = RequestMethod.GET)
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

        // booking 조회 (화면 표시용)
        Map<String, Object> booking = null;
        if (bookingId != null) {
            booking = paymentService.getBookingForPayment(bookingId);
            if (booking == null) {
                LOG.event("payment.form.booking_not_found",
                        kv("booking_id", bookingId));
            }
        }

        model.addAttribute("bookingId", bookingId);
        model.addAttribute("booking",   booking);   // null 일 수도 있음 (취약점 유지)
        return "payment/form";
    }

    /** /payment/result.do — 결제 처리 */
    @RequestMapping(value = "/result.do", method = RequestMethod.POST)
    public String result(@RequestParam(value = "bookingId", required = false) String bookingIdRaw,
                         @RequestParam(value = "amount",    required = false) String amountRaw,
                         @RequestParam(value = "memberId",  required = false) String memberIdRaw,
                         @RequestParam(value = "payMethod", required = false) String payMethod,
                         HttpServletRequest request,
                         HttpSession session,
                         Model model) throws Exception {

        Object sessionMember = session.getAttribute("memberId");

        LOG.event("payment.attempt",
                kv("booking_id_raw",    bookingIdRaw),
                kv("client_amount_raw", amountRaw),
                kv("client_member_id_raw", memberIdRaw),
                kv("pay_method",        payMethod),
                kv("session_member_id", sessionMember));

        // 검증 없이 그대로 VO 구성
        PaymentVO vo = new PaymentVO();
        vo.setBookingId(parseLongOrNull(bookingIdRaw));
        vo.setMemberId(parseLongOrNull(memberIdRaw));
        vo.setRequestedAmount(parseLongOrNull(amountRaw));
        vo.setPayMethod(payMethod);

        PaymentVO result = paymentService.processPayment(vo);

        // 취약점 유지: 받은 값을 그대로 msg 로 만들어 ${msg} 출력
        String msg = "bookingId=" + bookingIdRaw
                   + ", amount="  + amountRaw
                   + ", memberId="+ memberIdRaw
                   + ", payMethod=" + payMethod
                   + ", txId="    + result.getTransactionId()
                   + ", status="  + result.getStatus();
        model.addAttribute("msg", msg);
        model.addAttribute("status", result.getStatus());

        return "payment/result";
    }

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