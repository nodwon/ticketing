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
 * [메서드 분류]
 *   SELECT (조회) 5개 - 화면 표시용
 *   동시성 제어   1개 - selectSeatsForUpdate
 *   INSERT       2개 - 예매 생성용
 *   UPDATE       4개 - 좌석/잔여석 변경, 취소용
 */
@Repository("bookingDao")
public class BookingDao extends AbstractDao {

    // ====================================================
    // 조회 (SELECT) - 기존
    // ====================================================

    /** 공연 일정 정보 조회 */
    @SuppressWarnings("unchecked")
    public Map<String, Object> selectScheduleInfo(CommandMap map) throws Exception {
        return (Map<String, Object>) selectOne("booking.selectScheduleInfo", map.getMap());
    }

    /** 좌석 목록 조회 */
    @SuppressWarnings("unchecked")
    public List<Map<String, Object>> selectSeats(CommandMap map) throws Exception {
        return (List<Map<String, Object>>) selectList("booking.selectSeats", map.getMap());
    }

    /** 예매 상세 조회 */
    @SuppressWarnings("unchecked")
    public Map<String, Object> selectBookingDetail(CommandMap map) throws Exception {
        return (Map<String, Object>) selectOne("booking.selectBookingDetail", map.getMap());
    }

    /** 예매에 포함된 좌석 목록 */
    @SuppressWarnings("unchecked")
    public List<Map<String, Object>> selectBookingItems(CommandMap map) throws Exception {
        return (List<Map<String, Object>>) selectList("booking.selectBookingItems", map.getMap());
    }

    /** 내 예매 목록 조회 */
    @SuppressWarnings("unchecked")
    public List<Map<String, Object>> selectMyBookings(CommandMap map) throws Exception {
        return (List<Map<String, Object>>) selectList("booking.selectMyBookings", map.getMap());
    }


    // ====================================================
    // 예매 생성 (Round 1에서 추가한 SQL 호출)
    // ====================================================

    /** [동시성 제어] 좌석 상태 조회 + 행 잠금 (FOR UPDATE) 
     *  params: seatIds (List<Long>)
     *  return: List<Map>  - seatId, status, price 포함 */
    @SuppressWarnings("unchecked")
    public List<Map<String, Object>> selectSeatsForUpdate(Map<String, Object> map) throws Exception {
        return (List<Map<String, Object>>) selectList("booking.selectSeatsForUpdate", map);
    }

    /** 예매 헤더 INSERT 
     *  params: memberId, scheduleId, totalPrice
     *  생성된 bookingId가 자동으로 map에 주입됨 (useGeneratedKeys) */
    public int insertBooking(Map<String, Object> map) throws Exception {
        return (Integer) insert("booking.insertBooking", map);
    }

    /** 예매 항목 INSERT (좌석당 1행)
     *  params: bookingId, seatId, unitPrice */
    public int insertBookingItem(Map<String, Object> map) throws Exception {
        return (Integer) insert("booking.insertBookingItem", map);
    }

    /** 좌석 상태 RESERVED 변경 (이중 안전장치 포함)
     *  params: seatIds (List<Long>)
     *  return: 영향 받은 행 수. 요청 좌석 수와 다르면 동시성 충돌 → 롤백 필요 */
    public int updateSeatStatusToReserved(Map<String, Object> map) throws Exception {
        return (Integer) update("booking.updateSeatStatusToReserved", map);
    }

    /** 잔여 좌석수 차감
     *  params: scheduleId, seatCount
     *  return: 영향 받은 행 수. 0이면 잔여석 부족 → 롤백 필요 */
    public int decreaseAvailableSeats(Map<String, Object> map) throws Exception {
        return (Integer) update("booking.decreaseAvailableSeats", map);
    }


    // ====================================================
    // 예매 취소
    // ====================================================

    /** 예매 취소 (status → CANCELLED, 취소일시/사유 기록)
     *  params: bookingId, cancelReason
     *  return: 영향 받은 행 수. 0이면 이미 취소되었거나 존재하지 않음 */
    public int cancelBooking(Map<String, Object> map) throws Exception {
        return (Integer) update("booking.cancelBooking", map);
    }

    /** 좌석 상태 복구 (RESERVED → AVAILABLE)
     *  params: bookingId
     *  return: 복구된 좌석 수 */
    public int restoreSeatStatus(Map<String, Object> map) throws Exception {
        return (Integer) update("booking.restoreSeatStatus", map);
    }

    /** 잔여 좌석수 복구 (취소 시 다시 늘리기)
     *  params: bookingId
     *  return: 영향 받은 행 수 */
    public int increaseAvailableSeats(Map<String, Object> map) throws Exception {
        return (Integer) update("booking.increaseAvailableSeats", map);
    }
}