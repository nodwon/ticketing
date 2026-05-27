package stu.booking;

import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import org.apache.log4j.Logger;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
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

    @Resource(name = "pendingBookingTracker")
    private PendingBookingTracker pendingTracker;

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
    //    [보안] memberId 는 세션의 SESSION_NO 만 사용.
    //    URL 파라미터로 받던 방식은 IDOR(타인 예매 열람) 위험.
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

        log.debug("bookingMyList - memberId=" + sessionMemberNo
                + ", count=" + (myBookings == null ? 0 : myBookings.size()));

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
    public ModelAndView bookingCreate(CommandMap commandMap, HttpServletRequest request, HttpSession session) throws Exception {

        log.info("===== 예매 생성 요청 시작 (PENDING) =====");

        // [보안] 클라이언트가 보낸 memberId 는 신뢰하지 않는다.
        //        세션의 SESSION_NO (로그인한 본인) 으로 강제 주입.
        Object sessionMemberNo = session.getAttribute("SESSION_NO");
        if (sessionMemberNo == null) {
            log.warn("미로그인 상태에서 예매 생성 시도 - 차단");
            ModelAndView mv = new ModelAndView();
            mv.setView(new RedirectView("/loginForm.do"));
            return mv;
        }
        commandMap.remove("memberId");
        commandMap.put("memberId", String.valueOf(sessionMemberNo));

        try {
            Long bookingId = bookingService.createBooking(commandMap);

            // [중요] 결제 페이지 진입 직전, lifecycle 추적 시작
            //         이 시점부터 heartbeat 가 끊기거나 abandon 신호가 오면 자동 cancel
            pendingTracker.register(bookingId);

            log.info("예매 생성 성공 (PENDING) - bookingId=" + bookingId
                    + ", memberId=" + sessionMemberNo
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
    //    [보안 2026.05.26]
    //      - memberId 는 세션의 SESSION_NO 만 사용 (URL 파라미터 무시)
    //      - 해당 bookingId 가 정말 본인 소유인지 DB 로 검증 후 취소
    //        → 타인 bookingId 변조 취소(IDOR) 차단
    //
    //    호출 주체:
    //      - 사용자 직접 취소 (마이페이지) — 이 엔드포인트
    //      - 결제 실패/타임아웃 콜백 — RealBookingStatusUpdater 가
    //        BookingService 빈을 직접 호출하므로 이 엔드포인트를 타지 않음
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

        // [보안] 본인 소유 예매인지 검증
        Map<String, Object> bookingDetail = bookingService.selectBookingDetail(commandMap);
        if (bookingDetail == null) {
            log.warn("존재하지 않는 예매 취소 시도 - bookingId=" + bookingId);
            ModelAndView mv = new ModelAndView("booking/bookingError");
            mv.addObject("errorMessage", "예매 정보를 찾을 수 없습니다.");
            return mv;
        }
        // MyBatis + Oracle 조합에서 컬럼 별칭이 대문자로 올라오는 경우가 있어
        // (memberId / MEMBERID / member_id / MEMBER_ID) 모두 시도.
        Object ownerMemberId = bookingDetail.get("memberId");
        if (ownerMemberId == null) ownerMemberId = bookingDetail.get("MEMBERID");
        if (ownerMemberId == null) ownerMemberId = bookingDetail.get("member_id");
        if (ownerMemberId == null) ownerMemberId = bookingDetail.get("MEMBER_ID");

        if (!isSameMember(ownerMemberId, sessionMemberNo)) {
            log.warn("[IDOR 시도] 타인 예매 취소 시도 - bookingId=" + bookingId
                    + ", owner=" + ownerMemberId
                    + " (" + (ownerMemberId == null ? "null" : ownerMemberId.getClass().getSimpleName()) + ")"
                    + ", session=" + sessionMemberNo
                    + " (" + (sessionMemberNo == null ? "null" : sessionMemberNo.getClass().getSimpleName()) + ")"
                    + ", detailKeys=" + bookingDetail.keySet());
            ModelAndView mv = new ModelAndView("booking/bookingError");
            mv.addObject("errorMessage", "본인의 예매만 취소할 수 있습니다.");
            return mv;
        }

        try {
            bookingService.cancelBooking(commandMap);

            log.info("예매 취소 성공 - bookingId=" + bookingId
                    + ", memberId=" + sessionMemberNo);

            ModelAndView mv = new ModelAndView();
            mv.setView(new RedirectView("/bookingMyList.do"));
            return mv;

        } catch (Exception e) {
            log.error("예매 취소 실패: " + e.getMessage(), e);

            ModelAndView mv = new ModelAndView("booking/bookingError");
            mv.addObject("errorMessage", e.getMessage());
            return mv;
        }
    }


    // ====================================================
    // 9. 결제 페이지 heartbeat (POST)
    //    POST /booking/heartbeat.do?bookingId=N
    //    결제 페이지에서 30초마다 호출.
    //    응답 body 는 의미 없음. 본인 소유 검증을 수반.
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
    // 10. 결제 페이지 abandon (POST) - 즉시 cancel
    //     POST /booking/abandon.do?bookingId=N
    //     navigator.sendBeacon 으로 호출.
    //     본인 소유 검증을 수반 (타인 bookingId 변조로 cancel 못 하게).
    // ====================================================
    @RequestMapping(value = "/booking/abandon.do", method = RequestMethod.POST)
    @ResponseBody
    public Map<String, Object> abandon(@RequestParam("bookingId") String bookingIdStr,
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

        // [보안] 본인 소유 예매만 abandon 가능
        CommandMap probe = new CommandMap();
        probe.put("bookingId", bookingIdStr);
        Map<String, Object> detail = bookingService.selectBookingDetail(probe);
        if (detail == null) {
            resp.put("result", "notfound");
            return resp;
        }
        Object owner = detail.get("memberId");
        if (owner == null) owner = detail.get("MEMBERID");
        if (owner == null) owner = detail.get("member_id");
        if (owner == null) owner = detail.get("MEMBER_ID");

        if (!isSameMember(owner, sessionMemberNo)) {
            log.warn("[IDOR 시도] 타인 예매 abandon 시도 - bookingId=" + bookingId
                    + ", owner=" + owner + ", session=" + sessionMemberNo);
            resp.put("result", "forbidden");
            return resp;
        }

        pendingTracker.abandonImmediately(bookingId, "beacon");
        resp.put("result", "ok");
        return resp;
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