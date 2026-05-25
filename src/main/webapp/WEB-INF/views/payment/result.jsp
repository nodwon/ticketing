<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<title>결제 완료</title>
</head>
<body>
    <div style="text-align:center; margin-top:50px;">
        <h2>🎉 결제가 정상적으로 완료되었습니다!</h2>
        <p>고객님의 예매 내역이 안전하게 저장되었습니다.</p>
        <p>전송된 데이터: ${msg}</p>
        <br>
        <a href="${pageContext.request.contextPath}/main.do">[메인으로 이동]</a>
    </div>
</body>
</html>
