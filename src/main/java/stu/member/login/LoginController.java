/**
 * ============================================================
 * Project   : 관제 티켓 (Ticketing System)
 * Package   : stu.member.login
 * FileName  : LoginController.java
 *
 * Developer : 심재학 (feature/batman)
 * Created   : 2026.05.25
 * Modified  : 2026.05.28 - SecurityLogger + SESSION_GRADE 추가
 *
 * Description :
 *   - 로그인 폼 / 로그인 처리 / 로그아웃
 *   - 아이디(이메일) 찾기 / 비밀번호 초기화
 *   - ★ SESSION_GRADE 세션 저장 (ADMIN/USER) → 관리자 권한 체크 가능
 *   - ★ Brute Force / 크리덴셜 스터핑 탐지 → log_auth.json
 * ============================================================
 */
package stu.member.login;

import java.util.Map;
import java.util.Random;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import org.springframework.security.crypto.bcrypt.BCrypt;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import stu.common.common.CommandMap;
import stu.common.logger.SecurityLogger;
import stu.member.join.JoinService;

@Controller
public class LoginController {

	private static final Logger log = LoggerFactory.getLogger(LoginController.class);

	@Resource(name = "loginService")
	private LoginService loginService;

	@Resource(name = "joinService")
	private JoinService joinService;


	@RequestMapping(value = "/loginForm.do")
	public ModelAndView loginForm(
	        @RequestParam(value = "returnUrl", required = false) String returnUrl,
	        CommandMap commandMap) throws Exception {
	    ModelAndView mv = new ModelAndView("login/loginForm");
	    
	    if (returnUrl != null && !returnUrl.isEmpty()) {
	        mv.addObject("returnUrl", returnUrl);
	    }
	    
	    return mv;
	}

	// 로그인 처리 (★ SESSION_GRADE 추가)
	@RequestMapping(value = "/loginAction.do", method = RequestMethod.POST)
	public ModelAndView loginAction(CommandMap commandMap, HttpServletRequest request) throws Exception {
	    ModelAndView mv = new ModelAndView();
	    HttpSession session = request.getSession();

	    String returnUrl = (String) commandMap.get("returnUrl");
	    String srcIp = request.getRemoteAddr();

	    Map<String, Object> chk = loginService.loginAction(commandMap.getMap());

		if (chk == null) {
			// 존재하지 않는 아이디
			SecurityLogger.auth(null, srcIp, "FAIL");
			
			mv.setViewName("login/loginForm");
			mv.addObject("message", "해당 아이디 혹은 비밀번호가 일치하지 않습니다.");
			return mv;
		} else {
			if (chk.get("MEMBER_DELETE").equals("1")) {
				// 탈퇴 회원
				Long deletedUserId = chk.get("MEMBER_NO") != null 
					? ((Number) chk.get("MEMBER_NO")).longValue() : null;
				SecurityLogger.auth(deletedUserId, srcIp, "FAIL");
				
				mv.setViewName("login/loginForm");
				mv.addObject("message", "탈퇴한 회원 입니다.");
			} else {
			    String plainPassword = (String) commandMap.get("MEMBER_PASSWD");
			    String hashedPassword = (String) chk.get("MEMBER_PASSWD");
			    Long userId = chk.get("MEMBER_NO") != null
			    	? ((Number) chk.get("MEMBER_NO")).longValue() : null;
			    
			    if (BCrypt.checkpw(plainPassword, hashedPassword)) {
			        // 로그인 성공
			        SecurityLogger.auth(userId, srcIp, "SUCCESS");
			        
			        session.setAttribute("SESSION_ID", chk.get("MEMBER_ID"));
			        session.setAttribute("SESSION_NO", chk.get("MEMBER_NO"));
			        session.setAttribute("SESSION_NAME", chk.get("MEMBER_NAME"));
			        
			        // ★★★ 핵심: 권한(ADMIN/USER) 세션에 저장
			        // DB의 role 컬럼 → MEMBER_GRADE 별칭으로 조회됨
			        Object grade = chk.get("MEMBER_GRADE");
			        if (grade == null) grade = chk.get("ROLE");
			        if (grade == null) grade = chk.get("role");
			        session.setAttribute("SESSION_GRADE", grade != null ? String.valueOf(grade) : "USER");

			        String redirectUrl = isValidReturnUrl(returnUrl) ? returnUrl : "/main.do";
			        mv = new ModelAndView("redirect:" + redirectUrl);
			        mv.addObject("MEMBER", chk);

			        session.getMaxInactiveInterval();
			        
			        log.info("로그인 성공: id={}, grade={}", chk.get("MEMBER_ID"), grade);
			    } else {
			        // 비밀번호 불일치 (Brute Force 후보)
			        SecurityLogger.auth(userId, srcIp, "FAIL");
			        
			        mv.setViewName("login/loginForm");
			        mv.addObject("message", "해당 아이디 혹은 비밀번호가 일치하지 않습니다.");
			        log.warn("로그인 실패(비밀번호 불일치): {}", commandMap.get("MEMBER_ID"));
			    }
			}
			return mv;
	    }
	}

