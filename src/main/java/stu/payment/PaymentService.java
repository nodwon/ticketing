/** 
* ============================================================ * 
Project : 관제 티켓 (Ticketing System)

- Package : stu.payment
- FileName : PaymentService.java *

* Developer : 이규왕 (feature/king)

* Created : 2026.05.22

- Modified : 2026.05.28 *
- Description : 
 *   결제 서비스 인터페이스 (명세서 반영).
 *     - 결제 요청 / 확정 (PG 콜백) 흐름
 *     - 환불은 마이페이지팀 영역으로 위임 (본 서비스 책임 아님)
 *
 *   [2026.05.28] 관리자 강제 취소용 환불 메서드 추가 (기존 흐름은 변경 없음)
 *     - refundByBooking(Long) : 예매 ID 기준 결제 SUCCESS → REFUNDED
 *     - 관리자(admin) 모듈이 예매 강제 취소 시 호출
 *     - mock 결제 구조이므로 실제 환불 행위 없이 status 표시만 변경
* ============================================================ */

package stu.payment;

import java.util.List;
import java.util.Map;

public interface PaymentService {

    /**
     * 결제 요청 (PENDING 상태로 INSERT).
     * payments + log_payment 동시 기록.
     * 변조 (clientAmount != actualPrice) 도 거부하지 않고 그대로 진행하되 result=TAMPER 로 로깅.
     */
    PaymentVO requestPayment(PaymentVO vo) throws Exception;

    /**
     * 결제 완료 처리 (PG 콜백 시뮬레이션).
     * @param transactionId 거래 식별자
     * @param pgResult      "SUCCESS" 또는 "FAILED"
     */
    PaymentVO confirmPayment(String transactionId, String pgResult) throws Exception;

    /** 결제 단건 조회 */
    PaymentVO getPaymentResult(String transactionId) throws Exception;

    /** 회원별 결제 내역 */
    List<PaymentVO> getPaymentHistory(Long memberId) throws Exception;

    /** 결제 폼 화면 표시용 — booking + schedule + concert JOIN */
    Map<String, Object> getBookingForPayment(Long bookingId) throws Exception;

    /**
     * [2026.05.28] 예매 ID 기준 결제 환불 처리 (SUCCESS → REFUNDED).
     * 관리자 강제 취소 시 호출되며, 좌석/예매 취소와 동일 트랜잭션에서 동작한다.
     *
     * @param bookingId 환불할 예매 ID
     * @return 환불 처리된 결제 건수 (0 = 결제 내역 없음 또는 이미 환불됨)
     */
    int refundByBooking(Long bookingId) throws Exception;
}