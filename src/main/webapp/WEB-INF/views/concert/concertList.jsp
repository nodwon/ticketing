<%--
    ============================================================
    Project    : 관제 티켓 (Ticketing System)
    FileName   : concertList.jsp
    Developer  : 주재현 (feature/jjh)
    Created    : 2026.05.22
    Modified   : 2026.05.25
    Description: 공연 목록 페이지
                 - 좌측 상단 홈("/") 이동 버튼
                 - 대소문자 무관 검색
                 - 정렬: 최신순/공연명순/아티스트순
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
<title>공연 목록 | STU Concert</title>
<style>
    *,*::before,*::after { margin:0; padding:0; box-sizing:border-box; }
    body {
        font-family: 'Pretendard', -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Noto Sans KR', sans-serif;
        background: #f5f6fa; color: #1a1a1a; line-height: 1.5;
        -webkit-font-smoothing: antialiased;
    }
    a { text-decoration:none; color:inherit; }
    button { font-family: inherit; }

    /* ===== Top Bar (홈 버튼) ===== */
    .topbar {
        background: rgba(255,255,255,0.08); backdrop-filter: blur(10px);
        padding: 14px 0; position: relative; z-index: 10;
    }
    .topbar-inner {
        max-width: 1200px; margin: 0 auto; padding: 0 24px;
        display: flex; align-items: center; gap: 12px;
    }
    .btn-home {
        display: inline-flex; align-items: center; gap: 6px;
        padding: 9px 16px; background: rgba(255,255,255,0.18);
        color: #fff; border: 1px solid rgba(255,255,255,0.3);
        border-radius: 8px; font-size: 13px; font-weight: 600;
        cursor: pointer; transition: background .15s;
    }
    .btn-home:hover { background: rgba(255,255,255,0.3); }

    /* ===== Header ===== */
    .header-wrap {
        background: linear-gradient(135deg, #6a11cb 0%, #2575fc 100%);
        color: #fff; box-shadow: 0 4px 20px rgba(0,0,0,0.1);
    }
    .header {
        max-width: 1200px; margin: 0 auto;
        padding: 36px 24px 80px;
    }
    .brand {
        font-size: 13px; font-weight: 600; letter-spacing: 2px;
        opacity: 0.85; margin-bottom: 12px;
    }
    .header h1 {
        font-size: 36px; font-weight: 800;
        margin-bottom: 10px; letter-spacing: -1px;
    }
    .header p { font-size: 15px; opacity: 0.9; }

    /* ===== Container ===== */
    .container {
        max-width: 1200px; margin: -40px auto 60px;
        padding: 0 24px; position: relative;
    }

    /* ===== Search Box ===== */
    .search-box {
        background: #fff; border-radius: 16px; padding: 28px;
        box-shadow: 0 8px 30px rgba(0,0,0,0.08); margin-bottom: 24px;
    }
    .search-form {
        display: grid;
        grid-template-columns: 1fr 180px 110px 90px;
        gap: 12px;
    }
    .search-form input, .search-form select {
        padding: 14px 16px;
        border: 1.5px solid #e5e7eb; border-radius: 10px;
        font-size: 14px; outline: none;
        transition: border-color .15s, box-shadow .15s;
        background: #fff; color: #1a1a1a;
    }
    .search-form input:focus, .search-form select:focus {
        border-color: #6a11cb;
        box-shadow: 0 0 0 3px rgba(106,17,203,0.1);
    }
    .btn-search {
        background: linear-gradient(135deg, #6a11cb 0%, #2575fc 100%);
        color: #fff; border: none; border-radius: 10px;
        font-size: 14px; font-weight: 700; cursor: pointer;
        transition: transform .12s, box-shadow .12s;
    }
    .btn-search:hover { transform: translateY(-1px); box-shadow: 0 6px 16px rgba(106,17,203,0.35); }
    .btn-reset {
        background: #f3f4f6; color: #555; border: none;
        border-radius: 10px; font-size: 14px; font-weight: 500; cursor: pointer;
        transition: background .15s;
    }
    .btn-reset:hover { background: #e5e7eb; }

    /* ===== Toolbar ===== */
    .toolbar {
        display: flex; justify-content: space-between; align-items: center;
        margin-bottom: 20px; padding: 0 4px;
    }
    .result-count { font-size: 14px; color: #6b7280; }
    .result-count strong { color: #6a11cb; font-weight: 700; }
    .sort-tabs {
        display: flex; gap: 4px; background: #fff; padding: 4px;
        border-radius: 10px; box-shadow: 0 2px 8px rgba(0,0,0,0.05);
    }
    .sort-tab {
        padding: 8px 16px; border-radius: 8px;
        font-size: 13px; font-weight: 500; color: #6b7280;
        cursor: pointer; transition: all .15s;
    }
    .sort-tab:hover { color: #1a1a1a; background: #f3f4f6; }
    .sort-tab.active {
        background: linear-gradient(135deg, #6a11cb 0%, #2575fc 100%);
        color: #fff; font-weight: 700;
    }

    /* ===== Concert Grid ===== */
    .concert-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
        gap: 22px;
    }
    .concert-card {
        background: #fff; border-radius: 14px; overflow: hidden;
        box-shadow: 0 2px 10px rgba(0,0,0,0.06);
        transition: transform .2s, box-shadow .2s;
        display: flex; flex-direction: column;
    }
    .concert-card:hover {
        transform: translateY(-6px);
        box-shadow: 0 14px 32px rgba(0,0,0,0.13);
    }
    .card-thumb {
        width: 100%; height: 320px;
        background: linear-gradient(135deg, #e5e7eb, #cbd5e1);
        background-size: cover; background-position: center;
        position: relative;
    }
    .card-thumb-placeholder {
        height: 100%; display: flex; align-items: center;
        justify-content: center; color: #94a3b8; font-size: 14px;
    }
    .status-badge {
        position: absolute; top: 12px; right: 12px;
        padding: 5px 12px; border-radius: 20px;
        font-size: 11px; font-weight: 700; color: #fff;
        backdrop-filter: blur(8px);
    }
    .status-UPCOMING { background: rgba(245,158,11,0.95); }
    .status-ONGOING  { background: rgba(34,197,94,0.95); }
    .status-CLOSED   { background: rgba(107,114,128,0.95); }

    .card-body { padding: 16px 18px 18px; flex: 1; display: flex; flex-direction: column; }
    .card-artist {
        font-size: 12px; color: #6a11cb;
        font-weight: 700; letter-spacing: 0.3px;
        margin-bottom: 6px; text-transform: uppercase;
    }
    .card-title {
        font-size: 15px; font-weight: 700; color: #1a1a1a;
        line-height: 1.4; margin-bottom: 8px;
        display: -webkit-box; -webkit-line-clamp: 2;
        -webkit-box-orient: vertical; overflow: hidden;
        min-height: 42px;
    }
    .card-venue {
        font-size: 12px; color: #6b7280;
        display: -webkit-box; -webkit-line-clamp: 1;
        -webkit-box-orient: vertical; overflow: hidden;
    }

    .empty-state {
        background: #fff; border-radius: 16px; padding: 80px 20px;
        text-align: center; color: #9ca3af;
        box-shadow: 0 2px 10px rgba(0,0,0,0.04);
    }
    .empty-state-icon { font-size: 56px; margin-bottom: 16px; }
    .empty-state h3 { color: #4b5563; margin-bottom: 8px; font-size: 18px; }

    @media (max-width: 768px) {
        .header { padding: 28px 24px 60px; }
        .header h1 { font-size: 24px; }
        .search-form { grid-template-columns: 1fr; }
        .toolbar { flex-direction: column; gap: 12px; align-items: flex-start; }
        .sort-tabs { width: 100%; overflow-x: auto; }
        .concert-grid { grid-template-columns: repeat(2, 1fr); gap: 12px; }
        .card-thumb { height: 220px; }
    }
</style>
</head>
<body>

<!-- ===== Top Bar with Home Button ===== -->
<div class="header-wrap">
    <div class="topbar">
        <div class="topbar-inner">
            <a href="/" class="btn-home">🏠 홈으로</a>
        </div>
    </div>
    <div class="header">
        <div class="brand">STU CONCERT · TICKETING</div>
        <h1>🎵 지금 가장 핫한 공연</h1>
        <p>당신만의 특별한 순간, STU Concert에서 만나보세요.</p>
    </div>
</div>

<div class="container">

    <!-- ===== Search ===== -->
    <div class="search-box">
        <form class="search-form" action="/concert/list.do" method="get">
            <input type="text" name="keyword" placeholder="공연명 / 아티스트 / 공연장 (대소문자 구분 없음)"
                   value="<c:out value='${keyword}'/>"/>
            <select name="status">
                <option value="">전체 상태</option>
                <option value="UPCOMING" <c:if test="${status == 'UPCOMING'}">selected</c:if>>예매예정</option>
                <option value="ONGOING"  <c:if test="${status == 'ONGOING'}">selected</c:if>>진행중</option>
                <option value="CLOSED"   <c:if test="${status == 'CLOSED'}">selected</c:if>>종료</option>
            </select>
            <input type="hidden" name="orderBy" value="<c:out value='${orderBy}'/>"/>
            <button type="submit" class="btn-search">🔍 검색</button>
            <button type="button" class="btn-reset" onclick="location.href='/concert/list.do'">초기화</button>
        </form>
    </div>

    <!-- ===== Toolbar ===== -->
    <div class="toolbar">
        <div class="result-count">
            전체 <strong><c:out value="${fn:length(concertList)}"/></strong>건의 공연
        </div>
        <div class="sort-tabs">
            <div class="sort-tab <c:if test="${orderBy == 'newest' or empty orderBy}">active</c:if>"
                 onclick="sortBy('newest')">최신순</div>
            <div class="sort-tab <c:if test="${orderBy == 'title'}">active</c:if>"
                 onclick="sortBy('title')">공연명순</div>
            <div class="sort-tab <c:if test="${orderBy == 'artist'}">active</c:if>"
                 onclick="sortBy('artist')">아티스트순</div>
        </div>
    </div>

    <!-- ===== Grid ===== -->
    <c:choose>
        <c:when test="${empty concertList}">
            <div class="empty-state">
                <div class="empty-state-icon">🎭</div>
                <h3>등록된 공연이 없습니다</h3>
                <p>검색 조건을 변경하거나 잠시 후 다시 시도해주세요.</p>
            </div>
        </c:when>
        <c:otherwise>
            <div class="concert-grid">
                <c:forEach var="concert" items="${concertList}">
                    <a class="concert-card" href="/concert/detail.do?concertId=${concert.concertId}">
                        <div class="card-thumb"
                             <c:if test="${not empty concert.thumbnail}">
                                style="background-image: url('<c:out value="${concert.thumbnail}"/>');"
                             </c:if>>
                            <c:if test="${empty concert.thumbnail}">
                                <div class="card-thumb-placeholder">🎵 No Image</div>
                            </c:if>
                            <c:if test="${not empty concert.status}">
                                <span class="status-badge status-${concert.status}">
                                    <c:choose>
                                        <c:when test="${concert.status == 'UPCOMING'}">예매예정</c:when>
                                        <c:when test="${concert.status == 'ONGOING'}">진행중</c:when>
                                        <c:when test="${concert.status == 'CLOSED'}">종료</c:when>
                                        <c:otherwise><c:out value="${concert.status}"/></c:otherwise>
                                    </c:choose>
                                </span>
                            </c:if>
                        </div>
                        <div class="card-body">
                            <div class="card-artist"><c:out value="${concert.artist}"/></div>
                            <div class="card-title"><c:out value="${concert.title}"/></div>
                            <div class="card-venue">📍 <c:out value="${concert.venue}"/></div>
                        </div>
                    </a>
                </c:forEach>
            </div>
        </c:otherwise>
    </c:choose>

</div>

<script>
    function sortBy(orderBy) {
        var params = new URLSearchParams(window.location.search);
        params.set('orderBy', orderBy);
        window.location.href = '/concert/list.do?' + params.toString();
    }
</script>

</body>
</html>
