/** 
* ============================================================ * 
Project : 관제 티켓 (Ticketing System)

- Package : stu.payment
- FileName : PaymentService.java *

* Developer : 이규왕 (feature/king)

* Created : 2026.05.22

- Modified : 2026.05.24 *
- Description : 결제 처리 서비스
* ============================================================ */

package stu.payment;

import java.util.List;
import java.util.Map;

public interface PaymentService {

    /** 결제 처리: payments INSERT(PENDING) → mock PG → UPDATE(SUCCESS/FAILED) */
    PaymentVO processPayment(PaymentVO vo) throws Exception;

    /** 거래 ID 기반 단건 조회 */
    PaymentVO getPaymentResult(String transactionId) throws Exception;

    /** 회원별 결제 내역 */
    List<PaymentVO> getPaymentHistory(Long memberId) throws Exception;

    /** 결제 폼 표시용: booking + schedule + concert 조인 결과 */
    Map<String, Object> getBookingForPayment(Long bookingId) throws Exception;
}