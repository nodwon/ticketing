/**
 * ============================================================
 * Project  : 관제 티켓 (Ticketing System)
 * Package  : stu.board.notice
 * FileName : NoticeController.java
 *
 * Developer : dw (feature/dw)
 * Created   : 2026.05.22
 * Modified  : 2026.05.28 - 권한 체크 + SecurityLogger 통합
 *
 * Description :
 *   - 공지사항 컨트롤러
 *   - ★ 보안 패치: 일반 사용자가 URL 직접 호출로 수정/삭제 못하게 차단
 *   - ★ 무단 접근 시 log_admin_access.json 자동 기록
 * ============================================================
 */
package stu.board.notice;

import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.servlet.ModelAndView;

import stu.common.common.CommandMap;
import stu.common.logger.SecurityLogger;

@Controller
public class NoticeController {

    private static final Logger log = LoggerFactory.getLogger(NoticeController.class);

    @Resource(name = "noticeService")
    private NoticeService noticeService;

    // ====================================================
    // 공지사항 목록 페이지 (모두 접근 가능)
    // ====================================================
    @RequestMapping(value = "/notice/openNoticeList.do")
    public ModelAndView openNoticeList(CommandMap commandMap) throws Exception {
        ModelAndView mv = new ModelAndView("/board/noticeList");
        return mv;
    }

    // ====================================================
    // 공지사항 목록 데이터 (Ajax)
    // ====================================================
    @RequestMapping(value = "/notice/selectNoticeList.do")
    public ModelAndView selectNoticeList(CommandMap commandMap) throws Exception {
        ModelAndView mv = new ModelAndView("jsonView");
        List<Map<String, Object>> list = noticeService.selectNoticeList(commandMap.getMap());
        mv.addObject("list", list);
        if (list.size() > 0) {
            mv.addObject("TOTAL", list.get(0).get("TOTAL_COUNT"));
        } else {
            mv.addObject("TOTAL", 0);
        }
        return mv;
    }

    // ====================================================
    // 공지사항 등록 폼 (★ ADMIN 전용)
    // ====================================================
    @RequestMapping(value = "/notice/openNoticeWrite.do")
    public ModelAndView openNoticeWrite(CommandMap commandMap,
            HttpServletRequest request, HttpSession session) throws Exception {
        
        if (!checkAdmin("/notice/openNoticeWrite.do", request, session)) {
            return new ModelAndView("redirect:/notice/openNoticeList.do");
        }
        
        return new ModelAndView("/board/noticeWrite");
    }

    // ====================================================
    // 공지사항 등록 처리 (★ ADMIN 전용)
    // ====================================================
    @RequestMapping(value = "/notice/insertNotice.do")
    public ModelAndView insertNotice(CommandMap commandMap,
            HttpServletRequest request, HttpSession session) throws Exception {
        
        ModelAndView mv = new ModelAndView("redirect:/notice/openNoticeList.do");
        
        if (!checkAdmin("/notice/insertNotice.do", request, session)) {
            return mv;
        }
        
        noticeService.insertNotice(commandMap.getMap(), request);
        
        // 보안 로그: 공지 등록 감사
        Long userId = getSessionUserId(session);
        String content = (String) commandMap.get("NOTICE_CONTENT");
        SecurityLogger.board(
            userId,
            "NOTICE",
            content != null && content.length() > 200 ? content.substring(0, 200) : content,
            null,
            null
        );
        
        log.info("공지사항 등록 - userId={}, title={}", userId, commandMap.get("NOTICE_TITLE"));
        return mv;
    }

    // ====================================================
    // 공지사항 상세 (모두 접근 가능)
    // ====================================================
    @RequestMapping(value = "/notice/openNoticeDetail.do")
    public ModelAndView openNoticeDetail(CommandMap commandMap) throws Exception {
        ModelAndView mv = new ModelAndView("/board/noticeDetail");
        Map<String, Object> map = noticeService.selectNoticeDetail(commandMap.getMap());
        mv.addObject("map", map.get("map"));
        mv.addObject("list", map.get("list"));
        return mv;
    }

