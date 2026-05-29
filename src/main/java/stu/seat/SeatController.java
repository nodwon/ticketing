/**
 * ============================================================
 * Project   : 관제 티켓 (Ticketing System)
 * Package   : stu.seat
 * FileName  : SeatController.java
 *
 * Developer : 정희영 (feature/jhyjhy)
 * Modified  : 2026.05.26 - MacroDetectionLogger 통합
 *
 * Description :
 *   1) GET  /seat/select.do  - 좌석 선택 페이지 진입
 *   2) GET  /seat/list.do    - 좌석 현황 조회 (Ajax)
 *   3) POST /seat/hold.do    - 좌석 임시 선점 ★매크로 탐지 로그★
 *   4) POST /seat/release.do - 좌석 선점 해제
 *   5) GET  /seat/zone.do    - 구역별 좌석 조회 (봇 탐지용)
 * ============================================================
 */
package stu.seat;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.ModelAndView;

import stu.common.logger.SecurityLogger;
import stu.common.logger.MacroDetectionLogger;

@Controller
public class SeatController {

    private Logger log = LoggerFactory.getLogger(this.getClass());

    @Resource(name = "seatService")
    private SeatService seatService;

    // ================================================================
    // 1) 좌석 선택 페이지 진입
    // ================================================================
    @RequestMapping(value = "/seat/select.do", method = RequestMethod.GET)
    public ModelAndView seatSelectPage(@RequestParam("scheduleId") String scheduleId) throws Exception {
        log.debug("==== 좌석 선택 페이지 요청 : scheduleId={} ====", scheduleId);
        ModelAndView mv = new ModelAndView("seat/seatSelect");
        mv.addObject("scheduleId", scheduleId);
        return mv;
    }

    // ================================================================
    // 2) 좌석 현황 조회 (Ajax)
    // ================================================================
    @RequestMapping(value = "/seat/list.do", method = RequestMethod.GET)
    @ResponseBody
    public List<Map<String, Object>> seatList(@RequestParam("scheduleId") String scheduleId) throws Exception {
        log.debug("==== 좌석 목록 조회 : scheduleId={} ====", scheduleId);
        Map<String, Object> map = new HashMap<String, Object>();
        map.put("scheduleId", scheduleId);
        return seatService.selectSeatList(map);
    }

    // ================================================================
    // 3) 좌석 임시 선점 (AVAILABLE → HELD) ★매크로 탐지 로그★
    //
    //    클라이언트에서 추가로 전송해야 할 파라미터:
    //    - seat_page_load_ts : seatSelect.jsp 로드 시각 (JS에서 Date.now())
    //    - concert_id        : 공연 ID
    // ================================================================
    @RequestMapping(value = "/seat/hold.do", method = RequestMethod.POST)
    @ResponseBody
    public Map<String, Object> holdSeat(
            @RequestParam("seatId")   String seatId,
            @RequestParam("memberId") String memberId,
            @RequestParam(value = "concertId",        required = false) String concertId,
            @RequestParam(value = "scheduleId",        required = false) String scheduleId,
            @RequestParam(value = "seat_page_load_ts", required = false) String seatPageLoadTsStr,
            HttpServletRequest request,
            HttpSession session) throws Exception {

        long startTime = System.currentTimeMillis();
        String srcIp   = getClientIp(request);

        log.debug("==== 좌석 선점 요청 : seatId={}, memberId={} ====", seatId, memberId);

        Map<String, Object> map = new HashMap<String, Object>();
        map.put("seatId",   seatId);
        map.put("memberId", memberId);

        int result = seatService.holdSeat(map);

        Map<String, Object> response = new HashMap<String, Object>();
        String requestResult;
        if (result == 1) {
            response.put("result",  "success");
            response.put("message", "좌석 선점 성공");
            requestResult = "SUCCESS";
        } else {
            response.put("result",  "fail");
            response.put("message", "이미 선점된 좌석입니다");
            requestResult = "FAIL";
        }

        int elapsedMs = (int)(System.currentTimeMillis() - startTime);

        try {
            Long userIdLong    = parseLong(memberId);
            Long seatIdLong    = parseLong(seatId);
            Long concertIdLong = parseLong(concertId);
            Long scheduleIdLong= parseLong(scheduleId);

            // ★ 기존 SecurityLogger 유지
            SecurityLogger.seat(userIdLong, concertIdLong, seatIdLong, requestResult, elapsedMs);

            // ★ seat/select.do 로드 ~ hold.do 호출까지 시간 측정
            if (seatPageLoadTsStr != null && !seatPageLoadTsStr.isEmpty()) {
                long seatPageLoadTs = Long.parseLong(seatPageLoadTsStr);

                // redirectTime: GET /seat/select.do ~ POST /seat/hold.do 전체 소요 시간
                int redirectMs = (int)(startTime - seatPageLoadTs);
                MacroDetectionLogger.redirectTime(
                    userIdLong, srcIp, concertIdLong, scheduleIdLong, redirectMs
                );

                // seatHoldTime: 페이지 체류 시간 + 서버 처리 시간
                MacroDetectionLogger.seatHoldTime(
                    userIdLong, srcIp, concertIdLong, seatIdLong,
                    seatPageLoadTs, elapsedMs, requestResult
                );
            }

        } catch (Exception e) {
            log.warn("좌석 보안 로그 기록 실패: {}", e.getMessage());
        }

        return response;
    }

