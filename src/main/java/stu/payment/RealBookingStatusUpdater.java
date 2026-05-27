/** 
* ============================================================ * 
Project : 관제 티켓 (Ticketing System)

- Package : stu.payment
- FileName : RealBookingStatusUpdater.java *

* Developer : 이규왕 (feature/king)

* Created : 2026.05.26

- Modified : *
- Description :
 *   결제 모듈이 결제 성공/실패/환불 시점에 호출하는 booking 상태 콜백.
 *   팀원의 BookingService 빈에 위임하여 다음 두 동작을 트리거:
 *     - 결제 성공 → BookingService.confirmBooking() → bookings.status=CONFIRMED, seats.status=RESERVED
 *     - 결제 실패/환불 → BookingService.cancelBooking() → bookings.status=CANCELLED, seats.status=AVAILABLE
 *
 *   설계 의도:
 *     - 결제 모듈은 BookingStatusUpdater 인터페이스만 의존
 *     - BookingService 구현은 팀원 모듈에 캡슐화
 *     - 팀원 모듈이 바뀌어도 결제 모듈은 영향 X (느슨한 결합)
 *
 *   주의:
 *     - 빈 이름은 "bookingStatusUpdater" 그대로 유지
 *       (PaymentServiceImpl 이 이 이름으로 주입받음)
 *     - NoopBookingStatusUpdater 의 @Component 는 반드시 주석 처리할 것
 *       (빈 이름 충돌 방지)
 *
 *   트랜잭션:
 *     - 결제 모듈의 @Transactional 안에서 호출됨
 *     - BookingService.confirmBooking / cancelBooking 도 @Transactional 이라
 *       전파(Propagation.REQUIRED) 로 같은 트랜잭션 참여
 *     - BookingService 에서 예외 발생 시 결제도 함께 롤백
* ============================================================ */

package stu.payment;
 
import javax.annotation.Resource;
 
import org.springframework.stereotype.Component;
 
import stu.booking.BookingService;
import stu.common.common.CommandMap;
import stu.common.logger.StructuredLogger;
 
import static stu.common.logger.StructuredLogger.kv;
 
@Component("bookingStatusUpdater")
public class RealBookingStatusUpdater implements BookingStatusUpdater {
 
    private static final StructuredLogger LOG =
            StructuredLogger.of(RealBookingStatusUpdater.class);
 
    @Resource(name = "bookingService")
    private BookingService bookingService;
 
    @Override
    public void confirm(Long bookingId, String transactionId) {
        if (bookingId == null) {
            LOG.warnEvent("booking.confirm.skip",
                    kv("reason",         "bookingId is null"),
                    kv("transaction_id", transactionId));
            return;
        }
 
        CommandMap cm = new CommandMap();
        cm.put("bookingId", String.valueOf(bookingId));
 
        try {
            bookingService.confirmBooking(cm);
 
            LOG.event("booking.confirm.delegated",
                    kv("booking_id",     bookingId),
                    kv("transaction_id", transactionId),
                    kv("target",         "BookingService.confirmBooking"));
 
        } catch (Exception e) {
            LOG.errorEvent("booking.confirm.failed", e,
                    kv("booking_id",     bookingId),
                    kv("transaction_id", transactionId));
            throw new RuntimeException("booking confirm failed for booking_id=" + bookingId, e);
        }
    }
 
    @Override
    public void cancel(Long bookingId, String transactionId, String reason) {
        if (bookingId == null) {
            LOG.warnEvent("booking.cancel.skip",
                    kv("reason",         "bookingId is null"),
                    kv("transaction_id", transactionId));
            return;
        }
 
        CommandMap cm = new CommandMap();
        cm.put("bookingId",    String.valueOf(bookingId));
        cm.put("cancelReason", "payment:" + reason);
 
        try {
            bookingService.cancelBooking(cm);
 
            LOG.event("booking.cancel.delegated",
                    kv("booking_id",     bookingId),
                    kv("transaction_id", transactionId),
                    kv("reason",         reason),
                    kv("target",         "BookingService.cancelBooking"));
 
        } catch (Exception e) {
            LOG.errorEvent("booking.cancel.failed", e,
                    kv("booking_id",     bookingId),
                    kv("transaction_id", transactionId),
                    kv("reason",         reason));
            throw new RuntimeException("booking cancel failed for booking_id=" + bookingId, e);
        }
    }
}
