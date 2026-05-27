/**
 * ============================================================
 * Project   : 관제 티켓 (Ticketing System)
 * Package   : stu.member.login
 * FileName  : LoginController.java
 *
 * Developer : 심재학 (feature/batman)
 * Modified  : 2026.05.27 by 김태희 (feature/kth)
 *
 * Description :
 *   - 로그인 폼 / 로그인 처리 / 로그아웃
 *   - 아이디(이메일) 찾기 / 비밀번호 초기화
 *
 * History :
 *   2026.05.26 - SESSION_GRADE 세션 저장 추가 (kth)
 *                · header.jsp 가 SESSION_GRADE 로 ADMIN 판정하는데
 *                  세션에 저장이 누락되어 관리자 버튼이 안 뜨던 문제 수정
 *                · 일반 로그인 + 소셜 로그인 둘 다 적용
 *   2026.05.27 - USER_BANNED 회원 로그인 차단 추가 (kth)
 *                · admin 의 회원 권한 관리 기능과 연동
 *                · USER_BANNED role 회원은 로그인 시 차단 메시지 표시
 * ============================================================
 */
package stu.member.login;

import java.util.Map;
import java.util.Random;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import org.springframework.security.crypto.bcrypt.BCrypt;
import org.apache.log4j.Logger;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import stu.common.common.CommandMap;
import stu.member.join.JoinService;

@Controller
public class LoginController {

	Logger log = Logger.getLogger(this.getClass());

	@Resource(name = "loginService")
	private LoginService loginService;

	@Resource(name = "joinService")
	private JoinService joinService;


	@RequestMapping(value = "/loginForm.do")
	public ModelAndView loginForm(
	        @RequestParam(value = "returnUrl", required = false) String returnUrl,
	        CommandMap commandMap) throws Exception {
	    ModelAndView mv = new ModelAndView("login/loginForm");

	    // returnUrl을 JSP로 전달 (hidden input에 담길 예정)
	    if (returnUrl != null && !returnUrl.isEmpty()) {
	        mv.addObject("returnUrl", returnUrl);
	    }

	    return mv;
	}

	// 로그인 이후 메인페이지 이동 (또는 returnUrl로 복귀)
	@RequestMapping(value = "/loginAction.do", method = RequestMethod.POST)
	public ModelAndView loginAction(CommandMap commandMap, HttpServletRequest request) throws Exception {
	    ModelAndView mv = new ModelAndView();
	    HttpSession session = request.getSession();

	    // returnUrl 추출 (loginForm.jsp의 hidden input에서 보냄)
	    String returnUrl = (String) commandMap.get("returnUrl");

	    Map<String, Object> chk = loginService.loginAction(commandMap.getMap());

		if (chk == null) {
			mv.setViewName("login/loginForm");
			mv.addObject("message", "해당 아이디 혹은 비밀번호가 일치하지 않습니다.");
			return mv;
		} else {
			if (chk.get("MEMBER_DELETE").equals("1")) {
				mv.setViewName("login/loginForm");
				mv.addObject("message", "탈퇴한 회원 입니다.");
			} else {
			    // 비밀번호 검증: 사용자 입력(평문) vs DB 저장(BCrypt 해시)
			    String plainPassword = (String) commandMap.get("MEMBER_PASSWD");
			    String hashedPassword = (String) chk.get("MEMBER_PASSWD");

			    if (BCrypt.checkpw(plainPassword, hashedPassword)) {

			        // ⭐ 2026.05.26 추가: USER_BANNED 회원 로그인 차단
			        // admin 페이지에서 정지 처리된 회원은 로그인 불가
			        String memberGrade = (String) chk.get("MEMBER_GRADE");
			        if ("USER_BANNED".equals(memberGrade)) {
			            mv.setViewName("login/loginForm");
			            mv.addObject("message", "정지된 계정입니다. 관리자에게 문의해주세요.");
			            log.warn("[AUDIT][login][BLOCKED] USER_BANNED 회원 로그인 시도: "
			                    + commandMap.get("MEMBER_ID")
			                    + ", ip=" + getClientIp(request));
			            return mv;
			        }

			        // 세션에 회원 정보 저장
			        session.setAttribute("SESSION_ID", chk.get("MEMBER_ID"));
			        session.setAttribute("SESSION_NO", chk.get("MEMBER_NO"));
			        session.setAttribute("SESSION_NAME", chk.get("MEMBER_NAME"));

			        // ⭐ 2026.05.26 추가: SESSION_GRADE 저장 (header.jsp 가 ADMIN 판정에 사용)
			        session.setAttribute("SESSION_GRADE", chk.get("MEMBER_GRADE"));

			        String redirectUrl = isValidReturnUrl(returnUrl) ? returnUrl : "/main.do";
			        mv = new ModelAndView("redirect:" + redirectUrl);
			        mv.addObject("MEMBER", chk);

			        session.getMaxInactiveInterval();

			        log.info("로그인 성공: " + chk.get("MEMBER_ID") + ", grade=" + memberGrade);
			    } else {
			        mv.setViewName("login/loginForm");
			        mv.addObject("message", "해당 아이디 혹은 비밀번호가 일치하지 않습니다.");

			        log.warn("로그인 실패(비밀번호 불일치): " + commandMap.get("MEMBER_ID"));
			    }
			}
			return mv;
	    }
	}

