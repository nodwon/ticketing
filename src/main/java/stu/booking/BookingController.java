/**
 * ============================================================
 * Project   : 관제 티켓 (Ticketing System)
 * Package   : stu.booking
 * FileName  : BookingController.java
 *
 * Modified  : 2026.05.26 - MacroDetectionLogger 통합
 *
 * [URL 매핑]
 *   GET  /bookingSeatList.do  좌석 현황 (AJAX)
 *   GET  /bookingDetail.do    예매 상세
 *   GET  /bookingMyList.do    내 예매 목록
 *   POST /bookingCreate.do    예매 생성 ★매크로 탐지 로그★
 *   GET  /bookingComplete.do  예매 완료 화면
 *   POST /bookingConfirm.do   예매 확정
 *   POST /bookingCancel.do    예매 취소
 * ============================================================
 */
package stu.booking;

import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.view.RedirectView;

import stu.common.common.CommandMap;
import stu.common.logger.SecurityLogger;
import stu.common.logger.MacroDetectionLogger;

@Controller
public class BookingController {

    private static final Logger log = LoggerFactory.getLogger(BookingController.class);

    @Resource(name = "bookingService")
    private BookingService bookingService;

    @Resource(name = "pendingBookingTracker")
    private PendingBookingTracker pendingTracker;

    // ================================================================
    // 1. 좌석 현황 조회 (Ajax)
    // ================================================================
    @RequestMapping(value = "/bookingSeatList.do", method = RequestMethod.GET)
    public ModelAndView bookingSeatList(CommandMap commandMap,
                                         HttpServletRequest request) throws Exception {
        ModelAndView mv = new ModelAndView("jsonView");
        commandMap.put("scheduleId", request.getParameter("scheduleId"));
        List<Map<String, Object>> seatList = bookingService.selectSeats(commandMap);
        mv.addObject("seatList", seatList);
        return mv;
    }

    // ================================================================
    // 2. 예매 상세 조회
    // ================================================================
    @RequestMapping(value = "/bookingDetail.do", method = RequestMethod.GET)
    public ModelAndView bookingDetail(CommandMap commandMap,
                                       HttpServletRequest request,
                                       HttpSession session) throws Exception {
        ModelAndView mv = new ModelAndView("booking/detail");
        String bookingId = request.getParameter("bookingId");
        commandMap.put("bookingId", bookingId);

        Map<String, Object> bookingDetail = bookingService.selectBookingDetail(commandMap);
        mv.addObject("bookingDetail", bookingDetail);
        mv.addObject("bookingItems",  bookingService.selectBookingItems(commandMap));

        // IDOR 탐지
        Object sessionMemberNo = session.getAttribute("SESSION_NO");
        if (bookingDetail != null && sessionMemberNo != null) {
            Object ownerMemberId = extractMemberId(bookingDetail);
            if (ownerMemberId != null && !isSameMember(ownerMemberId, sessionMemberNo)) {
                Long currentUserId = ((Number) sessionMemberNo).longValue();
                SecurityLogger.adminAccess(
                    "/bookingDetail.do?bookingId=" + bookingId,
                    currentUserId, request.getRemoteAddr(), 403
                );
                log.warn("[IDOR] 타인 예매 조회 - bookingId={}, owner={}, session={}",
                    bookingId, ownerMemberId, sessionMemberNo);
            }
        }
        return mv;
    }

    // ================================================================
    // 3. 내 예매 목록
    // ================================================================
    @RequestMapping(value = "/bookingMyList.do", method = RequestMethod.GET)
    public ModelAndView bookingMyList(CommandMap commandMap,
                                       HttpServletRequest request,
                                       HttpSession session) throws Exception {
        ModelAndView mv = new ModelAndView();
        Object sessionMemberNo = session.getAttribute("SESSION_NO");
        if (sessionMemberNo == null) {
            mv.setView(new RedirectView("/loginForm.do"));
            return mv;
        }
        commandMap.remove("memberId");
        commandMap.put("memberId", String.valueOf(sessionMemberNo));
        mv.addObject("myBookings", bookingService.selectMyBookings(commandMap));
        mv.setViewName("booking/myList");
        return mv;
    }

