<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<title>가짜 결제 시스템</title>
</head>
<body>
    <h2>💳 결제 및 예매 정보 확인</h2>

    <%-- 취약점 유지: booking 이 null 이어도 그대로 EL 출력 (B안) --%>
    <p>예매 ID: ${bookingId}</p>
    <p>콘서트: ${booking.CONCERTTITLE}</p>
    <p>아티스트: ${booking.ARTIST}</p>
    <p>공연장: ${booking.VENUE}</p>
    <p>관람일: ${booking.PERFORMANCEDATE}</p>
    <p>최종 결제 금액: <strong>${booking.TOTALPRICE} 원</strong></p>
    <p>예매 상태: ${booking.BOOKINGSTATUS}</p>

    <hr>

    <form action="${pageContext.request.contextPath}/payment/result.do" method="post">
        <%-- bookingId 만 받는 게 정석이나, B안에서는 변조 시나리오 수집을 위해 hidden 으로 다 노출 --%>
        <input type="hidden" name="bookingId" value="${bookingId}">
        <input type="hidden" name="amount"    value="${booking.TOTALPRICE}">
        <input type="hidden" name="memberId"  value="${booking.MEMBERID}">

        <h3>결제 수단 선택 (가짜)</h3>
        <input type="radio" name="payMethod" value="CARD" checked> 신용카드
        <input type="radio" name="payMethod" value="BANK"> 계좌이체
        <br><br>

        <button type="submit" style="width:200px; height:50px; background:#222; color:#fff;">
            테스트 결제하기 (무료)
        </button>
    </form>
</body>
</html>