package stu.booking;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.apache.log4j.Logger;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import stu.common.common.CommandMap;

@Service("bookingService")
public class BookingServiceImpl implements BookingService {

    Logger log = Logger.getLogger(this.getClass());

    @Resource(name = "bookingDao")
    private BookingDao bookingDao;


    // ====================================================
    // 조회 (SELECT) - 단순 위임
    // ====================================================

    @Override
    public Map<String, Object> selectScheduleInfo(CommandMap commandMap) throws Exception {
        return bookingDao.selectScheduleInfo(commandMap);
    }

    @Override
    public List<Map<String, Object>> selectSeats(CommandMap commandMap) throws Exception {
        return bookingDao.selectSeats(commandMap);
    }

    @Override
    public Map<String, Object> selectBookingDetail(CommandMap commandMap) throws Exception {
        return bookingDao.selectBookingDetail(commandMap);
    }

    @Override
    public List<Map<String, Object>> selectBookingItems(CommandMap commandMap) throws Exception {
        return bookingDao.selectBookingItems(commandMap);
    }

    @Override
    public List<Map<String, Object>> selectMyBookings(CommandMap commandMap) throws Exception {
        return bookingDao.selectMyBookings(commandMap);
    }


    // ====================================================
    // 예매 생성 (트랜잭션) - PENDING 상태로 생성
    // 
    // 흐름:
    //   1. 파라미터 검증
    //   2. 좌석 락 + 상태 확인 (FOR UPDATE)
    //   3. 모든 좌석 AVAILABLE 검증 + 가격 서버측 재계산
    //   4. bookings INSERT (status='PENDING')
    //   5. booking_items INSERT × N
    //   6. seats UPDATE (AVAILABLE → HELD)
    //   7. concert_schedules.available_seats 차감
    // ====================================================
    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long createBooking(CommandMap commandMap) throws Exception {

        // [1] 파라미터 추출 및 검증
        Map<String, Object> params = commandMap.getMap();
        Long memberId   = parseLong(params.get("memberId"));
        Long scheduleId = parseLong(params.get("scheduleId"));
        String seatIdsStr = (String) params.get("seatIds");

        if (memberId == null || scheduleId == null || seatIdsStr == null || seatIdsStr.isEmpty()) {
            throw new Exception("필수 파라미터 누락: memberId, scheduleId, seatIds");
        }

        List<Long> seatIds = parseSeatIds(seatIdsStr);
        if (seatIds.isEmpty()) {
            throw new Exception("선택된 좌석이 없습니다");
        }
        if (seatIds.size() > 4) {
            throw new Exception("최대 4석까지 예매 가능합니다");
        }

        log.info("예매 생성 시도 - memberId=" + memberId + ", scheduleId=" + scheduleId 
                + ", seatIds=" + seatIds);

        // [2] 좌석 락 + 상태 확인 (FOR UPDATE)
        Map<String, Object> lockParam = new HashMap<String, Object>();
        lockParam.put("seatIds", seatIds);
        List<Map<String, Object>> seats = bookingDao.selectSeatsForUpdate(lockParam);

        if (seats.size() != seatIds.size()) {
            throw new Exception("존재하지 않는 좌석이 포함되어 있습니다");
        }

        // [3] 모든 좌석 AVAILABLE 검증 + 가격 합산 (서버측 재계산)
        long totalPrice = 0;
        for (Map<String, Object> seat : seats) {
            String status = (String) seat.get("STATUS");
            if (!"AVAILABLE".equals(status)) {
                Object seatId = seat.get("SEATID");
                log.warn("이미 점유된 좌석 시도 감지 - seatId=" + seatId + ", status=" + status);
                throw new Exception("이미 점유된 좌석이 포함되어 있습니다 (seatId=" + seatId + ", status=" + status + ")");
            }
            totalPrice += ((Number) seat.get("PRICE")).longValue();
        }

        log.info("좌석 검증 완료 - 총 가격=" + totalPrice);

        // [4] bookings 테이블에 헤더 INSERT (status='PENDING')
        Map<String, Object> bookingParam = new HashMap<String, Object>();
        bookingParam.put("memberId", memberId);
        bookingParam.put("scheduleId", scheduleId);
        bookingParam.put("totalPrice", totalPrice);
        bookingDao.insertBooking(bookingParam);

        Long bookingId = ((Number) bookingParam.get("bookingId")).longValue();
        log.info("예매 헤더 생성 (PENDING) - bookingId=" + bookingId);

        // [5] booking_items INSERT (좌석 수만큼)
        for (Map<String, Object> seat : seats) {
            Map<String, Object> itemParam = new HashMap<String, Object>();
            itemParam.put("bookingId", bookingId);
            itemParam.put("seatId", seat.get("SEATID"));
            itemParam.put("unitPrice", seat.get("PRICE"));
            bookingDao.insertBookingItem(itemParam);
        }
        log.info("예매 항목 생성 - " + seats.size() + "건");

        // [6] seats 상태 변경 (AVAILABLE → HELD)
        Map<String, Object> updateSeatParam = new HashMap<String, Object>();
        updateSeatParam.put("seatIds", seatIds);
        int seatsAffected = bookingDao.updateSeatStatusToHeld(updateSeatParam);

        // 이중 안전장치: 영향 행 수가 요청과 다르면 동시성 충돌
        if (seatsAffected != seatIds.size()) {
            log.error("동시성 충돌 감지 - 요청=" + seatIds.size() + ", 영향=" + seatsAffected);
            throw new Exception("동시성 충돌: 일부 좌석이 이미 점유되었습니다");
        }

        // [7] concert_schedules.available_seats 차감
        Map<String, Object> updateScheduleParam = new HashMap<String, Object>();
        updateScheduleParam.put("scheduleId", scheduleId);
        updateScheduleParam.put("seatCount", seatIds.size());
        int schedulesAffected = bookingDao.decreaseAvailableSeats(updateScheduleParam);

        if (schedulesAffected == 0) {
            log.error("잔여 좌석 차감 실패 - scheduleId=" + scheduleId);
            throw new Exception("잔여 좌석이 부족합니다");
        }

        log.info("예매 생성 완료 (PENDING 상태) - bookingId=" + bookingId);
        return bookingId;
    }


