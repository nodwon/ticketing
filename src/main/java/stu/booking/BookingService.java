package stu.booking;

import java.util.List;
import java.util.Map;

import stu.common.common.CommandMap;

/**
 * 예매(Booking) 도메인 Service 인터페이스
 * 
 * [기능 분류]
 *   조회 5개 - 화면 표시용
 *   생성 1개 - createBooking (트랜잭션 필수)
 *   취소 1개 - cancelBooking (트랜잭션 필수)
 */
public interface BookingService {

    // ====================================================
    // 조회 (SELECT)
    // ====================================================

    Map<String, Object> selectScheduleInfo(CommandMap commandMap) throws Exception;
    List<Map<String, Object>> selectSeats(CommandMap commandMap) throws Exception;
    Map<String, Object> selectBookingDetail(CommandMap commandMap) throws Exception;
    List<Map<String, Object>> selectBookingItems(CommandMap commandMap) throws Exception;
    List<Map<String, Object>> selectMyBookings(CommandMap commandMap) throws Exception;

    // ====================================================
    // 생성/취소 (INSERT/UPDATE - 트랜잭션)
    // ====================================================

    /**
     * 예매 생성 (트랜잭션)
     * 
     * 필수 파라미터:
     *   memberId    Long   회원 ID
     *   scheduleId  Long   공연 일정 ID
     *   seatIds     String "1,2,3,4" 형태의 좌석 ID 목록 (콤마 구분)
     * 
     * @return 생성된 booking_id
     * @throws Exception 좌석 점유 실패, 가격 불일치 등
     */
    Long createBooking(CommandMap commandMap) throws Exception;

    /**
     * 예매 취소 (트랜잭션)
     * 
     * 필수 파라미터:
     *   bookingId     Long   예매 ID
     *   cancelReason  String 취소 사유
     */
    void cancelBooking(CommandMap commandMap) throws Exception;
}