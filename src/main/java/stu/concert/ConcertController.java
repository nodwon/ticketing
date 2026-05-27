/**
 * ============================================================
 * Project    : 관제 티켓 (Ticketing System)
 * Package    : stu.concert
 * FileName   : ConcertController.java
 * Developer  : 주재현 (feature/jjh)
 * Created    : 2026.05.22
 * Modified   : 2026.05.27
 *
 * ⚠️⚠️⚠️ SECURITY LAB - MULTIPLE VULNERABILITIES ⚠️⚠️⚠️
 *
 * 포함된 취약점:
 *   [VULN-1] SQL Injection (Tautology / Error-based / Blind Boolean)
 *   [VULN-2] XSS Reflected (HTML / Attribute / JS)
 *   [VULN-3] Open Redirect
 *   [VULN-4] SQL Error 정보 누출
 *   [VULN-5] 민감정보 (세션 ID / 쿠키) 로그 노출
 *   [VULN-6] X-Frame-Options 미설정 (Clickjacking 허용)
 *
 * 운영 환경 절대 배포 금지. 시연 후 원복 필수.
 * ============================================================
 */
package stu.concert;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
@RequestMapping("/concert")
public class ConcertController {

    private static final Logger logger = LoggerFactory.getLogger(ConcertController.class);

    @Resource(name = "goodsService")
    private GoodsService goodsService;

    // ================================================================
    // 공연 목록 + 검색 (통합)
    // ================================================================
    @RequestMapping("/list.do")
    public String concertList(
            @RequestParam(value = "keyword", required = false) String keyword,
            @RequestParam(value = "status",  required = false) String status,
            HttpServletRequest request,
            HttpServletResponse response,
            Model model) throws Exception {

        // [VULN-6] X-Frame-Options 명시적으로 설정 안 함 (Clickjacking 허용)

        boolean isSearch = (keyword != null && !keyword.trim().isEmpty());

        // [VULN-5] 민감 정보 로그 노출 - 세션 ID / 쿠키 통째로 기록
        if (isSearch) {
            logger.warn("[SECURITY-SQLI-TEST] /concert/list.do (search) ip={}, ua={}, session={}, cookie={}, keyword={}, status={}",
                    new Object[]{
                        request.getRemoteAddr(),
                        request.getHeader("User-Agent"),
                        request.getSession().getId(),
                        request.getHeader("Cookie"),
                        keyword,
                        status
                    });
        } else {
            logger.info("[CTRL] /concert/list.do (browse) ip={}, status={}",
                    request.getRemoteAddr(), status);
        }

        Map<String, Object> paramMap = new HashMap<>();
        // ⚠️ 대소문자 무관 검색을 위해 keyword 를 소문자로 미리 변환
        //    (매퍼는 LOWER(컬럼) LIKE '%${keyword}%' 사용)
        if (isSearch) {
            paramMap.put("keyword", keyword.toLowerCase());
        } else {
            paramMap.put("keyword", keyword);
        }
        paramMap.put("status",  status);

        List<Map<String, Object>> concertList;
        String sqlError = null;

        try {
            if (isSearch) {
                // [VULN-1] 취약 경로 - 매퍼가 ${keyword} 사용
                concertList = goodsService.searchConcertsByKeyword(paramMap);
            } else {
                concertList = goodsService.selectConcertList(paramMap);
            }
        } catch (Exception e) {
            // [VULN-4] SQL 에러 메시지를 그대로 화면에 노출
            logger.error("[SECURITY-SQLI-ERROR] keyword={}, msg={}", keyword, e.getMessage());
            sqlError = e.getMessage();
            concertList = new ArrayList<>();
        }

        model.addAttribute("concertList", concertList);
        model.addAttribute("keyword", keyword);       // ⚠️ JSP에서 escape 없이 출력 (XSS)
        model.addAttribute("status",  status);
        model.addAttribute("sqlError", sqlError);
        return "concert/concertList";
    }

    // ================================================================
    // 공연 상세 ([VULN-3] returnUrl 검증 없이 전달)
    // ================================================================
    @RequestMapping("/detail.do")
    public String concertDetail(
            @RequestParam("concertId") Long concertId,
            @RequestParam(value = "returnUrl", required = false) String returnUrl,
            HttpServletRequest request,
            Model model) throws Exception {

        logger.info("[CTRL] /concert/detail.do ip={}, concertId={}, returnUrl={}",
                new Object[]{request.getRemoteAddr(), concertId, returnUrl});

        Map<String, Object> concert = goodsService.selectConcertDetail(concertId);
        if (concert == null) {
            logger.warn("[CTRL] concert not found. id={}", concertId);
            model.addAttribute("errorMsg", "해당 공연 정보를 찾을 수 없습니다.");
            return "concert/concertDetail";
        }

        List<Map<String, Object>> scheduleList = goodsService.selectScheduleListByConcertId(concertId);

        model.addAttribute("concert", concert);
        model.addAttribute("scheduleList", scheduleList);
        model.addAttribute("returnUrl", returnUrl);   // ⚠️ 검증 없이 그대로 전달
        return "concert/concertDetail";
    }
}
