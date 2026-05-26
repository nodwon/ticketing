/** 
* ============================================================ * 
Project : 관제 티켓 (Ticketing System)

- Package : stu.payment
- FileName : PaymentDao.java *

* Developer : 이규왕 (feature/king)

* Created : 2026.05.22

- Modified : 2026.05.26 *
- Description :
 *   payments / log_payment 테이블 DAO.
 *     - AbstractDao(stu.common.dao.AbstractDao) 의 메서드만 사용
 *     - VO 반환은 Map 받아서 수동 매핑
 *     - 명세서 반영: confirm / refund / log_payment INSERT 추가
* ============================================================ */

package stu.payment;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Repository;

import stu.common.dao.AbstractDao;

@Repository("paymentDao")
public class PaymentDao extends AbstractDao {

    private static final String NS = "Payment.";

    // ---------- INSERT / UPDATE ----------

    public void insertPayment(PaymentVO vo) {
        insert(NS + "insertPayment", vo);
    }

    /** PG 콜백으로 결제 완료 처리 — status SUCCESS / FAILED 등으로 전이 */
    public void confirmPayment(String transactionId, String status) {
        Map<String, Object> params = new HashMap<>();
        params.put("transactionId", transactionId);
        params.put("status",        status);
        update(NS + "confirmPayment", params);
    }

    /** 환불 처리 — SUCCESS → REFUNDED */
    public void refundPayment(String transactionId) {
        update(NS + "refundPayment", transactionId);
    }

    /** 감사/관제 로그 INSERT */
    public void insertLogPayment(LogPaymentVO vo) {
        insert(NS + "insertLogPayment", vo);
    }

    // ---------- SELECT ----------

    @SuppressWarnings("unchecked")
    public PaymentVO selectByTxId(String transactionId) {
        Map<String, Object> row =
            (Map<String, Object>) selectOne(NS + "selectByTxId", transactionId);
        return toPaymentVO(row);
    }

    @SuppressWarnings("unchecked")
    public List<PaymentVO> selectHistoryByMember(Long memberId) {
        List<Map<String, Object>> rows = selectList(NS + "selectHistoryByMember", memberId);
        List<PaymentVO> result = new ArrayList<>();
        if (rows != null) {
            for (Map<String, Object> row : rows) {
                result.add(toPaymentVO(row));
            }
        }
        return result;
    }

    @SuppressWarnings("unchecked")
    public Map<String, Object> selectBookingForPayment(Long bookingId) {
        return (Map<String, Object>) selectOne(NS + "selectBookingForPayment", bookingId);
    }

    // ---------- 매핑 헬퍼 ----------

    private PaymentVO toPaymentVO(Map<String, Object> row) {
        if (row == null) return null;
        PaymentVO vo = new PaymentVO();
        vo.setPaymentId(      toLong  (row.get("PAYMENT_ID")));
        vo.setBookingId(      toLong  (row.get("BOOKING_ID")));
        vo.setMemberId(       toLong  (row.get("MEMBER_ID")));
        vo.setTransactionId(  toString(row.get("TRANSACTION_ID")));
        vo.setRequestedAmount(toLong  (row.get("REQUESTED_AMOUNT")));
        vo.setStatus(         toString(row.get("STATUS")));
        return vo;
    }

    private Long toLong(Object o) {
        if (o == null) return null;
        if (o instanceof Number) return ((Number) o).longValue();
        try { return Long.parseLong(o.toString().trim()); }
        catch (NumberFormatException e) { return null; }
    }

    private String toString(Object o) {
        return o == null ? null : o.toString();
    }
}
