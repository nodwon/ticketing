package stu.booking;

import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Repository;

import stu.common.common.CommandMap;
import stu.common.dao.AbstractDao;

/**
 * 예매(Booking) 도메인 DAO
 * 
 * - Mapper XML: src/main/resources/mapper/booking/Booking_SQL.xml
 * - namespace: "booking"
 * 
 * [PENDING 흐름]
 *   createBooking 시점:
 *     - bookings.status = 'PENDING'
 *     - seats.status    = 'AVAILABLE' → 'HELD'
 *   
 *   confirmBooking 시점 (결제 모듈이 호출):
 *     - bookings.status = 'PENDING' → 'CONFIRMED'
 *     - seats.status    = 'HELD' → 'RESERVED'
 *   
 *   cancelBooking 시점:
 *     - bookings.status = ('PENDING' or 'CONFIRMED') → 'CANCELLED'
 *     - seats.status    = ('HELD' or 'RESERVED') → 'AVAILABLE'
 *   
 *   [2026.05.27] 예매 생성 실패 시 정희영측 HELD 좌석 강제 해제:
 *     - releaseHeldSeats(): HELD → AVAILABLE (seat_id 목록 + schedule_id 기준)
 *   
 *   [2026.05.27] available_seats 재계산 방식 전면 도입:
 *     - recalcAvailableSeats()           : booking_id 기준
 *     - recalcAvailableSeatsBySchedule() : schedule_id 직접 기준
 *     → seats 테이블의 실제 상태(AVAILABLE 카운트)로 강제 동기화
 *     → 기존 +N / -N 누적 방식의 부정합 버그 해결
 *     → 정희영/king 모듈이 available_seats를 어떻게 다루든 무관하게 항상 정확
 */
@Repository("bookingDao")
public class BookingDao extends AbstractDao {

    // ====================================================
    // 조회 (SELECT)
    // ====================================================

    @SuppressWarnings("unchecked")
    public Map<String, Object> selectScheduleInfo(CommandMap map) throws Exception {
        return (Map<String, Object>) selectOne("booking.selectScheduleInfo", map.getMap());
    }

    @SuppressWarnings("unchecked")
    public List<Map<String, Object>> selectSeats(CommandMap map) throws Exception {
        return (List<Map<String, Object>>) selectList("booking.selectSeats", map.getMap());
    }

    @SuppressWarnings("unchecked")
    public Map<String, Object> selectBookingDetail(CommandMap map) throws Exception {
        return (Map<String, Object>) selectOne("booking.selectBookingDetail", map.getMap());
    }

    @SuppressWarnings("unchecked")
    public List<Map<String, Object>> selectBookingItems(CommandMap map) throws Exception {
        return (List<Map<String, Object>>) selectList("booking.selectBookingItems", map.getMap());
    }

    @SuppressWarnings("unchecked")
    public List<Map<String, Object>> selectMyBookings(CommandMap map) throws Exception {
        return (List<Map<String, Object>>) selectList("booking.selectMyBookings", map.getMap());
    }


    // ====================================================
    // 예매 생성 (PENDING 흐름)
    // ====================================================

    /** [동시성 제어] 좌석 상태 조회 + 행 잠금 (FOR UPDATE) */
    @SuppressWarnings("unchecked")
    public List<Map<String, Object>> selectSeatsForUpdate(Map<String, Object> map) throws Exception {
        return (List<Map<String, Object>>) selectList("booking.selectSeatsForUpdate", map);
    }

    /** 예매 헤더 INSERT (status='PENDING'으로 생성)
     *  생성된 bookingId가 자동으로 map에 주입됨 (useGeneratedKeys) */
    public void insertBooking(Map<String, Object> map) throws Exception {
        insert("booking.insertBooking", map);
    }

    /** 예매 항목 INSERT (좌석당 1행) */
    public void insertBookingItem(Map<String, Object> map) throws Exception {
        insert("booking.insertBookingItem", map);
    }

    /** 좌석 상태 변경 (AVAILABLE → HELD) - 예매 생성 시
     *  return: 영향 받은 행 수. 요청 좌석 수와 다르면 동시성 충돌 → 롤백 필요 */
    public int updateSeatStatusToHeld(Map<String, Object> map) throws Exception {
        Object result = update("booking.updateSeatStatusToHeld", map);
        return (result == null) ? 0 : ((Number) result).intValue();
    }

    /** [DEPRECATED 2026.05.27] 잔여 좌석수 -N 차감 방식
     *  - 정희영 hold.do와의 정책 불일치로 부정합 발생
     *  - recalcAvailableSeatsBySchedule()로 대체됨
     *  - 메서드 자체는 호환성 위해 남겨둠 (당분간 호출 안 함) */
    public int decreaseAvailableSeats(Map<String, Object> map) throws Exception {
        Object result = update("booking.decreaseAvailableSeats", map);
        return (result == null) ? 0 : ((Number) result).intValue();
    }


    // ====================================================
    // 예매 확정 (PENDING → CONFIRMED) - 결제 모듈이 호출
    // ====================================================

