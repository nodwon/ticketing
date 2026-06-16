/**
 * ============================================================
 * Project   : 관제 티켓 (Ticketing System)
 * Package   : stu.common.logger
 * FileName  : ClickIntervalController.java
 *
 * Description :
 *   seatSelect.jsp JS에서 수집한 클릭 타임스탬프를 받아 로그 기록
 *   URL: POST /log/clickInterval.do
 *
 *   Request Parameters:
 *   - timestamps : 콤마 구분 타임스탬프 목록  예) "1716000100,1716000300,1716000550"
 *   - concertId  : 공연 ID
 * ============================================================
 */
package stu.common.logger;

import java.util.HashMap;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

@Controller
public class ClickIntervalController {

    private static final Logger log = LoggerFactory.getLogger(ClickIntervalController.class);

    @RequestMapping(value = "/log/clickInterval.do", method = RequestMethod.POST)
    @ResponseBody
    public Map<String, Object> logClickInterval(
            @RequestParam("timestamps") String timestampsStr,
            @RequestParam(value = "concertId", required = false) String concertIdStr,
            HttpServletRequest request,
            HttpSession session) {

        Map<String, Object> resp = new HashMap<String, Object>();

        try {
            Object sessionMemberNo = session.getAttribute("SESSION_NO");
            Long userId   = sessionMemberNo != null
                    ? Long.parseLong(String.valueOf(sessionMemberNo)) : null;
            String srcIp  = getClientIp(request);
            Long concertId = concertIdStr != null ? Long.parseLong(concertIdStr) : null;

            String[] parts = timestampsStr.split(",");
            if (parts.length < 2) {
                resp.put("result", "skip");
                return resp;
            }

            long[] ts = new long[parts.length];
            for (int i = 0; i < parts.length; i++) {
                ts[i] = Long.parseLong(parts[i].trim());
            }

            double[] intervals = new double[ts.length - 1];
            for (int i = 0; i < intervals.length; i++) {
                intervals[i] = ts[i + 1] - ts[i];
            }

            double avg = average(intervals);
            double std = stdDev(intervals, avg);

            MacroDetectionLogger.clickInterval(userId, srcIp, avg, std, ts.length, concertId);
            BehaviorTracker.get(session).recordClicks(avg, std, ts.length);

            log.debug("[클릭간격] userId={}, avg={}ms, std={}, clicks={}", userId, avg, std, ts.length);

            resp.put("result", "ok");
            resp.put("avg_ms", avg);
            resp.put("std",    std);

        } catch (Exception e) {
            log.warn("클릭 간격 로그 실패: {}", e.getMessage());
            resp.put("result", "error");
        }

        return resp;
    }

    private double average(double[] arr) {
        double sum = 0;
        for (double v : arr) sum += v;
        return sum / arr.length;
    }

    private double stdDev(double[] arr, double avg) {
        double sum = 0;
        for (double v : arr) sum += (v - avg) * (v - avg);
        return Math.sqrt(sum / arr.length);
    }

    private String getClientIp(HttpServletRequest request) {
        String ip = request.getHeader("X-Forwarded-For");
        if (ip == null || ip.isEmpty()) ip = request.getRemoteAddr();
        return ip.split(",")[0].trim();
    }
}
