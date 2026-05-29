/** 
* ============================================================ * 
Project : 관제 티켓 (Ticketing System)

- Package : stu.payment
- FileName : PaymentDao.java *

* Developer : 이규왕 (feature/king)

* Created : 2026.05.22

- Modified : 2026.05.28 *
- Description :
 *     - 프로젝트 표준 AbstractDao(stu.common.dao.AbstractDao) 를 상속
 *     - AbstractDao 의 sqlSession 이 private 이라 자식이 직접 접근 불가
 *       → AbstractDao 의 selectList/selectOne 만 사용
 *     - 반환 타입이 List<Map> / Object 이므로 PaymentVO 로 수동 매핑
 *     - Oracle 은 컬럼명을 대문자로 반환하므로 대문자 키로 조회
 *
 *   [2026.05.28] 관리자 강제 취소용 메서드 2개 추가 (기존 메서드는 변경 없음)
 *     - selectByBookingId(Long)  : 예매 ID 기준 결제 단건 조회 (환불 로그용)
 *     - refundByBookingId(Long)  : 예매 ID 기준 결제 SUCCESS → REFUNDED UPDATE
* ============================================================ */

package stu.payment;
 
import java.util.ArrayList;
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
 
    public void updateStatus(PaymentVO vo) {
        update(NS + "updateStatus", vo);
    }

    /** [2026.05.28] 예매 환불 처리 (booking_id 기준, SUCCESS → REFUNDED).
     *  @return 영향받은 행 수 (0 이면 환불 대상 결제 없음) */
    public int refundByBookingId(Long bookingId) {
        Object result = update(NS + "refundByBookingId", bookingId);
        return (result == null) ? 0 : ((Number) result).intValue();
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

    /** [2026.05.28] 예매 ID 기준 결제 단건 조회 (관리자 강제 취소용). */
    @SuppressWarnings("unchecked")
    public PaymentVO selectByBookingId(Long bookingId) {
        Map<String, Object> row =
            (Map<String, Object>) selectOne(NS + "selectByBookingId", bookingId);
        return toPaymentVO(row);
    }
 
    // ---------- 매핑 헬퍼 ----------
 
    /**
     * Oracle 의 대문자 컬럼명 기반 Map → PaymentVO 변환.
     * 결과가 null 이면 null 반환.
     */
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
        try {
            return Long.parseLong(o.toString().trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }
 
    private String toString(Object o) {
        return o == null ? null : o.toString();
    }
}