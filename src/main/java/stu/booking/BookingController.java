package stu.booking;

import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import org.slf4j.Logger;                                  // ★ slf4j 교체
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.view.RedirectView;

import stu.common.common.CommandMap;
import stu.common.logger.SecurityLogger;                  // ★★ 추가

/**
 * 예매(Booking) 도메인 Controller
 * 
 * [URL 매핑]
 *   GET  /bookingSeatList.do    좌석 현황 (AJAX, JSON)
 *   GET  /bookingDetail.do      예매 상세 화면
 *   GET  /bookingMyList.do      내 예매 목록
 *   POST /bookingCreate.do      예매 생성 처리 (PENDING) ★보안로그★
 *   GET  /bookingComplete.do    예매 완료 화면
 *   POST /bookingConfirm.do     예매 확정 처리
 *   POST /bookingCancel.do      예매 취소 처리 ★보안로그★
 *
 * [Modified 2026.05.27]
 *   - SecurityLogger 통합 (예매 봇 / IDOR 시도 탐지 → log_seat.json)
 */
@Controller
public class BookingController {

    private static final Logger log = LoggerFactory.getLogger(BookingController.class);

    @Resource(name = "bookingService")
    private BookingService bookingService;

    @Resource(name = "pendingBookingTracker")
    private PendingBookingTracker pendingTracker;

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
    public ModelAndView bookingDetail(CommandMap commandMap, HttpServletRequest request, HttpSession session) throws Exception {

        ModelAndView mv = new ModelAndView("booking/detail");

        String bookingId = request.getParameter("bookingId");
        commandMap.put("bookingId", bookingId);

        Map<String, Object> bookingDetail = bookingService.selectBookingDetail(commandMap);
        mv.addObject("bookingDetail", bookingDetail);

        List<Map<String, Object>> bookingItems = bookingService.selectBookingItems(commandMap);
        mv.addObject("bookingItems", bookingItems);

        // ★★ 보안 로그: 본인 예매가 아닌 경우 IDOR 시도 탐지
        Object sessionMemberNo = session.getAttribute("SESSION_NO");
        if (bookingDetail != null && sessionMemberNo != null) {
            Object ownerMemberId = extractMemberId(bookingDetail);
            if (ownerMemberId != null && !isSameMember(ownerMemberId, sessionMemberNo)) {
                // IDOR 시도 - 관리자 접근 로그로 기록
                Long currentUserId = ((Number) sessionMemberNo).longValue();
                SecurityLogger.adminAccess(
                    "/bookingDetail.do?bookingId=" + bookingId,
                    currentUserId,
                    request.getRemoteAddr(),
                    403
                );
                log.warn("[IDOR 시도] 타인 예매 상세 조회 - bookingId={}, owner={}, session={}",
                    bookingId, ownerMemberId, sessionMemberNo);
            }
        }

        log.debug("bookingDetail - bookingId={}", bookingId);
        return mv;
    }

    // ====================================================
    // 4. 내 예매 목록
    // ====================================================
    @RequestMapping(value = "/bookingMyList.do", method = RequestMethod.GET)
    public ModelAndView bookingMyList(CommandMap commandMap, HttpServletRequest request, HttpSession session) throws Exception {

        ModelAndView mv = new ModelAndView();

        Object sessionMemberNo = session.getAttribute("SESSION_NO");
        if (sessionMemberNo == null) {
            log.warn("미로그인 상태에서 내 예매 목록 조회 시도 - 차단");
            mv.setView(new RedirectView("/loginForm.do"));
            return mv;
        }

        commandMap.remove("memberId");
        commandMap.put("memberId", String.valueOf(sessionMemberNo));

        List<Map<String, Object>> myBookings = bookingService.selectMyBookings(commandMap);
        mv.addObject("myBookings", myBookings);
        mv.setViewName("booking/myList");

        log.debug("bookingMyList - memberId={}, count={}", sessionMemberNo, 
            myBookings == null ? 0 : myBookings.size());

        return mv;
    }

