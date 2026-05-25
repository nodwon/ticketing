<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    결제 모듈 단독 테스트용 임시 로그인 페이지.

    회원 모듈이 구현되기 전까지 세션에 memberId 를 박아두는 용도.
    seed-data.sql 로 INSERT 한 회원의 member_id 를 사용한다.

    !!! 운영 배포 시 반드시 제거 또는 비활성화 !!!
--%>
<%
    // 첫 회원이 보통 member_id = 1
    String memberIdParam = request.getParameter("memberId");
    Long memberId = (memberIdParam == null || memberIdParam.isEmpty())
                    ? 1L : Long.parseLong(memberIdParam);

    session.setAttribute("memberId", memberId);
%>
<!DOCTYPE html>
<html>
<head><title>[TEST] 세션 주입</title></head>
<body>
    <h2>[테스트 전용] 세션 주입 완료</h2>
    <p>session.memberId = <%= memberId %></p>
    <hr>
    <h3>결제 흐름 진입</h3>
    <ul>
        <li><a href="<%= request.getContextPath() %>/payment/form.do?bookingId=1">
            정상 결제: bookingId=1
        </a></li>
        <li><a href="<%= request.getContextPath() %>/payment/form.do?bookingId=999">
            존재하지 않는 booking: bookingId=999
        </a></li>
        <li><a href="<%= request.getContextPath() %>/payment/form.do?bookingId=<script>alert(1)</script>">
            XSS payload in bookingId
        </a></li>
    </ul>
</body>
</html>