<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>예매 상세 - 예매번호 ${bookingDetail.BOOKINGID}</title>
<style>
    body { font-family: 'Malgun Gothic', sans-serif; background: #f5f5f5; margin: 0; padding: 20px; }
    .container { max-width: 700px; margin: 0 auto; background: #fff; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    h1 { color: #333; border-bottom: 2px solid #ff6b6b; padding-bottom: 10px; }
    .status {
        display: inline-block;
        padding: 5px 15px;
        border-radius: 20px;
        font-size: 13px;
        font-weight: bold;
        margin-left: 10px;
    }
    .status-CONFIRMED { background: #d4edda; color: #155724; }
    .status-PENDING { background: #fff3cd; color: #856404; }
    .status-CANCELLED { background: #f8d7da; color: #721c24; }
    table { width: 100%; border-collapse: collapse; margin: 20px 0; }
    th, td { padding: 12px; border-bottom: 1px solid #eee; text-align: left; }
    th { background: #f8f8f8; width: 30%; color: #555; }
    .seats-list { background: #fff8f8; padding: 15px; border-radius: 8px; }
    .seat-item { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px dashed #ddd; }
    .seat-item:last-child { border-bottom: none; }
    .total { font-size: 20px; font-weight: bold; color: #ff6b6b; text-align: right; margin-top: 15px; }
    .btn { display: inline-block; padding: 10px 25px; border-radius: 6px; text-decoration: none; margin: 5px; font-size: 14px; cursor: pointer; border: none; }
    .btn-primary { background: #ff6b6b; color: #fff; }
    .btn-danger { background: #dc3545; color: #fff; }
    .btn-secondary { background: #999; color: #fff; }
    .actions { text-align: center; margin-top: 30px; }
    .empty-msg { text-align: center; color: #999; padding: 50px 20px; }
</style>
</head>
<body>

<div class="container">

    <c:choose>
        <c:when test="${empty bookingDetail}">
            <h1>예매 상세</h1>
            <div class="empty-msg">
                <p>해당 예매 정보를 찾을 수 없습니다.</p>
            </div>
            <div class="actions">
                <a href="<c:url value='/bookingMyList.do'/>" class="btn btn-primary">내 예매 목록</a>
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
                <a href="<c:url value='/bookingMyList.do?memberId=${bookingDetail.MEMBERID}'/>" class="btn btn-secondary">목록</a>

                <c:if test="${bookingDetail.STATUS == 'CONFIRMED'}">
                    <form action="<c:url value='/bookingCancel.do'/>" method="post" 
                          style="display: inline;"
                          onsubmit="return confirm('정말 예매를 취소하시겠습니까?');">
                        <input type="hidden" name="bookingId" value="${bookingDetail.BOOKINGID}" />
                        <input type="hidden" name="memberId" value="${bookingDetail.MEMBERID}" />
                        <button type="submit" class="btn btn-danger">예매 취소</button>
                    </form>
                </c:if>
            </div>
        </c:otherwise>
    </c:choose>

</div>

</body>
</html>