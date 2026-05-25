<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>예매 완료 - 예매번호 ${bookingDetail.BOOKINGID}</title>
<style>
    body { font-family: 'Malgun Gothic', sans-serif; background: #f5f5f5; margin: 0; padding: 20px; }
    .container { max-width: 700px; margin: 0 auto; background: #fff; padding: 40px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    .success-header { text-align: center; padding: 20px 0; }
    .success-icon { font-size: 64px; color: #4caf50; margin-bottom: 10px; }
    .success-title { font-size: 28px; color: #333; margin: 10px 0; }
    .booking-number { color: #ff6b6b; font-weight: bold; font-size: 18px; margin: 5px 0; }
    .divider { border: 0; height: 2px; background: #ff6b6b; margin: 25px 0; }
    .section-title { font-size: 16px; font-weight: bold; color: #333; margin: 20px 0 10px 0; }
    .info-table { width: 100%; border-collapse: collapse; }
    .info-table th, .info-table td { padding: 10px 12px; border-bottom: 1px solid #eee; text-align: left; font-size: 14px; }
    .info-table th { background: #f8f8f8; width: 30%; color: #555; }
    .seats-box { background: #fff8f8; padding: 15px 20px; border-radius: 8px; }
    .seat-row { display: flex; justify-content: space-between; padding: 6px 0; border-bottom: 1px dashed #ddd; }
    .seat-row:last-child { border-bottom: none; }
    .total-box { text-align: right; font-size: 20px; font-weight: bold; color: #ff6b6b; margin-top: 15px; padding-top: 15px; border-top: 2px solid #eee; }
    .actions { text-align: center; margin-top: 30px; }
    .btn { display: inline-block; padding: 12px 25px; border-radius: 6px; text-decoration: none; margin: 5px; font-size: 14px; }
    .btn-primary { background: #ff6b6b; color: #fff; }
    .btn-secondary { background: #999; color: #fff; }
    .notice { background: #fff8e7; border-left: 4px solid #ffc107; padding: 12px 15px; margin-top: 20px; font-size: 13px; color: #666; border-radius: 4px; }
</style>
</head>
<body>

<div class="container">

    <div class="success-header">
        <div class="success-icon">✓</div>
        <div class="success-title">예매가 완료되었습니다!</div>
        <div class="booking-number">예매번호: #${bookingDetail.BOOKINGID}</div>
    </div>

    <hr class="divider">

    <!-- 공연 정보 -->
    <div class="section-title">공연 정보</div>
    <table class="info-table">
        <tr><th>공연명</th><td>${bookingDetail.TITLE}</td></tr>
        <tr><th>아티스트</th><td>${bookingDetail.ARTIST}</td></tr>
        <tr><th>장소</th><td>${bookingDetail.VENUE}</td></tr>
        <tr><th>공연일시</th><td>${bookingDetail.PERFORMANCEDATE}</td></tr>
    </table>

    <!-- 예매자 정보 -->
    <div class="section-title">예매자 정보</div>
    <table class="info-table">
        <tr><th>예매자</th><td>${bookingDetail.MEMBERNAME}</td></tr>
        <tr><th>이메일</th><td>${bookingDetail.MEMBEREMAIL}</td></tr>
        <tr><th>예매일시</th><td>${bookingDetail.CREATEDAT}</td></tr>
    </table>

    <!-- 좌석 -->
    <div class="section-title">예매 좌석 (${fn:length(bookingItems)}석)</div>
    <div class="seats-box">
        <c:forEach var="item" items="${bookingItems}">
            <div class="seat-row">
                <span>${item.SEATROW}열 ${item.SEATCOL}번</span>
                <span><fmt:formatNumber value="${item.UNITPRICE}" pattern="#,###"/>원</span>
            </div>
        </c:forEach>
        <div class="total-box">
            총 결제금액: <fmt:formatNumber value="${bookingDetail.TOTALPRICE}" pattern="#,###"/>원
        </div>
    </div>

    <div class="notice">
        ※ 예매 내역은 [내 예매 목록]에서 다시 확인하실 수 있습니다.<br>
        ※ 공연 시작 3일 전까지 취소 가능합니다.
    </div>

    <div class="actions">
        <a href="<c:url value='/bookingMyList.do?memberId=${bookingDetail.MEMBERID}'/>" class="btn btn-primary">내 예매 목록</a>
        <a href="<c:url value='/bookingSeat.do?scheduleId=1'/>" class="btn btn-secondary">다른 좌석 예매</a>
    </div>

</div>

</body>
</html>