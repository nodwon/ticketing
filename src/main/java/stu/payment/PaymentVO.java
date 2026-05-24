/** 
* ============================================================ * 
Project : 관제 티켓 (Ticketing System)

- Package : stu.payment
- FileName : PaymentVO.java *

* Developer : 이규왕 (feature/king)

* Created : 2026.05.24

- Modified : *
- Description :
 * payments 테이블 매핑 VO. (ERD 반영)
 *  - payment_id       : PK, GENERATED AS IDENTITY
 *  - booking_id       : FK -> bookings.booking_id
 *  - member_id        : FK -> members.member_id
 *  - transaction_id   : 거래 식별자 (UUID, UNIQUE)
 *  - requested_amount : 결제 요청 금액 (클라이언트 값을 그대로 박는다 — B안)
 *  - status           : PENDING / SUCCESS / FAILED
 *
 * 보안관제(B안) 컨텍스트:
 *  - bookings.total_price 와 payments.requested_amount 의 불일치가
 *    파라미터 변조 탐지의 핵심 지표 → 둘 다 raw 로 남긴다.
* ============================================================ */

package stu.payment;

public class PaymentVO {

    private Long   paymentId;
    private Long   bookingId;
    private Long   memberId;          // members.member_id (FK)
    private String transactionId;
    private Long   requestedAmount;
    private String status;            // PENDING / SUCCESS / FAILED

    /** DB 컬럼은 아니지만 결제수단을 로그/처리에 사용하기 위해 보관 */
    private String payMethod;

    public Long getPaymentId()                  { return paymentId; }
    public void setPaymentId(Long paymentId)    { this.paymentId = paymentId; }

    public Long getBookingId()                  { return bookingId; }
    public void setBookingId(Long bookingId)    { this.bookingId = bookingId; }

    public Long getMemberId()                   { return memberId; }
    public void setMemberId(Long memberId)      { this.memberId = memberId; }

    public String getTransactionId()            { return transactionId; }
    public void setTransactionId(String txId)   { this.transactionId = txId; }

    public Long getRequestedAmount()            { return requestedAmount; }
    public void setRequestedAmount(Long amount) { this.requestedAmount = amount; }

    public String getStatus()                   { return status; }
    public void setStatus(String status)        { this.status = status; }

    public String getPayMethod()                { return payMethod; }
    public void setPayMethod(String payMethod)  { this.payMethod = payMethod; }
}
