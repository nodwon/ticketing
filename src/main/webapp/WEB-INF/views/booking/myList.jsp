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
    .container { max-width: 900px; margin: 0 auto; }
    h1 { color: #333; margin-bottom: 20px; }
    
    /* 상단 네비게이션 */
    .top-nav {
        background: #fff;
        padding: 12px 20px;
        border-radius: 8px;
        margin-bottom: 20px;
        display: flex;
        gap: 10px;
        box-shadow: 0 2px 6px rgba(0,0,0,0.06);
    }
    .nav-btn {
        padding: 8px 16px;
        border-radius: 6px;
        text-decoration: none;
        font-weight: 600;
        font-size: 14px;
        transition: all 0.2s;
    }
    .nav-home { background: #4a90e2; color: #fff; }
    .nav-home:hover { background: #3a7ec8; }
    .nav-mypage { background: #f5f5f5; color: #555; border: 1px solid #ddd; }
    .nav-mypage:hover { background: #e0e0e0; }
    .nav-concert { background: #1abc9c; color: #fff; }
    .nav-concert:hover { background: #16a085; }
    
    /* 예매 카드 */
    .booking-card {
        background: #fff;
        padding: 20px;
        margin-bottom: 15px;
        border-radius: 8px;
        box-shadow: 0 2px 6px rgba(0,0,0,0.08);
        display: flex;
        justify-content: space-between;
        align-items: center;
        transition: transform 0.2s, box-shadow 0.2s;
    }
    .booking-card:hover {
        transform: translateY(-2px);
        box-shadow: 0 4px 12px rgba(0,0,0,0.12);
    }
    /* PENDING 카드는 좌측 노란 액센트로 시각적 강조 */
    .booking-card.pending {
        border-left: 4px solid #f39c12;
    }
    .booking-info { flex: 1; }
    .booking-info h3 { color: #333; margin: 0 0 8px 0; font-size: 18px; }
    .booking-info p { margin: 4px 0; color: #666; font-size: 14px; }
    .booking-info .meta { color: #999; font-size: 12px; }
    
    /* 상태 배지 */
    .status-badge {
        display: inline-block;
        padding: 6px 14px;
        border-radius: 20px;
        font-size: 12px;
        font-weight: bold;
        margin-bottom: 8px;
    }
    .status-PENDING { background: #fff3cd; color: #856404; }
    .status-CONFIRMED { background: #d4edda; color: #155724; }
    .status-CANCELLED { background: #f8d7da; color: #721c24; }
    
    .booking-actions { display: flex; flex-direction: column; align-items: flex-end; gap: 10px; }
    .price { font-size: 20px; color: #e74c3c; font-weight: bold; }
    
    /* 액션 버튼 (상태별 색상 분리) */
    .btn-action {
        padding: 8px 18px;
        color: #fff;
        text-decoration: none;
        border-radius: 5px;
        font-size: 13px;
        font-weight: 600;
        transition: background 0.2s;
        white-space: nowrap;
    }
    .btn-resume { background: #f39c12; }   /* PENDING: 결제 이어서 */
    .btn-resume:hover { background: #e67e22; }
    .btn-detail { background: #ff6b6b; }   /* CONFIRMED/CANCELLED: 상세 */
    .btn-detail:hover { background: #ee5a5a; }
    
    /* 빈 목록 */
    .empty-state {
        background: #fff;
        padding: 60px 20px;
        text-align: center;
        border-radius: 8px;
        box-shadow: 0 2px 6px rgba(0,0,0,0.08);
    }
    .empty-state .icon { font-size: 60px; margin-bottom: 20px; }
    .empty-state h2 { color: #555; margin-bottom: 10px; }
    .empty-state p { color: #999; margin-bottom: 20px; }
    
    /* 하단 액션 */
    .bottom-actions {
        text-align: center;
        margin-top: 30px;
        padding: 20px;
        background: #fff;
        border-radius: 8px;
        box-shadow: 0 2px 6px rgba(0,0,0,0.06);
    }
    .bottom-actions a {
        display: inline-block;
        padding: 12px 28px;
        background: #1abc9c;
        color: #fff;
        text-decoration: none;
        border-radius: 6px;
        font-weight: 600;
        font-size: 15px;
        transition: background 0.2s;
    }
    .bottom-actions a:hover { background: #16a085; }
</style>
</head>
<body>
<div class="container">

    <!-- 상단 네비게이션 -->
    <div class="top-nav">
        <a href="<c:url value='/'/>" class="nav-btn nav-home">🏠 홈</a>
        <a href="<c:url value='/myPage.do'/>" class="nav-btn nav-mypage">👤 마이페이지</a>
    </div>

    <h1>📋 내 예매 목록</h1>

    <c:choose>
        <%-- 빈 목록 --%>
        <c:when test="${empty myBookings}">
            <div class="empty-state">
                <div class="icon">🎫</div>
                <h2>아직 예매 내역이 없습니다</h2>
                <p>마음에 드는 공연을 찾아 첫 예매를 시작해보세요!</p>
                <a href="<c:url value='/concert/list.do'/>" class="nav-btn nav-concert" style="margin-top:15px;">
                    🎵 콘서트 보러 가기
                </a>
            </div>
        </c:when>
        
        <%-- 예매 목록 --%>
        <c:otherwise>
            <c:forEach var="booking" items="${myBookings}">
                <%-- PENDING 여부에 따라 카드 스타일/링크 분기 --%>
                <c:set var="isPending" value="${booking.STATUS eq 'PENDING'}"/>
                
                <div class="booking-card ${isPending ? 'pending' : ''}">
                    <div class="booking-info">
                        <span class="status-badge status-${booking.STATUS}">${booking.STATUS}</span>
                        <h3>${booking.TITLE}</h3>
                        <p>${booking.ARTIST} · ${booking.VENUE}</p>
                        <p class="meta">공연일시: ${booking.PERFORMANCEDATE}</p>
                        <p class="meta">예매일: ${booking.CREATEDAT} · 좌석 ${booking.SEATCOUNT}석</p>
                    </div>
                    <div class="booking-actions">
                        <span class="price">
                            <fmt:formatNumber value="${booking.TOTALPRICE}" pattern="#,###"/>원
                        </span>
                        
                        <c:choose>
                            <%-- PENDING: 결제 대기 화면(complete.jsp)으로 복귀
                                 from=mylist 파라미터로 로그 분석 시 진입 경로 식별 --%>
                            <c:when test="${isPending}">
                                <a href="<c:url value='/bookingComplete.do?bookingId=${booking.BOOKINGID}&from=mylist'/>"
                                   class="btn-action btn-resume">
                                    💳 결제 이어서 진행
                                </a>
                            </c:when>
                            
                            <%-- CONFIRMED / CANCELLED: 상세 화면으로 --%>
                            <c:otherwise>
                                <a href="<c:url value='/bookingDetail.do?bookingId=${booking.BOOKINGID}'/>"
                                   class="btn-action btn-detail">
                                    상세보기
                                </a>
                            </c:otherwise>
                        </c:choose>
                    </div>
                </div>
            </c:forEach>

            <!-- 하단 액션 -->
            <div class="bottom-actions">
                <a href="<c:url value='/concert/list.do'/>" class="nav-btn nav-concert">
                    🎵 다른 공연 예매하러 가기
                </a>
            </div>
        </c:otherwise>
    </c:choose>

</div>
</body>
</html>