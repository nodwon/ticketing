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

/**
 * 예매(Booking) 도메인 Controller
 * 
 * [URL 매핑]
 *   GET  /bookingSeatList.do    좌석 현황 (AJAX, JSON)
 *   GET  /bookingDetail.do      예매 상세 화면
 *   GET  /bookingMyList.do      내 예매 목록
 *   POST /bookingCreate.do      예매 생성 처리 (PENDING) → /payment/form.do redirect
 *   GET  /bookingComplete.do    예매 완료 화면 (결제 SUCCESS 후 진입)
 *   POST /bookingConfirm.do     예매 확정 처리 (결제 모듈이 호출, PENDING → CONFIRMED)
 *   POST /bookingCancel.do      예매 취소 처리
 *
 *   [2026.05.26]
 *     - /bookingSeat.do (임시 좌석 선택 화면) 제거됨
 *       → 좌석 모듈 /seat/select.do 로 일원화
 *     - /bookingCreate.do 성공 시 /payment/form.do?bookingId=N 으로 redirect
 */
@Controller
public class BookingController {

    Logger log = Logger.getLogger(this.getClass());

    @Resource(name = "bookingService")
    private BookingService bookingService;

    // ====================================================
    // 1. [제거됨 - 2026.05.26]
    //    임시 좌석 선택 화면(/bookingSeat.do)은 좌석 모듈(/seat/select.do)
    //    통합으로 더 이상 필요 없어 삭제됨.
    //    공연 상세 → 좌석 선택은 /seat/select.do?scheduleId=N 사용.
    // ====================================================

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
    //    [2026.05.26 결제 모듈(king) 통합 완료]
    //      생성 직후 /payment/form.do?bookingId=N 으로 redirect
    // ====================================================
    @RequestMapping(value = "/bookingCreate.do", method = RequestMethod.POST)
    public ModelAndView bookingCreate(CommandMap commandMap, HttpServletRequest request) throws Exception {

        log.info("===== 예매 생성 요청 시작 (PENDING) =====");

        try {
            Long bookingId = bookingService.createBooking(commandMap);

            log.info("예매 생성 성공 (PENDING) - bookingId=" + bookingId
                    + " → 결제 폼으로 이동");

            // 결제 모듈로 위임 (PaymentController.form())
            ModelAndView mv = new ModelAndView();
            mv.setView(new RedirectView("/payment/form.do?bookingId=" + bookingId, false));
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