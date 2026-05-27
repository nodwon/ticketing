package stu.booking;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.apache.log4j.Logger;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import stu.common.common.CommandMap;

/**
 * 예매(Booking) 도메인 Service 구현체
 * 
 * [2026.05.27 available_seats 정합성 개편]
 *   기존: +N / -N 누적 방식 → 정희영 hold/release 정책에 의존, 부정합 다발
 *   변경: seats 테이블 실제 상태 SELECT COUNT 재계산 방식
 *         → 누가 뭘 했든 항상 정확한 잔여좌석 값 보장
 *   적용: createBooking, confirmBooking, cancelBooking, releaseHeldSeats
 */
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
    // [통합 메모]
    // 정희영 좌석 모듈 통합 후, 좌석은 두 가지 진입점에서 들어옴:
    //   A. 본인 임시 화면: AVAILABLE 상태 그대로 진입
    //   B. 정희영 모듈: /seat/hold.do 호출로 이미 HELD 상태로 진입
    // → 두 경우 모두 허용. RESERVED만 거부.
    //
    // [2026.05.27 수정] available_seats 재계산 방식 도입
    //   - 기존 [7] +/- 방식은 정희영 hold.do와의 정책 불일치로 부정합 발생
    //     (정희영이 차감 안 함 → 본인도 생략 → 영원히 500/500 유지되는 버그)
    //   - 변경: seats 실제 상태(AVAILABLE 카운트)로 강제 동기화
    //     → 정희영이 뭘 했든 무관하게 항상 정확
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

        // [3] 좌석 상태 검증 + 가격 합산 (서버측 재계산)
        long totalPrice = 0;
        int heldCount = 0;
        int availableCount = 0;

        for (Map<String, Object> seat : seats) {
            String status = (String) seat.get("STATUS");
            Object seatId = seat.get("SEATID");

            if ("RESERVED".equals(status)) {
                log.warn("이미 예매 완료된 좌석 시도 - seatId=" + seatId);
                throw new Exception("이미 예매 완료된 좌석입니다 (seatId=" + seatId + ")");
            }

            if (!"AVAILABLE".equals(status) && !"HELD".equals(status)) {
                log.warn("예매 불가능한 좌석 시도 - seatId=" + seatId + ", status=" + status);
                throw new Exception("예매 불가능한 좌석 (seatId=" + seatId + ", status=" + status + ")");
            }

            if ("HELD".equals(status)) heldCount++;
            else availableCount++;

            totalPrice += ((Number) seat.get("PRICE")).longValue();
        }

        log.info("좌석 검증 완료 - 총 가격=" + totalPrice 
                + " (AVAILABLE=" + availableCount + ", HELD=" + heldCount + ")");

        // [4] bookings INSERT (status='PENDING')
        Map<String, Object> bookingParam = new HashMap<String, Object>();
        bookingParam.put("memberId", memberId);
        bookingParam.put("scheduleId", scheduleId);
        bookingParam.put("totalPrice", totalPrice);
        bookingDao.insertBooking(bookingParam);

        Long bookingId = ((Number) bookingParam.get("bookingId")).longValue();
        log.info("예매 헤더 생성 (PENDING) - bookingId=" + bookingId);

        // [5] booking_items INSERT
        for (Map<String, Object> seat : seats) {
            Map<String, Object> itemParam = new HashMap<String, Object>();
            itemParam.put("bookingId", bookingId);
            itemParam.put("seatId", seat.get("SEATID"));
            itemParam.put("unitPrice", seat.get("PRICE"));
            bookingDao.insertBookingItem(itemParam);
        }
        log.info("예매 항목 생성 - " + seats.size() + "건");

        // [6] seats 상태 변경 → HELD
        //     - AVAILABLE 좌석만 HELD로 변경 (WHERE status='AVAILABLE')
        //     - 이미 HELD인 좌석은 영향 없음 (정희영이 미리 HELD 처리)
        Map<String, Object> updateSeatParam = new HashMap<String, Object>();
        updateSeatParam.put("seatIds", seatIds);
        int seatsAffected = bookingDao.updateSeatStatusToHeld(updateSeatParam);

        if (seatsAffected != availableCount) {
            log.error("동시성 충돌 감지 - AVAILABLE 좌석=" + availableCount 
                    + ", UPDATE 영향=" + seatsAffected);
            throw new Exception("동시성 충돌: 일부 좌석이 이미 점유되었습니다");
        }
        log.info("좌석 HELD 처리 - AVAILABLE→HELD " + seatsAffected + "건, 기존 HELD 유지 " 
                + heldCount + "건");

        // [7] available_seats 재계산 (seats 실제 상태 기반)
        //     [기존 +/- 방식 제거 이유]
        //       - availableCount > 0 이면 본인이 -N 차감 (정희영이 안 했다는 가정)
        //       - availableCount == 0 이면 차감 생략 (정희영이 이미 했다는 가정)
        //       → 정희영이 실제로 안 차감하니까 후자에서 영원히 500 유지 버그
        //     [변경 방식]
        //       - seats 테이블에서 AVAILABLE 카운트 직접 SELECT
        //       - 누가 뭘 했든 무관하게 항상 정확
        Map<String, Object> recalcParam = new HashMap<String, Object>();
        recalcParam.put("scheduleId", scheduleId);
        bookingDao.recalcAvailableSeatsBySchedule(recalcParam);
        log.info("잔여 좌석 재계산 완료 (seats 실제 상태 기반) - scheduleId=" + scheduleId);

        log.info("예매 생성 완료 (PENDING 상태) - bookingId=" + bookingId);
        return bookingId;
    }


    // ====================================================
    // 예매 확정 (트랜잭션) - PENDING → CONFIRMED
    //
    // [2026.05.27 추가] available_seats 재계산 (안전망)
    //   - HELD→RESERVED는 둘 다 not-AVAILABLE이라 이론적으론 변화 없음
    //   - 하지만 이전 단계에서 부정합이 있었다면 여기서 교정 가능
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

        // [3] available_seats 재계산 (안전망)
        bookingDao.recalcAvailableSeats(param);
        log.info("잔여 좌석 재계산 완료 (seats 실제 상태 기반)");

        log.info("예매 확정 완료 - bookingId=" + bookingId);
    }


    // ====================================================
    // 예매 취소 (트랜잭션) - PENDING 또는 CONFIRMED → CANCELLED
    //
    // [2026.05.27 수정] available_seats 누적 부정합 버그 수정
    //   - 기존: booking_items 개수만큼 무조건 +N
    //   - 변경: 좌석 풀기 후 seats 실제 상태로 재계산
    // ====================================================
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void cancelBooking(CommandMap commandMap) throws Exception {

        Map<String, Object> params = commandMap.getMap();
        Long bookingId = parseLong(params.get("bookingId"));

        if (bookingId == null) {
            throw new Exception("필수 파라미터 누락: bookingId");
        }

        log.info("예매 취소 시도 - bookingId=" + bookingId);

        // [1] 좌석 HELD/RESERVED → AVAILABLE (먼저 풀어준다)
        Map<String, Object> restoreParam = new HashMap<String, Object>();
        restoreParam.put("bookingId", bookingId);
        int restored = bookingDao.restoreSeatStatus(restoreParam);
        log.info("좌석 복구 완료 - " + restored + "석");

        // [2] 예매 status → CANCELLED
        Map<String, Object> cancelParam = new HashMap<String, Object>();
        cancelParam.put("bookingId", bookingId);
        int cancelled = bookingDao.cancelBooking(cancelParam);

        if (cancelled == 0) {
            log.warn("취소 가능한 예매 없음 - bookingId=" + bookingId);
            throw new Exception("취소할 수 없는 예매입니다 (이미 취소되었거나 존재하지 않음)");
        }

        // [3] 잔여 좌석 재계산 (seats 실제 상태 기반)
        Map<String, Object> recalcParam = new HashMap<String, Object>();
        recalcParam.put("bookingId", bookingId);
        bookingDao.recalcAvailableSeats(recalcParam);
        log.info("잔여 좌석 재계산 완료 (seats 실제 상태 기반)");

        log.info("예매 취소 완료 - bookingId=" + bookingId);
    }


    // ====================================================
    // 좌석 강제 해제 (HELD → AVAILABLE) - 예매 생성 실패 시
    // 
    // [중요] REQUIRES_NEW 트랜잭션
    //   호출 컨텍스트: createBooking이 throw 한 후 catch 블록에서 호출됨.
    //   같은 트랜잭션에 묶이면 본 UPDATE도 함께 롤백되어 의미가 없다.
    //   → 별도 트랜잭션으로 분리해서 무조건 커밋되도록 한다.
    //
    // [2026.05.27 수정] available_seats 재계산 추가
    //   - 이전엔 정희영 책임 영역이라 +N 안 했음
    //   - SELECT COUNT 방식이면 누가 뭘 했든 정확하므로 본인이 재계산 책임짐
    // ====================================================
    @Override
    @Transactional(rollbackFor = Exception.class, propagation = Propagation.REQUIRES_NEW)
    public void releaseHeldSeats(CommandMap commandMap) throws Exception {

        Map<String, Object> params = commandMap.getMap();
        Long scheduleId = parseLong(params.get("scheduleId"));
        String seatIdsStr = (String) params.get("seatIds");

        if (scheduleId == null || seatIdsStr == null || seatIdsStr.isEmpty()) {
            log.warn("releaseHeldSeats - 파라미터 누락. scheduleId=" + scheduleId
                    + ", seatIds=" + seatIdsStr);
            return;
        }

        List<Long> seatIds = parseSeatIds(seatIdsStr);
        if (seatIds.isEmpty()) {
            log.warn("releaseHeldSeats - 유효한 seatId 없음");
            return;
        }

        log.info("좌석 강제 해제 시도 - scheduleId=" + scheduleId 
                + ", seatIds=" + seatIds);

        // [1] 좌석 HELD → AVAILABLE
        Map<String, Object> releaseParam = new HashMap<String, Object>();
        releaseParam.put("seatIds", seatIds);
        releaseParam.put("scheduleId", scheduleId);
        int released = bookingDao.releaseHeldSeats(releaseParam);

        // [2] available_seats 재계산 (seats 실제 상태 기반)
        Map<String, Object> recalcParam = new HashMap<String, Object>();
        recalcParam.put("scheduleId", scheduleId);
        bookingDao.recalcAvailableSeatsBySchedule(recalcParam);
        log.info("잔여 좌석 재계산 완료 (seats 실제 상태 기반)");

        log.info("좌석 강제 해제 완료 - 해제 좌석 수=" + released 
                + " (요청 " + seatIds.size() + "개 중)");

        if (released < seatIds.size()) {
            log.warn("[SEAT_RELEASE_PARTIAL] 일부 좌석만 해제됨 - 요청=" 
                    + seatIds.size() + ", 해제=" + released
                    + " (RESERVED 상태이거나 다른 schedule의 좌석일 수 있음)");
        }
    }


    // ====================================================
    // 유틸리티
    // ====================================================

    private Long parseLong(Object value) {
        if (value == null) return null;
        if (value instanceof Number) return ((Number) value).longValue();
        try {
            return Long.parseLong(value.toString().trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private List<Long> parseSeatIds(String seatIdsStr) {
        List<Long> result = new ArrayList<Long>();
        if (seatIdsStr == null || seatIdsStr.isEmpty()) return result;
        
        String[] parts = seatIdsStr.split(",");
        for (String part : parts) {
            try {
                result.add(Long.parseLong(part.trim()));
            } catch (NumberFormatException e) {
                // 무시
            }
        }
        return result;
    }
}