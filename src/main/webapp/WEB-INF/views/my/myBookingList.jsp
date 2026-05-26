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
Modified   : 2026.05.26

Description :
  - 마이페이지 예매 내역 조회
  - URL: GET /my/bookingList.do
  - 카드 레이아웃 + 공연 이미지 + 예매 취소 버튼
  - 취소: CONFIRMED / PENDING 상태에서만 가능
============================================================
--%>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>마이페이지 - 예매내역</title>

<link rel="stylesheet" href="${pageContext.request.contextPath}/css/bootstrap.min.css">
<link href="${pageContext.request.contextPath}/css/dashboard.css" rel="stylesheet">
<link href="${pageContext.request.contextPath}/css/justified-nav.css" rel="stylesheet">
<script src="https://code.jquery.com/jquery-3.5.1.js"></script>
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/bootstrap-theme.min.css">
<script src="${pageContext.request.contextPath}/js/bootstrap.min.js"></script>

<style>
a { text-decoration: none; color: #666; }
.container { width: 100%; display: flex; padding: 0; }
.contents { width: 100%; margin: 10px; }

.booking-wrap {
    max-width: 900px;
    margin: 20px auto;
    padding: 0 20px;
}
.booking-header {
    border-bottom: 2px solid #ff4f6b;
    padding-bottom: 12px;
    margin-bottom: 24px;
}
.booking-header h2 {
    margin: 0;
    font-size: 24px;
    font-weight: 700;
    color: #222;
}
.booking-header .count {
    color: #ff4f6b;
    font-weight: 600;
}
.booking-header .sub {
    color: #888;
    font-size: 14px;
    margin: 6px 0 0;
}

.booking-card {
    display: flex;
    background: #fff;
    border: 1px solid #eee;
    border-radius: 12px;
    box-shadow: 0 2px 8px rgba(0,0,0,0.04);
    margin-bottom: 16px;
    overflow: hidden;
    transition: box-shadow 0.15s;
}
.booking-card:hover {
    box-shadow: 0 4px 16px rgba(0,0,0,0.08);
}

.booking-thumb {
    width: 160px;
    min-height: 180px;
    background: #f5f5f5;
    flex-shrink: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    overflow: hidden;
}
.booking-thumb img {
    width: 100%;
    height: 100%;
    object-fit: cover;
}
.booking-thumb .no-img {
    color: #ccc;
    font-size: 14px;
    text-align: center;
    padding: 20px;
}

.booking-body {
    flex: 1;
    padding: 18px 24px;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
}
.booking-top {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    margin-bottom: 12px;
}
.booking-title {
    margin: 0 0 6px;
    font-size: 17px;
    font-weight: 700;
    color: #222;
}
.booking-artist {
    color: #555;
    font-size: 14px;
    margin: 0 0 8px;
}
.booking-meta {
    color: #666;
    font-size: 13px;
    line-height: 1.7;
}
.booking-meta .label {
    display: inline-block;
    width: 70px;
    color: #999;
}

.booking-status {
    display: inline-block;
    padding: 4px 12px;
    border-radius: 20px;
    font-size: 12px;
    font-weight: 600;
}
.status-CONFIRMED { background: #d4f7d4; color: #060; }
.status-PENDING   { background: #fff4cc; color: #b80; }
.status-CANCELLED { background: #ffe4e4; color: #c00; }

.booking-bottom {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding-top: 12px;
    border-top: 1px solid #f3f3f3;
    margin-top: 10px;
}
.booking-id {
    color: #999;
    font-size: 12px;
}
.booking-price {
    font-size: 18px;
    font-weight: 700;
    color: #ff4f6b;
}
.booking-actions {
    display: flex;
    gap: 8px;
}
.btn-cancel {
    display: inline-block;
    padding: 6px 16px;
    background: #fff;
    color: #d33;
    border: 1px solid #d33;
    border-radius: 6px;
    font-size: 13px;
    cursor: pointer;
    transition: background 0.15s;
}
.btn-cancel:hover { background: #d33; color: #fff; }
.btn-disabled {
    display: inline-block;
    padding: 6px 16px;
    background: #f5f5f5;
    color: #aaa;
    border: 1px solid #ddd;
    border-radius: 6px;
    font-size: 13px;
    cursor: not-allowed;
}

.empty-msg {
    text-align: center;
    padding: 80px 20px;
    color: #999;
}
.empty-msg .icon {
    font-size: 48px;
    margin-bottom: 16px;
}
.empty-msg a {
    color: #ff4f6b;
    font-weight: 600;
}
</style>
</head>
<body>
<div class="container">

    <div class="contents">
        <div class="booking-wrap">

            <div class="booking-header">
                <h2>내 예매 내역
                    <c:if test="${not empty bookingList}">
                        <span class="count">(${fn:length(bookingList)})</span>
                    </c:if>
                </h2>
                <p class="sub">예매하신 공연 목록입니다</p>
            </div>

            <c:choose>
                <c:when test="${empty bookingList}">
                    <div class="empty-msg">
                        <div class="icon">🎫</div>
                        <p>아직 예매 내역이 없습니다.</p>
                        <a href="${pageContext.request.contextPath}/concert/list.do">공연 보러 가기 →</a>
                    </div>
                </c:when>
                <c:otherwise>
                    <c:forEach items="${bookingList}" var="booking">
                        <div class="booking-card">

                            <!-- 썸네일 -->
                            <div class="booking-thumb">
                                <c:choose>
                                    <c:when test="${not empty booking.THUMBNAIL}">
                                        <img src="${booking.THUMBNAIL}"
                                             alt="${booking.CONCERT_TITLE}"
                                             onerror="this.parentNode.innerHTML='<div class=\'no-img\'>이미지 없음</div>'">
                                    </c:when>
                                    <c:otherwise>
                                        <div class="no-img">이미지 없음</div>
                                    </c:otherwise>
                                </c:choose>
                            </div>

                            <!-- 내용 -->
                            <div class="booking-body">

                                <div class="booking-top">
                                    <div>
                                        <h3 class="booking-title">${booking.CONCERT_TITLE}</h3>
                                        <p class="booking-artist">${booking.ARTIST}</p>
                                    </div>
                                    <span class="booking-status status-${booking.BOOKING_STATUS}">
                                        ${booking.BOOKING_STATUS}
                                    </span>
                                </div>

                                <div class="booking-meta">
                                    <div><span class="label">장소</span> ${booking.VENUE}</div>
                                    <div><span class="label">공연일시</span> ${booking.PERFORMANCE_DATE}</div>
                                    <div><span class="label">예매일</span> ${booking.CREATED_AT}</div>
                                </div>

                                <div class="booking-bottom">
                                    <div>
                                        <div class="booking-id">예매번호 #${booking.BOOKING_ID}</div>
                                        <div class="booking-price">
                                            <fmt:formatNumber value="${booking.TOTAL_PRICE}" pattern="#,###"/>원
                                        </div>
                                    </div>

                                    <div class="booking-actions">
                                        <c:choose>
                                            <c:when test="${booking.BOOKING_STATUS eq 'CONFIRMED' or booking.BOOKING_STATUS eq 'PENDING'}">
                                                <form method="post"
                                                      action="${pageContext.request.contextPath}/my/bookingCancel.do"
                                                      onsubmit="return confirm('예매를 취소하시겠습니까?\n\n공연: ${booking.CONCERT_TITLE}\n예매번호: #${booking.BOOKING_ID}');"
                                                      style="margin: 0;">
                                                    <input type="hidden" name="bookingId" value="${booking.BOOKING_ID}">
                                                    <button type="submit" class="btn-cancel">예매 취소</button>
                                                </form>
                                            </c:when>
                                            <c:otherwise>
                                                <span class="btn-disabled">취소 불가</span>
                                            </c:otherwise>
                                        </c:choose>
                                    </div>
                                </div>

                            </div>
                        </div>
                    </c:forEach>
                </c:otherwise>
            </c:choose>

        </div>
    </div>
</div>
</body>
</html>