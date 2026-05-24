package stu.admin.main;

/**
 * ============================================================
 *  Project   : 관제 티켓 (Ticketing System)
 *  Package   : stu.admin.main
 *  FileName  : AdminMainController.java
 *
 *  Developer : 김태희 (feature/kth)
 *  Created   : 2026.05.24
 *  Modified  : 2026.05.25
 *
 *  Description :
 *    - 관리자 메인 페이지 컨트롤러
 *    - URL prefix : /admin
 *    - 대시보드 / 공연관리 / 회원관리 / 예매관리
 *
 *  History :
 *    2026.05.25 - 탬퍼 탐지 로직 제거 (Splunk 측 처리)
 *    2026.05.25 - URL 네이밍 팀 규칙 적용 (소문자 + 슬래시 분리)
 *                 예) /admin/concertList.do → /admin/concert/list.do
 * ============================================================
 */

import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;

import org.apache.log4j.Logger;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.view.RedirectView;

import stu.common.common.CommandMap;

@Controller
@RequestMapping("/admin")
public class AdminMainController {

	private Logger log = Logger.getLogger(this.getClass());

	@Resource(name = "adminMainService")
	private AdminMainService adminMainService;

	// =====================================================================
	// 1. 대시보드
	// =====================================================================

	/**
	 * 관리자 메인 대시보드.
	 * URL : GET /admin/main.do
	 */
	@RequestMapping(value = "/main.do", method = RequestMethod.GET)
	public ModelAndView adminMain(CommandMap commandMap) throws Exception {

		log.debug("[admin] /admin/main.do called");

		ModelAndView mv = new ModelAndView("admin/adminMain");

		Map<String, Object> dashboard = adminMainService.selectDashboard(commandMap);
		mv.addObject("dashboard", dashboard);

		return mv;
	}

	// =====================================================================
	// 2. 공연 관리
	// =====================================================================

	/**
	 * 공연 목록 + 검색 + 페이징.
	 * URL : GET /admin/concert/list.do
	 */
	@RequestMapping(value = "/concert/list.do", method = RequestMethod.GET)
	public ModelAndView concertList(CommandMap commandMap) throws Exception {

		log.debug("[admin] /admin/concert/list.do called, params=" + commandMap.getMap());

		ModelAndView mv = new ModelAndView("admin/concertList");

		List<Map<String, Object>> concertList = adminMainService.selectConcertList(commandMap.getMap());
		mv.addObject("concertList", concertList);

		// 페이징/검색 파라미터 유지
		mv.addObject("searchType",  commandMap.get("searchType"));
		mv.addObject("keyword",     commandMap.get("keyword"));
		mv.addObject("PAGE_INDEX",  commandMap.get("PAGE_INDEX"));
		if (concertList != null && concertList.size() > 0) {
			mv.addObject("TOTAL", concertList.get(0).get("TOTAL_COUNT"));
		} else {
			mv.addObject("TOTAL", 0);
		}

		return mv;
	}

	/**
	 * 공연 등록/수정 폼.
	 * URL : GET /admin/concert/form.do              (등록 모드)
	 *       GET /admin/concert/form.do?concertId=10 (수정 모드)
	 */
	@RequestMapping(value = "/concert/form.do", method = RequestMethod.GET)
	public ModelAndView concertForm(CommandMap commandMap) throws Exception {

		log.debug("[admin] /admin/concert/form.do called, params=" + commandMap.getMap());

		ModelAndView mv = new ModelAndView("admin/concertForm");

		Object concertId = commandMap.get("concertId");
		if (concertId != null && !"".equals(concertId.toString())) {
			Map<String, Object> concert = adminMainService.selectConcert(commandMap);
			mv.addObject("concert", concert);
			mv.addObject("mode", "edit");
		} else {
			mv.addObject("mode", "create");
		}

		return mv;
	}

