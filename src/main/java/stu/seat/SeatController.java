/**
 * ============================================================
 * Project  : 관제 티켓 (Ticketing System)
 * Package  : stu.seat
 * FileName : SeatController.java
 * 
 * Developer : 정희영 (feature/jhyjhy)
 * Created   : 2026.05.24
 * Modified  : 2026.05.27 - SecurityLogger 통합 (매크로 봇 탐지)
 * Modified  : 2026.05.29 - 김희재 (구역별 좌석 조회 추가, 봇 탐지용)
 * 
 * Description :
 * - 좌석 관련 요청 처리 Controller
 * - 명세서 API 14, 15, 16, 17번 구현
 * - ★ 매크로 봇 탐지: elapsed_time 측정 후 log_seat.json 기록
 *   1) GET    /seat/select.do   - 좌석 선택 페이지 진입
 *   2) GET    /seat/list.do     - 좌석 현황 조회 (Ajax)
 *   3) POST   /seat/hold.do     - 좌석 임시 선점 ★보안로그★
 *   4) POST   /seat/release.do  - 좌석 선점 해제 ★보안로그★
 *   5) GET    /seat/zone.do     - 구역별 좌석 조회 (Ajax) ★봇 탐지용★ [김희재 추가]
 * ============================================================
 */
package stu.seat;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.ModelAndView;

import stu.common.logger.SecurityLogger;             // ★★ 추가

@Controller
public class SeatController {
    
    private Logger log = LoggerFactory.getLogger(this.getClass());
    
    @Resource(name="seatService")
    private SeatService seatService;
    
    /**
     * 1) 좌석 선택 페이지 진입
     */
    @RequestMapping(value="/seat/select.do", method=RequestMethod.GET)
    public ModelAndView seatSelectPage(@RequestParam("scheduleId") String scheduleId) throws Exception {
        log.debug("==== 좌석 선택 페이지 요청 : scheduleId={} ====", scheduleId);
        
        ModelAndView mv = new ModelAndView("seat/seatSelect");
        mv.addObject("scheduleId", scheduleId);
        return mv;
    }
    
    /**
     * 2) 좌석 현황 조회 (Ajax)
     */
    @RequestMapping(value="/seat/list.do", method=RequestMethod.GET)
    @ResponseBody
    public List<Map<String, Object>> seatList(@RequestParam("scheduleId") String scheduleId) throws Exception {
        log.debug("==== 좌석 목록 조회 : scheduleId={} ====", scheduleId);
        
        Map<String, Object> map = new HashMap<String, Object>();
        map.put("scheduleId", scheduleId);
        
        return seatService.selectSeatList(map);
    }
    
    /**
     * 3) 좌석 임시 선점 (AVAILABLE → HELD) ★보안로그★
     *    - elapsed_time 측정 → 100ms 미만이면 매크로 봇 의심
     */
    @RequestMapping(value="/seat/hold.do", method=RequestMethod.POST)
    @ResponseBody
    public Map<String, Object> holdSeat(
            @RequestParam("seatId") String seatId,
            @RequestParam("memberId") String memberId,
            @RequestParam(value="concertId", required=false) String concertId) throws Exception {
        
        // ★ 매크로 탐지용 시작 시간 기록
        long startTime = System.currentTimeMillis();
        
        log.debug("==== 좌석 선점 요청 : seatId={}, memberId={} ====", seatId, memberId);
        
        Map<String, Object> map = new HashMap<String, Object>();
        map.put("seatId", seatId);
        map.put("memberId", memberId);
        
        int result = seatService.holdSeat(map);
        
        Map<String, Object> response = new HashMap<String, Object>();
        String requestResult;
        if (result == 1) {
            response.put("result", "success");
            response.put("message", "좌석 선점 성공");
            requestResult = "SUCCESS";
        } else {
            response.put("result", "fail");
            response.put("message", "이미 선점된 좌석입니다");
            requestResult = "FAIL";
        }
        
        // ★★ 보안 로그: 좌석 선점 이벤트 + 처리시간 (매크로 탐지용)
        int elapsedMs = (int)(System.currentTimeMillis() - startTime);
        try {
            Long userIdLong = parseLong(memberId);
            Long seatIdLong = parseLong(seatId);
            Long concertIdLong = parseLong(concertId);
            
            SecurityLogger.seat(userIdLong, concertIdLong, seatIdLong, requestResult, elapsedMs);
        } catch (Exception e) {
            log.warn("좌석 보안 로그 기록 실패: {}", e.getMessage());
        }
        
        return response;
    }
    
