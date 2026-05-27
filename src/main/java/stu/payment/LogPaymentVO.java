/** 
* ============================================================ * 
Project : 관제 티켓 (Ticketing System)

- Package : stu.payment
- FileName : PaymentController.java *

* Developer : 이규왕 (feature/king)

* Created : 2026.05.26

- Modified : *
- Description : 더미파일임 삭제할 것
 *   log_payment 테이블 매핑 VO (API 명세서 반영).
 *     - paymentResult : SUCCESS / FAIL / TAMPER
 *     - 'TAMPER' = paymentAmount != actualPrice (변조 탐지)
 *     - 명세상 컬럼명 timestamp 는 Oracle 예약어이므로
 *       DDL/매퍼에서 log_timestamp 로 사용
* ============================================================ */

package stu.payment;

public class LogPaymentVO {

    private Long   logId;
    private Long   userId;          // members.member_id
    private String transactionId;
    private Long   paymentAmount;   // 클라이언트가 보낸 금액
    private Long   actualPrice;     // 서버에서 booking 으로 재조회한 실제 금액
    private String paymentResult;   // SUCCESS / FAIL / TAMPER
    // log_timestamp 은 DB default SYSTIMESTAMP 사용 — VO 필드 불필요

    public Long getLogId()                          { return logId; }
    public void setLogId(Long logId)                { this.logId = logId; }

    public Long getUserId()                         { return userId; }
    public void setUserId(Long userId)              { this.userId = userId; }

    public String getTransactionId()                { return transactionId; }
    public void setTransactionId(String txId)       { this.transactionId = txId; }

    public Long getPaymentAmount()                  { return paymentAmount; }
    public void setPaymentAmount(Long amount)       { this.paymentAmount = amount; }

    public Long getActualPrice()                    { return actualPrice; }
    public void setActualPrice(Long actualPrice)    { this.actualPrice = actualPrice; }

    public String getPaymentResult()                { return paymentResult; }
    public void setPaymentResult(String result)     { this.paymentResult = result; }
}