    // ================================================================
    // 4) 좌석 선점 해제 (HELD → AVAILABLE)
    // ================================================================
    @RequestMapping(value = "/seat/release.do", method = RequestMethod.POST)
    @ResponseBody
    public Map<String, Object> releaseSeat(
            @RequestParam("seatId")   String seatId,
            @RequestParam("memberId") String memberId,
            @RequestParam(value = "concertId", required = false) String concertId) throws Exception {

        long startTime = System.currentTimeMillis();

        log.debug("==== 좌석 해제 요청 : seatId={}, memberId={} ====", seatId, memberId);

        Map<String, Object> map = new HashMap<String, Object>();
        map.put("seatId",   seatId);
        map.put("memberId", memberId);

        int result = seatService.releaseSeat(map);

        Map<String, Object> response = new HashMap<String, Object>();
        String requestResult;
        if (result == 1) {
            response.put("result", "success");
            requestResult = "SUCCESS";
        } else {
            response.put("result", "fail");
            requestResult = "FAIL";
        }

        int elapsedMs = (int)(System.currentTimeMillis() - startTime);
        try {
            SecurityLogger.seat(parseLong(memberId), parseLong(concertId),
                    parseLong(seatId), requestResult, elapsedMs);
        } catch (Exception e) {
            log.warn("좌석 해제 보안 로그 실패: {}", e.getMessage());
        }

        return response;
    }

    // ================================================================
    // 5) 구역별 좌석 조회 (Ajax) ★봇 탐지용★
    //    zone(A~E) → seat_row 범위 매핑
    // ================================================================
    @RequestMapping(value = "/seat/zone.do", method = RequestMethod.GET)
    @ResponseBody
    public List<Map<String, Object>> seatListByZone(
            @RequestParam("scheduleId") String scheduleId,
            @RequestParam("zone")       String zone) throws Exception {

        log.debug("==== 구역별 좌석 조회 : scheduleId={}, zone={} ====", scheduleId, zone);

        int rowStart, rowEnd;
        switch (zone.toUpperCase()) {
            case "A": rowStart = 1;  rowEnd = 10; break;
            case "B": rowStart = 11; rowEnd = 20; break;
            case "C": rowStart = 21; rowEnd = 30; break;
            case "D": rowStart = 31; rowEnd = 40; break;
            case "E": rowStart = 41; rowEnd = 50; break;
            default:  rowStart = 1;  rowEnd = 50;
        }

        Map<String, Object> map = new HashMap<String, Object>();
        map.put("scheduleId", scheduleId);
        map.put("rowStart",   rowStart);
        map.put("rowEnd",     rowEnd);

        return seatService.selectSeatListByZone(map);
    }

    // ── 헬퍼 ────────────────────────────────────────────
    private Long parseLong(String s) {
        if (s == null || s.trim().isEmpty()) return null;
        try { return Long.parseLong(s.trim()); }
        catch (NumberFormatException e) { return null; }
    }

    private String getClientIp(HttpServletRequest request) {
        String ip = request.getHeader("X-Forwarded-For");
        if (ip == null || ip.isEmpty()) ip = request.getRemoteAddr();
        return ip.split(",")[0].trim();
    }
}
