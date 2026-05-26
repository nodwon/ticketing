package stu.booking;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import org.apache.log4j.Logger;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.view.RedirectView;

import stu.common.common.CommandMap;

/**
 * 예매(Booking) 도메인 Controller
 * 
 * [URL 매핑]
 *   GET  /booking/complete.do    예매 생성 (정희영 좌석 모듈 호출) ⭐ 메인 진입점
 *   GET  /bookingComplete.do     예매 완료 화면
 *   POST /bookingCreate.do       예매 생성 (form 방식, 백업용)
 *   POST /api/bookings           예매 생성 (REST API, JSON, 백업용)
 *   GET  /bookingSeatList.do     좌석 현황 AJAX
 *   GET  /bookingDetail.do       예매 상세 화면
 *   GET  /bookingMyList.do       내 예매 목록
 *   POST /bookingConfirm.do      예매 확정 (결제 모듈 호출)
 *   POST /bookingCancel.do       예매 취소
 *   
 *   [제거됨] /bookingSeat.do - 본인 임시 좌석 화면 (정희영 모듈로 대체)
 */
@Controller
public class BookingController {

    Logger log = Logger.getLogger(this.getClass());

    @Resource(name = "bookingService")
    private BookingService bookingService;


    // ====================================================
    // ⭐ 메인 진입점: 정희영 좌석 모듈에서 호출 (GET)
    //    GET /booking/complete.do?scheduleId=N&seatIds=1,2,3,4
    //    
    //    흐름:
    //      1. 좌석 모듈에서 좌석 선택 후 이 URL로 GET 호출
    //      2. 본인이 예매 생성 (PENDING)
    //      3. /bookingComplete.do?bookingId=N 으로 리다이렉트
    //      4. complete.jsp PENDING 화면 표시
    // ====================================================
    @RequestMapping(value = "/booking/complete.do", method = RequestMethod.GET)
    public ModelAndView bookingCreateFromSeat(
            CommandMap commandMap, HttpServletRequest request) throws Exception {

        log.info("===== 좌석 모듈에서 예매 생성 요청 (GET) =====");
        
        String scheduleId = request.getParameter("scheduleId");
        String seatIds = request.getParameter("seatIds");
        
        log.info("scheduleId=" + scheduleId + ", seatIds=" + seatIds);
        
        if (scheduleId == null || seatIds == null) {
            ModelAndView mv = new ModelAndView("booking/bookingError");
            mv.addObject("errorMessage", "필수 파라미터 누락: scheduleId, seatIds");
            return mv;
        }
        
        try {
            // member_id 세션에서 (없으면 임시 1)
            HttpSession session = request.getSession();
            Object sessionMemberId = session.getAttribute("memberId");
            if (sessionMemberId == null) sessionMemberId = session.getAttribute("MEMBER_NO");
            if (sessionMemberId == null) sessionMemberId = session.getAttribute("SESSION_NO");
            if (sessionMemberId == null) {
                log.warn("세션에 memberId 없음, 테스트용 memberId=1 사용");
                sessionMemberId = "1";
            }
            
            commandMap.put("memberId", sessionMemberId);
            commandMap.put("scheduleId", scheduleId);
            commandMap.put("seatIds", seatIds);
            
            Long bookingId = bookingService.createBooking(commandMap);
            
            log.info("예매 생성 성공 (PENDING) - bookingId=" + bookingId);
            
            ModelAndView mv = new ModelAndView();
            mv.setView(new RedirectView("/bookingComplete.do?bookingId=" + bookingId));
            return mv;
            
        } catch (Exception e) {
            log.error("예매 생성 실패: " + e.getMessage(), e);
            ModelAndView mv = new ModelAndView("booking/bookingError");
            mv.addObject("errorMessage", e.getMessage());
            mv.addObject("scheduleId", scheduleId);
            return mv;
        }
    }