	/**
	 * 공연 등록 처리.
	 * URL : POST /admin/concert/insert.do
	 */
	@RequestMapping(value = "/concert/insert.do", method = RequestMethod.POST)
	public ModelAndView concertInsert(CommandMap commandMap, HttpServletRequest request)
			throws Exception {

		log.info("[AUDIT][admin] concertInsert called from ip=" + getClientIp(request)
				+ ", title=" + commandMap.get("title"));

		adminMainService.insertConcert(commandMap);

		// PRG 패턴 (POST 후 GET 리다이렉트)
		return new ModelAndView(new RedirectView("/admin/concert/list.do"));
	}

	/**
	 * 공연 수정 처리.
	 * URL : POST /admin/concert/update.do
	 */
	@RequestMapping(value = "/concert/update.do", method = RequestMethod.POST)
	public ModelAndView concertUpdate(CommandMap commandMap, HttpServletRequest request)
			throws Exception {

		log.info("[AUDIT][admin] concertUpdate called from ip=" + getClientIp(request)
				+ ", concertId=" + commandMap.get("concertId"));

		adminMainService.updateConcert(commandMap);

		return new ModelAndView(new RedirectView("/admin/concert/list.do"));
	}

	/**
	 * 공연 삭제 처리 (soft delete : status='CLOSED').
	 * URL : POST /admin/concert/delete.do
	 */
	@RequestMapping(value = "/concert/delete.do", method = RequestMethod.POST)
	public ModelAndView concertDelete(CommandMap commandMap, HttpServletRequest request)
			throws Exception {

		log.info("[AUDIT][admin] concertDelete called from ip=" + getClientIp(request)
				+ ", concertId=" + commandMap.get("concertId"));

		adminMainService.deleteConcert(commandMap);

		return new ModelAndView(new RedirectView("/admin/concert/list.do"));
	}

	// =====================================================================
	// 3. 회원 관리
	// =====================================================================

	/**
	 * 회원 목록 + 검색 + 페이징.
	 * URL : GET /admin/member/list.do
	 */
	@RequestMapping(value = "/member/list.do", method = RequestMethod.GET)
	public ModelAndView memberList(CommandMap commandMap) throws Exception {

		log.debug("[admin] /admin/member/list.do called, params=" + commandMap.getMap());

		ModelAndView mv = new ModelAndView("admin/memberList");

		List<Map<String, Object>> memberList = adminMainService.selectMemberList(commandMap.getMap());
		mv.addObject("memberList", memberList);

		mv.addObject("searchType",  commandMap.get("searchType"));
		mv.addObject("keyword",     commandMap.get("keyword"));
		mv.addObject("PAGE_INDEX",  commandMap.get("PAGE_INDEX"));
		if (memberList != null && memberList.size() > 0) {
			mv.addObject("TOTAL", memberList.get(0).get("TOTAL_COUNT"));
		} else {
			mv.addObject("TOTAL", 0);
		}

		return mv;
	}

	// =====================================================================
	// 4. 예매 관리
	// =====================================================================

	/**
	 * 예매 내역 목록 + 검색 + 페이징.
	 * URL : GET /admin/booking/list.do
	 */
	@RequestMapping(value = "/booking/list.do", method = RequestMethod.GET)
	public ModelAndView bookingList(CommandMap commandMap) throws Exception {

		log.debug("[admin] /admin/booking/list.do called, params=" + commandMap.getMap());

		ModelAndView mv = new ModelAndView("admin/bookingList");

		List<Map<String, Object>> bookingList = adminMainService.selectBookingList(commandMap.getMap());
		mv.addObject("bookingList", bookingList);

		mv.addObject("searchType",  commandMap.get("searchType"));
		mv.addObject("keyword",     commandMap.get("keyword"));
		mv.addObject("status",      commandMap.get("status"));
		mv.addObject("PAGE_INDEX",  commandMap.get("PAGE_INDEX"));
		if (bookingList != null && bookingList.size() > 0) {
			mv.addObject("TOTAL", bookingList.get(0).get("TOTAL_COUNT"));
		} else {
			mv.addObject("TOTAL", 0);
		}

		return mv;
	}

	// =====================================================================
	// helper
	// =====================================================================

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