	/**
	 * returnUrl 안전성 검증 (Open Redirect 공격 방어)
	 */
	private boolean isValidReturnUrl(String returnUrl) {
	    if (returnUrl == null || returnUrl.isEmpty()) {
	        return false;
	    }
	    if (returnUrl.startsWith("//")) {
	        return false;
	    }
	    String lower = returnUrl.toLowerCase();
	    if (lower.startsWith("http://") || lower.startsWith("https://")) {
	        return false;
	    }
	    if (!returnUrl.startsWith("/")) {
	        return false;
	    }
	    return true;
	}

	/** 클라이언트 IP 추출 (X-Forwarded-For 우선 처리). */
	private String getClientIp(HttpServletRequest request) {
		String ip = request.getHeader("X-Forwarded-For");
		if (ip == null || ip.length() == 0 || "unknown".equalsIgnoreCase(ip)) {
			ip = request.getHeader("Proxy-Client-IP");
		}
		if (ip == null || ip.length() == 0 || "unknown".equalsIgnoreCase(ip)) {
			ip = request.getHeader("WL-Proxy-Client-IP");
		}
		if (ip == null || ip.length() == 0 || "unknown".equalsIgnoreCase(ip)) {
			ip = request.getRemoteAddr();
		}
		return ip;
	}

	// 소셜로그인 이후 메인페이지 이동
	@RequestMapping(value = "/socialLoginAction.do", method = RequestMethod.POST)
	@ResponseBody
	public Map<String, Object> googleLoginAction(@RequestBody Map<String, Object> map, HttpServletRequest request)
			throws Exception {

		HttpSession session = request.getSession();

		session.setAttribute("SESSION_ID", map.get("ID"));
		session.setAttribute("SESSION_NO", map.get("MEMBER_NO"));
		session.setAttribute("SESSION_NAME", map.get("Name"));

		// ⭐ 2026.05.26 추가: 소셜 로그인도 GRADE 저장 (없으면 USER 로 기본)
		Object grade = map.get("MEMBER_GRADE");
		session.setAttribute("SESSION_GRADE", grade != null ? grade : "USER");

		session.getMaxInactiveInterval();

		String url = request.getScheme() + "://" + request.getServerName() + ":" + request.getServerPort()
				+ request.getContextPath() + "/main.do";
		map.put("URL", url);

		return map;
	}

	// 네이버 로그인 Callback 페이지
	@RequestMapping(value = "/loginCallback.do")
	public ModelAndView loginCallback(CommandMap commandMap) throws Exception {
		ModelAndView mv = new ModelAndView("/loginCallback");

		return mv;
	}

	// 로그아웃
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

	// 아이디 찾기 폼
	@RequestMapping(value = "/findId.do")
	public ModelAndView findId(CommandMap commandMap) throws Exception {
		ModelAndView mv = new ModelAndView("login/findId");

		return mv;
	}

	// 아이디 찾기
	@RequestMapping(value = "/findIdAction.do", method = RequestMethod.POST)
	public String selectSearchMyId(HttpSession session, CommandMap commandMap, RedirectAttributes ra) throws Exception {
		String email = (String) commandMap.get("MEMBER_EMAIL");
		Map<String, Object> map = loginService.selectFindId(commandMap.getMap());
		if (map == null) {
			ra.addFlashAttribute("resultMsg", "입력된 정보가 일치하지 않습니다.");
			return "redirect:/findId.do";
		}
		String user_name = (String) map.get("MEMBER_NAME");
		String user = (String) map.get("MEMBER_ID");

		String subject = "<JM COLLECTION>" + user_name + "님, 아이디 찾기 결과 입니다.";
		StringBuilder sb = new StringBuilder();
		sb.append("귀하의 아이디는 " + user + " 입니다.");
//		joinService.send(subject, sb.toString(), "1teampjt@gmail.com", email, null);
		ra.addFlashAttribute("resultMsg", "귀하의 아이디는 " + user + " 입니다.");
		ra.addFlashAttribute("isResult", "1");

		return "redirect:/findId.do";
	}

	// 비밀번호 초기화 폼
	@RequestMapping(value = "/findPw.do")
	public ModelAndView findPw(CommandMap commandMap) throws Exception {
		ModelAndView mv = new ModelAndView("login/findPw");

		return mv;
	}

	// 비밀번호 초기화
	@RequestMapping(value = "/findPwAction.do", method = RequestMethod.POST)
	public String sendMailPassword(HttpSession session, CommandMap commandMap, RedirectAttributes ra) throws Exception {
		String email = (String) commandMap.get("MEMBER_EMAIL");
		String user = loginService.selectFindPw(commandMap.getMap());

		if (user == null) {
			ra.addFlashAttribute("resultMsg", "입력된 정보가 일치하지 않습니다.");
			return "redirect:/findPw.do";
		}

		int ran = new Random().nextInt(100000) + 10000;
		String password = String.valueOf(ran);

		commandMap.put("MEMBER_PASSWD", password);
		loginService.updatePw(commandMap.getMap());

		String subject = "<JM COLLECTION>임시 비밀번호입니다.";
		StringBuilder sb = new StringBuilder();
		sb.append("귀하의 임시 비밀번호는 " + password + " 입니다. 로그인 후 패스워드를 변경해 주세요.");
//		joinService.send(subject, sb.toString(), "1teampjt@gmail.com", email, null);
		ra.addFlashAttribute("resultMsg", "귀하의 임시 비밀번호는 " + password + " 입니다.");
		ra.addFlashAttribute("isResult", "1");

		return "redirect:/findPw.do";
	}
}