    // ====================================================
    // 5. 예매 생성 처리 (POST) ★★보안로그★★
    // ====================================================
    @RequestMapping(value = "/bookingCreate.do", method = RequestMethod.POST)
    public ModelAndView bookingCreate(CommandMap commandMap, HttpServletRequest request, HttpSession session) throws Exception {

        log.info("===== 예매 생성 요청 시작 (PENDING) =====");
        
        // ★ 매크로 탐지용 시간 측정
        long startTime = System.currentTimeMillis();

        Object sessionMemberNo = session.getAttribute("SESSION_NO");
        if (sessionMemberNo == null) {
            log.warn("미로그인 상태에서 예매 생성 시도 - 차단");
            ModelAndView mv = new ModelAndView();
            mv.setView(new RedirectView("/loginForm.do"));
            return mv;
        }
        commandMap.remove("memberId");
        commandMap.put("memberId", String.valueOf(sessionMemberNo));
        
        Long memberId = ((Number) sessionMemberNo).longValue();
        String scheduleIdStr = (String) commandMap.get("scheduleId");
        String seatIdsStr = (String) commandMap.get("seatIds");

        try {
            Long bookingId = bookingService.createBooking(commandMap);
            pendingTracker.register(bookingId);

            log.info("예매 생성 성공 - bookingId={}, memberId={}", bookingId, sessionMemberNo);

            // ★★ 보안 로그: 좌석별 SUCCESS 기록 (매크로 / 예매봇 탐지)
            int elapsedMs = (int)(System.currentTimeMillis() - startTime);
            recordSeatLogs(memberId, scheduleIdStr, seatIdsStr, "SUCCESS", elapsedMs);

            ModelAndView mv = new ModelAndView();
            mv.setView(new RedirectView("/payment/form.do?bookingId=" + bookingId, false));
            return mv;

        } catch (Exception e) {
            log.error("예매 생성 실패: {}", e.getMessage(), e);
            
            // ★★ 보안 로그: FAIL 기록
            int elapsedMs = (int)(System.currentTimeMillis() - startTime);
            recordSeatLogs(memberId, scheduleIdStr, seatIdsStr, "FAIL", elapsedMs);

            ModelAndView mv = new ModelAndView("booking/bookingError");
            mv.addObject("errorMessage", e.getMessage());
            mv.addObject("scheduleId", request.getParameter("scheduleId"));
            return mv;
        }
    }

    // ====================================================
    // 6. 예매 완료 화면 (GET)
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

