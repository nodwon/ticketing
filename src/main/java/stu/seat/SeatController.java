/**
 * ============================================================
 * Project   : 관제 티켓 (Ticketing System)
 * Package   : stu.seat
 * FileName  : SeatController.java
 *
 * Developer : 정희영 (feature/jhyjhy)
 * Modified  : 2026.05.26 - MacroDetectionLogger 통합
 * Modified  : 2026.05.29 - zone.do 보안 로그 추가 ★
 *
 * Description :
 *   1) GET  /seat/select.do  - 좌석 선택 페이지 진입
 *   2) GET  /seat/list.do    - 좌석 현황 조회 (Ajax)
 *   3) POST /seat/hold.do    - 좌석 임시 선점 ★매크로 탐지 로그★
 *   4) POST /seat/release.do - 좌석 선점 해제
 *   5) GET  /seat/zone.do    - 구역별 좌석 조회 ★봇 탐지 로그 추가★
 *
 * 매크로 탐지 시그니처 (zone.do):
 *   - 사람: 구역당 평균 2~5초 머묾, 보통 2~3개 구역만 둘러봄
 *   - 봇:  0.1초 안에 A→B→C→D→E 다 훑음 (정찰 패턴)
 *
 *   → log_seat.json 에 "request_result=ZONE_SCAN_X" 기록
 *      X = 클릭된 구역 (A/B/C/D/E)
 *      elapsed_time = 직전 zone 클릭 이후 경과시간 (세션에 저장)
 * ============================================================
 */
package stu.seat;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Set;
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
import stu.common.logger.BehaviorTracker;

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

            // ★ 세션에 '내가 hold한 좌석' 기록 → BookingService가 본인 좌석이면 통과시킴
            @SuppressWarnings("unchecked")
            Set<Long> myHeld = (Set<Long>) session.getAttribute("_my_held_seats");
            if (myHeld == null) {
                myHeld = new HashSet<Long>();
                session.setAttribute("_my_held_seats", myHeld);
            }
            try { myHeld.add(Long.parseLong(seatId)); } catch (Exception ignore) {}
        } else {
            // ★ fail: 이미 HELD상태. 본인이 이전에 잡았을 가능성이 있으니 세션에는 추가
            // (BookingService가 DB에서 정밀 검증하므로 다른 사람의 좌석이면 자동 거부됨)
            response.put("result",  "success");
            response.put("message", "좌석 선택됨 (본인 잡아둠)");
            requestResult = "ALREADY_HELD";

            @SuppressWarnings("unchecked")
            Set<Long> myHeld = (Set<Long>) session.getAttribute("_my_held_seats");
            if (myHeld == null) {
                myHeld = new HashSet<Long>();
                session.setAttribute("_my_held_seats", myHeld);
            }
            try { myHeld.add(Long.parseLong(seatId)); } catch (Exception ignore) {}
        }

        // ★ 행동 누적: 좌석 클릭 (seat_change_count / unique_seat_count)
        try { BehaviorTracker.get(session).recordSeat(parseLong(seatId)); } catch (Exception ignore) {}

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

                int redirectMs = (int)(startTime - seatPageLoadTs);
                MacroDetectionLogger.redirectTime(
                    userIdLong, srcIp, concertIdLong, scheduleIdLong, redirectMs
                );

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
            @RequestParam(value = "concertId", required = false) String concertId,
            HttpSession session) throws Exception {

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

            // ★ 세션에서 '내가 hold한 좌석' 목록에서 제거
            @SuppressWarnings("unchecked")
            Set<Long> myHeld = (Set<Long>) session.getAttribute("_my_held_seats");
            if (myHeld != null) {
                try { myHeld.remove(Long.parseLong(seatId)); } catch (Exception ignore) {}
            }
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
    // 5) 구역별 좌석 조회 (Ajax) ★봇 탐지 로그 추가★
    //
    //    탐지 시그니처:
    //    - 직전 zone 클릭으로부터 elapsed_time 측정 (세션 활용)
    //    - 사람: 평균 2000~5000ms
    //    - 봇:   100ms 이하 (구역 스캐닝 패턴)
    //
    //    기록 위치: log_seat.json
    //      - request_result = "ZONE_SCAN_A" / "ZONE_SCAN_B" / ...
    //      - elapsed_time   = 직전 zone 클릭 이후 경과시간
    //      - seat_id        = -1 (좌석이 아닌 구역 이벤트라는 의미)
    // ================================================================
    @RequestMapping(value = "/seat/zone.do", method = RequestMethod.GET)
    @ResponseBody
    public List<Map<String, Object>> seatListByZone(
            @RequestParam("scheduleId") String scheduleId,
            @RequestParam("zone")       String zone,
            HttpServletRequest request,
            HttpSession session) throws Exception {

        long startTime = System.currentTimeMillis();
        String srcIp   = getClientIp(request);

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

        List<Map<String, Object>> seatList = seatService.selectSeatListByZone(map);

        // ★★ 봇 탐지 보안 로그 (zone 클릭마다 기록) ─────────────
        try {
            // 세션에서 사용자 ID + 이전 zone 클릭 시각 추출
            Object sessionMemberNo = session.getAttribute("SESSION_NO");
            Long userId = sessionMemberNo != null
                    ? Long.parseLong(String.valueOf(sessionMemberNo)) : null;

            Long scheduleIdLong = parseLong(scheduleId);

            // ── 직전 zone 클릭 이후 경과시간 계산 ──
            String sessKey = "_last_zone_click_ts_" + scheduleId;
            Object lastClickObj = session.getAttribute(sessKey);
            int gapMs;

            if (lastClickObj != null) {
                gapMs = (int)(startTime - (Long) lastClickObj);
            } else {
                gapMs = -1;   // 첫 클릭 (이전 데이터 없음)
            }
            // 이번 클릭 시각 저장 (다음 클릭의 기준)
            session.setAttribute(sessKey, startTime);

            // ── log_seat.json 기록 ──
            // seatId=-1 (구역 이벤트라는 의미), result에 zone 정보 포함
            SecurityLogger.seat(
                userId,
                scheduleIdLong,        // concertId 자리에 scheduleId 사용 (기존 패턴 유지)
                -1L,                   // seatId = -1 (구역 이벤트)
                "ZONE_SCAN_" + zone.toUpperCase(),
                gapMs                  // ★ 핵심: 직전 zone 클릭부터 경과시간
            );

            log.debug("[ZONE_SCAN] user={}, zone={}, gap={}ms, isFast={}",
                    userId, zone, gapMs, (gapMs >= 0 && gapMs < 200));

        } catch (Exception e) {
            log.warn("zone 보안 로그 기록 실패: {}", e.getMessage());
        }

        return seatList;
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
