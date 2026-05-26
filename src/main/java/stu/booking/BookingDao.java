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

    /** 잔여 좌석수 차감 */
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

    /** 잔여 좌석수 복구 */
    public int increaseAvailableSeats(Map<String, Object> map) throws Exception {
        Object result = update("booking.increaseAvailableSeats", map);
        return (result == null) ? 0 : ((Number) result).intValue();
    }
}