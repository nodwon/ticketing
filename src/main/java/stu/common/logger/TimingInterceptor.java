/**
 * ============================================================
 * Project   : 관제 티켓 (Ticketing System)
 * Package   : stu.common.logger
 * FileName  : TimingInterceptor.java
 *
 * Description :
 *   모든 요청 시작 시간을 request attribute 에 저장
 *   컨트롤러에서 getElapsed(request) 로 경과 시간 조회
 *
 *   context-mvc.xml 등록:
 *   <mvc:interceptors>
 *     <bean class="stu.common.logger.TimingInterceptor"/>
 *   </mvc:interceptors>
 * ============================================================
 */
package stu.common.logger;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.springframework.web.servlet.handler.HandlerInterceptorAdapter;

public class TimingInterceptor extends HandlerInterceptorAdapter {

    public static final String START_TIME_ATTR = "_req_start_ms";

    @Override
    public boolean preHandle(HttpServletRequest request,
                             HttpServletResponse response,
                             Object handler) throws Exception {
        request.setAttribute(START_TIME_ATTR, System.currentTimeMillis());
        return true;
    }

    /** 경과 시간 조회 헬퍼 */
    public static int getElapsed(HttpServletRequest request) {
        Object start = request.getAttribute(START_TIME_ATTR);
        if (start == null) return -1;
        return (int)(System.currentTimeMillis() - (Long) start);
    }
}
