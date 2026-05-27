/**
 * ============================================================
 * Project  : 관제 티켓 (Ticketing System)
 * Package  : stu.booking
 * FileName : PendingBookingTracker.java
 *
 * Created  : 2026-05-26
 *
 * Description :
 *   PENDING 예매의 lifecycle 추적기.
 *
 *   [필요성]
 *   결제 페이지에서 사용자가 브라우저를 강제 종료하면 좌석이 HELD,
 *   bookings 는 PENDING 으로 영원히 남는 문제가 있다.
 *   DB 스키마를 변경하지 않고 다음 두 채널로 감지한다:
 *
 *     1) navigator.sendBeacon  (정상 닫힘 / 새로고침 / 탭 전환)
 *        → /booking/abandon.do 호출 → 즉시 cancelBooking
 *
 *     2) Heartbeat (30초 주기)
 *        → /booking/heartbeat.do 호출 → 메모리 Map 의 lastSeenAt 갱신
 *        → 본 클래스의 sweeper 가 60초 이상 갱신 없는 PENDING 을 cancel
 *        → 전원 OFF, 네트워크 단절 등 beacon 못 가는 케이스 커버
 *
 *   [관제]
 *   abandon 사유 (beacon / heartbeat-timeout / explicit) 를 로그로 분리.
 *   Splunk 에서 이탈/강제종료 비율 대시보드 작성 가능.
 *
 *   [메모리 관리]
 *   ConcurrentHashMap 단일. 인메모리만 사용 → 서버 재시작 시 추적정보 소실.
 *   재시작 시 살아남은 PENDING 은 별도 부트 스윕이 정리한다 (sweep 메서드 동일 로직 재사용).
 * ============================================================
 */
package stu.booking;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

import javax.annotation.PostConstruct;
import javax.annotation.PreDestroy;
import javax.annotation.Resource;

import org.apache.log4j.Logger;
import org.springframework.stereotype.Component;

import stu.common.common.CommandMap;

@Component("pendingBookingTracker")
public class PendingBookingTracker {

    private static final Logger log = Logger.getLogger(PendingBookingTracker.class);

    // 클라이언트가 heartbeat 를 보내는 간격: 30초
    // 서버가 만료로 판단하는 무응답 임계치: 60초 (= 2번 연속 누락)
    private static final long HEARTBEAT_TIMEOUT_MS = 60_000L;
    // sweeper 실행 주기: 30초
    private static final long SWEEP_INTERVAL_SEC   = 30L;

    @Resource(name = "bookingService")
    private BookingService bookingService;

    // bookingId → lastSeenAt (millis)
    private final Map<Long, Long> lastSeenAt = new ConcurrentHashMap<Long, Long>();

    private ScheduledExecutorService scheduler;


    // ====================================================
    // 라이프사이클
    // ====================================================
    @PostConstruct
    public void start() {
        scheduler = Executors.newSingleThreadScheduledExecutor(new java.util.concurrent.ThreadFactory() {
            public Thread newThread(Runnable r) {
                Thread t = new Thread(r, "pending-booking-sweeper");
                t.setDaemon(true);
                return t;
            }
        });
        scheduler.scheduleWithFixedDelay(new Runnable() {
            public void run() {
                try {
                    sweepExpired();
                } catch (Throwable t) {
                    log.error("sweep 중 예외", t);
                }
            }
        }, SWEEP_INTERVAL_SEC, SWEEP_INTERVAL_SEC, TimeUnit.SECONDS);

        log.info("PendingBookingTracker 시작 - sweep 주기 " + SWEEP_INTERVAL_SEC
                + "s, 만료 임계치 " + HEARTBEAT_TIMEOUT_MS + "ms");
    }

    @PreDestroy
    public void stop() {
        if (scheduler != null) {
            scheduler.shutdownNow();
        }
    }


    // ====================================================
    // 외부 API (Controller 에서 호출)
    // ====================================================

    /** 결제 페이지 진입 시 추적 등록 */
    public void register(long bookingId) {
        lastSeenAt.put(bookingId, System.currentTimeMillis());
        log.info("PENDING 추적 등록 - bookingId=" + bookingId);
    }

    /** Heartbeat 수신 */
    public void heartbeat(long bookingId) {
        // 이미 등록된 것만 갱신 (낯선 bookingId 가 임의로 끼어드는 것 차단)
        if (lastSeenAt.containsKey(bookingId)) {
            lastSeenAt.put(bookingId, System.currentTimeMillis());
        }
    }

    /** 정상 종료 (beacon / 명시적 취소) → 즉시 정리 */
    public void abandonImmediately(long bookingId, String reason) {
        Long removed = lastSeenAt.remove(bookingId);
        if (removed == null) {
            log.debug("추적되지 않은 bookingId 의 abandon 요청 (이미 정리됨?) - bookingId="
                    + bookingId + ", reason=" + reason);
            return;
        }
        cancelQuietly(bookingId, reason);
    }

    /** 결제 확정 시 추적 해제 (정리할 필요 없음) */
    public void confirmed(long bookingId) {
        lastSeenAt.remove(bookingId);
    }


    // ====================================================
    // 내부: 만료 스윕
    // ====================================================
    void sweepExpired() {
        long now = System.currentTimeMillis();
        List<Long> expired = new ArrayList<Long>();

        for (Map.Entry<Long, Long> e : lastSeenAt.entrySet()) {
            if (now - e.getValue() > HEARTBEAT_TIMEOUT_MS) {
                expired.add(e.getKey());
            }
        }

        if (expired.isEmpty()) return;

        log.info("만료 PENDING 감지 - " + expired.size() + "건: " + expired);
        for (Long bookingId : expired) {
            lastSeenAt.remove(bookingId);
            cancelQuietly(bookingId, "heartbeat-timeout");
        }
    }

    private void cancelQuietly(long bookingId, String reason) {
        try {
            CommandMap cm = new CommandMap();
            cm.put("bookingId", String.valueOf(bookingId));
            bookingService.cancelBooking(cm);
            log.info("[booking.abandon] reason=" + reason + " bookingId=" + bookingId + " result=ok");
        } catch (Exception ex) {
            // 이미 CONFIRMED/CANCELLED 된 케이스는 BookingService 가 예외를 던짐 → 정상
            log.info("[booking.abandon] reason=" + reason + " bookingId=" + bookingId
                    + " result=skip msg=" + ex.getMessage());
        }
    }
}
