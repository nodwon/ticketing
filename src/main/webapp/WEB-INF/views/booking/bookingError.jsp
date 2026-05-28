<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>예매 오류 | GWANJE TICKET</title>
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/theme.css">
<style>
    body { background: var(--gray); }
    .er-container {
        max-width: 600px; margin: 56px auto; background: var(--white); padding: 48px 40px;
        border: 1px solid var(--border); border-radius: var(--radius-lg);
        box-shadow: var(--shadow); text-align: center;
    }
    .error-icon { font-size: 60px; margin-bottom: 20px; }
    .er-container h1 { color: var(--dark); margin-bottom: 20px; font-size: 24px; }
    .error-msg {
        background: #fde8ea; border-left: 4px solid var(--red);
        padding: 20px; margin: 20px 0; text-align: left; color: #7a2230;
        word-break: break-all; line-height: 1.6; border-radius: 0 var(--radius) var(--radius) 0;
    }
    .actions { margin-top: 30px; display: flex; gap: 10px; justify-content: center; flex-wrap: wrap; }
</style>
</head>
<body>
    <div class="er-container">
        <div class="error-icon">⚠️</div>
        <h1>예매 처리 중 오류가 발생했습니다</h1>

        <div class="error-msg">
            <strong>오류 내용:</strong><br>
            <c:out value="${errorMessage}" default="알 수 없는 오류" />
        </div>

        <div class="actions">
            <c:if test="${not empty scheduleId}">
                <a href="<c:url value='/seat/select.do?scheduleId=${scheduleId}'/>" class="tk-btn tk-btn-primary">
                    🪑 좌석 다시 선택
                </a>
            </c:if>
            <a href="<c:url value='/'/>" class="tk-btn tk-btn-ghost">🏠 메인으로</a>
        </div>
    </div>
</body>
</html>
