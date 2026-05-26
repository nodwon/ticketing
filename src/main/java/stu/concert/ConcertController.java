/**
 * ============================================================
 * Project    : 관제 티켓 (Ticketing System)
 * Package    : stu.concert
 * FileName   : ConcertController.java
 * Developer  : 주재현 (feature/jjh)
 * Created    : 2026.05.22
 * Modified   : 2026.05.26
 * Description: 공연(Concert) 컨트롤러
 *              - /concert/list.do    : 공연 목록
 *              - /concert/detail.do  : 공연 상세 + 스케줄 목록
 *              - /concert/search.do  : 공연 검색
 * ============================================================
 */
package stu.concert;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;

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
    // 1) 공연 목록
    // ================================================================
    @RequestMapping("/list.do")
    public String concertList(
            @RequestParam(value = "keyword",  required = false) String keyword,
            @RequestParam(value = "status",   required = false) String status,
            @RequestParam(value = "orderBy",  required = false, defaultValue = "newest") String orderBy,
            HttpServletRequest request,
            Model model) throws Exception {

        logger.info("[CTRL] /concert/list.do ip={}, keyword={}, status={}, orderBy={}",
                new Object[]{request.getRemoteAddr(), keyword, status, orderBy});

        Map<String, Object> paramMap = new HashMap<>();
        paramMap.put("keyword", keyword);
        paramMap.put("status",  status);
        paramMap.put("orderBy", orderBy);

        List<Map<String, Object>> concertList = goodsService.selectConcertList(paramMap);

        model.addAttribute("concertList", concertList);
        model.addAttribute("keyword", keyword);
        model.addAttribute("status",  status);
        model.addAttribute("orderBy", orderBy);
        return "concert/concertList";
    }

    // ================================================================
    // 2) 공연 상세 + 스케줄 목록
    // ================================================================
    @RequestMapping("/detail.do")
    public String concertDetail(
            @RequestParam("concertId") Long concertId,
            HttpServletRequest request,
            Model model) throws Exception {

        logger.info("[CTRL] /concert/detail.do ip={}, concertId={}",
                request.getRemoteAddr(), concertId);

        Map<String, Object> concert = goodsService.selectConcertDetail(concertId);
        if (concert == null) {
            logger.warn("[CTRL] concert not found. id={}", concertId);
            model.addAttribute("errorMsg", "해당 공연 정보를 찾을 수 없습니다.");
            return "concert/concertDetail";
        }

        // 공연 스케줄 목록 함께 조회
        List<Map<String, Object>> scheduleList = goodsService.selectScheduleListByConcertId(concertId);
        logger.info("[CTRL] schedule count = {}", scheduleList == null ? 0 : scheduleList.size());

        model.addAttribute("concert", concert);
        model.addAttribute("scheduleList", scheduleList);
        return "concert/concertDetail";
    }

    // ================================================================
    // 3) 통합 검색
    // ================================================================
    @RequestMapping("/search.do")
    public String search(
            @RequestParam(value = "keyword", required = false) String keyword,
            HttpServletRequest request,
            Model model) throws Exception {

        logger.info("[CTRL] /concert/search.do ip={}, keyword={}",
                request.getRemoteAddr(), keyword);

        List<Map<String, Object>> result = goodsService.searchConcerts(keyword);
        model.addAttribute("concertList", result);
        model.addAttribute("keyword", keyword);
        return "concert/search";
    }
}