    // ================================================================
    // 4. 예매 생성 ★★ 매크로 탐지 로그 ★★
    //
    //    seatSelect.jsp 에서 추가로 전송해야 할 hidden 파라미터:
    //    - seat_page_load_ts : JS Date.now() 로 페이지 로드 시각
    // ================================================================
    @RequestMapping(value = "/bookingCreate.do", method = RequestMethod.POST)
    public ModelAndView bookingCreate(CommandMap commandMap,
                                       HttpServletRequest request,
                                       HttpSession session) throws Exception {
        log.info("===== 예매 생성 요청 =====");
        long startTime = System.currentTimeMillis();

        Object sessionMemberNo = session.getAttribute("SESSION_NO");
        if (sessionMemberNo == null) {
            ModelAndView mv = new ModelAndView();
            mv.setView(new RedirectView("/loginForm.do"));
            return mv;
        }

        commandMap.remove("memberId");
        commandMap.put("memberId", String.valueOf(sessionMemberNo));

        Long   memberId      = ((Number) sessionMemberNo).longValue();
        String srcIp         = getClientIp(request);
        String scheduleIdStr = (String) commandMap.get("scheduleId");
        String seatIdsStr    = (String) commandMap.get("seatIds");

        // ★ seat_page_load_ts: seatSelect.jsp 로드 시각 (JS Date.now())
        String seatPageTsStr = request.getParameter("seat_page_load_ts");
        long seatPageTs = 0;
        if (seatPageTsStr != null) {
            try { seatPageTs = Long.parseLong(seatPageTsStr); } catch (Exception e) {}
        }

        try {
            Long bookingId = bookingService.createBooking(commandMap);
            pendingTracker.register(bookingId);

            int elapsedMs = (int)(System.currentTimeMillis() - startTime);

            // ★ 예매 생성 시간 로그 (좌석 페이지 ~ 예매 완료 총 시간)
            Long scheduleId = parseLong(scheduleIdStr);
            MacroDetectionLogger.bookingCreateTime(
                memberId, srcIp, scheduleId, seatIdsStr,
                seatPageTs, elapsedMs, "SUCCESS"
            );

            // 기존 SecurityLogger 유지
            recordSeatLogs(memberId, scheduleIdStr, seatIdsStr, "SUCCESS", elapsedMs);

            log.info("예매 생성 성공 - bookingId={}, elapsed={}ms", bookingId, elapsedMs);

            // ★ 세션에 예매 생성 시각 저장 → PaymentController 에서 사용
            session.setAttribute("_booking_create_ts", System.currentTimeMillis());
            session.setAttribute("_booking_seat_page_ts", seatPageTs);

            ModelAndView mv = new ModelAndView();
            mv.setView(new RedirectView("/payment/form.do?bookingId=" + bookingId, false));
            return mv;

        } catch (Exception e) {
            int elapsedMs = (int)(System.currentTimeMillis() - startTime);

            MacroDetectionLogger.bookingCreateTime(
                memberId, srcIp, parseLong(scheduleIdStr), seatIdsStr,
                seatPageTs, elapsedMs, "FAIL"
            );
            recordSeatLogs(memberId, scheduleIdStr, seatIdsStr, "FAIL", elapsedMs);

            log.error("예매 생성 실패: {}", e.getMessage(), e);
            ModelAndView mv = new ModelAndView("booking/bookingError");
            mv.addObject("errorMessage", e.getMessage());
            mv.addObject("scheduleId",   request.getParameter("scheduleId"));
            return mv;
        }
    }

