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
        //     [2026-05-27 정책 변경]
        //     이전: AVAILABLE + HELD 둘 다 허용 (클릭 즉시 hold.do 호출하던 시절의 잔재)
        //     현재: AVAILABLE 만 허용.
        //       - 좌석 클릭은 로컬 저장만 하고 서버에 hold 신호를 보내지 않음.
        //       - 따라서 createBooking 시점에 HELD 인 좌석 = 다른 사용자가 먼저
        //         결제창에 진입해 잡아둔 것 → 즉시 거부.
        //       - RESERVED 는 기결제 좌석 → 거부.
        long totalPrice = 0;

        for (Map<String, Object> seat : seats) {
            String status = (String) seat.get("STATUS");
            Object seatId = seat.get("SEATID");

            if ("RESERVED".equals(status)) {
                log.warn("이미 예매 완료된 좌석 시도 - seatId=" + seatId);
                throw new Exception("이미 예매 완료된 좌석입니다 (seatId=" + seatId + ")");
            }

            if (!"AVAILABLE".equals(status)) {
                // HELD: 다른 사용자가 결제 진행 중인 좌석
                log.warn("이미 선점된 좌석 시도 - seatId=" + seatId + ", status=" + status);
                throw new Exception("이미 다른 사용자가 선택 중인 좌석입니다 (seatId=" + seatId + ")");
            }

            totalPrice += ((Number) seat.get("PRICE")).longValue();
        }

        log.info("좌석 검증 완료 - 총 가격=" + totalPrice + ", 좌석수=" + seats.size());

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
        //     FOR UPDATE 로 락이 잡혀있는 상태에서 UPDATE 하므로
        //     이 사이에 다른 트랜잭션이 끼어들 수 없음.
        //     UPDATE 영향 행 수가 좌석 수와 다르면 = 락 획득 직전에 다른 트랜잭션이
        //     먼저 HELD/RESERVED 로 바꿔버린 충돌 → 롤백.
        Map<String, Object> updateSeatParam = new HashMap<String, Object>();
        updateSeatParam.put("seatIds", seatIds);
        updateSeatParam.put("memberId", memberId);
        int seatsAffected = bookingDao.updateSeatStatusToHeld(updateSeatParam);

        if (seatsAffected != seatIds.size()) {
            log.error("동시성 충돌 감지 - 요청 좌석=" + seatIds.size()
                    + ", HELD 전환 성공=" + seatsAffected
                    + " (차이: " + (seatIds.size() - seatsAffected) + "석이 이미 선점됨)");
            throw new Exception("동시성 충돌: 일부 좌석이 이미 다른 사용자에게 선점되었습니다");
        }
        log.info("좌석 HELD 처리 완료 - " + seatsAffected + "석");

        // [7] concert_schedules.available_seats 차감 (전체 좌석 수)
        Map<String, Object> updateScheduleParam = new HashMap<String, Object>();
        updateScheduleParam.put("scheduleId", scheduleId);
        updateScheduleParam.put("seatCount", seatIds.size());
        int schedulesAffected = bookingDao.decreaseAvailableSeats(updateScheduleParam);

        if (schedulesAffected == 0) {
            log.error("잔여 좌석 차감 실패 - scheduleId=" + scheduleId);
            throw new Exception("잔여 좌석이 부족합니다");
        }
        log.info("잔여 좌석 차감 - " + seatIds.size() + "석");

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