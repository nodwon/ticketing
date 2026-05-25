<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>내 예매 목록</title>
<style>
    body { font-family: 'Malgun Gothic', sans-serif; background: #f5f5f5; margin: 0; padding: 20px; }
    .container { max-width: 900px; margin: 0 auto; background: #fff; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    h1 { color: #333; border-bottom: 2px solid #ff6b6b; padding-bottom: 10px; }
    .booking-card {
        border: 1px solid #eee;
        border-radius: 8px;
        padding: 20px;
        margin-bottom: 15px;
        display: flex;
        justify-content: space-between;
        align-items: center;
        transition: all 0.2s;
    }
    .booking-card:hover { background: #fafafa; box-shadow: 0 2px 5px rgba(0,0,0,0.05); }
    .booking-info h3 { margin: 0 0 10px 0; color: #333; }
    .booking-info p { margin: 4px 0; color: #666; font-size: 14px; }
    .booking-meta { text-align: right; }
    .price { font-size: 20px; font-weight: bold; color: #ff6b6b; }
    .status {
        display: inline-block;
        padding: 4px 12px;
        border-radius: 15px;
        font-size: 12px;
        font-weight: bold;
        margin-bottom: 8px;
    }
    .status-CONFIRMED { background: #d4edda; color: #155724; }
    .status-PENDING { background: #fff3cd; color: #856404; }
    .status-CANCELLED { background: #f8d7da; color: #721c24; }
    .btn-detail {
        display: inline-block;
        background: #ff6b6b;
        color: #fff;
        padding: 6px 15px;
        border-radius: 5px;
        text-decoration: none;
        font-size: 13px;
        margin-top: 8px;
    }
    .empty { text-align: center; color: #999; padding: 50px 20px; }
</style>
</head>
<body>

<div class="container">

    <h1>내 예매 목록</h1>

    <c:choose>
        <c:when test="${empty myBookings}">
            <div class="empty">
                <p>예매 내역이 없습니다.</p>
            </div>
        </c:when>
        <c:otherwise>
            <c:forEach var="booking" items="${myBookings}">
                <div class="booking-card">
                    <div class="booking-info">
                        <h3>${booking.TITLE}</h3>
                        <p>${booking.ARTIST} · ${booking.VENUE}</p>
                        <p>공연일시: ${booking.PERFORMANCEDATE}</p>
                        <p>예매일: ${booking.CREATEDAT} · 좌석 ${booking.SEATCOUNT}석</p>
                    </div>
                    <div class="booking-meta">
                        <span class="status status-${booking.STATUS}">${booking.STATUS}</span><br>
                        <span class="price"><fmt:formatNumber value="${booking.TOTALPRICE}" pattern="#,###"/>원</span><br>
                        <a href="<c:url value='/bookingDetail.do?bookingId=${booking.BOOKINGID}'/>" class="btn-detail">상세보기</a>
                    </div>
                </div>
            </c:forEach>
        </c:otherwise>
    </c:choose>

</div>

</body>
</html>