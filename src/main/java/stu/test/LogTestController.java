/**
 * ============================================================
 * Project   : 티켓팅 보안관제
 * Package   : stu.test
 * FileName  : LogTestController.java
 * Purpose   : 보안 로그 출력 테스트 전용 컨트롤러
 * Usage     :
 *   http://localhost:8080/test/log.do  → 모든 로그 1세트 발생
 *   http://localhost:8080/test/attack.do?type=brute  → 공격 시나리오
 * Note      :
 *   - 개발/테스트 환경에서만 사용
 *   - 운영 배포 시 제거하거나 admin only로 제한
 * ============================================================
 */
package stu.test;

import javax.servlet.http.HttpServletRequest;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import stu.common.logger.SecurityLogger;

@Controller
@RequestMapping("/test")
public class LogTestController {

    /* ============================================================
     * /test/log.do
     *   - 6종 보안 로그를 1세트씩 발생시킴
     *   - 결과: C:/logs/ticketing/security/ 아래에 6개 JSON 파일 생성
     * ============================================================ */
    @RequestMapping("/log.do")
    @ResponseBody
    public String testLog(HttpServletRequest request) {
        String ip = request.getRemoteAddr();
        StringBuilder sb = new StringBuilder();

        // 1. log_auth - 로그인 성공/실패
        SecurityLogger.auth(1001L, ip, "SUCCESS");
        SecurityLogger.auth(null,  ip, "FAIL");
        sb.append("log_auth: 2 events<br>");

        // 2. log_seat - 좌석 선택
        SecurityLogger.seat(1001L, 100L, 5001L, "SUCCESS", 42);
        SecurityLogger.seat(1001L, 100L, 5002L, "FAIL",    18);
        sb.append("log_seat: 2 events<br>");

        // 3. log_payment - 결제 (TAMPER 시나리오 포함)
        SecurityLogger.payment(1001L, "TX_NORMAL_001", 100000L, 100000L, "SUCCESS");
        SecurityLogger.payment(1001L, "TX_TAMPER_002", 150000L, 100000L, "TAMPER");
        sb.append("log_payment: 2 events (1 TAMPER)<br>");

        // 4. log_admin_access - 관리자 접근
        SecurityLogger.adminAccess("/admin/main.do",   1001L, ip, 200);
        SecurityLogger.adminAccess("/admin/users",     null,  ip, 403);
        sb.append("log_admin_access: 2 events<br>");

        // 5. log_board - 게시판
        SecurityLogger.board(1001L, "NOTICE", "테스트 글입니다", "report.pdf", "pdf");
        SecurityLogger.board(1001L, "QNA",    "이상한 첨부",     "malicious.exe", "exe");
        sb.append("log_board: 2 events (1 suspicious ext)<br>");

        // 6. log_behavior_feature - MLTK 행동 Feature
        SecurityLogger.behavior(1001L, ip)
            .requestsPerSecond(42.5)
            .requestsPerMinute(1850.0)
            .burstRequestCount(15)
            .seatChangeCount(120)
            .uniqueSeatCount(85)
            .failedSelectRatio(0.85)
            .avgActionInterval(50.0)
            .loginFailRatio(0.0)
            .excessiveTokenRequest(true)
            .emit();
        sb.append("log_behavior_feature: 1 event<br>");

        sb.insert(0, "<h2>Security Log Test - OK</h2>");
        sb.append("<hr>Check: <code>C:/logs/ticketing/security/</code>");
        return sb.toString();
    }

    /* ============================================================
     * /test/attack.do?type=brute     → 무차별 로그인 공격 시뮬레이션
     * /test/attack.do?type=replay    → 결제 Replay Attack
     * /test/attack.do?type=tamper    → 결제 금액 변조
     * /test/attack.do?type=macro     → 좌석 매크로
     * ============================================================ */
    @RequestMapping("/attack.do")
    @ResponseBody
    public String simulateAttack(
            @RequestParam(defaultValue = "brute") String type,
            HttpServletRequest request) {

        String ip = request.getRemoteAddr();

        switch (type) {

            case "brute":
                // 50회 연속 로그인 실패 (크리덴셜 스터핑)
                for (int i = 0; i < 50; i++) {
                    SecurityLogger.auth(null, ip, "FAIL");
                }
                // 행동 Feature 에 잡혀야 함
                SecurityLogger.behavior(null, ip)
                    .requestsPerSecond(25.0)
                    .loginFailRatio(1.0)
                    .repeatedFailCount(50)
                    .targetAccountCount(50)
                    .emit();
                return "[ATTACK] Brute force: 50 failed logins from " + ip;

            case "replay":
                // 같은 transaction_id 로 결제 3회
                String txId = "TX_REPLAY_" + System.currentTimeMillis();
                SecurityLogger.payment(1001L, txId, 50000L, 50000L, "SUCCESS");
                SecurityLogger.payment(1001L, txId, 50000L, 50000L, "SUCCESS");
                SecurityLogger.payment(1001L, txId, 50000L, 50000L, "SUCCESS");
                return "[ATTACK] Replay attack: same txId 3 times = " + txId;

            case "tamper":
                // 금액 변조 시도
                SecurityLogger.payment(1001L, "TX_TAMPER_" + System.currentTimeMillis(),
                                       1000L, 200000L, "TAMPER");
                return "[ATTACK] Payment tamper: requested 1000, actual 200000";

            case "macro":
                // 좌석 100개 1초 안에 선택 시도
                for (int i = 1; i <= 100; i++) {
                    SecurityLogger.seat(2001L, 100L, (long)(5000 + i),
                                        i % 5 == 0 ? "FAIL" : "SUCCESS", 5);
                }
                SecurityLogger.behavior(2001L, ip)
                    .requestsPerSecond(100.0)
                    .burstRequestCount(100)
                    .seatChangeCount(100)
                    .uniqueSeatCount(100)
                    .avgActionInterval(10.0)
                    .emit();
                return "[ATTACK] Seat macro: 100 seats selected in 1s";

            default:
                return "Unknown attack type. Use: brute, replay, tamper, macro";
        }
    }
}
