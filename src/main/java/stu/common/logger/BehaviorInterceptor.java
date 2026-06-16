/**
 * ============================================================
 * Project   : 관제 티켓 (Ticketing System)
 * Package   : stu.common.logger
 * FileName  : BehaviorInterceptor.java
 *
 * Description :
 *   모든 요청을 세션 BehaviorTracker 에 기록한다.
 *   → 요청 수 / 시각을 누적해 rps · burst · 평균 간격 계산의 근거가 된다.
 *   action-servlet.xml 에 등록.
 * ============================================================
 */
package stu.common.logger;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.springframework.web.servlet.handler.HandlerInterceptorAdapter;

public class BehaviorInterceptor extends HandlerInterceptorAdapter {

    @Override
    public boolean preHandle(HttpServletRequest request,
                             HttpServletResponse response,
                             Object handler) {
        try {
            HttpSession session = request.getSession(true);
            BehaviorTracker.get(session).recordRequest(System.currentTimeMillis());
        } catch (Exception ignore) {
            // 행동 추적 실패가 요청 처리를 막으면 안 됨
        }
        return true;
    }
}
