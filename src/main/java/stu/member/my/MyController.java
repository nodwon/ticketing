package stu.member.my;

/*
 * ============================================================
 * Project    : 관제 티켓 (Ticketing System)
 * Package    : stu.member.my
 * FileName   : MyController.java
 *
 * Developer  : 김희재 (feature/khj)
 * Created    : 2026.05.24
 * Modified   : 2026.05.24
 *
 * Description :
 *   - 마이페이지 Controller
 *   - URL 매핑:
 *       GET  /my/info.do        → 회원정보 조회
 *       POST /my/info.do        → 회원정보 수정
 *       GET  /my/bookingList.do → 예매 내역 조회
 *       POST /my/delete.do      → 회원 탈퇴
 *
 *   - 세션 키 (로그인 모듈과 협의 필요):
 *       MEMBER_ID : members.member_id (NUMBER)
 *       EMAIL     : 로그인 이메일
 *       NAME      : 회원명
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

        // 로그인 체크
        Object memberId = session.getAttribute("memberId");
        if (memberId == null) {
            log.debug("[MY/INFO] 미로그인 → 로그인 페이지로 이동");
            mv.setViewName("redirect:/member/loginForm.do");
            return mv;
        }

        Map<String, Object> param = new HashMap<String, Object>();
        param.put("MEMBER_ID", memberId);

        Map<String, Object> memberInfo = myService.getMemberInfo(param);
        mv.addObject("member", memberInfo);
        mv.setViewName("my/info");

        log.debug("[MY/INFO] member_id=" + memberId);
        return mv;
    }


    // =====================================================================
    // 2. 회원정보 수정 (POST /my/info.do)
    //    - 이름, 휴대폰, 생년월일만 수정 가능
    //    - 이메일/비번/role 은 별도 메뉴 (권한 상승 방지)
    //    - MEMBER_ID 는 세션값으로 강제 (파라미터 변조 차단)
    // =====================================================================
    @RequestMapping(value = "/my/info.do", method = RequestMethod.POST)
    public ModelAndView updateMemberInfo(CommandMap commandMap, HttpSession session) throws Exception {
        ModelAndView mv = new ModelAndView();

        Object memberId = session.getAttribute("memberId");
        if (memberId == null) {
            mv.setViewName("redirect:/member/loginForm.do");
            return mv;
        }

        // 세션 값 강제 적용 (요청 파라미터의 MEMBER_ID 는 무시)
        commandMap.remove("MEMBER_ID");
        commandMap.put("MEMBER_ID", memberId);

        // 생년월일 조립 (YYYY + MM + DD → YYYYMMDD)
        String year  = (String) commandMap.get("BIRTH_YEAR");
        String month = (String) commandMap.get("BIRTH_MONTH");
        String day   = (String) commandMap.get("BIRTH_DAY");
        if (year != null && month != null && day != null) {
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

        Object memberId = session.getAttribute("memberId");
        if (memberId == null) {
            mv.setViewName("redirect:/member/loginForm.do");
            return mv;
        }

        Map<String, Object> param = new HashMap<String, Object>();
        param.put("MEMBER_ID", memberId);

        List<Map<String, Object>> bookingList = myService.getBookingList(param);
        mv.addObject("bookingList", bookingList);
        mv.setViewName("my/bookingList");

        log.debug("[MY/BOOKING_LIST] member_id=" + memberId
                + " count=" + (bookingList == null ? 0 : bookingList.size()));
        return mv;
    }


    // =====================================================================
    // 4. 회원 탈퇴 (POST /my/delete.do)
    //    - 물리 삭제 (요구사항 기준)
    //    - 탈퇴 후 세션 무효화
    // =====================================================================
    @RequestMapping(value = "/my/delete.do", method = RequestMethod.POST)
    public ModelAndView deleteMember(HttpSession session) throws Exception {
        ModelAndView mv = new ModelAndView();

        Object memberId = session.getAttribute("memberId");
        if (memberId == null) {
            mv.setViewName("redirect:/member/loginForm.do");
            return mv;
        }

        Map<String, Object> param = new HashMap<String, Object>();
        param.put("MEMBER_ID", memberId);

        int affected = myService.deleteMember(param);
        log.debug("[MY/DELETE] member_id=" + memberId + " affected=" + affected);

        // 세션 종료
        session.invalidate();

        mv.setViewName("redirect:/main.do");
        return mv;
    }
}
