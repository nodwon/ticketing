<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>예매 오류</title>
<style>
    body { font-family: 'Malgun Gothic', sans-serif; background: #f5f5f5; padding: 50px; }
    .container { 
        max-width: 600px; margin: 0 auto; background: #fff; padding: 40px; 
        border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); text-align: center;
    }
    .error-icon { font-size: 60px; margin-bottom: 20px; }
    h1 { color: #e74c3c; margin-bottom: 20px; }
    .error-msg {
        background: #fff5f5; border-left: 4px solid #e74c3c;
        padding: 20px; margin: 20px 0; text-align: left; color: #555;
        word-break: break-all; line-height: 1.6;
    }
    .actions { margin-top: 30px; }
    .btn {
        display: inline-block; padding: 12px 24px; margin: 0 5px;
        background: #4a90e2; color: #fff; text-decoration: none;
        border-radius: 6px; font-weight: bold;
    }
    .btn-secondary { background: #95a5a6; }
</style>
</head>
<body>
    <div class="container">
        <div class="error-icon">⚠️</div>
        <h1>예매 처리 중 오류가 발생했습니다</h1>
        
        <div class="error-msg">
            <strong>오류 내용:</strong><br>
            <c:out value="${errorMessage}" default="알 수 없는 오류" />
        </div>
        
        <div class="actions">
            <c:if test="${not empty scheduleId}">
                <a href="<c:url value='/seat/select.do?scheduleId=${scheduleId}'/>" class="btn">
                    🪑 좌석 다시 선택
                </a>
            </c:if>
            <a href="<c:url value='/'/>" class="btn btn-secondary">🏠 메인으로</a>
        </div>
    </div>
</body>
</html>