    // ====================================================
    // 공지사항 수정 폼 (★ ADMIN 전용 - URL 직접 호출 차단!)
    // ====================================================
    @RequestMapping(value = "/notice/openNoticeUpdate.do")
    public ModelAndView openNoticeUpdate(CommandMap commandMap,
            HttpServletRequest request, HttpSession session) throws Exception {
        
        // ★★ 권한 체크: 일반 사용자가 URL 직접 입력해도 차단
        if (!checkAdmin("/notice/openNoticeUpdate.do", request, session)) {
            return new ModelAndView("redirect:/notice/openNoticeList.do");
        }
        
        ModelAndView mv = new ModelAndView("/board/noticeUpdate");
        Map<String, Object> map = noticeService.selectNoticeDetail(commandMap.getMap());
        mv.addObject("map", map.get("map"));
        mv.addObject("list", map.get("list"));
        return mv;
    }

    // ====================================================
    // 공지사항 수정 처리 (★ ADMIN 전용)
    // ====================================================
    @RequestMapping(value = "/notice/updateNotice.do")
    public ModelAndView updateNotice(CommandMap commandMap,
            HttpServletRequest request, HttpSession session) throws Exception {
        
        ModelAndView mv = new ModelAndView("redirect:/notice/openNoticeDetail.do");
        
        if (!checkAdmin("/notice/updateNotice.do", request, session)) {
            return new ModelAndView("redirect:/notice/openNoticeList.do");
        }
        
        noticeService.updateNotice(commandMap.getMap(), request);
        
        // 보안 로그: 공지 수정 감사
        Long userId = getSessionUserId(session);
        String content = (String) commandMap.get("NOTICE_CONTENT");
        SecurityLogger.board(
            userId,
            "NOTICE_UPDATE",
            content != null && content.length() > 200 ? content.substring(0, 200) : content,
            null,
            null
        );
        
        log.info("공지사항 수정 - userId={}, NOTICE_NO={}", userId, commandMap.get("NOTICE_NO"));
        
        mv.addObject("NOTICE_NO", commandMap.get("NOTICE_NO"));
        return mv;
    }

    // ====================================================
    // 공지사항 삭제 (★ ADMIN 전용 - URL 직접 호출 차단!)
    // ====================================================
    @RequestMapping(value = "/notice/deleteNotice.do")
    public ModelAndView deleteNotice(CommandMap commandMap,
            HttpServletRequest request, HttpSession session) throws Exception {
        
        ModelAndView mv = new ModelAndView("redirect:/notice/openNoticeList.do");
        
        // ★★ 권한 체크: URL 직접 호출 시도 차단
        if (!checkAdmin("/notice/deleteNotice.do", request, session)) {
            return mv;
        }
        
        noticeService.deleteNotice(commandMap.getMap());
        
        // 보안 로그: 공지 삭제 감사 (중요!)
        Long userId = getSessionUserId(session);
        log.warn("공지사항 삭제 - userId={}, NOTICE_NO={}", userId, commandMap.get("NOTICE_NO"));
        
        return mv;
    }

    // ====================================================
    // ★ 헬퍼: 관리자 권한 체크 + 보안 로그 자동 기록
    //   - ADMIN 아니면 → log_admin_access.json 에 403 기록 후 false 반환
    //   - ADMIN 이면 → 200 기록 후 true 반환
    // ====================================================
    private boolean checkAdmin(String accessUrl, HttpServletRequest request, HttpSession session) {
        String role = (String) session.getAttribute("SESSION_GRADE");
        Long userId = getSessionUserId(session);
        String srcIp = request.getRemoteAddr();
        
        if (!"ADMIN".equals(role)) {
            // ★★ 무단 접근 시도 탐지 → 보안 로그 기록
            SecurityLogger.adminAccess(accessUrl, userId, srcIp, 403);
            log.warn("[SECURITY] 무단 공지사항 관리 시도 - URL={}, userId={}, role={}, ip={}",
                accessUrl, userId, role, srcIp);
            return false;
        }
        
        // 정상 관리자 접근 감사 로그
        SecurityLogger.adminAccess(accessUrl, userId, srcIp, 200);
        return true;
    }

    private Long getSessionUserId(HttpSession session) {
        if (session == null) return null;
        Object idObj = session.getAttribute("SESSION_NO");
        if (idObj == null) return null;
        if (idObj instanceof Number) return ((Number) idObj).longValue();
        try {
            return Long.parseLong(String.valueOf(idObj));
        } catch (NumberFormatException e) {
            return null;
        }
    }
}
