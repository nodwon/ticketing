package stu.admin.main;

/**
 * ============================================================
 *  Project   : 관제 티켓 (Ticketing System)
 *  Package   : stu.admin.main
 *  FileName  : AdminAuthInterceptor.java
 *
 *  Developer : 김태희 (feature/kth)
 *  Created   : 2026.05.27
 *  Modified  : 2026.05.28 - SecurityLogger 통합 (log_admin_access.json 기록)
 *
 *  Description :
 *    - /admin/** 모든 요청에 대한 권한 체크 인터셉터
 *    - 세션의 SESSION_GRADE 값으로 ADMIN 여부 판정
 *    - ★ 모든 차단/허용 이벤트를 log_admin_access.json 에 자동 기록
 *
 *  동작 규칙 :
 *    - 비로그인       → /loginForm.do (returnUrl 포함) + 403 로그
 *    - USER (일반)    → /main.do + 403 로그 (권한 우회 시도)
 *    - USER_BANNED    → 세션 invalidate + 403 로그
 *    - ADMIN          → 통과 + 200 로그 (감사용)
 *
 *  보안 관제 연동 :
 *    - SecurityLogger.adminAccess() 호출 → log_admin_access.json
 *    - Splunk SPL: index=ticketing_security log_type=log_admin_access status_code=403
 * ============================================================
 */

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.servlet.handler.HandlerInterceptorAdapter;

import stu.common.logger.SecurityLogger;       // ★★ 추가: 보안 로그

public class AdminAuthInterceptor extends HandlerInterceptorAdapter {

	private static final Logger log = LoggerFactory.getLogger(AdminAuthInterceptor.class);

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

			// ★★ 보안 로그: 비로그인 admin 접근 시도 (user_id=null, 403)
			SecurityLogger.adminAccess(requestUri, null, clientIp, 403);

			// 로그인 후 원래 페이지로 복귀할 수 있게 returnUrl 포함
			response.sendRedirect(request.getContextPath()
					+ "/loginForm.do?returnUrl=" + requestUri);
			return false;
		}

		String sessionId    = (String) session.getAttribute("SESSION_ID");
		String sessionGrade = (String) session.getAttribute("SESSION_GRADE");
		Long userId = getSessionUserId(session);

		// ============================================================
		// 2. USER_BANNED → 강제 로그아웃 + 로그인 페이지
		// ============================================================
		if (ROLE_USER_BANNED.equals(sessionGrade)) {

			log.warn(AUDIT_TAG + " USER_BANNED 회원의 admin 접근 시도, 세션 강제 종료 "
					+ "uri=" + requestUri + ", id=" + sessionId + ", ip=" + clientIp);

			// ★★ 보안 로그: 정지 회원 접근 시도 (403)
			SecurityLogger.adminAccess(requestUri, userId, clientIp, 403);

			// 세션 무효화 (로그아웃 처리)
			session.invalidate();

			response.sendRedirect(request.getContextPath()
					+ "/loginForm.do?banned=1");
			return false;
		}

		// ============================================================
		// 3. ADMIN 이 아닌 일반 회원 → 메인 페이지로 (★ 권한 우회 시도)
		// ============================================================
		if (!ROLE_ADMIN.equals(sessionGrade)) {

			log.warn(AUDIT_TAG + " 권한 없는 사용자의 admin 접근 시도 "
					+ "uri=" + requestUri + ", id=" + sessionId
					+ ", grade=" + sessionGrade + ", ip=" + clientIp);

			// ★★ 보안 로그: 일반 USER가 /admin/* 접근 시도 (대표적 권한 우회 공격)
			SecurityLogger.adminAccess(requestUri, userId, clientIp, 403);

			response.sendRedirect(request.getContextPath()
					+ "/main.do?deny=admin");
			return false;
		}

		// ============================================================
		// 4. ADMIN → 통과 ✅ (감사 로그 기록)
		// ============================================================
		log.debug("[admin-auth] ADMIN 접근 허용 uri=" + requestUri
				+ ", id=" + sessionId);

		// ★★ 보안 로그: 정상 ADMIN 접근 감사 기록 (status_code=200)
		SecurityLogger.adminAccess(requestUri, userId, clientIp, 200);

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

	/** 세션의 SESSION_NO 추출 (Long 변환). */
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
