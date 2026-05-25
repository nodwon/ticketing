<%--
    ============================================================
    Project    : 관제 티켓 (Ticketing System)
    FileName   : concertDetail.jsp
    Developer  : 주재현 (feature/jjh)
    Created    : 2026.05.22
    Modified   : 2026.05.25
    Description: 공연 상세 페이지
                 - 예매하기 버튼 → /booking/form.do (다른 팀원 구현)
                 - CLOB(description) 정상 표시
    ============================================================
--%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c"   uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn"  uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>
    <c:choose>
        <c:when test="${not empty concert}"><c:out value="${concert.title}"/> | STU Concert</c:when>
        <c:otherwise>공연 정보 | STU Concert</c:otherwise>
    </c:choose>
</title>
<style>
    *,*::before,*::after { margin:0; padding:0; box-sizing:border-box; }
    body {
        font-family: 'Pretendard', -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Noto Sans KR', sans-serif;
        background: #f5f6fa; color: #1a1a1a; line-height: 1.6;
        -webkit-font-smoothing: antialiased;
    }
    a { text-decoration:none; color:inherit; }
    button { font-family: inherit; }

    /* ===== Header (홈 + 목록 버튼) ===== */
    .header { background: linear-gradient(135deg, #6a11cb 0%, #2575fc 100%); color: #fff; padding: 18px 0; }
    .header-inner {
        max-width: 1200px; margin: 0 auto; padding: 0 24px;
        display: flex; justify-content: space-between; align-items: center;
    }
    .header-left { display: flex; align-items: center; gap: 10px; }
    .btn-icon {
        display: inline-flex; align-items: center; gap: 6px;
        padding: 8px 14px; background: rgba(255,255,255,0.18);
        color: #fff; border: 1px solid rgba(255,255,255,0.3);
        border-radius: 8px; font-size: 13px; font-weight: 600;
        cursor: pointer; transition: background .15s;
    }
    .btn-icon:hover { background: rgba(255,255,255,0.3); }
    .header h1 {
        font-size: 20px; font-weight: 800; cursor: pointer; letter-spacing:-0.5px;
        margin-left: 8px;
    }

    /* ===== Container ===== */
    .container { max-width: 1200px; margin: 40px auto 60px; padding: 0 24px; }

    /* ===== Detail Card ===== */
    .detail-card {
        background: #fff; border-radius: 20px; overflow: hidden;
        box-shadow: 0 8px 30px rgba(0,0,0,0.08);
        display: grid; grid-template-columns: 1fr 1fr; gap: 0;
    }
    .detail-thumb {
        height: 620px;
        background: linear-gradient(135deg, #e5e7eb, #cbd5e1);
        background-size: cover; background-position: center;
        position: relative;
    }
    .thumb-placeholder {
        height: 100%; display: flex; align-items: center;
        justify-content: center; color: #94a3b8; font-size: 22px;
    }
    .status-badge-lg {
        position: absolute; top: 20px; right: 20px;
        padding: 8px 18px; border-radius: 24px;
        font-size: 13px; font-weight: 700; color: #fff;
        backdrop-filter: blur(8px);
    }
    .status-UPCOMING { background: rgba(245,158,11,0.95); }
    .status-ONGOING  { background: rgba(34,197,94,0.95); }
    .status-CLOSED   { background: rgba(107,114,128,0.95); }

    /* ===== Detail Info ===== */
    .detail-info { padding: 48px; display: flex; flex-direction: column; }
    .detail-artist {
        color: #6a11cb; font-size: 13px; font-weight: 700;
        letter-spacing: 1.5px; text-transform: uppercase; margin-bottom: 10px;
    }
    .detail-title {
        font-size: 30px; font-weight: 800; color: #1a1a1a;
        margin-bottom: 28px; line-height: 1.25; letter-spacing: -1px;
    }
    .info-table {
        border-top: 1.5px solid #e5e7eb;
        border-bottom: 1.5px solid #e5e7eb;
        padding: 22px 0; margin-bottom: 28px;
    }
    .info-row { display: flex; padding: 8px 0; font-size: 14px; }
    .info-label { width: 110px; color: #9ca3af; font-weight: 500; }
    .info-value { flex: 1; color: #1a1a1a; font-weight: 600; }

    .detail-desc-title {
        font-size: 15px; font-weight: 800; color: #1a1a1a;
        margin-bottom: 14px; padding-bottom: 10px;
        border-bottom: 2.5px solid #6a11cb; display: inline-block;
    }
    .detail-desc {
        font-size: 14px; color: #4b5563; line-height: 1.85;
        white-space: pre-wrap; flex: 1; margin-bottom: 28px;
    }

    /* ===== Action Buttons ===== */
    .action-buttons { display: flex; gap: 10px; margin-top: auto; }
    .btn-primary {
        flex: 1; padding: 18px;
        background: linear-gradient(135deg, #6a11cb 0%, #2575fc 100%);
        color: #fff; border: none; border-radius: 12px;
        font-size: 15px; font-weight: 700; cursor: pointer;
        transition: transform .15s, box-shadow .15s;
    }
    .btn-primary:hover {
        transform: translateY(-2px);
        box-shadow: 0 10px 24px rgba(106,17,203,0.4);
    }
    .btn-primary:disabled {
        background: #d1d5db; cursor: not-allowed;
        transform: none; box-shadow: none;
    }
    .btn-secondary {
        padding: 18px 24px; background: #fff; color: #4b5563;
        border: 1.5px solid #e5e7eb; border-radius: 12px;
        font-size: 15px; font-weight: 600; cursor: pointer;
        transition: border-color .15s, color .15s;
    }
    .btn-secondary:hover { border-color: #6a11cb; color: #6a11cb; }

    /* ===== Error ===== */
    .error-box {
        background: #fff; border-radius: 20px; padding: 100px 20px;
        text-align: center; box-shadow: 0 8px 30px rgba(0,0,0,0.06);
    }
    .error-icon { font-size: 72px; margin-bottom: 20px; }
    .error-box h2 { margin-bottom: 12px; color: #1a1a1a; font-size: 22px; }
    .error-box p  { color: #9ca3af; margin-bottom: 32px; }
    .btn-home-lg {
        padding: 14px 32px;
        background: linear-gradient(135deg, #6a11cb 0%, #2575fc 100%);
        color: #fff; border-radius: 10px; font-weight: 700; font-size: 14px;
        display: inline-block;
    }

    @media (max-width: 900px) {
        .detail-card { grid-template-columns: 1fr; }
        .detail-thumb { height: 380px; }
        .detail-info  { padding: 28px 22px; }
        .detail-title { font-size: 22px; }
        .header h1 { display: none; }
    }
</style>
</head>
<body>

<!-- ===== Header ===== -->
<div class="header">
    <div class="header-inner">
        <div class="header-left">
            <a href="/" class="btn-icon">🏠 홈</a>
            <a href="/concert/list.do" class="btn-icon">📋 목록</a>
            <h1 onclick="location.href='/concert/list.do'">🎵 STU Concert</h1>
        </div>
    </div>
</div>

<div class="container">

<c:choose>
    <c:when test="${empty concert}">
        <div class="error-box">
            <div class="error-icon">😢</div>
            <h2>공연 정보를 찾을 수 없습니다</h2>
            <p>
                <c:choose>
                    <c:when test="${not empty errorMsg}"><c:out value="${errorMsg}"/></c:when>
                    <c:otherwise>요청하신 공연이 존재하지 않거나 삭제되었습니다.</c:otherwise>
                </c:choose>
            </p>
            <a href="/concert/list.do" class="btn-home-lg">목록으로 돌아가기</a>
        </div>
    </c:when>
    <c:otherwise>

        <div class="detail-card">

            <!-- Left: Thumbnail -->
            <div class="detail-thumb"
                 <c:if test="${not empty concert.thumbnail}">
                    style="background-image: url('<c:out value="${concert.thumbnail}"/>');"
                 </c:if>>
                <c:if test="${empty concert.thumbnail}">
                    <div class="thumb-placeholder">🎵 No Image</div>
                </c:if>
                <c:if test="${not empty concert.status}">
                    <span class="status-badge-lg status-${concert.status}">
                        <c:choose>
                            <c:when test="${concert.status == 'UPCOMING'}">예매예정</c:when>
                            <c:when test="${concert.status == 'ONGOING'}">진행중</c:when>
                            <c:when test="${concert.status == 'CLOSED'}">종료</c:when>
                            <c:otherwise><c:out value="${concert.status}"/></c:otherwise>
                        </c:choose>
                    </span>
                </c:if>
            </div>

            <!-- Right: Info -->
            <div class="detail-info">
                <div class="detail-artist"><c:out value="${concert.artist}"/></div>
                <h2 class="detail-title"><c:out value="${concert.title}"/></h2>

                <div class="info-table">
                    <div class="info-row">
                        <div class="info-label">공연번호</div>
                        <div class="info-value"><c:out value="${concert.concertId}"/></div>
                    </div>
                    <div class="info-row">
                        <div class="info-label">아티스트</div>
                        <div class="info-value"><c:out value="${concert.artist}"/></div>
                    </div>
                    <div class="info-row">
                        <div class="info-label">공연장소</div>
                        <div class="info-value"><c:out value="${concert.venue}"/></div>
                    </div>
                    <div class="info-row">
                        <div class="info-label">상태</div>
                        <div class="info-value">
                            <c:choose>
                                <c:when test="${concert.status == 'UPCOMING'}">예매예정</c:when>
                                <c:when test="${concert.status == 'ONGOING'}">진행중 (예매가능)</c:when>
                                <c:when test="${concert.status == 'CLOSED'}">종료</c:when>
                                <c:otherwise><c:out value="${concert.status}"/></c:otherwise>
                            </c:choose>
                        </div>
                    </div>
                </div>

                <div class="detail-desc-title">공연 소개</div>
                <div class="detail-desc"><c:out value="${concert.description}"/></div>

                <!-- ===== 예매하기 버튼 (/booking/form.do 로 이동) ===== -->
                <div class="action-buttons">
                    <c:choose>
                        <c:when test="${concert.status == 'ONGOING' or concert.status == 'UPCOMING'}">
                            <button class="btn-primary"
                                    onclick="location.href='/booking/form.do?concertId=${concert.concertId}'">
                                🎟️ 예매하기
                            </button>
                        </c:when>
                        <c:otherwise>
                            <button class="btn-primary" disabled>예매 종료</button>
                        </c:otherwise>
                    </c:choose>
                    <button class="btn-secondary" onclick="location.href='/concert/list.do'">목록</button>
                </div>
            </div>

        </div>

    </c:otherwise>
</c:choose>

</div>

</body>
</html>