    /** bookings 상태 변경 (PENDING → CONFIRMED)
     *  return: 영향 받은 행 수. 0이면 PENDING이 아니어서 확정 불가 */
    public int confirmBookingStatus(Map<String, Object> map) throws Exception {
        Object result = update("booking.confirmBookingStatus", map);
        return (result == null) ? 0 : ((Number) result).intValue();
    }

    /** 좌석 상태 변경 (HELD → RESERVED) - 결제 확정 시
     *  return: 변경된 좌석 수 */
    public int updateSeatStatusHeldToReserved(Map<String, Object> map) throws Exception {
        Object result = update("booking.updateSeatStatusHeldToReserved", map);
        return (result == null) ? 0 : ((Number) result).intValue();
    }


    // ====================================================
    // 예매 취소 (PENDING 또는 CONFIRMED 상태에서 호출 가능)
    // ====================================================

    /** 예매 취소 (status → CANCELLED) */
    public int cancelBooking(Map<String, Object> map) throws Exception {
        Object result = update("booking.cancelBooking", map);
        return (result == null) ? 0 : ((Number) result).intValue();
    }

    /** 좌석 상태 복구 (HELD/RESERVED → AVAILABLE) */
    public int restoreSeatStatus(Map<String, Object> map) throws Exception {
        Object result = update("booking.restoreSeatStatus", map);
        return (result == null) ? 0 : ((Number) result).intValue();
    }

    /** [DEPRECATED 2026.05.27] 잔여 좌석수 booking_id 기준 +N 방식
     *  - 정희영/king 모듈이 available_seats를 건드린 경우 누적 부정합 발생
     *  - cancelBooking 흐름에서는 recalcAvailableSeats()로 대체됨
     *  - 메서드 자체는 호환성 위해 남겨둠 (당분간 호출 안 함) */
    public int increaseAvailableSeats(Map<String, Object> map) throws Exception {
        Object result = update("booking.increaseAvailableSeats", map);
        return (result == null) ? 0 : ((Number) result).intValue();
    }


    // ====================================================
    // [2026.05.27] 예매 생성 실패 시 좌석 강제 해제 (HELD → AVAILABLE)
    //   - 정희영 /seat/hold.do 가 HELD 처리한 좌석을 본인 검증 단계에서
    //     실패했을 때 풀어주기 위한 안전망
    //   - seat_id 목록 + schedule_id 기준
    // ====================================================

    /** 좌석 강제 해제 (HELD → AVAILABLE)
     *  - seat_id 목록 + schedule_id 기준
     *  - HELD 상태인 좌석만 해제 (RESERVED는 건드리지 않음) */
    public int releaseHeldSeats(Map<String, Object> map) throws Exception {
        Object result = update("booking.releaseHeldSeats", map);
        return (result == null) ? 0 : ((Number) result).intValue();
    }

    /** [DEPRECATED 2026.05.27] 잔여 좌석수 +N 방식 (schedule_id + count)
     *  - releaseHeldSeats 후 호출되던 메서드
     *  - 본인이 차감 안 한 값을 증가시켜 누적 부정합 발생 → 호출 제거됨
     *  - 메서드 자체는 호환성 위해 남겨둠 (당분간 호출 안 함) */
    public int increaseAvailableSeatsByCount(Map<String, Object> map) throws Exception {
        Object result = update("booking.increaseAvailableSeatsByCount", map);
        return (result == null) ? 0 : ((Number) result).intValue();
    }


    // ====================================================
    // [2026.05.27] available_seats 재계산 (seats 실제 상태 기반) ⭐
    //
    //   기존 +N / -N 누적 방식의 부정합 버그를 근본 해결하는 메서드 2종.
    //   seats 테이블의 실제 AVAILABLE 카운트로 강제 동기화하므로
    //   정희영/king 모듈이 available_seats를 어떻게 다루든 항상 정확.
    //
    //   사용처:
    //     - recalcAvailableSeats()           : bookingId 있는 시점
    //       → confirmBooking, cancelBooking
    //     - recalcAvailableSeatsBySchedule() : bookingId 없는 시점
    //       → createBooking (booking 만든 직후 가능하지만 schedule이 더 직관적),
    //         releaseHeldSeats (booking이 안 만들어진 케이스)
    // ====================================================

    /** 잔여 좌석 재계산 - booking_id 기준
     *  - bookingId로 schedule_id 찾고, 그 schedule의 AVAILABLE 카운트로 강제 동기화 */
    public int recalcAvailableSeats(Map<String, Object> map) throws Exception {
        Object result = update("booking.recalcAvailableSeats", map);
        return (result == null) ? 0 : ((Number) result).intValue();
    }

    /** 잔여 좌석 재계산 - schedule_id 직접 지정 버전
     *  - createBooking, releaseHeldSeats 등 bookingId 없거나 아직 안 만들어진 시점 사용 */
    public int recalcAvailableSeatsBySchedule(Map<String, Object> map) throws Exception {
        Object result = update("booking.recalcAvailableSeatsBySchedule", map);
        return (result == null) ? 0 : ((Number) result).intValue();
    }
}