package stu.admin.main;

/**
 * ============================================================
 *  Project   : 관제 티켓 (Ticketing System)
 *  Package   : stu.admin.main
 *  FileName  : AdminMainController.java
 *
 *  Developer : 김태희 (feature/kth)
 *  Created   : 2026.05.24
 *  Modified  : 2026.05.27
 *
 *  Description :
 *    - 관리자 메인 페이지 컨트롤러
 *    - URL prefix : /admin
 *    - 대시보드 / 공연관리 / 회원관리 / 예매관리
 *
 *  History :
 *    2026.05.25 - URL 네이밍 팀 규칙 적용 (/admin/도메인/액션.do)
 *    2026.05.25 - Flash Message + 스마트 삭제 분기 메시지
 *    2026.05.27 - 회원 권한 변경 endpoint 4개 추가
 *                 · POST /admin/member/ban.do      (정지)
 *                 · POST /admin/member/unban.do    (활성화)
 *                 · POST /admin/member/promote.do  (승격)
 *                 · POST /admin/member/demote.do   (강등)
 *                 · 보호 장치 위반 시 MemberRoleChangeException 잡아서 error 배너 표시
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

import stu.admin.main.AdminMainService.MemberRoleChangeException;
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

	@RequestMapping(value = "/main.do", method = RequestMethod.GET)
	public ModelAndView adminMain(CommandMap commandMap) throws Exception {

		log.debug("[admin] /admin/main.do called");
		ModelAndView mv = new ModelAndView("admin/adminMain");
		mv.addObject("dashboard", adminMainService.selectDashboard(commandMap));
		return mv;
	}

	// =====================================================================
	// 2. 공연 관리
	// =====================================================================

	@RequestMapping(value = "/concert/list.do", method = RequestMethod.GET)
	public ModelAndView concertList(CommandMap commandMap) throws Exception {

		log.debug("[admin] /admin/concert/list.do called, params=" + commandMap.getMap());
		ModelAndView mv = new ModelAndView("admin/concertList");

		List<Map<String, Object>> concertList = adminMainService.selectConcertList(commandMap.getMap());
		mv.addObject("concertList", concertList);
		mv.addObject("searchType",  commandMap.get("searchType"));
		mv.addObject("keyword",     commandMap.get("keyword"));
		mv.addObject("PAGE_INDEX",  commandMap.get("PAGE_INDEX"));
		mv.addObject("TOTAL", (concertList != null && concertList.size() > 0)
			? concertList.get(0).get("TOTAL_COUNT") : 0);

		return mv;
	}

	@RequestMapping(value = "/concert/form.do", method = RequestMethod.GET)
	public ModelAndView concertForm(CommandMap commandMap) throws Exception {

		log.debug("[admin] /admin/concert/form.do called, params=" + commandMap.getMap());
		ModelAndView mv = new ModelAndView("admin/concertForm");

		Object concertId = commandMap.get("concertId");
		if (concertId != null && !"".equals(concertId.toString())) {
			mv.addObject("concert", adminMainService.selectConcert(commandMap));
			mv.addObject("mode", "edit");
		} else {
			mv.addObject("mode", "create");
		}
		return mv;
	}

	@RequestMapping(value = "/concert/insert.do", method = RequestMethod.POST)
	public String concertInsert(CommandMap commandMap,
			HttpServletRequest request,
			RedirectAttributes redirectAttributes) throws Exception {

		log.info("[AUDIT][admin] concertInsert called from ip=" + getClientIp(request)
				+ ", title=" + commandMap.get("title"));
		adminMainService.insertConcert(commandMap);

		redirectAttributes.addFlashAttribute("msg", "공연이 등록되었습니다.");
		redirectAttributes.addFlashAttribute("msgType", "success");
		return "redirect:/admin/concert/list.do";
	}

	@RequestMapping(value = "/concert/update.do", method = RequestMethod.POST)
	public String concertUpdate(CommandMap commandMap,
			HttpServletRequest request,
			RedirectAttributes redirectAttributes) throws Exception {

		log.info("[AUDIT][admin] concertUpdate called from ip=" + getClientIp(request)
				+ ", concertId=" + commandMap.get("concertId"));
		adminMainService.updateConcert(commandMap);

		redirectAttributes.addFlashAttribute("msg", "공연 정보가 수정되었습니다.");
		redirectAttributes.addFlashAttribute("msgType", "success");
		return "redirect:/admin/concert/list.do";
	}

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
			redirectAttributes.addFlashAttribute("msg", "공연이 완전히 삭제되었습니다.");
			redirectAttributes.addFlashAttribute("msgType", "success");
		}
		return "redirect:/admin/concert/list.do";
	}

	// =====================================================================
	// 3. 회원 관리
	// =====================================================================

	@RequestMapping(value = "/member/list.do", method = RequestMethod.GET)
	public ModelAndView memberList(CommandMap commandMap) throws Exception {

		log.debug("[admin] /admin/member/list.do called, params=" + commandMap.getMap());
		ModelAndView mv = new ModelAndView("admin/memberList");

		List<Map<String, Object>> memberList = adminMainService.selectMemberList(commandMap.getMap());
		mv.addObject("memberList", memberList);
		mv.addObject("searchType", commandMap.get("searchType"));
		mv.addObject("keyword",    commandMap.get("keyword"));
		mv.addObject("role",       commandMap.get("role"));
		mv.addObject("PAGE_INDEX", commandMap.get("PAGE_INDEX"));
		mv.addObject("TOTAL", (memberList != null && memberList.size() > 0)
			? memberList.get(0).get("TOTAL_COUNT") : 0);

		return mv;
	}

	/**
	 * 일반 회원 정지.
	 * URL : POST /admin/member/ban.do
	 */
	@RequestMapping(value = "/member/ban.do", method = RequestMethod.POST)
	public String memberBan(CommandMap commandMap,
			HttpServletRequest request,
			RedirectAttributes redirectAttributes) throws Exception {

		return handleRoleChange("BAN", commandMap, request, redirectAttributes);
	}

	/**
	 * 정지된 회원 활성화.
	 * URL : POST /admin/member/unban.do
	 */
	@RequestMapping(value = "/member/unban.do", method = RequestMethod.POST)
	public String memberUnban(CommandMap commandMap,
			HttpServletRequest request,
			RedirectAttributes redirectAttributes) throws Exception {

		return handleRoleChange("UNBAN", commandMap, request, redirectAttributes);
	}

	/**
	 * 관리자 승격.
	 * URL : POST /admin/member/promote.do
	 */
	@RequestMapping(value = "/member/promote.do", method = RequestMethod.POST)
	public String memberPromote(CommandMap commandMap,
			HttpServletRequest request,
			RedirectAttributes redirectAttributes) throws Exception {

		return handleRoleChange("PROMOTE", commandMap, request, redirectAttributes);
	}

	/**
	 * 관리자 강등.
	 * URL : POST /admin/member/demote.do
	 */
	@RequestMapping(value = "/member/demote.do", method = RequestMethod.POST)
	public String memberDemote(CommandMap commandMap,
			HttpServletRequest request,
			RedirectAttributes redirectAttributes) throws Exception {

		return handleRoleChange("DEMOTE", commandMap, request, redirectAttributes);
	}

	// =====================================================================
	// 4. 예매 관리
	// =====================================================================

	@RequestMapping(value = "/booking/list.do", method = RequestMethod.GET)
	public ModelAndView bookingList(CommandMap commandMap) throws Exception {

		log.debug("[admin] /admin/booking/list.do called, params=" + commandMap.getMap());
		ModelAndView mv = new ModelAndView("admin/bookingList");

		List<Map<String, Object>> bookingList = adminMainService.selectBookingList(commandMap.getMap());
		mv.addObject("bookingList", bookingList);
		mv.addObject("searchType", commandMap.get("searchType"));
		mv.addObject("keyword",    commandMap.get("keyword"));
		mv.addObject("status",     commandMap.get("status"));
		mv.addObject("PAGE_INDEX", commandMap.get("PAGE_INDEX"));
		mv.addObject("TOTAL", (bookingList != null && bookingList.size() > 0)
			? bookingList.get(0).get("TOTAL_COUNT") : 0);

		return mv;
	}

	// =====================================================================
	// helper
	// =====================================================================

	/**
	 * 회원 권한 변경(ban/unban/promote/demote) 공통 처리.
	 *  - Service 호출 → Flash Message 설정
	 *  - 보호 장치 위반(MemberRoleChangeException) 발생 시 error 배너로 안내
	 */
	private String handleRoleChange(String action,
			CommandMap commandMap,
			HttpServletRequest request,
			RedirectAttributes redirectAttributes) throws Exception {

		String ip = getClientIp(request);
		Object memberId = commandMap.get("memberId");

		log.info("[AUDIT][admin][CRITICAL] " + action + " requested from ip=" + ip
				+ ", memberId=" + memberId);

		try {
			Map<String, Object> changed;
			String successMsg;

			if ("BAN".equals(action)) {
				changed = adminMainService.banMember(commandMap);
				successMsg = "회원 [" + changed.get("NAME") + "] 님을 정지 처리했습니다.";
			} else if ("UNBAN".equals(action)) {
				changed = adminMainService.unbanMember(commandMap);
				successMsg = "회원 [" + changed.get("NAME") + "] 님을 활성화했습니다.";
			} else if ("PROMOTE".equals(action)) {
				changed = adminMainService.promoteMember(commandMap);
				successMsg = "회원 [" + changed.get("NAME") + "] 님을 관리자(ADMIN) 로 승격했습니다.";
			} else if ("DEMOTE".equals(action)) {
				changed = adminMainService.demoteMember(commandMap);
				successMsg = "회원 [" + changed.get("NAME") + "] 님을 일반 회원(USER) 으로 강등했습니다.";
			} else {
				throw new IllegalArgumentException("Unknown role-change action: " + action);
			}

			redirectAttributes.addFlashAttribute("msg", successMsg);
			redirectAttributes.addFlashAttribute("msgType", "success");

		} catch (MemberRoleChangeException e) {
			// 보호 장치 위반 -> 빨간 배너로 안내
			log.warn("[AUDIT][admin][CRITICAL] " + action + " REJECTED from ip=" + ip
					+ ", memberId=" + memberId + ", reason=" + e.getMessage());

			redirectAttributes.addFlashAttribute("msg", e.getMessage());
			redirectAttributes.addFlashAttribute("msgType", "error");
		}

		return "redirect:/admin/member/list.do";
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