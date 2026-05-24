/** 
* ============================================================ * 
Project : 관제 티켓 (Ticketing System)

- Package : stu.payment
- FileName : NoopBookingStatusUpdater.java *

* Developer : 이규왕 (feature/king)

* Created : 2026.05.24

- Modified : *
- Description :
 * 합의 전 임시 구현체.
 *  - 실제 booking/seat 테이블을 건드리지 않는다
 *  - 호출되었다는 사실만 로그로 남긴다 → 결제 흐름은 정상 동작하고,
 *    좌석팀/예매팀과 합의 후 이 클래스를 BookingStatusUpdaterImpl 로 교체하거나
 *    @Primary 빈으로 갈아끼우면 된다.
* ============================================================ */

package stu.payment;

import org.springframework.stereotype.Component;

import stu.common.logger.StructuredLogger;
import static stu.common.logger.StructuredLogger.kv;

@Component("bookingStatusUpdater")
public class NoopBookingStatusUpdater implements BookingStatusUpdater {

    private static final StructuredLogger LOG =
            StructuredLogger.of(NoopBookingStatusUpdater.class);

    @Override
    public void confirm(Long bookingId, String transactionId) {
        LOG.event("booking.confirm.callback.noop",
                kv("booking_id",     bookingId),
                kv("transaction_id", transactionId),
                kv("note",           "awaiting team integration"));
    }

    @Override
    public void cancel(Long bookingId, String transactionId, String reason) {
        LOG.event("booking.cancel.callback.noop",
                kv("booking_id",     bookingId),
                kv("transaction_id", transactionId),
                kv("reason",         reason),
                kv("note",           "awaiting team integration"));
    }
}
