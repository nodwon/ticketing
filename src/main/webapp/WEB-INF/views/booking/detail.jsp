<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>예매 상세 - 예매번호 ${bookingDetail.BOOKINGID} | GWANJE TICKET</title>
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/theme.css">
<style>
    body { background: var(--gray); }
    .dt-container { max-width: 700px; margin: 24px auto 60px; background: var(--white); padding: 32px; border: 1px solid var(--border); border-radius: var(--radius-lg); box-shadow: var(--shadow); }
    .dt-container h1 { color: var(--dark); border-bottom: 2px solid var(--red); padding-bottom: 12px; font-size: 24px; }
    .dt-container h3 { color: var(--dark); margin: 24px 0 10px; font-size: 16px; }
    .status { display: inline-block; padding: 5px 15px; border-radius: 20px; font-size: 13px; font-weight: 700; margin-left: 10px; }
    .status-CONFIRMED { background: #d7f0df; color: #1a7a3a; }
    .status-PENDING { background: #fdecc8; color: #8a5a00; }
    .status-CANCELLED { background: #fde2e5; color: var(--red); }
    table { width: 100%; border-collapse: collapse; margin: 12px 0; }
    th, td { padding: 12px; border-bottom: 1px solid var(--border); text-align: left; font-size: 14px; }
    th { background: var(--gray); width: 30%; color: var(--muted); font-weight: 600; }
    .seats-list { background: #fff5f6; padding: 16px; border-radius: var(--radius); }
    .seat-item { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid var(--border); }
    .seat-item:last-child { border-bottom: none; }
    .total { font-size: 20px; font-weight: 800; color: var(--red); text-align: right; margin-top: 15px; }
    .actions { text-align: center; margin-top: 30px; display: flex; gap: 10px; justify-content: center; flex-wrap: wrap; }
    .actions form { display: inline; }
    .empty-msg { text-align: center; color: var(--muted); padding: 50px 20px; }
</style>
</head>
<body>

<!-- 페이지 헤더 (공통 톤) -->
<div class="tk-page-head">
    <div class="tk-page-head-inner">
        <div class="brand">BOOKING DETAIL</div>
        <h1>예매 상세</h1>
        <p>예매 내역을 확인하실 수 있습니다.</p>
    </div>
</div>

<div class="dt-container">

    <c:choose>
        <c:when test="${empty bookingDetail}">
            <h1>예매 상세</h1>
            <div class="empty-msg">
                <p>해당 예매 정보를 찾을 수 없습니다.</p>
            </div>
            <div class="actions">
                <a href="<c:url value='/bookingMyList.do'/>" class="tk-btn tk-btn-primary">내 예매 목록</a>
            </div>
        </c:when>

        <c:otherwise>
            <h1>
                예매 상세 #${bookingDetail.BOOKINGID}
                <span class="status status-${bookingDetail.STATUS}">${bookingDetail.STATUS}</span>
            </h1>

            <h3>공연 정보</h3>
            <table>
                <tr><th>공연명</th><td>${bookingDetail.TITLE}</td></tr>
                <tr><th>아티스트</th><td>${bookingDetail.ARTIST}</td></tr>
                <tr><th>장소</th><td>${bookingDetail.VENUE}</td></tr>
                <tr><th>공연일시</th><td>${bookingDetail.PERFORMANCEDATE}</td></tr>
            </table>

            <h3>예매자 정보</h3>
            <table>
                <tr><th>예매자명</th><td>${bookingDetail.MEMBERNAME}</td></tr>
                <tr><th>이메일</th><td>${bookingDetail.MEMBEREMAIL}</td></tr>
                <tr><th>예매일시</th><td>${bookingDetail.CREATEDAT}</td></tr>
            </table>

            <h3>예매 좌석 (${fn:length(bookingItems)}석)</h3>
            <div class="seats-list">
                <c:choose>
                    <c:when test="${empty bookingItems}">
                        <p style="text-align:center; color:#999;">예매된 좌석이 없습니다.</p>
                    </c:when>
                    <c:otherwise>
                        <c:forEach var="item" items="${bookingItems}">
                            <div class="seat-item">
                                <span>${item.SEATROW}열 ${item.SEATCOL}번</span>
                                <span><fmt:formatNumber value="${item.UNITPRICE}" pattern="#,###"/>원</span>
                            </div>
                        </c:forEach>
                        <div class="total">
                            총 결제금액: <fmt:formatNumber value="${bookingDetail.TOTALPRICE}" pattern="#,###"/>원
                        </div>
                    </c:otherwise>
                </c:choose>
            </div>

            <div class="actions">
                <a href="<c:url value='/bookingMyList.do?memberId=${bookingDetail.MEMBERID}'/>" class="tk-btn tk-btn-ghost">목록</a>

                <c:if test="${bookingDetail.STATUS == 'CONFIRMED'}">
                    <form action="<c:url value='/bookingCancel.do'/>" method="post"
                          onsubmit="return confirm('정말 예매를 취소하시겠습니까?');">
                        <input type="hidden" name="bookingId" value="${bookingDetail.BOOKINGID}" />
                        <input type="hidden" name="memberId" value="${bookingDetail.MEMBERID}" />
                        <button type="submit" class="tk-btn tk-btn-primary">예매 취소</button>
                    </form>
                </c:if>
            </div>
        </c:otherwise>
    </c:choose>

</div>

</body>
</html>
