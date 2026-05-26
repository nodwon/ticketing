/** 
* ============================================================ * 
Project : 관제 티켓 (Ticketing System)

- Package : stu.payment
- FileName : PaymentServiceImpl.java *

* Developer : 이규왕 (feature/king)

* Created : 2026.05.24

- Modified : 2026.05.26 *
- Description :
 *   결제 서비스 구현 (API 명세서 반영, B안 슬림 유지).
 *     - requestPayment: PENDING INSERT + log_payment 기록 (PG 호출 X — 분리)
 *     - confirmPayment: PG 콜백 시점에 SUCCESS/FAILED 전이 + booking 콜백
 *     - refundPayment: SUCCESS → REFUNDED + booking 콜백
 *
 *   변조 탐지:
 *     - bookings.total_price (서버 actualPrice) 와
 *       클라이언트 requested_amount 가 다르면 log_payment.payment_result = 'TAMPER'
 *     - 변조여도 결제는 진행 (B안 — 거부하지 않고 로그만)
* ============================================================ */

package stu.payment;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import javax.annotation.Resource;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import stu.common.logger.StructuredLogger;

import static stu.common.logger.StructuredLogger.kv;

@Service("paymentService")
public class PaymentServiceImpl implements PaymentService {

    private static final StructuredLogger LOG = StructuredLogger.of(PaymentServiceImpl.class);

    @Resource(name = "paymentDao")
    private PaymentDao paymentDao;

    @Resource(name = "bookingStatusUpdater")
    private BookingStatusUpdater bookingStatusUpdater;

    /** 결제 요청 — payments(PENDING) + log_payment 동시 기록 */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public PaymentVO requestPayment(PaymentVO vo) throws Exception {

        // 1) 거래 ID 발급
        String txId = "TX-" + UUID.randomUUID().toString().replace("-", "").substring(0, 16);
        vo.setTransactionId(txId);
        vo.setStatus("PENDING");

        // 2) 서버 기준 실제 금액 조회 (변조 탐지용)
        Long actualPrice = lookupActualPrice(vo.getBookingId());

        // 3) payments INSERT (PENDING)
        paymentDao.insertPayment(vo);

        // 4) log_payment INSERT — TAMPER 여부 판정
        String paymentResult = determineLogResult(vo.getRequestedAmount(), actualPrice);
        LogPaymentVO logVo = new LogPaymentVO();
        logVo.setUserId(vo.getMemberId());
        logVo.setTransactionId(txId);
        logVo.setPaymentAmount(vo.getRequestedAmount());
        logVo.setActualPrice(actualPrice);
        logVo.setPaymentResult(paymentResult);
        paymentDao.insertLogPayment(logVo);

        // 5) 구조화 이벤트 로그 (파일/콘솔)
        LOG.event("payment.requested",
                kv("transaction_id",   txId),
                kv("payment_id",       vo.getPaymentId()),
                kv("booking_id",       vo.getBookingId()),
                kv("member_id",        vo.getMemberId()),
                kv("requested_amount", vo.getRequestedAmount()),
                kv("actual_price",     actualPrice),
                kv("log_result",       paymentResult));

        return vo;
    }

    /** PG 콜백 — confirm */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public PaymentVO confirmPayment(String transactionId, String pgResult) throws Exception {

        // pgResult 는 PG사 응답 — 명세에는 "SUCCESS" / "FAILED" 가정
        String newStatus = "SUCCESS".equalsIgnoreCase(pgResult) ? "SUCCESS" : "FAILED";
        paymentDao.confirmPayment(transactionId, newStatus);

        PaymentVO updated = paymentDao.selectByTxId(transactionId);

        LOG.event("payment.confirmed",
                kv("transaction_id", transactionId),
                kv("new_status",     newStatus),
                kv("pg_result_raw",  pgResult));

        // booking 상태 콜백 (좌석팀과 합의 전이라 NoopBookingStatusUpdater 가 받음)
        if (updated != null && "SUCCESS".equals(newStatus)) {
            bookingStatusUpdater.confirm(updated.getBookingId(), transactionId);
        } else if (updated != null) {
            bookingStatusUpdater.cancel(updated.getBookingId(), transactionId, "pg_" + pgResult);
        }

        return updated;
    }

    /** 환불 — SUCCESS → REFUNDED */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public PaymentVO refundPayment(String transactionId, String reason) throws Exception {

        paymentDao.refundPayment(transactionId);
        PaymentVO updated = paymentDao.selectByTxId(transactionId);

        LOG.event("payment.refunded",
                kv("transaction_id", transactionId),
                kv("reason",         reason));

        if (updated != null) {
            bookingStatusUpdater.cancel(updated.getBookingId(), transactionId, "refund:" + reason);
        }
        return updated;
    }

    @Override
    public PaymentVO getPaymentResult(String transactionId) throws Exception {
        return paymentDao.selectByTxId(transactionId);
    }

    @Override
    public List<PaymentVO> getPaymentHistory(Long memberId) throws Exception {
        return paymentDao.selectHistoryByMember(memberId);
    }

    @Override
    public Map<String, Object> getBookingForPayment(Long bookingId) throws Exception {
        return paymentDao.selectBookingForPayment(bookingId);
    }

    // ---------- 내부 헬퍼 ----------

    /**
     * bookings.total_price 를 서버 actualPrice 로 사용.
     *  - booking 이 없으면 0 반환 (= 클라이언트 값과 다르면 TAMPER)
     *  - 명세서가 "actual_price" 를 요구하므로 반드시 별도 조회 필요
     */
    private Long lookupActualPrice(Long bookingId) {
        if (bookingId == null) return 0L;
        Map<String, Object> booking = paymentDao.selectBookingForPayment(bookingId);
        if (booking == null) return 0L;
        // selectBookingForPayment 는 alias 로 totalPrice 를 줬는데
        // Oracle 은 alias 그대로 대문자 반환 → "TOTALPRICE"
        Object total = booking.get("TOTALPRICE");
        if (total == null) total = booking.get("totalPrice");
        if (total == null) return 0L;
        if (total instanceof Number) return ((Number) total).longValue();
        try { return Long.parseLong(total.toString()); }
        catch (NumberFormatException e) { return 0L; }
    }

    /**
     * log_payment.payment_result 결정.
     *   - clientAmount == actualPrice → 일단 'SUCCESS' 로 기록
     *     (실제 PG 결과는 confirmPayment 단계에서 재기록 가능)
     *   - 둘이 다르면 'TAMPER'
     *   - null 이면 'FAIL'
     */
    private String determineLogResult(Long clientAmount, Long actualPrice) {
        if (clientAmount == null || actualPrice == null) return "FAIL";
        if (!clientAmount.equals(actualPrice)) return "TAMPER";
        return "SUCCESS";
    }
}
