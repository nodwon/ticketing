<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>내 예매 목록 | GWANJE TICKET</title>
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/theme.css">
<style>
    body { background: var(--gray); }
    .ml-container { max-width: 900px; margin: 0 auto; padding: 0 20px 60px; }

    /* 상단 네비게이션 */
    .top-nav {
        background: var(--white); padding: 12px 16px;
        border: 1px solid var(--border); border-radius: var(--radius-lg);
        margin: 24px 0 20px; display: flex; gap: 10px;
        box-shadow: var(--shadow);
    }

    /* 예매 카드 */
    .booking-card {
        background: var(--white); padding: 22px 24px; margin-bottom: 15px;
        border: 1px solid var(--border); border-radius: var(--radius-lg);
        box-shadow: var(--shadow);
        display: flex; justify-content: space-between; align-items: center;
        transition: transform .2s, box-shadow .2s;
    }
    .booking-card:hover { transform: translateY(-3px); box-shadow: var(--shadow-hover); }
    /* PENDING 카드는 좌측 레드 액센트로 시각적 강조 */
    .booking-card.pending { border-left: 4px solid var(--red); }

    .booking-info { flex: 1; }
    .booking-info h3 { color: var(--dark); margin: 0 0 8px 0; font-size: 18px; font-weight: 700; }
    .booking-info p { margin: 4px 0; color: #555; font-size: 14px; }
    .booking-info .meta { color: var(--muted); font-size: 12px; }

    /* 상태 배지 - 의미 유지(확정/취소/대기), 톤만 정리 */
    .status-badge {
        display: inline-block; padding: 5px 14px; border-radius: 20px;
        font-size: 12px; font-weight: 700; margin-bottom: 10px; letter-spacing: .5px;
    }
    .status-PENDING   { background: #fdecc8; color: #8a5a00; }
    .status-CONFIRMED { background: #d7f0df; color: #1a7a3a; }
    .status-CANCELLED { background: #fde2e5; color: var(--red); }

    .booking-actions { display: flex; flex-direction: column; align-items: flex-end; gap: 12px; }
    .price { font-size: 20px; color: var(--red); font-weight: 800; }

    /* 빈 목록 */
    .empty-state {
        background: var(--white); padding: 60px 20px; text-align: center;
        border: 1px solid var(--border); border-radius: var(--radius-lg);
        box-shadow: var(--shadow);
    }
    .empty-state .icon { font-size: 60px; margin-bottom: 20px; }
    .empty-state h2 { color: var(--text); margin-bottom: 10px; }
    .empty-state p { color: var(--muted); margin-bottom: 20px; }

    /* 하단 액션 */
    .bottom-actions {
        text-align: center; margin-top: 28px; padding: 22px;
        background: var(--white); border: 1px solid var(--border);
        border-radius: var(--radius-lg); box-shadow: var(--shadow);
    }
</style>
</head>
<body>

<!-- 페이지 헤더 (공통 톤) -->
<div class="tk-page-head">
    <div class="tk-page-head-inner">
        <div class="brand">MY BOOKINGS</div>
        <h1>내 예매 목록</h1>
        <p>예매하신 공연 내역을 확인하실 수 있습니다.</p>
    </div>
</div>

<div class="ml-container">

    <!-- 상단 네비게이션 -->
    <div class="top-nav">
        <a href="<c:url value='/'/>" class="tk-btn tk-btn-sm tk-btn-dark">🏠 홈</a>
        <a href="<c:url value='/my/info.do'/>" class="tk-btn tk-btn-sm tk-btn-ghost">👤 마이페이지</a>
    </div>

    <c:choose>
        <%-- 빈 목록 --%>
        <c:when test="${empty myBookings}">
            <div class="empty-state">
                <div class="icon">🎫</div>
                <h2>아직 예매 내역이 없습니다</h2>
                <p>마음에 드는 공연을 찾아 첫 예매를 시작해보세요!</p>
                <a href="<c:url value='/concert/list.do'/>" class="tk-btn tk-btn-primary tk-mt-16">
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
                                   class="tk-btn tk-btn-sm tk-btn-dark">
                                    💳 결제 이어서 진행
                                </a>
                            </c:when>

                            <%-- CONFIRMED / CANCELLED: 상세 화면으로 --%>
                            <c:otherwise>
                                <a href="<c:url value='/bookingDetail.do?bookingId=${booking.BOOKINGID}'/>"
                                   class="tk-btn tk-btn-sm tk-btn-primary">
                                    상세보기
                                </a>
                            </c:otherwise>
                        </c:choose>
                    </div>
                </div>
            </c:forEach>

            <!-- 하단 액션 -->
            <div class="bottom-actions">
                <a href="<c:url value='/concert/list.do'/>" class="tk-btn tk-btn-primary tk-btn-lg">
                    🎵 다른 공연 예매하러 가기
                </a>
            </div>
        </c:otherwise>
    </c:choose>

</div>
</body>
</html>
