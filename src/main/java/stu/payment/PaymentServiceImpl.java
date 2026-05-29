/** 
* ============================================================ * 
Project : 관제 티켓 (Ticketing System)

- Package : stu.payment
- FileName : PaymentServiceImpl.java *

* Developer : 이규왕 (feature/king)

* Created : 2026.05.22

- Modified : 2026.05.28 *
- Description :
 *   결제 처리 서비스 (B안 슬림).
 *
 *   메서드별 책임:
 *     requestPayment  - payments INSERT(PENDING), 거래 ID 발급
 *     confirmPayment  - PG 결과 반영 (SUCCESS/FAILED), booking 상태 콜백 트리거
 *     refundByBooking - [2026.05.28 추가] 예매 ID 기준 결제 SUCCESS → REFUNDED
 *
 *   호출 패턴:
 *     - 사용자 결제 흐름: /result.do → requestPayment → confirmPayment 순차 호출
 *     - 향후 비동기 PG : confirmPayment 만 별도 엔드포인트로 노출 가능
 *     - 관리자 강제 취소 : admin 모듈이 refundByBooking() 호출
 *
 *   환불은 마이페이지팀이 자체 처리. 본 모듈에 환불 책임 없음.
 *
 *   [2026.05.28] 관리자 예매 강제 취소를 위한 refundByBooking() 추가.
 *     - 기존 requestPayment / confirmPayment 흐름은 일절 변경하지 않음 (추가만)
 *     - mock 결제 구조이므로 실제 환불 행위 없이 payments.status 만 REFUNDED 로 표시
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

    // ====================================================
    // 1) 결제 요청 - payments INSERT (PENDING)
    // ====================================================
    @Override
    @Transactional(rollbackFor = Exception.class)
    public PaymentVO requestPayment(PaymentVO vo) throws Exception {

        String txId = "TX-" + UUID.randomUUID().toString().replace("-", "").substring(0, 16);
        vo.setTransactionId(txId);
        vo.setStatus("PENDING");

        paymentDao.insertPayment(vo);

        LOG.event("payment.requested",
                kv("transaction_id",   txId),
                kv("payment_id",       vo.getPaymentId()),
                kv("booking_id",       vo.getBookingId()),
                kv("member_id",        vo.getMemberId()),
                kv("requested_amount", vo.getRequestedAmount()));

        return vo;
    }

    // ====================================================
    // 2) 결제 확정 - PG 결과를 payments.status 에 반영
    //    pgResult: "SUCCESS" 또는 "FAILED"
    // ====================================================
    @Override
    @Transactional(rollbackFor = Exception.class)
    public PaymentVO confirmPayment(String transactionId, String pgResult) throws Exception {

        PaymentVO vo = paymentDao.selectByTxId(transactionId);
        if (vo == null) {
            LOG.warnEvent("payment.confirm.tx_not_found",
                    kv("transaction_id", transactionId),
                    kv("pg_result",      pgResult));
            throw new Exception("거래를 찾을 수 없습니다: " + transactionId);
        }

        boolean approved = "SUCCESS".equalsIgnoreCase(pgResult);

        if (approved) {
            vo.setStatus("SUCCESS");
            paymentDao.updateStatus(vo);

            LOG.event("payment.success",
                    kv("transaction_id",   transactionId),
                    kv("booking_id",       vo.getBookingId()),
                    kv("member_id",        vo.getMemberId()),
                    kv("requested_amount", vo.getRequestedAmount()));

            // booking 모듈 콜백 (PENDING → CONFIRMED, seats HELD → RESERVED)
            bookingStatusUpdater.confirm(vo.getBookingId(), transactionId);

        } else {
            vo.setStatus("FAILED");
            paymentDao.updateStatus(vo);

            LOG.event("payment.failed",
                    kv("transaction_id",   transactionId),
                    kv("booking_id",       vo.getBookingId()),
                    kv("member_id",        vo.getMemberId()),
                    kv("requested_amount", vo.getRequestedAmount()),
                    kv("reason",           "pg_denied"));

            // booking 모듈 콜백 (PENDING → CANCELLED, 좌석 복구)
            bookingStatusUpdater.cancel(vo.getBookingId(), transactionId, "pg_denied");
        }

        return vo;
    }

    // ====================================================
    // 조회
    // ====================================================
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

    // ====================================================
    // [2026.05.28] 예매 환불 - 관리자 강제 취소 시 호출
    //   - SUCCESS 결제만 REFUNDED 로 변경 (조건부)
    //   - 결제 내역이 없거나 이미 환불된 경우 0 반환 (예외 아님)
    //   - 호출자(관리자 취소 트랜잭션)의 @Transactional 안에서 동작
    // ====================================================
    @Override
    @Transactional(rollbackFor = Exception.class)
    public int refundByBooking(Long bookingId) throws Exception {

        if (bookingId == null) {
            LOG.warnEvent("payment.refund.skip", kv("reason", "bookingId is null"));
            return 0;
        }

        PaymentVO vo = paymentDao.selectByBookingId(bookingId);
        int refunded = paymentDao.refundByBookingId(bookingId);

        if (refunded > 0) {
            LOG.event("payment.refunded",
                    kv("booking_id",       bookingId),
                    kv("payment_id",       vo != null ? vo.getPaymentId() : null),
                    kv("member_id",        vo != null ? vo.getMemberId() : null),
                    kv("requested_amount", vo != null ? vo.getRequestedAmount() : null),
                    kv("reason",           "admin_force_cancel"));
        } else {
            LOG.warnEvent("payment.refund.noop",
                    kv("booking_id", bookingId),
                    kv("reason",     "no SUCCESS payment to refund"));
        }

        return refunded;
    }

    // ====================================================
    // 내부 헬퍼 - mock PG 승인 판정
    //   금액 null/0 이하 → FAILED
    //   그 외             → SUCCESS
    // ====================================================
    public static String mockPgApprove(Long requestedAmount) {
        if (requestedAmount == null || requestedAmount <= 0) {
            return "FAILED";
        }
        return "SUCCESS";
    }
}