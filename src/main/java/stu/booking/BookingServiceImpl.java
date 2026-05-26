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
    // [통합 메모]
    // 정희영 좌석 모듈 통합 후, 좌석은 두 가지 진입점에서 들어옴:
    //   A. 본인 임시 화면: AVAILABLE 상태 그대로 진입
    //   B. 정희영 모듈: /seat/hold.do 호출로 이미 HELD 상태로 진입
    // → 두 경우 모두 허용. RESERVED만 거부.
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
        //     AVAILABLE: 일반 예매 진입 (본인 임시 화면)
        //     HELD: 좌석 모듈에서 임시 선점 후 진입 (정희영 모듈)
        //     RESERVED: 이미 결제 완료 → 거부
        long totalPrice = 0;
        int heldCount = 0;       // HELD로 진입한 좌석 수 (디버깅 + 보안 관제용)
        int availableCount = 0;  // AVAILABLE로 진입한 좌석 수

        for (Map<String, Object> seat : seats) {
            String status = (String) seat.get("STATUS");
            Object seatId = seat.get("SEATID");

            // RESERVED는 거부 (이미 결제된 좌석)
            if ("RESERVED".equals(status)) {
                log.warn("이미 예매 완료된 좌석 시도 - seatId=" + seatId);
                throw new Exception("이미 예매 완료된 좌석입니다 (seatId=" + seatId + ")");
            }

            // AVAILABLE 또는 HELD만 통과
            if (!"AVAILABLE".equals(status) && !"HELD".equals(status)) {
                log.warn("예매 불가능한 좌석 시도 - seatId=" + seatId + ", status=" + status);
                throw new Exception("예매 불가능한 좌석 (seatId=" + seatId + ", status=" + status + ")");
            }

            // 통계 카운트
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
        //     - AVAILABLE 좌석: HELD로 변경
        //     - 이미 HELD인 좌석: 그대로 (영향받지 않음)
        //     → updateSeatStatusToHeld는 WHERE status='AVAILABLE'을 사용하므로
        //       이미 HELD인 좌석은 영향 없음. 이건 정상.
        Map<String, Object> updateSeatParam = new HashMap<String, Object>();
        updateSeatParam.put("seatIds", seatIds);
        int seatsAffected = bookingDao.updateSeatStatusToHeld(updateSeatParam);

        // 동시성 충돌 검증: AVAILABLE 좌석 수와 영향받은 UPDATE 수가 일치해야 함
        // HELD로 들어온 좌석은 이미 HELD라서 영향 받지 않는 게 정상
        if (seatsAffected != availableCount) {
            log.error("동시성 충돌 감지 - AVAILABLE 좌석=" + availableCount 
                    + ", UPDATE 영향=" + seatsAffected);
            throw new Exception("동시성 충돌: 일부 좌석이 이미 점유되었습니다");
        }
        log.info("좌석 HELD 처리 - AVAILABLE→HELD " + seatsAffected + "건, 기존 HELD 유지 " 
                + heldCount + "건");

        // [7] concert_schedules.available_seats 차감
        //     단, HELD로 진입한 좌석은 이미 available_seats에서 차감된 상태일 수 있음
        //     → 정희영 /seat/hold.do가 available_seats 차감을 처리한다면 중복 차감 가능성
        //     → 현재는 일단 모두 차감 (정희영 측 정책 확인 필요)
        //     [TODO] 정희영과 협의: hold.do에서 available_seats 차감 여부 확인
        if (availableCount > 0) {
            Map<String, Object> updateScheduleParam = new HashMap<String, Object>();
            updateScheduleParam.put("scheduleId", scheduleId);
            updateScheduleParam.put("seatCount", availableCount);  // AVAILABLE만 차감
            int schedulesAffected = bookingDao.decreaseAvailableSeats(updateScheduleParam);

            if (schedulesAffected == 0) {
                log.error("잔여 좌석 차감 실패 - scheduleId=" + scheduleId);
                throw new Exception("잔여 좌석이 부족합니다");
            }
            log.info("잔여 좌석 차감 - " + availableCount + "석");
        } else {
            log.info("잔여 좌석 차감 생략 (모두 HELD 상태로 진입, 이미 차감됨)");
        }

        log.info("예매 생성 완료 (PENDING 상태) - bookingId=" + bookingId);
        return bookingId;
    }


    // ====================================================
    // 예매 확정 (트랜잭션) - PENDING → CONFIRMED
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
    // cancelled_at, cancel_reason 제거됨 (명세서 표준 적용)
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

        // [1] 잔여 좌석 복구
        Map<String, Object> increaseParam = new HashMap<String, Object>();
        increaseParam.put("bookingId", bookingId);
        bookingDao.increaseAvailableSeats(increaseParam);

        // [2] 좌석 HELD/RESERVED → AVAILABLE
        Map<String, Object> restoreParam = new HashMap<String, Object>();
        restoreParam.put("bookingId", bookingId);
        int restored = bookingDao.restoreSeatStatus(restoreParam);
        log.info("좌석 복구 완료 - " + restored + "석");

        // [3] 예매 status → CANCELLED
        Map<String, Object> cancelParam = new HashMap<String, Object>();
        cancelParam.put("bookingId", bookingId);
        int cancelled = bookingDao.cancelBooking(cancelParam);

        if (cancelled == 0) {
            log.warn("취소 가능한 예매 없음 - bookingId=" + bookingId);
            throw new Exception("취소할 수 없는 예매입니다 (이미 취소되었거나 존재하지 않음)");
        }

        log.info("예매 취소 완료 - bookingId=" + bookingId);
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