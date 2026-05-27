package stu.admin.main;

/**
 * ============================================================
 *  Project   : 관제 티켓 (Ticketing System)
 *  Package   : stu.admin.main
 *  FileName  : AdminAuthInterceptor.java
 *
 *  Developer : 김태희 (feature/kth)
 *  Created   : 2026.05.27
 *  Modified  : 2026.05.27
 *
 *  Description :
 *    - /admin/** 모든 요청에 대한 권한 체크 인터셉터
 *    - 세션의 SESSION_GRADE 값으로 ADMIN 여부 판정
 *
 *  동작 규칙 :
 *    - 비로그인       → /loginForm.do (returnUrl 포함) 로 리다이렉트
 *    - USER (일반)    → /main.do 로 리다이렉트 + 메시지
 *    - USER_BANNED    → 세션 invalidate (강제 로그아웃) + /loginForm.do
 *    - ADMIN          → 통과
 *
 *  보안 관제 연동 :
 *    - 차단 시 [AUDIT][admin-auth][BLOCKED] prefix 로 로그 출력
 *    - Splunk 가 [BLOCKED] 키워드로 즉시 알림 매칭 가능
 *
 *  등록 위치 :
 *    - /WEB-INF/config/action-servlet.xml 의 <mvc:interceptors> 에 등록
 *    - <mvc:mapping path="/admin/**"/>
 * ============================================================
 */

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.apache.log4j.Logger;
import org.springframework.web.servlet.handler.HandlerInterceptorAdapter;

public class AdminAuthInterceptor extends HandlerInterceptorAdapter {

	private Logger log = Logger.getLogger(this.getClass());

	/** 권한 체크 차단 로그 prefix (Splunk Alert 매칭용). */
	private static final String AUDIT_TAG = "[AUDIT][admin-auth][BLOCKED]";

	/** role 상수. */
	private static final String ROLE_ADMIN       = "ADMIN";
	private static final String ROLE_USER_BANNED = "USER_BANNED";

	@Override
	public boolean preHandle(HttpServletRequest request,
			HttpServletResponse response,
			Object handler) throws Exception {

		HttpSession session = request.getSession(false);
		String requestUri = request.getRequestURI();
		String clientIp = getClientIp(request);

		// ============================================================
		// 1. 비로그인 사용자 → 로그인 페이지로
		// ============================================================
		if (session == null
				|| session.getAttribute("SESSION_ID") == null) {

			log.warn(AUDIT_TAG + " 비로그인 사용자의 admin 접근 시도 "
					+ "uri=" + requestUri + ", ip=" + clientIp);

			// 로그인 후 원래 페이지로 복귀할 수 있게 returnUrl 포함
			response.sendRedirect(request.getContextPath()
					+ "/loginForm.do?returnUrl=" + requestUri);
			return false;
		}

		String sessionId    = (String) session.getAttribute("SESSION_ID");
		String sessionGrade = (String) session.getAttribute("SESSION_GRADE");

		// ============================================================
		// 2. USER_BANNED → 강제 로그아웃 + 로그인 페이지
		//    (admin 페이지에서 정지된 회원이 이미 로그인 상태였을 경우)
		// ============================================================
		if (ROLE_USER_BANNED.equals(sessionGrade)) {

			log.warn(AUDIT_TAG + " USER_BANNED 회원의 admin 접근 시도, 세션 강제 종료 "
					+ "uri=" + requestUri + ", id=" + sessionId + ", ip=" + clientIp);

			// 세션 무효화 (로그아웃 처리)
			session.invalidate();

			response.sendRedirect(request.getContextPath()
					+ "/loginForm.do?banned=1");
			return false;
		}

		// ============================================================
		// 3. ADMIN 이 아닌 일반 회원 → 메인 페이지로
		// ============================================================
		if (!ROLE_ADMIN.equals(sessionGrade)) {

			log.warn(AUDIT_TAG + " 권한 없는 사용자의 admin 접근 시도 "
					+ "uri=" + requestUri + ", id=" + sessionId
					+ ", grade=" + sessionGrade + ", ip=" + clientIp);

			response.sendRedirect(request.getContextPath()
					+ "/main.do?deny=admin");
			return false;
		}

		// ============================================================
		// 4. ADMIN → 통과 ✅
		// ============================================================
		log.debug("[admin-auth] ADMIN 접근 허용 uri=" + requestUri
				+ ", id=" + sessionId);
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

}