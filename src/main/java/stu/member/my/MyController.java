package stu.member.my;

/*
 * ============================================================
 * Project    : 관제 티켓 (Ticketing System)
 * Package    : stu.member.my
 * FileName   : MyController.java
 *
 * Developer  : 김희재 (feature/khj)
 * Created    : 2026.05.24
 * Modified   : 2026.05.26
 *
 * Description :
 *   - 마이페이지 Controller
 *   - URL 매핑:
 *       GET  /my/info.do          → 회원정보 조회 (memberModify.jsp)
 *       POST /my/info.do          → 회원정보 수정
 *       GET  /my/bookingList.do   → 예매 내역 조회 (myBookingList.jsp)
 *       POST /my/delete.do        → 회원 탈퇴 (예매 있으면 차단)
 *
 *   - 예매 취소는 성우님(booking 모듈)의 /bookingDetail.do 페이지에서 처리
 *
 *   - 세션 키 (batman 컨벤션):
 *       SESSION_ID    : email
 *       SESSION_NO    : 회원번호(member_id 숫자) ← 본인이 사용
 *       SESSION_NAME  : 이름
 * ============================================================
 */

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpSession;

import org.apache.log4j.Logger;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import stu.common.common.CommandMap;

@Controller
public class MyController {

    private static final Logger log = Logger.getLogger(MyController.class);

    @Resource(name = "myService")
    private MyService myService;

    // =====================================================================
    // 1. 회원정보 조회 (GET /my/info.do)
    // =====================================================================
    @RequestMapping(value = "/my/info.do", method = RequestMethod.GET)
    public ModelAndView getMemberInfo(HttpSession session) throws Exception {
        ModelAndView mv = new ModelAndView();

        Object memberId = session.getAttribute("SESSION_NO");
        if (memberId == null) {
            log.debug("[MY/INFO] 미로그인 → 로그인 페이지로 이동");
            mv.setViewName("redirect:/loginForm.do");
            return mv;
        }

        Map<String, Object> param = new HashMap<String, Object>();
        param.put("MEMBER_ID", memberId);

        Map<String, Object> memberInfo = myService.getMemberInfo(param);
        mv.addObject("member", memberInfo);
        mv.setViewName("my/memberModify");

        log.debug("[MY/INFO] member_id=" + memberId);
        return mv;
    }


    // =====================================================================
    // 2. 회원정보 수정 (POST /my/info.do)
    // =====================================================================
    @RequestMapping(value = "/my/info.do", method = RequestMethod.POST)
    public ModelAndView updateMemberInfo(CommandMap commandMap, HttpSession session) throws Exception {
        ModelAndView mv = new ModelAndView();

        Object memberId = session.getAttribute("SESSION_NO");
        if (memberId == null) {
            mv.setViewName("redirect:/loginForm.do");
            return mv;
        }

        commandMap.remove("MEMBER_ID");
        commandMap.put("MEMBER_ID", memberId);

        String year  = (String) commandMap.get("BIRTH_YEAR");
        String month = (String) commandMap.get("BIRTH_MONTH");
        String day   = (String) commandMap.get("BIRTH_DAY");
        if (year != null && month != null && day != null
                && !year.isEmpty() && !month.isEmpty() && !day.isEmpty()) {
            String birth = year
                         + (month.length() == 1 ? "0" + month : month)
                         + (day.length()   == 1 ? "0" + day   : day);
            commandMap.put("BIRTH_DATE", birth);
        }

        int affected = myService.updateMemberInfo(commandMap.getMap());
        log.debug("[MY/INFO/UPDATE] member_id=" + memberId + " affected=" + affected);

        mv.setViewName("redirect:/my/info.do");
        return mv;
    }


    // =====================================================================
    // 3. 예매 내역 조회 (GET /my/bookingList.do)
    // =====================================================================
    @RequestMapping(value = "/my/bookingList.do", method = RequestMethod.GET)
    public ModelAndView getBookingList(HttpSession session) throws Exception {
        ModelAndView mv = new ModelAndView();

        Object memberId = session.getAttribute("SESSION_NO");
        if (memberId == null) {
            mv.setViewName("redirect:/loginForm.do");
            return mv;
        }

        Map<String, Object> param = new HashMap<String, Object>();
        param.put("MEMBER_ID", memberId);

        List<Map<String, Object>> bookingList = myService.getBookingList(param);
        mv.addObject("bookingList", bookingList);
        mv.setViewName("my/myBookingList");

        log.debug("[MY/BOOKING_LIST] member_id=" + memberId
                + " count=" + (bookingList == null ? 0 : bookingList.size()));
        return mv;
    }


    // =====================================================================
    // 4. 회원 탈퇴 (POST /my/delete.do)
    //    - 예매 내역(PENDING/CONFIRMED)이 있으면 탈퇴 차단
    // =====================================================================
    @RequestMapping(value = "/my/delete.do", method = RequestMethod.POST)
    public ModelAndView deleteMember(HttpSession session, RedirectAttributes ra) throws Exception {
        ModelAndView mv = new ModelAndView();

        Object memberId = session.getAttribute("SESSION_NO");
        if (memberId == null) {
            mv.setViewName("redirect:/loginForm.do");
            return mv;
        }

        Map<String, Object> param = new HashMap<String, Object>();
        param.put("MEMBER_ID", memberId);

        // 예매 내역 체크 (CANCELLED 제외, 즉 PENDING/CONFIRMED만 카운트)
        int activeBookingCount = myService.countActiveBookings(param);
        if (activeBookingCount > 0) {
            log.debug("[MY/DELETE] 차단 - member_id=" + memberId
                    + " active_bookings=" + activeBookingCount);
            ra.addFlashAttribute("deleteError",
                "예매 내역이 " + activeBookingCount + "건 있어 탈퇴할 수 없습니다.\n"
              + "예매를 먼저 취소한 뒤 다시 시도해주세요.");
            mv.setViewName("redirect:/my/info.do");
            return mv;
        }

        int affected = myService.deleteMember(param);
        log.debug("[MY/DELETE] member_id=" + memberId + " affected=" + affected);

        session.invalidate();

        mv.setViewName("redirect:/main.do");
        return mv;
    }
}