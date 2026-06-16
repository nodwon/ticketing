/**
 * ============================================================
 * Project   : 관제 티켓 (Ticketing System)
 * Package   : stu.common.logger
 * FileName  : BehaviorTracker.java
 *
 * Description :
 *   세션 단위 행동 누적기.
 *   예매 흐름(로그인→좌석→예매→결제) 동안 요청/좌석/로그인/클릭을 모아 두었다가
 *   예매 완료 시점(PaymentController)에 behavior_feature 로 발행한다.
 *   - 세션 속성 "_behavior_tracker" 에 저장
 *   - 모든 메서드 null-safe (트래커가 없어도 기존 흐름이 깨지지 않음)
 * ============================================================
 */
package stu.common.logger;

import javax.servlet.http.HttpSession;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class BehaviorTracker implements Serializable {

    private static final long serialVersionUID = 1L;
    public  static final String SESSION_KEY     = "_behavior_tracker";
    private static final int    MAX_TIMES       = 1000;   // 요청 시각 보관 상한
    private static final long   BURST_WINDOW_MS = 1000L;  // 버스트 판정 창(1초)

    // 요청
    private long firstRequestMs = 0L;
    private long lastRequestMs  = 0L;
    private int  requestCount   = 0;
    private final List<Long> reqTimes = new ArrayList<Long>();

    // 좌석
    private int seatChangeCount = 0;
    private final Set<Long> uniqueSeats = new HashSet<Long>();

    // 로그인
    private int loginAttempts = 0;
    private int loginFails    = 0;
    private final Set<String> targetAccounts = new HashSet<String>();

    // 클릭(ClickIntervalController 에서 주입)
    private Double  avgClickInterval;
    private Double  clickIntervalStd;
    private Integer clickCount;

    /** 세션에서 가져오거나 없으면 생성 */
    public static synchronized BehaviorTracker get(HttpSession session) {
        if (session == null) return new BehaviorTracker();
        Object o = session.getAttribute(SESSION_KEY);
        if (o instanceof BehaviorTracker) return (BehaviorTracker) o;
        BehaviorTracker t = new BehaviorTracker();
        session.setAttribute(SESSION_KEY, t);
        return t;
    }

    // ── 기록 ───────────────────────────────
    public synchronized void recordRequest(long nowMs) {
        if (firstRequestMs == 0L) firstRequestMs = nowMs;
        lastRequestMs = nowMs;
        requestCount++;
        reqTimes.add(nowMs);
        if (reqTimes.size() > MAX_TIMES) reqTimes.remove(0);
    }

    public synchronized void recordSeat(Long seatId) {
        seatChangeCount++;
        if (seatId != null) uniqueSeats.add(seatId);
    }

    public synchronized void recordLogin(String account, boolean success) {
        loginAttempts++;
        if (!success) loginFails++;
        if (account != null && !account.isEmpty()) targetAccounts.add(account);
    }

    public synchronized void recordClicks(double avg, double std, int count) {
        this.avgClickInterval = avg;
        this.clickIntervalStd = std;
        this.clickCount       = count;
    }

    // ── 계산(피처) ─────────────────────────
    public synchronized double getRequestsPerSecond() {
        long span = lastRequestMs - firstRequestMs;
        return span <= 0 ? 0.0 : requestCount / (span / 1000.0);
    }

    public synchronized double getRequestsPerMinute() {
        long span = lastRequestMs - firstRequestMs;
        return span <= 0 ? 0.0 : requestCount / (span / 60000.0);
    }

    /** 1초 창 안에 몰린 최대 요청 수 */
    public synchronized int getBurstRequestCount() {
        int max = 0;
        for (int i = 0; i < reqTimes.size(); i++) {
            long t0 = reqTimes.get(i);
            int c = 0;
            for (int j = i; j < reqTimes.size(); j++) {
                if (reqTimes.get(j) - t0 <= BURST_WINDOW_MS) c++;
                else break;
            }
            if (c > max) max = c;
        }
        return max;
    }

    /** 요청 간 평균 간격(ms) */
    public synchronized double getAvgActionInterval() {
        if (reqTimes.size() < 2) return 0.0;
        long sum = 0;
        for (int i = 1; i < reqTimes.size(); i++) sum += (reqTimes.get(i) - reqTimes.get(i - 1));
        return (double) sum / (reqTimes.size() - 1);
    }

    public synchronized int    getSeatChangeCount()  { return seatChangeCount; }
    public synchronized int    getUniqueSeatCount()  { return uniqueSeats.size(); }
    public synchronized double getLoginFailRatio()   { return loginAttempts == 0 ? 0.0 : (double) loginFails / loginAttempts; }
    public synchronized int    getRepeatedFailCount(){ return loginFails; }
    public synchronized int    getTargetAccountCount(){ return targetAccounts.isEmpty() ? 1 : targetAccounts.size(); }
    public synchronized Double getAvgClickInterval() { return avgClickInterval; }
    public synchronized Double getClickIntervalStd() { return clickIntervalStd; }
    public synchronized Integer getClickCount()      { return clickCount; }
}
