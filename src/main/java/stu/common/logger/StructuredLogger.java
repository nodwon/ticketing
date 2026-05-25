/** 
* ============================================================ * 
Project : 관제 티켓 (Ticketing System)

- Package : stu.common.dao
- FileName : StructuredLogger.java *

* Developer : 이규왕 (feature/king)

* Created : 2026.05.24

- Modified : *
- Description :
 * 구조화 로그 헬퍼 (SLF4J only 버전).
 * - 프로젝트가 log4j 1.x 를 사용하므로 logstash-logback-encoder 를
 *   쓸 수 없는 환경. SLF4J 만으로 동일한 호출 형태를 흉내낸다.
 * - 출력 형태: "event_type=payment.attempt, booking_id=1, amount=50000"
 * - 관제 단계 진입 시 (logback + logstash-encoder) 로 교체 가능
 * — 호출부 코드는 그대로 두고 이 클래스만 바꾸면 됨
* ============================================================ */

package stu.common.logger;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class StructuredLogger {

    private final Logger logger;

    private StructuredLogger(Logger logger) {
        this.logger = logger;
    }

    public static StructuredLogger of(Class<?> clazz) {
        return new StructuredLogger(LoggerFactory.getLogger(clazz));
    }

    /** kv("key", value) 헬퍼 — 호출부가 logstash-encoder API 와 동일한 형태를 쓰도록 */
    public static KV kv(String key, Object value) {
        return new KV(key, value);
    }

    public void event(String eventType, KV... fields) {
        if (logger.isInfoEnabled()) {
            logger.info(format(eventType, fields));
        }
    }

    public void warnEvent(String eventType, KV... fields) {
        if (logger.isWarnEnabled()) {
            logger.warn(format(eventType, fields));
        }
    }

    public void errorEvent(String eventType, Throwable t, KV... fields) {
        if (logger.isErrorEnabled()) {
            logger.error(format(eventType, fields), t);
        }
    }

    private String format(String eventType, KV[] fields) {
        StringBuilder sb = new StringBuilder(128);
        sb.append("event_type=").append(eventType);
        if (fields != null) {
            for (KV f : fields) {
                if (f == null) continue;
                sb.append(", ").append(f.key).append('=').append(f.value);
            }
        }
        return sb.toString();
    }

    /** 키-값 쌍 단순 보유 객체 */
    public static class KV {
        final String key;
        final Object value;
        KV(String key, Object value) {
            this.key = key;
            this.value = value;
        }
    }
}