    // ====================================================
    // 예매 확정 (트랜잭션) - PENDING → CONFIRMED
    // 결제 모듈(king)이 결제 완료 후 호출
    // 
    // 흐름:
    //   1. bookings UPDATE (PENDING → CONFIRMED)
    //   2. seats UPDATE (HELD → RESERVED)
    // ====================================================
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void confirmBooking(CommandMap commandMap) throws Exception {

        Long bookingId = parseLong(commandMap.get("bookingId"));
        if (bookingId == null) {
            throw new Exception("필수 파라미터 누락: bookingId");
        }

        log.info("예매 확정 시도 - bookingId=" + bookingId);

        Map<String, Object> param = new HashMap<String, Object>();
        param.put("bookingId", bookingId);

        // [1] bookings: PENDING → CONFIRMED
        int updated = bookingDao.confirmBookingStatus(param);
        if (updated == 0) {
            log.warn("확정 불가능한 예매 (이미 처리되었거나 만료됨) - bookingId=" + bookingId);
            throw new Exception("확정 가능한 예매가 없습니다 (이미 처리되었거나 만료됨)");
        }

        // [2] seats: HELD → RESERVED
        int seatsConfirmed = bookingDao.updateSeatStatusHeldToReserved(param);
        log.info("좌석 확정 완료 - " + seatsConfirmed + "석");

        log.info("예매 확정 완료 - bookingId=" + bookingId);
    }


    // ====================================================
    // 예매 취소 (트랜잭션) - PENDING 또는 CONFIRMED → CANCELLED
    // 
    // 호출 주체:
    //   - 사용자 직접 취소
    //   - 결제 모듈의 결제 실패/타임아웃
    //   - 별도 스케줄러의 자동 취소
    // 
    // 흐름:
    //   1. 잔여 좌석수 복구 (좌석 정보 참조 위해 먼저 실행)
    //   2. seats UPDATE (HELD/RESERVED → AVAILABLE)
    //   3. bookings UPDATE (status → CANCELLED)
    // ====================================================
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void cancelBooking(CommandMap commandMap) throws Exception {

        Map<String, Object> params = commandMap.getMap();
        Long bookingId = parseLong(params.get("bookingId"));
        String cancelReason = (String) params.get("cancelReason");

        if (bookingId == null) {
            throw new Exception("필수 파라미터 누락: bookingId");
        }
        if (cancelReason == null || cancelReason.isEmpty()) {
            cancelReason = "사용자 요청";
        }

        log.info("예매 취소 시도 - bookingId=" + bookingId + ", reason=" + cancelReason);

        // [1] 잔여 좌석 복구 (예매/좌석 정보 참조 위해 먼저)
        Map<String, Object> increaseParam = new HashMap<String, Object>();
        increaseParam.put("bookingId", bookingId);
        bookingDao.increaseAvailableSeats(increaseParam);

        // [2] 좌석 상태 복구 (HELD/RESERVED → AVAILABLE)
        Map<String, Object> restoreParam = new HashMap<String, Object>();
        restoreParam.put("bookingId", bookingId);
        int restored = bookingDao.restoreSeatStatus(restoreParam);
        log.info("좌석 복구 완료 - " + restored + "석");

        // [3] 예매 상태 변경 (PENDING 또는 CONFIRMED → CANCELLED)
        Map<String, Object> cancelParam = new HashMap<String, Object>();
        cancelParam.put("bookingId", bookingId);
        cancelParam.put("cancelReason", cancelReason);
        int cancelled = bookingDao.cancelBooking(cancelParam);

        if (cancelled == 0) {
            log.warn("취소 가능한 예매 없음 (이미 취소되었거나 존재하지 않음) - bookingId=" + bookingId);
            throw new Exception("취소할 수 없는 예매입니다 (이미 취소되었거나 존재하지 않음)");
        }

        log.info("예매 취소 완료 - bookingId=" + bookingId);
    }


    // ====================================================
    // 유틸리티
    // ====================================================

    /** 파라미터를 Long으로 안전하게 변환 */
    private Long parseLong(Object value) {
        if (value == null) return null;
        if (value instanceof Number) return ((Number) value).longValue();
        try {
            return Long.parseLong(value.toString().trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    /** "1,2,3,4" 형태의 문자열을 List<Long>으로 변환 */
    private List<Long> parseSeatIds(String seatIdsStr) {
        List<Long> result = new ArrayList<Long>();
        if (seatIdsStr == null || seatIdsStr.isEmpty()) return result;
        
        String[] parts = seatIdsStr.split(",");
        for (String part : parts) {
            try {
                result.add(Long.parseLong(part.trim()));
            } catch (NumberFormatException e) {
                // 잘못된 값 무시
            }
        }
        return result;
    }
}