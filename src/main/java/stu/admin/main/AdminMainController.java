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
 *    2026.05.25 - 공연 등록/수정/삭제 처리 결과를 Flash Message 로 전달
 *                 · RedirectAttributes 사용 (Spring 표준)
 *                 · 삭제는 스마트 삭제 결과(0건=Hard, N건=Soft)에 따라 메시지 분기
 *                 · 리턴 타입 ModelAndView → String 변경 (PRG 패턴 단순화)
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
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

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
	public String concertInsert(CommandMap commandMap,
			HttpServletRequest request,
			RedirectAttributes redirectAttributes) throws Exception {

		log.info("[AUDIT][admin] concertInsert called from ip=" + getClientIp(request)
				+ ", title=" + commandMap.get("title"));

		adminMainService.insertConcert(commandMap);

		redirectAttributes.addFlashAttribute("msg",
			"공연이 등록되었습니다.");
		redirectAttributes.addFlashAttribute("msgType", "success");

		return "redirect:/admin/concert/list.do";
	}

	/**
	 * 공연 수정 처리.
	 * URL : POST /admin/concert/update.do
	 */
	@RequestMapping(value = "/concert/update.do", method = RequestMethod.POST)
	public String concertUpdate(CommandMap commandMap,
			HttpServletRequest request,
			RedirectAttributes redirectAttributes) throws Exception {

		log.info("[AUDIT][admin] concertUpdate called from ip=" + getClientIp(request)
				+ ", concertId=" + commandMap.get("concertId"));

		adminMainService.updateConcert(commandMap);

		redirectAttributes.addFlashAttribute("msg",
			"공연 정보가 수정되었습니다.");
		redirectAttributes.addFlashAttribute("msgType", "success");

		return "redirect:/admin/concert/list.do";
	}

	/**
	 * 공연 삭제 처리 (스마트 삭제).
	 * URL : POST /admin/concert/delete.do
	 *
	 *  - 예매 0건  : Hard Delete  → "공연이 완전히 삭제되었습니다." (success)
	 *  - 예매 1건+ : Soft Delete  → "예매 내역(N건)이 있어 비활성 처리되었습니다." (info)
	 */
	@RequestMapping(value = "/concert/delete.do", method = RequestMethod.POST)
	public String concertDelete(CommandMap commandMap,
			HttpServletRequest request,
			RedirectAttributes redirectAttributes) throws Exception {

		log.info("[AUDIT][admin] concertDelete called from ip=" + getClientIp(request)
				+ ", concertId=" + commandMap.get("concertId"));

		int bookingCount = adminMainService.deleteConcert(commandMap);

		if (bookingCount > 0) {
			redirectAttributes.addFlashAttribute("msg",
				"예매 내역이 " + bookingCount + "건 있어 공연을 비활성 처리했습니다. (상태: CLOSED)");
			redirectAttributes.addFlashAttribute("msgType", "info");
		} else {
			redirectAttributes.addFlashAttribute("msg",
				"공연이 완전히 삭제되었습니다.");
			redirectAttributes.addFlashAttribute("msgType", "success");
		}

		return "redirect:/admin/concert/list.do";
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
