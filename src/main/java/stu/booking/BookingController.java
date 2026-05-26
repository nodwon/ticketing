/** 
* ============================================================ * 
Project : 관제 티켓 (Ticketing System)

- Package : stu.booking
- FileName : BookingController.java *

* Developer : 이규왕 (feature/king)

* Created : 

- Modified : 2026.05.26 *
- Description :
 * [URL 매핑]
 *   GET  /bookingSeat.do        좌석 선택 화면 (임시, 좌석 모듈 통합 시 사라질 예정)
 *   GET  /bookingSeatList.do    좌석 현황 (AJAX, JSON)
 *   GET  /bookingDetail.do      예매 상세 화면
 *   GET  /bookingMyList.do      내 예매 목록
 *   POST /bookingCreate.do      예매 생성 처리 (PENDING) → /payment/form.do 로 redirect
 *   GET  /bookingComplete.do    예매 완료 화면
 *   POST /bookingConfirm.do     예매 확정 처리 (결제 모듈이 BookingService 통해 호출)
 *   POST /bookingCancel.do      예매 취소 처리
 *   
 *     bookingCreate.do 후 결제 모듈 /payment/form.do?bookingId={id} 로 redirect.
 *     결제 모듈은 BookingStatusUpdater → BookingService.confirmBooking 호출하여
 *     bookings.status PENDING→CONFIRMED, seats HELD→RESERVED 처리.
 *     bookingConfirm.do 는 다른 진입 (예: 관리자/수동 확정) 용으로 유지.
* ============================================================ */

package stu.booking;

import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;

import org.apache.log4j.Logger;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.view.RedirectView;

import stu.common.common.CommandMap;

@Controller
public class BookingController {

    Logger log = Logger.getLogger(this.getClass());

    @Resource(name = "bookingService")
    private BookingService bookingService;

    // ====================================================
    // 1. 좌석 선택 화면 (임시 - 좌석 모듈 통합 시 사라질 예정)
    // ====================================================
    @RequestMapping(value = "/bookingSeat.do", method = RequestMethod.GET)
    public ModelAndView bookingSeat(CommandMap commandMap, HttpServletRequest request) throws Exception {

        ModelAndView mv = new ModelAndView("booking/seatSelect");

        String scheduleId = request.getParameter("scheduleId");
        if (scheduleId == null || scheduleId.isEmpty()) {
            scheduleId = "1";
        }
        commandMap.put("scheduleId", scheduleId);

        Map<String, Object> scheduleInfo = bookingService.selectScheduleInfo(commandMap);
        mv.addObject("scheduleInfo", scheduleInfo);

        List<Map<String, Object>> seatList = bookingService.selectSeats(commandMap);
        mv.addObject("seatList", seatList);

        log.debug("bookingSeat - scheduleId=" + scheduleId + ", seat count=" + seatList.size());

        return mv;
    }

    // ====================================================
    // 2. 좌석 현황 조회 (AJAX, JSON 응답)
    // ====================================================
    @RequestMapping(value = "/bookingSeatList.do", method = RequestMethod.GET)
    public ModelAndView bookingSeatList(CommandMap commandMap, HttpServletRequest request) throws Exception {

        ModelAndView mv = new ModelAndView("jsonView");

        String scheduleId = request.getParameter("scheduleId");
        commandMap.put("scheduleId", scheduleId);

        List<Map<String, Object>> seatList = bookingService.selectSeats(commandMap);
        mv.addObject("seatList", seatList);

        return mv;
    }

    // ====================================================
    // 3. 예매 상세 조회
    // ====================================================
    @RequestMapping(value = "/bookingDetail.do", method = RequestMethod.GET)
    public ModelAndView bookingDetail(CommandMap commandMap, HttpServletRequest request) throws Exception {

        ModelAndView mv = new ModelAndView("booking/detail");

        String bookingId = request.getParameter("bookingId");
        commandMap.put("bookingId", bookingId);

        Map<String, Object> bookingDetail = bookingService.selectBookingDetail(commandMap);
        mv.addObject("bookingDetail", bookingDetail);

        List<Map<String, Object>> bookingItems = bookingService.selectBookingItems(commandMap);
        mv.addObject("bookingItems", bookingItems);

        log.debug("bookingDetail - bookingId=" + bookingId);

        return mv;
    }

    // ====================================================
    // 4. 내 예매 목록
    // ====================================================
    @RequestMapping(value = "/bookingMyList.do", method = RequestMethod.GET)
    public ModelAndView bookingMyList(CommandMap commandMap, HttpServletRequest request) throws Exception {

        ModelAndView mv = new ModelAndView("booking/myList");

        String memberId = request.getParameter("memberId");
        if (memberId == null || memberId.isEmpty()) {
            memberId = "1";
        }
        commandMap.put("memberId", memberId);

        List<Map<String, Object>> myBookings = bookingService.selectMyBookings(commandMap);
        mv.addObject("myBookings", myBookings);

        log.debug("bookingMyList - memberId=" + memberId + ", count=" + myBookings.size());

        return mv;
    }