        log.debug("bookingComplete - bookingId={}", bookingId);
        return mv;
    }

    // ====================================================
    // 7. 예매 확정 처리 (POST)
    // ====================================================
    @RequestMapping(value = "/bookingConfirm.do", method = RequestMethod.POST)
    public ModelAndView bookingConfirm(CommandMap commandMap, HttpServletRequest request) throws Exception {

        log.info("===== 예매 확정 요청 시작 (결제 모듈 호출) =====");

        try {
            bookingService.confirmBooking(commandMap);
            String bookingId = (String) commandMap.get("bookingId");
            log.info("예매 확정 성공 - bookingId={}", bookingId);

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

    // ====================================================
    // 8. 예매 취소 처리 (POST) ★★보안로그★★
    // ====================================================
    @RequestMapping(value = "/bookingCancel.do", method = RequestMethod.POST)
    public ModelAndView bookingCancel(CommandMap commandMap, HttpServletRequest request, HttpSession session) throws Exception {

        log.info("===== 예매 취소 요청 시작 =====");

        Object sessionMemberNo = session.getAttribute("SESSION_NO");
        if (sessionMemberNo == null) {
            log.warn("미로그인 상태에서 예매 취소 시도 - 차단");
            ModelAndView mv = new ModelAndView();
            mv.setView(new RedirectView("/loginForm.do"));
            return mv;
        }

        String bookingId = (String) commandMap.get("bookingId");
        if (bookingId == null || bookingId.isEmpty()) {
            log.warn("bookingId 누락 - 차단");
            ModelAndView mv = new ModelAndView("booking/bookingError");
            mv.addObject("errorMessage", "필수 파라미터 누락: bookingId");
            return mv;
        }

        Map<String, Object> bookingDetail = bookingService.selectBookingDetail(commandMap);
        if (bookingDetail == null) {
            log.warn("존재하지 않는 예매 취소 시도 - bookingId={}", bookingId);
            ModelAndView mv = new ModelAndView("booking/bookingError");
            mv.addObject("errorMessage", "예매 정보를 찾을 수 없습니다.");
            return mv;
        }
        
        Object ownerMemberId = extractMemberId(bookingDetail);

        if (!isSameMember(ownerMemberId, sessionMemberNo)) {
            log.warn("[IDOR 시도] 타인 예매 취소 시도 - bookingId={}, owner={}, session={}",
                bookingId, ownerMemberId, sessionMemberNo);
            
            // ★★ 보안 로그: IDOR 공격 시도 기록
            Long currentUserId = ((Number) sessionMemberNo).longValue();
            SecurityLogger.adminAccess(
                "/bookingCancel.do?bookingId=" + bookingId,
                currentUserId,
                request.getRemoteAddr(),
                403
            );
            
            ModelAndView mv = new ModelAndView("booking/bookingError");
            mv.addObject("errorMessage", "본인의 예매만 취소할 수 있습니다.");
            return mv;
        }

        try {
            bookingService.cancelBooking(commandMap);
            log.info("예매 취소 성공 - bookingId={}, memberId={}", bookingId, sessionMemberNo);

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

    // ====================================================
    // 9. heartbeat (POST)
    // ====================================================
    @RequestMapping(value = "/booking/heartbeat.do", method = RequestMethod.POST)
    @ResponseBody
    public Map<String, Object> heartbeat(@RequestParam("bookingId") String bookingIdStr,
                                         HttpSession session) {
        Map<String, Object> resp = new java.util.HashMap<String, Object>();
        Object sessionMemberNo = session.getAttribute("SESSION_NO");
        if (sessionMemberNo == null) {
            resp.put("result", "unauth");
            return resp;
        }
        try {
            long bookingId = Long.parseLong(bookingIdStr);
            pendingTracker.heartbeat(bookingId);
            resp.put("result", "ok");
        } catch (NumberFormatException e) {
            resp.put("result", "bad");
        }
        return resp;
    }

    // ====================================================
    // 10. abandon (POST)
    // ====================================================
    @RequestMapping(value = "/booking/abandon.do", method = RequestMethod.POST)
    @ResponseBody
    public Map<String, Object> abandon(@RequestParam("bookingId") String bookingIdStr,
                                       HttpServletRequest request,
                                       HttpSession session) throws Exception {
        Map<String, Object> resp = new java.util.HashMap<String, Object>();
        Object sessionMemberNo = session.getAttribute("SESSION_NO");
        if (sessionMemberNo == null) {
            resp.put("result", "unauth");
            return resp;
        }

        long bookingId;
        try {
            bookingId = Long.parseLong(bookingIdStr);
        } catch (NumberFormatException e) {
            resp.put("result", "bad");
            return resp;
        }

        CommandMap probe = new CommandMap();
        probe.put("bookingId", bookingIdStr);
        Map<String, Object> detail = bookingService.selectBookingDetail(probe);
        if (detail == null) {
            resp.put("result", "notfound");
            return resp;
        }
        Object owner = extractMemberId(detail);

        if (!isSameMember(owner, sessionMemberNo)) {
            log.warn("[IDOR 시도] 타인 예매 abandon 시도 - bookingId={}, owner={}, session={}",
                bookingId, owner, sessionMemberNo);
            
            // ★★ 보안 로그: IDOR 시도
            Long currentUserId = ((Number) sessionMemberNo).longValue();
            SecurityLogger.adminAccess(
                "/booking/abandon.do?bookingId=" + bookingId,
                currentUserId,
                request.getRemoteAddr(),
                403
            );
            
            resp.put("result", "forbidden");
            return resp;
        }

        pendingTracker.abandonImmediately(bookingId, "beacon");
        resp.put("result", "ok");
        return resp;
    }

    // ====================================================
    // ★ 헬퍼: 좌석별 보안 로그 기록 (매크로/예매봇 탐지용)
    // ====================================================
    private void recordSeatLogs(Long memberId, String scheduleIdStr, String seatIdsStr, 
                                 String result, int elapsedMs) {
        if (memberId == null || seatIdsStr == null) return;
        
        try {
            Long scheduleId = scheduleIdStr != null ? Long.parseLong(scheduleIdStr) : null;
            String[] seatIds = seatIdsStr.split(",");
            
            for (String seatIdStr : seatIds) {
                try {
                    Long seatId = Long.parseLong(seatIdStr.trim());
                    SecurityLogger.seat(memberId, scheduleId, seatId, result, elapsedMs);
                } catch (NumberFormatException e) {
                    // ignore single seat parse error
                }
            }
        } catch (Exception e) {
            log.warn("좌석 보안 로그 기록 실패: {}", e.getMessage());
        }
    }

    // ====================================================
    // 회원 ID 추출 (대소문자 변형 대응)
    // ====================================================
    private Object extractMemberId(Map<String, Object> bookingDetail) {
        Object id = bookingDetail.get("memberId");
        if (id == null) id = bookingDetail.get("MEMBERID");
        if (id == null) id = bookingDetail.get("member_id");
        if (id == null) id = bookingDetail.get("MEMBER_ID");
        return id;
    }

    // ====================================================
    // 회원 ID 비교 헬퍼
    // ====================================================
    private boolean isSameMember(Object a, Object b) {
        if (a == null || b == null) return false;
        try {
            long la = toLong(a);
            long lb = toLong(b);
            return la == lb;
        } catch (NumberFormatException e) {
            return String.valueOf(a).equals(String.valueOf(b));
        }
    }

    private long toLong(Object v) {
        if (v instanceof Number) {
            return ((Number) v).longValue();
        }
        String s = String.valueOf(v).trim();
        int dot = s.indexOf('.');
        if (dot >= 0) s = s.substring(0, dot);
        return Long.parseLong(s);
    }
}
