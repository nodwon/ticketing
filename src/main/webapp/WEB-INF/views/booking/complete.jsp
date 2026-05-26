<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>
    <c:choose>
        <c:when test="${bookingDetail.STATUS == 'PENDING'}">결제 대기 중 - #${bookingDetail.BOOKINGID}</c:when>
        <c:otherwise>예매 완료 - #${bookingDetail.BOOKINGID}</c:otherwise>
    </c:choose>
</title>
<style>
    body { font-family: 'Malgun Gothic', sans-serif; background: #f5f5f5; margin: 0; padding: 20px; }
    .container { max-width: 700px; margin: 0 auto; background: #fff; padding: 40px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    
    /* PENDING 헤더 (노란색 - 결제 대기) */
    .pending-header { text-align: center; padding: 20px 0; }
    .pending-icon { font-size: 64px; color: #f39c12; margin-bottom: 10px; }
    .pending-title { font-size: 28px; color: #333; margin: 10px 0; }
    
    /* CONFIRMED 헤더 (초록색 - 완료) */
    .success-header { text-align: center; padding: 20px 0; }
    .success-icon { font-size: 64px; color: #4caf50; margin-bottom: 10px; }
    .success-title { font-size: 28px; color: #333; margin: 10px 0; }
    
    .booking-number { color: #ff6b6b; font-weight: bold; font-size: 18px; margin: 5px 0; }
    .status-badge {
        display: inline-block;
        padding: 6px 16px;
        border-radius: 20px;
        font-size: 14px;
        font-weight: bold;
        margin-left: 8px;
    }
    .status-PENDING { background: #fff3cd; color: #856404; }
    .status-CONFIRMED { background: #d4edda; color: #155724; }
    
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
    .btn { display: inline-block; padding: 12px 25px; border-radius: 6px; text-decoration: none; margin: 5px; font-size: 14px; cursor: pointer; border: none; font-weight: bold; }
    .btn-primary { background: #ff6b6b; color: #fff; }
    .btn-secondary { background: #999; color: #fff; }
    .btn-pay { background: #f39c12; color: #fff; font-size: 16px; padding: 14px 30px; }
    .btn-pay:hover { background: #e67e22; }
    
    .notice { padding: 12px 15px; margin-top: 20px; font-size: 13px; border-radius: 4px; }
    .notice-warning { background: #fff8e7; border-left: 4px solid #ffc107; color: #856404; }
    .notice-info { background: #e8f4f8; border-left: 4px solid #3498db; color: #2874a6; }
    .notice-success { background: #f0f9f0; border-left: 4px solid #4caf50; color: #2e7d32; }
    
    .payment-temp-box {
        background: #fff8e7;
        border: 2px dashed #f39c12;
        padding: 20px;
        text-align: center;
        border-radius: 10px;
        margin: 25px 0;
    }
    .payment-temp-box h3 { color: #e67e22; margin: 0 0 10px 0; }
    .payment-temp-box p { color: #856404; margin: 8px 0; font-size: 14px; }
</style>
</head>
<body>

<div class="container">

    <c:choose>
        <%-- ============================================
             PENDING 상태: 결제 대기
             ============================================ --%>
        <c:when test="${bookingDetail.STATUS == 'PENDING'}">
            <div class="pending-header">
                <div class="pending-icon">⏳</div>
                <div class="pending-title">결제 대기 중</div>
                <div class="booking-number">
                    예매번호: #${bookingDetail.BOOKINGID}
                    <span class="status-badge status-PENDING">PENDING</span>
                </div>
            </div>

            <hr class="divider">

            <!-- 결제 안내 박스 -->
            <div class="payment-temp-box">
                <h3>💳 결제를 진행해주세요</h3>
                <p>좌석이 임시 선점되었습니다. 결제를 완료하면 예매가 확정됩니다.</p>
                <p style="font-size:12px; color:#999; margin-top:15px;">
                    ※ 결제 모듈은 별도 개발 중이며, 아래 [임시 결제 확정] 버튼으로 시뮬레이션 가능합니다.
                </p>
                
                <!-- 임시 결제 확정 form (king 모듈 통합 전까지 사용) -->
                <form action="<c:url value='/bookingConfirm.do'/>" method="post"
                      style="margin-top: 15px;"
                      onsubmit="return confirm('결제를 시뮬레이션 하시겠습니까?\n(실제 결제는 결제 모듈 통합 후 가능합니다)');">
                    <input type="hidden" name="bookingId" value="${bookingDetail.BOOKINGID}" />
                    <button type="submit" class="btn btn-pay">💳 임시 결제 확정 (개발용)</button>
                </form>
            </div>
        </c:when>

        <%-- ============================================
             CONFIRMED 상태: 예매 완료
             ============================================ --%>
        <c:otherwise>
            <div class="success-header">
                <div class="success-icon">✓</div>
                <div class="success-title">예매가 완료되었습니다!</div>
                <div class="booking-number">
                    예매번호: #${bookingDetail.BOOKINGID}
                    <span class="status-badge status-CONFIRMED">CONFIRMED</span>
                </div>
            </div>

            <hr class="divider">

            <div class="notice notice-success">
                ✓ 결제가 완료되어 예매가 확정되었습니다.
            </div>
        </c:otherwise>
    </c:choose>


    <!-- ============================================
         공통 영역: 공연/예매자/좌석 정보
         ============================================ -->

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
            <c:choose>
                <c:when test="${bookingDetail.STATUS == 'PENDING'}">결제 예정 금액</c:when>
                <c:otherwise>총 결제금액</c:otherwise>
            </c:choose>:
            <fmt:formatNumber value="${bookingDetail.TOTALPRICE}" pattern="#,###"/>원
        </div>
    </div>


    <!-- ============================================
         상태별 안내 메시지
         ============================================ -->
    <c:choose>
        <c:when test="${bookingDetail.STATUS == 'PENDING'}">
            <div class="notice notice-warning">
                ⚠️ 아직 결제가 완료되지 않은 상태입니다.<br>
                ※ 결제를 진행하지 않으면 일정 시간 후 예매가 자동 취소될 수 있습니다.
            </div>
        </c:when>
        <c:otherwise>
            <div class="notice notice-info">
                ※ 예매 내역은 [내 예매 목록]에서 다시 확인하실 수 있습니다.<br>
                ※ 공연 시작 3일 전까지 취소 가능합니다.
            </div>
        </c:otherwise>
    </c:choose>


    <!-- ============================================
         하단 버튼
         ============================================ -->
    <div class="actions">
        <a href="<c:url value='/bookingMyList.do?memberId=${bookingDetail.MEMBERID}'/>" class="btn btn-primary">내 예매 목록</a>
        
        <c:if test="${bookingDetail.STATUS == 'PENDING'}">
            <!-- PENDING 상태에서 취소 가능 -->
            <form action="<c:url value='/bookingCancel.do'/>" method="post" style="display:inline;"
                  onsubmit="return confirm('예매를 취소하시겠습니까? (좌석이 해제됩니다)');">
                <input type="hidden" name="bookingId" value="${bookingDetail.BOOKINGID}" />
                <input type="hidden" name="memberId" value="${bookingDetail.MEMBERID}" />
                <input type="hidden" name="cancelReason" value="결제 전 사용자 취소" />
                <button type="submit" class="btn btn-secondary">예매 취소</button>
            </form>
        </c:if>
    </div>

</div>

</body>
</html>