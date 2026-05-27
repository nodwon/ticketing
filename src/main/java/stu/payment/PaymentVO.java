/**
* ============================================================ *
* Project    : 관제 티켓 (Ticketing System)
* Package    : stu.payment
* FileName   : PaymentVO.java
*
* Developer  : 이규왕 (feature/king)
* Created    : 2026.05.22
* Modified   : 2026.05.26
*
* Description :
 *   payments 테이블 매핑 VO (명세서 일치).
 *     - payment_id      : PK, GENERATED AS IDENTITY
 *     - booking_id      : FK → bookings
 *     - member_id       : FK → members (명세는 → users 라고 적혀있지만
 *                          본인 ERD는 members 사용 — 사용자 결정 유지)
 *     - transaction_id  : 거래 식별자 (UNIQUE) — Replay Attack 탐지
 *     - requested_amount: 결제 요청 금액
 *     - status          : PENDING / SUCCESS / FAILED / REFUNDED
* ============================================================ */

package stu.payment;

public class PaymentVO {

    private Long   paymentId;
    private Long   bookingId;
    private Long   memberId;          // members.member_id (FK)
    private String transactionId;
    private Long   requestedAmount;
    private String status;            // PENDING / SUCCESS / FAILED / REFUNDED

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
}
