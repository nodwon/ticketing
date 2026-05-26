package stu.booking;

import java.util.List;
import java.util.Map;

import stu.common.common.CommandMap;

/**
 * 예매(Booking) 도메인 Service 인터페이스
 * 
 * [PENDING 흐름]
 *   1. createBooking()   - 예매 생성 (PENDING 상태)
 *   2. confirmBooking()  - 결제 확정 (PENDING → CONFIRMED, 결제 모듈이 호출)
 *   3. cancelBooking()   - 예매 취소 (PENDING 또는 CONFIRMED → CANCELLED)
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
    // 생성/확정/취소 (트랜잭션)
    // ====================================================

    /**
     * 예매 생성 (트랜잭션) - PENDING 상태로 생성
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
     * 예매 확정 (트랜잭션) - PENDING → CONFIRMED
     * 결제 모듈(king)이 결제 완료 후 호출
     * 
     * 필수 파라미터:
     *   bookingId   Long   예매 ID
     */
    void confirmBooking(CommandMap commandMap) throws Exception;

    /**
     * 예매 취소 (트랜잭션) - PENDING 또는 CONFIRMED → CANCELLED
     * 
     * 필수 파라미터:
     *   bookingId     Long   예매 ID
     *   cancelReason  String 취소 사유
     */
    void cancelBooking(CommandMap commandMap) throws Exception;
}