    // ====================================================
    // 예매 완료 화면 (GET)
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
        return mv;
    }


    // ====================================================
    // 예매 생성 (form POST, 백업용)
    //    POST /bookingCreate.do
    // ====================================================
    @RequestMapping(value = "/bookingCreate.do", method = RequestMethod.POST)
    public ModelAndView bookingCreate(CommandMap commandMap, HttpServletRequest request) throws Exception {
        log.info("===== 예매 생성 요청 (form 방식) =====");
        try {
            Long bookingId = bookingService.createBooking(commandMap);
            ModelAndView mv = new ModelAndView();
            mv.setView(new RedirectView("/bookingComplete.do?bookingId=" + bookingId));
            return mv;
        } catch (Exception e) {
            log.error("예매 생성 실패: " + e.getMessage(), e);
            ModelAndView mv = new ModelAndView("booking/bookingError");
            mv.addObject("errorMessage", e.getMessage());
            return mv;
        }
    }


    // ====================================================
    // 예매 생성 (REST API JSON, 백업용)
    //    POST /api/bookings
    // ====================================================
    @RequestMapping(
        value = "/api/bookings", 
        method = RequestMethod.POST,
        consumes = MediaType.APPLICATION_JSON_VALUE,
        produces = MediaType.APPLICATION_JSON_VALUE
    )
    @ResponseBody
    public Map<String, Object> bookingCreateApi(
            @RequestBody Map<String, Object> requestBody, 
            HttpServletRequest request) throws Exception {

        log.info("===== 예매 생성 API 요청 (JSON) =====");
        Map<String, Object> result = new HashMap<String, Object>();

        try {
            Object scheduleIdObj = requestBody.get("schedule_id");
            Object seatIdsObj = requestBody.get("seat_ids");
            if (scheduleIdObj == null || seatIdsObj == null) {
                throw new Exception("필수 파라미터 누락");
            }

            String seatIdsStr;
            if (seatIdsObj instanceof List) {
                @SuppressWarnings("unchecked")
                List<Object> seatIdsList = (List<Object>) seatIdsObj;
                StringBuilder sb = new StringBuilder();
                for (int i = 0; i < seatIdsList.size(); i++) {
                    if (i > 0) sb.append(",");
                    sb.append(seatIdsList.get(i).toString());
                }
                seatIdsStr = sb.toString();
            } else {
                seatIdsStr = seatIdsObj.toString();
            }

            HttpSession session = request.getSession();
            Object sessionMemberId = session.getAttribute("memberId");
            if (sessionMemberId == null) sessionMemberId = "1";

            CommandMap commandMap = new CommandMap();
            commandMap.put("memberId", sessionMemberId);
            commandMap.put("scheduleId", scheduleIdObj);
            commandMap.put("seatIds", seatIdsStr);

            Long bookingId = bookingService.createBooking(commandMap);

            result.put("success", true);
            result.put("booking_id", bookingId);
            return result;
        } catch (Exception e) {
            log.error("예매 생성 실패: " + e.getMessage(), e);
            result.put("success", false);
            result.put("message", e.getMessage());
            return result;
        }
    }


    // ====================================================
    // 좌석 현황 조회 (AJAX, JSON)
    //    GET /bookingSeatList.do?scheduleId=N
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
    // 예매 상세 조회
    //    GET /bookingDetail.do?bookingId=N
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
        return mv;
    }


    // ====================================================
    // 내 예매 목록
    //    GET /bookingMyList.do?memberId=N
    // ====================================================
    @RequestMapping(value = "/bookingMyList.do", method = RequestMethod.GET)
    public ModelAndView bookingMyList(CommandMap commandMap, HttpServletRequest request) throws Exception {
        ModelAndView mv = new ModelAndView("booking/myList");
        String memberId = request.getParameter("memberId");
        if (memberId == null || memberId.isEmpty()) memberId = "1";
        commandMap.put("memberId", memberId);
        List<Map<String, Object>> myBookings = bookingService.selectMyBookings(commandMap);
        mv.addObject("myBookings", myBookings);
        return mv;
    }


    // ====================================================
    // 예매 확정 (POST) - 결제 모듈에서 호출
    //    POST /bookingConfirm.do
    // ====================================================
    @RequestMapping(value = "/bookingConfirm.do", method = RequestMethod.POST)
    public ModelAndView bookingConfirm(CommandMap commandMap, HttpServletRequest request) throws Exception {
        log.info("===== 예매 확정 요청 =====");
        try {
            bookingService.confirmBooking(commandMap);
            String bookingId = (String) commandMap.get("bookingId");
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
    // 예매 취소 (POST)
    //    POST /bookingCancel.do
    // ====================================================
    @RequestMapping(value = "/bookingCancel.do", method = RequestMethod.POST)
    public ModelAndView bookingCancel(CommandMap commandMap, HttpServletRequest request) throws Exception {
        log.info("===== 예매 취소 요청 =====");
        try {
            bookingService.cancelBooking(commandMap);
            String bookingId = (String) commandMap.get("bookingId");
            ModelAndView mv = new ModelAndView();
            String memberId = request.getParameter("memberId");
            if (memberId == null || memberId.isEmpty()) memberId = "1";
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