    // ====================================================
    // 5. 예매 생성 처리 (POST) - PENDING 상태로 생성
    //    POST /bookingCreate.do
    //    파라미터: memberId, scheduleId, seatIds (예: "1,2,3,4")
    //    
    //    ⚠️ 결제 모듈(king) 통합 후 리다이렉트 URL을 결제 페이지로 변경 필요
    // ====================================================
    @RequestMapping(value = "/bookingCreate.do", method = RequestMethod.POST)
    public ModelAndView bookingCreate(CommandMap commandMap, HttpServletRequest request) throws Exception {

        log.info("===== 예매 생성 요청 시작 (PENDING) =====");

        try {
            Long bookingId = bookingService.createBooking(commandMap);

            log.info("예매 생성 성공 (PENDING) - bookingId=" + bookingId);

            // [통합 완료] 결제 모듈로 진입
            //   결제 폼: GET /payment/form.do?bookingId={id}
            //   결제 처리 후 BookingStatusUpdater 가 confirmBooking() 호출 → CONFIRMED
            ModelAndView mv = new ModelAndView();
            mv.setView(new RedirectView("/payment/form.do?bookingId=" + bookingId));
            return mv;

        } catch (Exception e) {
            log.error("예매 생성 실패: " + e.getMessage(), e);

            ModelAndView mv = new ModelAndView("booking/bookingError");
            mv.addObject("errorMessage", e.getMessage());
            mv.addObject("scheduleId", request.getParameter("scheduleId"));
            return mv;
        }
    }


    // ====================================================
    // 6. 예매 완료 화면 (GET)
    //    GET /bookingComplete.do?bookingId=N
    // ====================================================
    @RequestMapping(value = "/bookingComplete.do", method = RequestMethod.GET)
    public ModelAndView bookingComplete(CommandMap commandMap, HttpServletRequest request) throws Exception {

        ModelAndView mv = new ModelAndView("booking/complete");

        String bookingId = request.getParameter("bookingId");
        commandMap.put("bookingId", bookingId);

        Map<String, Object> bookingDetail = bookingService.selectBookingDetail(commandMap);
        List<Map<String, Object>> bookingItems = bookingService.selectBookingItems(commandMap);

        mv.addObject("bookingDetail", bookingDetail);
        mv.addObject("bookingItems", bookingItems);

        log.debug("bookingComplete - bookingId=" + bookingId);

        return mv;
    }


    // ====================================================
    // 7. 예매 확정 처리 (POST) - 결제 모듈(king)이 호출
    //    POST /bookingConfirm.do
    //    파라미터: bookingId
    //    
    //    호출 시점: 결제 성공 후
    //    효과: bookings.status PENDING → CONFIRMED
    //          seats.status HELD → RESERVED
    // ====================================================
    @RequestMapping(value = "/bookingConfirm.do", method = RequestMethod.POST)
    public ModelAndView bookingConfirm(CommandMap commandMap, HttpServletRequest request) throws Exception {

        log.info("===== 예매 확정 요청 시작 (결제 모듈 호출) =====");

        try {
            bookingService.confirmBooking(commandMap);

            String bookingId = (String) commandMap.get("bookingId");
            log.info("예매 확정 성공 - bookingId=" + bookingId);

            // 확정 완료 후 완료 화면으로 리다이렉트
            ModelAndView mv = new ModelAndView();
            mv.setView(new RedirectView("/bookingComplete.do?bookingId=" + bookingId));
            return mv;

        } catch (Exception e) {
            log.error("예매 확정 실패: " + e.getMessage(), e);

            ModelAndView mv = new ModelAndView("booking/bookingError");
            mv.addObject("errorMessage", e.getMessage());
            return mv;
        }
    }


    // ====================================================
    // 8. 예매 취소 처리 (POST) - PENDING 또는 CONFIRMED → CANCELLED
    //    POST /bookingCancel.do
    //    파라미터: bookingId, cancelReason (선택)
    //    
    //    호출 주체:
    //      - 사용자 직접 취소 (마이페이지)
    //      - 결제 모듈의 결제 실패/타임아웃
    //      - 별도 스케줄러의 자동 취소
    // ====================================================
    @RequestMapping(value = "/bookingCancel.do", method = RequestMethod.POST)
    public ModelAndView bookingCancel(CommandMap commandMap, HttpServletRequest request) throws Exception {

        log.info("===== 예매 취소 요청 시작 =====");

        try {
            bookingService.cancelBooking(commandMap);

            String bookingId = (String) commandMap.get("bookingId");
            log.info("예매 취소 성공 - bookingId=" + bookingId);

            ModelAndView mv = new ModelAndView();
            String memberId = request.getParameter("memberId");
            if (memberId == null || memberId.isEmpty()) {
                memberId = "1";
            }
            mv.setView(new RedirectView("/bookingMyList.do?memberId=" + memberId));
            return mv;

        } catch (Exception e) {
            log.error("예매 취소 실패: " + e.getMessage(), e);

            ModelAndView mv = new ModelAndView("booking/bookingError");
            mv.addObject("errorMessage", e.getMessage());
            return mv;
        }
    }
}