	private boolean isValidReturnUrl(String returnUrl) {
	    if (returnUrl == null || returnUrl.isEmpty()) return false;
	    if (returnUrl.startsWith("//")) return false;
	    String lower = returnUrl.toLowerCase();
	    if (lower.startsWith("http://") || lower.startsWith("https://")) return false;
	    if (!returnUrl.startsWith("/")) return false;
	    return true;
	}

	@RequestMapping(value = "/logout.do", method = RequestMethod.POST)
	@ResponseBody
	public Map<String, Object> logout(HttpServletRequest request, @RequestBody Map<String, Object> map) throws Exception {

		HttpSession session = request.getSession(false);
		if (session != null) session.invalidate();

		String url = request.getScheme() + "://" + request.getServerName() + ":" + request.getServerPort()
				+ request.getContextPath() + "/main.do";
		map.put("URL", url);

		return map;
	}

	@RequestMapping(value = "/findId.do")
	public ModelAndView findId(CommandMap commandMap) throws Exception {
		return new ModelAndView("login/findId");
	}

	@RequestMapping(value = "/findIdAction.do", method = RequestMethod.POST)
	public String selectSearchMyId(HttpSession session, CommandMap commandMap, 
			RedirectAttributes ra, HttpServletRequest request) throws Exception {
		String email = (String) commandMap.get("MEMBER_EMAIL");
		String srcIp = request.getRemoteAddr();
		
		Map<String, Object> map = loginService.selectFindId(commandMap.getMap());
		if (map == null) {
			SecurityLogger.adminAccess("/findIdAction.do", null, srcIp, 404);
			ra.addFlashAttribute("resultMsg", "입력된 정보가 일치하지 않습니다.");
			return "redirect:/findId.do";
		}
		String user_name = (String) map.get("MEMBER_NAME");
		String user = (String) map.get("MEMBER_ID");

		ra.addFlashAttribute("resultMsg", "귀하의 아이디는 " + user + " 입니다.");
		ra.addFlashAttribute("isResult", "1");

		return "redirect:/findId.do";
	}

	@RequestMapping(value = "/findPw.do")
	public ModelAndView findPw(CommandMap commandMap) throws Exception {
		return new ModelAndView("login/findPw");
	}

	@RequestMapping(value = "/findPwAction.do", method = RequestMethod.POST)
	public String sendMailPassword(HttpSession session, CommandMap commandMap, 
			RedirectAttributes ra, HttpServletRequest request) throws Exception {
		String email = (String) commandMap.get("MEMBER_EMAIL");
		String srcIp = request.getRemoteAddr();
		
		String user = loginService.selectFindPw(commandMap.getMap());

		if (user == null) {
			SecurityLogger.adminAccess("/findPwAction.do", null, srcIp, 404);
			ra.addFlashAttribute("resultMsg", "입력된 정보가 일치하지 않습니다.");
			return "redirect:/findPw.do";
		}

		int ran = new Random().nextInt(100000) + 10000;
		String password = String.valueOf(ran);

		// 임시 비밀번호를 BCrypt 해시로 저장 (로그인 시 BCrypt.checkpw 검증과 일치)
		commandMap.put("MEMBER_PASSWD", BCrypt.hashpw(password, BCrypt.gensalt()));
		loginService.updatePw(commandMap.getMap());

		ra.addFlashAttribute("resultMsg", "귀하의 임시 비밀번호는 " + password + " 입니다.");
		ra.addFlashAttribute("isResult", "1");

		return "redirect:/findPw.do";
	}
}
