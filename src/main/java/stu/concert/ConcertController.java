/**
 * ============================================================
 * Project    : 관제 티켓 (Ticketing System)
 * Package    : stu.concert
 * FileName   : ConcertController.java
 * Developer  : 주재현 (feature/jjh)
 * Created    : 2026.05.22
 * Modified   : 2026.05.26
 * Description: 공연(Concert) 컨트롤러
 *              - /concert/list.do      : 공연 목록 (status 필터)
 *              - /concert/detail.do    : 공연 상세 + 스케줄 목록
 *              - /concert/search.do    : 공연 검색
 *              - /concert/listJson.do  : 메인페이지용 Ajax JSON 반환 (추가)
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
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.ModelAndView;

@Controller
@RequestMapping("/concert")
public class ConcertController {

    private static final Logger logger = LoggerFactory.getLogger(ConcertController.class);

    @Resource(name = "goodsService")
    private GoodsService goodsService;

    // ================================================================
    // 1) 공연 목록 (status 필터)
    // ================================================================
    @RequestMapping("/list.do")
    public String concertList(
            @RequestParam(value = "keyword", required = false) String keyword,
            @RequestParam(value = "status",  required = false) String status,
            HttpServletRequest request,
            Model model) throws Exception {

        logger.info("[CTRL] /concert/list.do ip={}, keyword={}, status={}",
                new Object[]{request.getRemoteAddr(), keyword, status});

        Map<String, Object> paramMap = new HashMap<>();
        paramMap.put("keyword", keyword);
        paramMap.put("status",  status);

        List<Map<String, Object>> concertList = goodsService.selectConcertList(paramMap);

        model.addAttribute("concertList", concertList);
        model.addAttribute("keyword", keyword);
        model.addAttribute("status",  status);
        return "concert/concertList";
    }

    // ================================================================
    // 2) 공연 상세
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

        List<Map<String, Object>> scheduleList = goodsService.selectScheduleListByConcertId(concertId);

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

    // ================================================================
    // 4) 메인페이지용 공연 목록 Ajax (JSON 반환)
    //    URL : /concert/listJson.do
    //    Param: limit (기본 6)
    // ================================================================
    @RequestMapping("/listJson.do")
    public ModelAndView concertListJson(
            @RequestParam(value = "limit", required = false, defaultValue = "6") int limit,
            HttpServletRequest request) throws Exception {

        logger.info("[CTRL] /concert/listJson.do ip={}, limit={}",
                request.getRemoteAddr(), limit);

        Map<String, Object> paramMap = new HashMap<>();
        paramMap.put("keyword", null);
        paramMap.put("status",  null);

        List<Map<String, Object>> concertList = goodsService.selectConcertList(paramMap);

        // limit 적용
        if (concertList.size() > limit) {
            concertList = concertList.subList(0, limit);
        }

        ModelAndView mv = new ModelAndView("jsonView");
        mv.addObject("list",  concertList);
        mv.addObject("total", concertList.size());
        return mv;
    }
}
