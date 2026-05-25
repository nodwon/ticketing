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

    @RequestMapping(value = "/bookingSeatList.do", method = RequestMethod.GET)
    public ModelAndView bookingSeatList(CommandMap commandMap, HttpServletRequest request) throws Exception {

        ModelAndView mv = new ModelAndView("jsonView");

        String scheduleId = request.getParameter("scheduleId");
        commandMap.put("scheduleId", scheduleId);

        List<Map<String, Object>> seatList = bookingService.selectSeats(commandMap);
        mv.addObject("seatList", seatList);

        return mv;
    }

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

    @RequestMapping(value = "/bookingCreate.do", method = RequestMethod.POST)
    public ModelAndView bookingCreate(CommandMap commandMap, HttpServletRequest request) throws Exception {

        log.info("===== 예매 생성 요청 시작 =====");

        try {
            Long bookingId = bookingService.createBooking(commandMap);
            log.info("예매 생성 성공 - bookingId=" + bookingId);

            ModelAndView mv = new ModelAndView();
            mv.setView(new RedirectView("/bookingComplete.do?bookingId=" + bookingId));
            return mv;

        } catch (Exception e) {
            log.error("예매 생성 실패: " + e.getMessage(), e);

            ModelAndView mv = new ModelAndView("booking/bookingError");
            mv.addObject("errorMessage", e.getMessage());
            mv.addObject("scheduleId", request.getParameter("scheduleId"));
            return mv;
        }
    }

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