    /**
     * 4) 좌석 선점 해제 (HELD → AVAILABLE) ★보안로그★
     */
    @RequestMapping(value="/seat/release.do", method=RequestMethod.POST)
    @ResponseBody
    public Map<String, Object> releaseSeat(
            @RequestParam("seatId") String seatId,
            @RequestParam("memberId") String memberId,
            @RequestParam(value="concertId", required=false) String concertId) throws Exception {
        
        long startTime = System.currentTimeMillis();
        
        log.debug("==== 좌석 해제 요청 : seatId={}, memberId={} ====", seatId, memberId);
        
        Map<String, Object> map = new HashMap<String, Object>();
        map.put("seatId", seatId);
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
        
        // ★★ 보안 로그: 좌석 해제 이벤트
        int elapsedMs = (int)(System.currentTimeMillis() - startTime);
        try {
            Long userIdLong = parseLong(memberId);
            Long seatIdLong = parseLong(seatId);
            Long concertIdLong = parseLong(concertId);
            
            SecurityLogger.seat(userIdLong, concertIdLong, seatIdLong, requestResult, elapsedMs);
        } catch (Exception e) {
            log.warn("좌석 보안 로그 기록 실패: {}", e.getMessage());
        }
        
        return response;
    }
    
    /**
     * 5) 구역별 좌석 조회 (Ajax) ★봇 탐지용★
     *    [2026.05.29 김희재 추가]
     *    - 구역(A~E) 버튼 클릭 시마다 호출되는 AJAX 엔드포인트
     *    - 정상 사용자: 평균 2~3개 구역 조회 (둘러보는 행동)
     *    - 봇: 0개 또는 5개 전부 순식간에 조회
     *    - 봇 시그니처: log_api에 동일 session/IP의 zone.do 호출 패턴 분석
     *    
     *    zone(A~E) → seat_row 범위 매핑 (DB에 zone 컬럼 없음, UI 정의 기준)
     *      A: 1~10  / B: 11~20 / C: 21~30 / D: 31~40 / E: 41~50
     */
    @RequestMapping(value="/seat/zone.do", method=RequestMethod.GET)
    @ResponseBody
    public List<Map<String, Object>> seatListByZone(
            @RequestParam("scheduleId") String scheduleId,
            @RequestParam("zone") String zone) throws Exception {
        
        log.debug("==== 구역별 좌석 조회 : scheduleId={}, zone={} ====", scheduleId, zone);
        
        // zone(A~E) → seat_row 범위 매핑
        int rowStart, rowEnd;
        switch (zone.toUpperCase()) {
            case "A": rowStart = 1;  rowEnd = 10; break;
            case "B": rowStart = 11; rowEnd = 20; break;
            case "C": rowStart = 21; rowEnd = 30; break;
            case "D": rowStart = 31; rowEnd = 40; break;
            case "E": rowStart = 41; rowEnd = 50; break;
            default:  rowStart = 1;  rowEnd = 50;   // 잘못된 zone 값이면 전체
        }
        
        Map<String, Object> map = new HashMap<String, Object>();
        map.put("scheduleId", scheduleId);
        map.put("rowStart", rowStart);
        map.put("rowEnd", rowEnd);
        
        return seatService.selectSeatListByZone(map);
    }
    
    /**
     * ★ 헬퍼: String → Long 안전 변환 (null 허용)
     */
    private Long parseLong(String s) {
        if (s == null || s.trim().isEmpty()) return null;
        try {
            return Long.parseLong(s.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }
}