    // ================================================================
    // 5. 예매 완료 화면
    // ================================================================
    @RequestMapping(value = "/bookingComplete.do", method = RequestMethod.GET)
    public ModelAndView bookingComplete(CommandMap commandMap,
                                         HttpServletRequest request) throws Exception {
        ModelAndView mv = new ModelAndView("booking/complete");
        String bookingId = request.getParameter("bookingId");
        commandMap.put("bookingId", bookingId);
        mv.addObject("bookingDetail", bookingService.selectBookingDetail(commandMap));
        mv.addObject("bookingItems",  bookingService.selectBookingItems(commandMap));
        return mv;
    }

    // ================================================================
    // 6. 예매 확정
    // ================================================================
    @RequestMapping(value = "/bookingConfirm.do", method = RequestMethod.POST)
    public ModelAndView bookingConfirm(CommandMap commandMap,
                                        HttpServletRequest request) throws Exception {
        try {
            bookingService.confirmBooking(commandMap);
            String bookingId = (String) commandMap.get("bookingId");
            ModelAndView mv = new ModelAndView();
            mv.setView(new RedirectView("/bookingComplete.do?bookingId=" + bookingId));
            return mv;
        } catch (Exception e) {
            log.error("예매 확정 실패: {}", e.getMessage(), e);
            ModelAndView mv = new ModelAndView("booking/bookingError");
            mv.addObject("errorMessage", e.getMessage());
            return mv;
        }
    }

    // ================================================================
    // 7. 예매 취소
    // ================================================================
    @RequestMapping(value = "/bookingCancel.do", method = RequestMethod.POST)
    public ModelAndView bookingCancel(CommandMap commandMap,
                                       HttpServletRequest request,
                                       HttpSession session) throws Exception {
        Object sessionMemberNo = session.getAttribute("SESSION_NO");
        if (sessionMemberNo == null) {
            ModelAndView mv = new ModelAndView();
            mv.setView(new RedirectView("/loginForm.do"));
            return mv;
        }

        String bookingId = (String) commandMap.get("bookingId");
        if (bookingId == null || bookingId.isEmpty()) {
            ModelAndView mv = new ModelAndView("booking/bookingError");
            mv.addObject("errorMessage", "필수 파라미터 누락: bookingId");
            return mv;
        }

        Map<String, Object> bookingDetail = bookingService.selectBookingDetail(commandMap);
        if (bookingDetail == null) {
            ModelAndView mv = new ModelAndView("booking/bookingError");
            mv.addObject("errorMessage", "예매 정보를 찾을 수 없습니다.");
            return mv;
        }

        Object ownerMemberId = extractMemberId(bookingDetail);
        if (!isSameMember(ownerMemberId, sessionMemberNo)) {
            Long currentUserId = ((Number) sessionMemberNo).longValue();
            SecurityLogger.adminAccess(
                "/bookingCancel.do?bookingId=" + bookingId,
                currentUserId, request.getRemoteAddr(), 403
            );
            log.warn("[IDOR] 타인 예매 취소 시도 - bookingId={}", bookingId);
            ModelAndView mv = new ModelAndView("booking/bookingError");
            mv.addObject("errorMessage", "본인의 예매만 취소할 수 있습니다.");
            return mv;
        }

        try {
            bookingService.cancelBooking(commandMap);
            ModelAndView mv = new ModelAndView();
            mv.setView(new RedirectView("/bookingMyList.do"));
            return mv;
        } catch (Exception e) {
            log.error("예매 취소 실패: {}", e.getMessage(), e);
            ModelAndView mv = new ModelAndView("booking/bookingError");
            mv.addObject("errorMessage", e.getMessage());
            return mv;
        }
    }

