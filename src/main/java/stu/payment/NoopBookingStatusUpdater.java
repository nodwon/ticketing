/** 
* ============================================================ * 
Project : 관제 티켓 (Ticketing System)

- Package : stu.payment
- FileName : NoopBookingStatusUpdater.java *

* Developer : 이규왕 (feature/king)

* Created : 2026.05.24

- Modified : 2026.05.26 *
- Description :
 *   결제 단독 동작 확인용 임시 구현체.
 *   booking 모듈 통합 (RealBookingStatusUpdater 사용) 후에는 빈 등록하지 않음.
 *
 *   다시 단독 테스트가 필요하면:
 *     1) RealBookingStatusUpdater 의 @Component 주석 처리
 *     2) 아래 @Component 주석 해제
* ============================================================ */

package stu.payment;

// import org.springframework.stereotype.Component;

import stu.common.logger.StructuredLogger;

import static stu.common.logger.StructuredLogger.kv;

// @Component("bookingStatusUpdater")   // ★ 통합 후 빈 등록 비활성화 — RealBookingStatusUpdater 가 대체
public class NoopBookingStatusUpdater implements BookingStatusUpdater {

    private static final StructuredLogger LOG =
            StructuredLogger.of(NoopBookingStatusUpdater.class);

    @Override
    public void confirm(Long bookingId, String transactionId) {
        LOG.event("booking.confirm.callback.noop",
                kv("booking_id",     bookingId),
                kv("transaction_id", transactionId),
                kv("note",           "noop — booking module not integrated"));
    }

    @Override
    public void cancel(Long bookingId, String transactionId, String reason) {
        LOG.event("booking.cancel.callback.noop",
                kv("booking_id",     bookingId),
                kv("transaction_id", transactionId),
                kv("reason",         reason),
                kv("note",           "noop — booking module not integrated"));
    }
}
