/** 
* ============================================================ * 
Project : 관제 티켓 (Ticketing System)

- Package : stu.payment
- FileName : PaymentServiceImpl.java *

* Developer : 이규왕 (feature/king)

* Created : 2026.05.22

- Modified : 2026.05.24 *
- Description :
 * 결제 처리 서비스 (B안 슬림).
 *  - 입력 검증 / 차단 X (취약점 유지)
 *  - 받은 값을 그대로 DB INSERT
 *  - 발생 이벤트는 structured JSON 으로 토해낸다
 *  - 결제 후 booking 상태 갱신은 BookingStatusUpdater 콜백에 위임
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

    @Override
    @Transactional(rollbackFor = Exception.class)
    public PaymentVO processPayment(PaymentVO vo) throws Exception {

        // 1) 거래 ID 발급
        String txId = "TX-" + UUID.randomUUID().toString().replace("-", "").substring(0, 16);
        vo.setTransactionId(txId);
        vo.setStatus("PENDING");

        // 2) PENDING INSERT (감사 추적용 1단계 기록)
        paymentDao.insertPayment(vo);
        LOG.event("payment.requested",
                kv("transaction_id",   txId),
                kv("payment_id",       vo.getPaymentId()),
                kv("booking_id",       vo.getBookingId()),
                kv("member_id",        vo.getMemberId()),
                kv("requested_amount", vo.getRequestedAmount()),
                kv("pay_method",       vo.getPayMethod()));

        // 3) mock PG 승인
        boolean approved = mockPgApprove(vo);

        if (approved) {
            vo.setStatus("SUCCESS");
            paymentDao.updateStatus(vo);
            LOG.event("payment.success",
                    kv("transaction_id", txId),
                    kv("booking_id",     vo.getBookingId()),
                    kv("member_id",      vo.getMemberId()),
                    kv("requested_amount", vo.getRequestedAmount()));

            // booking 상태 갱신 콜백 (현재는 NoopBookingStatusUpdater 가 받음)
            bookingStatusUpdater.confirm(vo.getBookingId(), txId);

        } else {
            vo.setStatus("FAILED");
            paymentDao.updateStatus(vo);
            LOG.event("payment.failed",
                    kv("transaction_id", txId),
                    kv("booking_id",     vo.getBookingId()),
                    kv("member_id",      vo.getMemberId()),
                    kv("requested_amount", vo.getRequestedAmount()),
                    kv("reason",         "mock_pg_denied"));

            bookingStatusUpdater.cancel(vo.getBookingId(), txId, "mock_pg_denied");
        }

        return vo;
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

    /**
     * 가짜 PG 승인 (학습용).
     *  - 금액 null/0 이하 → 실패
     *  - 그 외 → 성공
     */
    private boolean mockPgApprove(PaymentVO vo) {
        if (vo.getRequestedAmount() == null || vo.getRequestedAmount() <= 0) {
            return false;
        }
        return true;
    }
}