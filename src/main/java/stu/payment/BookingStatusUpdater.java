/** 
* ============================================================ * 
Project : 관제 티켓 (Ticketing System)

- Package : stu.payment
- FileName : BookingStatusUpdater.java *

* Developer : 이규왕 (feature/king)

* Created : 2026.05.24

- Modified : *
- Description :
 * 결제 모듈이 booking/seat 상태를 직접 건드리지 않도록 분리한 인터페이스.
 *
 * 좌석팀/예매팀과 다음주 합의 후 실 구현체를 만든다.
 * 그때까지는 NoopBookingStatusUpdater (기본 빈) 가 무동작으로 자리를 채운다.
 *
 * bookings.status 도메인 값 (합의됨):
 *   PENDING   - 좌석 HOLD + 결제 대기 (좌석팀이 INSERT 시 설정)
 *   CONFIRMED - 결제 완료
 *   CANCELLED - 결제 실패 또는 사용자 취소
* ============================================================ */

package stu.payment;

public interface BookingStatusUpdater {

    /** 결제 SUCCESS 시 호출 — booking → CONFIRMED, seats → SOLD */
    void confirm(Long bookingId, String transactionId);

    /** 결제 FAILED 시 호출 — booking → CANCELLED, seats → AVAILABLE */
    void cancel(Long bookingId, String transactionId, String reason);
}