    // ================================================================
    // 8. heartbeat
    // ================================================================
    @RequestMapping(value = "/booking/heartbeat.do", method = RequestMethod.POST)
    @ResponseBody
    public Map<String, Object> heartbeat(@RequestParam("bookingId") String bookingIdStr,
                                          HttpSession session) {
        Map<String, Object> resp = new java.util.HashMap<String, Object>();
        if (session.getAttribute("SESSION_NO") == null) {
            resp.put("result", "unauth"); return resp;
        }
        try {
            pendingTracker.heartbeat(Long.parseLong(bookingIdStr));
            resp.put("result", "ok");
        } catch (NumberFormatException e) {
            resp.put("result", "bad");
        }
        return resp;
    }

    // ================================================================
    // 9. abandon
    // ================================================================
    @RequestMapping(value = "/booking/abandon.do", method = RequestMethod.POST)
    @ResponseBody
    public Map<String, Object> abandon(@RequestParam("bookingId") String bookingIdStr,
                                        HttpServletRequest request,
                                        HttpSession session) throws Exception {
        Map<String, Object> resp = new java.util.HashMap<String, Object>();
        Object sessionMemberNo = session.getAttribute("SESSION_NO");
        if (sessionMemberNo == null) { resp.put("result", "unauth"); return resp; }

        long bookingId;
        try { bookingId = Long.parseLong(bookingIdStr); }
        catch (NumberFormatException e) { resp.put("result", "bad"); return resp; }

        CommandMap probe = new CommandMap();
        probe.put("bookingId", bookingIdStr);
        Map<String, Object> detail = bookingService.selectBookingDetail(probe);
        if (detail == null) { resp.put("result", "notfound"); return resp; }

        Object owner = extractMemberId(detail);
        if (!isSameMember(owner, sessionMemberNo)) {
            SecurityLogger.adminAccess(
                "/booking/abandon.do?bookingId=" + bookingId,
                ((Number) sessionMemberNo).longValue(), request.getRemoteAddr(), 403
            );
            resp.put("result", "forbidden");
            return resp;
        }

        pendingTracker.abandonImmediately(bookingId, "beacon");
        resp.put("result", "ok");
        return resp;
    }

    // ── 헬퍼 ────────────────────────────────────────────
    private void recordSeatLogs(Long memberId, String scheduleIdStr,
                                 String seatIdsStr, String result, int elapsedMs) {
        if (memberId == null || seatIdsStr == null) return;
        try {
            Long scheduleId = scheduleIdStr != null ? Long.parseLong(scheduleIdStr) : null;
            for (String seatIdStr : seatIdsStr.split(",")) {
                try {
                    SecurityLogger.seat(memberId, scheduleId,
                        Long.parseLong(seatIdStr.trim()), result, elapsedMs);
                } catch (NumberFormatException e) { /* ignore */ }
            }
        } catch (Exception e) {
            log.warn("좌석 보안 로그 실패: {}", e.getMessage());
        }
    }

    private String getClientIp(HttpServletRequest request) {
        String ip = request.getHeader("X-Forwarded-For");
        if (ip == null || ip.isEmpty()) ip = request.getRemoteAddr();
        return ip.split(",")[0].trim();
    }

    private Long parseLong(String s) {
        if (s == null || s.trim().isEmpty()) return null;
        try { return Long.parseLong(s.trim()); }
        catch (NumberFormatException e) { return null; }
    }

    private Object extractMemberId(Map<String, Object> d) {
        Object id = d.get("memberId");
        if (id == null) id = d.get("MEMBERID");
        if (id == null) id = d.get("member_id");
        if (id == null) id = d.get("MEMBER_ID");
        return id;
    }

    private boolean isSameMember(Object a, Object b) {
        if (a == null || b == null) return false;
        try { return toLong(a) == toLong(b); }
        catch (NumberFormatException e) { return String.valueOf(a).equals(String.valueOf(b)); }
    }

    private long toLong(Object v) {
        if (v instanceof Number) return ((Number) v).longValue();
        String s = String.valueOf(v).trim();
        int dot = s.indexOf('.');
        if (dot >= 0) s = s.substring(0, dot);
        return Long.parseLong(s);
    }
}
