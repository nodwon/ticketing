<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>

<%--
============================================================
Project    : 관제 티켓 (Ticketing System)
FileName   : myBookingList.jsp
Developer  : 김희재 (feature/khj)
Modified   : 2026.05.25

Description :
  - 마이페이지 예매 내역 조회
  - URL: GET /my/bookingList.do
  - bookings × concert_schedules × concerts 조인 결과 표시
============================================================
--%>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>마이페이지 - 예매내역</title>

<link rel="stylesheet" href="/css/bootstrap.min.css">
<link href="/css/dashboard.css" rel="stylesheet">
<link href="/css/justified-nav.css" rel="stylesheet">
<script src="http://code.jquery.com/jquery-3.5.1.js"></script>
<link rel="stylesheet" href="/css/bootstrap-theme.min.css">
<script src="/js/bootstrap.min.js"></script>

<style>
a { text-decoration: none; color: #666; }
.container { width: 100%; display: flex; padding: 0; }
.contents { width: 100%; margin: 10px; }
.booking-status { display: inline-block; padding: 3px 10px; border-radius: 4px; font-size: 12px; }
.status-CONFIRMED { background: #d4f7d4; color: #060; }
.status-PENDING   { background: #fff4cc; color: #b80; }
.status-CANCELLED { background: #ffe4e4; color: #c00; }
.empty-msg { text-align: center; padding: 60px 20px; color: #999; }
</style>
</head>
<body>
<div class="container">
    <%@include file="/WEB-INF/tiles/mySide.jsp" %>

    <div id="bookingList" class="contents">
        <div class="row" align="center">
            <div>
                <h2>예매 내역</h2>
                <p>예매하신 공연 목록입니다.
                    <c:if test="${not empty bookingList}">
                        (총 ${fn:length(bookingList)}건)
                    </c:if>
                </p>
            </div>
        </div>

        <div class="table-responsive">
            <c:choose>
                <c:when test="${empty bookingList}">
                    <div class="empty-msg">
                        😴 예매 내역이 없습니다.<br><br>
                        <a href="/concert/list.do" style="color: #0066ff;">공연 보러가기 →</a>
                    </div>
                </c:when>
                <c:otherwise>
                    <table class="table table-striped">
                        <colgroup>
                            <col width="15%" />
                            <col width="35%" />
                            <col width="15%" />
                            <col width="15%" />
                            <col width="10%" />
                            <col width="10%" />
                        </colgroup>
                        <thead>
                            <tr>
                                <th>예매일자<br/>예매번호</th>
                                <th>공연 정보</th>
                                <th>공연 일시</th>
                                <th>장소</th>
                                <th>금액</th>
                                <th>상태</th>
                            </tr>
                        </thead>
                        <tbody>
                            <c:forEach items="${bookingList}" var="booking">
                                <tr>
                                    <td>
                                        ${booking.CREATED_AT}<br/>
                                        <small>#${booking.BOOKING_ID}</small>
                                    </td>
                                    <td>
                                        <strong>${booking.CONCERT_TITLE}</strong><br/>
                                        <small>${booking.ARTIST}</small>
                                    </td>
                                    <td>${booking.PERFORMANCE_DATE}</td>
                                    <td>${booking.VENUE}</td>
                                    <td>
                                        <fmt:formatNumber value="${booking.TOTAL_PRICE}" pattern="#,###"/>원
                                    </td>
                                    <td>
                                        <span class="booking-status status-${booking.BOOKING_STATUS}">
                                            ${booking.BOOKING_STATUS}
                                        </span>
                                    </td>
                                </tr>
                            </c:forEach>
                        </tbody>
                    </table>
                </c:otherwise>
            </c:choose>
        </div>
    </div>
</div>
</body>
</html>
