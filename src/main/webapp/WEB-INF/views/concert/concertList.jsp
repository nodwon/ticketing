<%--
 * Project    : 관제 티켓 (Ticketing System)
 * FileName   : concertList.jsp
 * Developer  : 주재현 (feature/jjh)
 * Created    : 2026.05.22
 * Modified   : 2026.05.27
 
    ⚠️ SECURITY LAB - concertList.jsp
    [VULN-2a] XSS Reflected - HTML 컨텍스트
    [VULN-2b] XSS Reflected - Attribute 컨텍스트
    [VULN-2c] XSS DOM-based - JavaScript 문자열
    [VULN-4]  SQL Error 화면 노출
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
    body { font-family: 'Pretendard', sans-serif; background: #f5f6fa; color: #1a1a1a; line-height: 1.5; }
    a { text-decoration:none; color:inherit; }
    button { font-family: inherit; }
    .topbar { background: rgba(255,255,255,0.08); padding: 14px 0; }
    .topbar-inner { max-width: 1200px; margin: 0 auto; padding: 0 24px; display: flex; align-items: center; gap: 12px; }
    .btn-home { display: inline-flex; align-items: center; gap: 6px; padding: 9px 16px; background: rgba(255,255,255,0.18); color: #fff; border: 1px solid rgba(255,255,255,0.3); border-radius: 8px; font-size: 13px; font-weight: 600; cursor: pointer; }
    .header-wrap { background: linear-gradient(135deg, #6a11cb 0%, #2575fc 100%); color: #fff; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
    .header { max-width: 1200px; margin: 0 auto; padding: 36px 24px 80px; }
    .brand { font-size: 13px; font-weight: 600; letter-spacing: 2px; opacity: 0.85; margin-bottom: 12px; }
    .header h1 { font-size: 36px; font-weight: 800; margin-bottom: 10px; }
    .header p { font-size: 15px; opacity: 0.9; }
    .container { max-width: 1200px; margin: -40px auto 60px; padding: 0 24px; position: relative; }
    .sql-error-banner { background: #fef2f2; border: 2px solid #fca5a5; border-radius: 12px; padding: 16px 20px; margin-bottom: 20px; font-family: 'Courier New', monospace; font-size: 13px; color: #991b1b; line-height: 1.6; word-break: break-all; white-space: pre-wrap; }
    .sql-error-title { font-weight: 800; font-size: 14px; margin-bottom: 8px; font-family: 'Pretendard', sans-serif; }
    .search-box { background: #fff; border-radius: 16px; padding: 24px 28px; box-shadow: 0 8px 30px rgba(0,0,0,0.08); margin-bottom: 20px; }
    .search-form { display: grid; grid-template-columns: 1fr 110px 90px; gap: 12px; }
    .search-form input { padding: 14px 16px; border: 1.5px solid #e5e7eb; border-radius: 10px; font-size: 14px; outline: none; background: #fff; color: #1a1a1a; }
    .btn-search { background: linear-gradient(135deg, #6a11cb 0%, #2575fc 100%); color: #fff; border: none; border-radius: 10px; font-size: 14px; font-weight: 700; cursor: pointer; }
    .btn-reset { background: #f3f4f6; color: #555; border: none; border-radius: 10px; font-size: 14px; font-weight: 500; cursor: pointer; }
    .filter-bar { background: #fff; border-radius: 16px; padding: 8px; box-shadow: 0 4px 14px rgba(0,0,0,0.06); display: flex; gap: 4px; margin-bottom: 24px; }
    .filter-tab { flex: 1; padding: 14px 18px; border-radius: 10px; font-size: 14px; font-weight: 600; color: #6b7280; cursor: pointer; text-align: center; display: flex; align-items: center; justify-content: center; gap: 8px; }
    .filter-tab.active { background: linear-gradient(135deg, #6a11cb 0%, #2575fc 100%); color: #fff; font-weight: 700; }
    .toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; padding: 0 4px; }
    .result-count { font-size: 14px; color: #6b7280; }
    .result-count strong { color: #6a11cb; font-weight: 700; }
    .sort-info { font-size: 12px; color: #9ca3af; }
    .concert-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 22px; }
    .concert-card { background: #fff; border-radius: 14px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.06); transition: transform .2s, box-shadow .2s; display: flex; flex-direction: column; }
    .concert-card:hover { transform: translateY(-6px); box-shadow: 0 14px 32px rgba(0,0,0,0.13); }
    .card-thumb { width: 100%; height: 320px; background: linear-gradient(135deg, #e5e7eb, #cbd5e1); background-size: cover; background-position: center; position: relative; }
    .card-thumb-placeholder { height: 100%; display: flex; align-items: center; justify-content: center; color: #94a3b8; font-size: 14px; }
    .status-badge { position: absolute; top: 12px; right: 12px; padding: 5px 12px; border-radius: 20px; font-size: 11px; font-weight: 700; color: #fff; }
    .status-UPCOMING { background: rgba(245,158,11,0.95); }
    .status-ONGOING  { background: rgba(34,197,94,0.95); }
    .status-CLOSED   { background: rgba(107,114,128,0.95); }
    .card-body { padding: 18px 20px 20px; flex: 1; display: flex; flex-direction: column; }
    .card-artist { font-size: 12px; color: #6a11cb; font-weight: 700; margin-bottom: 6px; text-transform: uppercase; }
    .card-title { font-size: 16px; font-weight: 700; color: #1a1a1a; line-height: 1.4; margin-bottom: 10px; min-height: 44px; }
    .card-venue { font-size: 13px; color: #4b5563; font-weight: 500; margin-bottom: 14px; }
    .card-periods { border-top: 1px solid #f3f4f6; padding-top: 12px; display: flex; flex-direction: column; gap: 8px; margin-top: auto; }
    .period-row { display: flex; align-items: flex-start; gap: 8px; font-size: 12px; }
    .period-label { flex-shrink: 0; padding: 2px 8px; border-radius: 6px; font-size: 10px; font-weight: 800; background: #f3f4f6; color: #6b7280; }
    .period-label.booking { background: #ede9fe; color: #6a11cb; }
    .period-label.perform { background: #dbeafe; color: #2563eb; }
    .period-value { flex: 1; color: #1a1a1a; font-weight: 500; }
    .period-value.muted { color: #9ca3af; font-weight: 400; }
    .empty-state { background: #fff; border-radius: 16px; padding: 80px 20px; text-align: center; color: #9ca3af; }
    .empty-state-icon { font-size: 56px; margin-bottom: 16px; }
    .empty-state h3 { color: #4b5563; margin-bottom: 8px; font-size: 18px; }
</style>
</head>
<body>

<div class="header-wrap">
    <div class="topbar"><div class="topbar-inner"><a href="/" class="btn-home">🏠 홈으로</a></div></div>
    <div class="header">
        <div class="brand">STU CONCERT · TICKETING</div>
        <h1>🎵 지금 만날 수 있는 공연</h1>
        <p>당신만의 특별한 순간, STU Concert에서 만나보세요.</p>
    </div>
</div>

<div class="container">

    <%-- [VULN-4] SQL 에러 그대로 노출 --%>
    <c:if test="${not empty sqlError}">
        <div class="sql-error-banner">
            <div class="sql-error-title">⚠️ SQL Error</div>${sqlError}
        </div>
    </c:if>

    <%-- [VULN-2b] input value 속성에 ${keyword} 직접 출력 --%>
    <div class="search-box">
        <form class="search-form" action="/concert/list.do" method="get">
            <input type="text" name="keyword" placeholder="공연명 / 아티스트 / 공연장 (대소문자 구분 없음)" value="${keyword}"/>
            <input type="hidden" name="status" value="${status}"/>
            <button type="submit" class="btn-search">🔍 검색</button>
            <button type="button" class="btn-reset" onclick="location.href='/concert/list.do'">초기화</button>
        </form>
    </div>

    <div class="filter-bar">
        <div class="filter-tab <c:if test='${empty status}'>active</c:if>" onclick="setStatus('')"><span>🎫</span><span>전체</span></div>
        <div class="filter-tab <c:if test='${status == "ONGOING"}'>active</c:if>" onclick="setStatus('ONGOING')"><span>🔥</span><span>진행중</span></div>
        <div class="filter-tab <c:if test='${status == "UPCOMING"}'>active</c:if>" onclick="setStatus('UPCOMING')"><span>⏳</span><span>예매예정</span></div>
        <div class="filter-tab <c:if test='${status == "CLOSED"}'>active</c:if>" onclick="setStatus('CLOSED')"><span>✓</span><span>종료</span></div>
    </div>

    <%-- [VULN-2a] HTML 컨텍스트에 ${keyword} 직접 출력 --%>
    <div class="toolbar">
        <div class="result-count">
            <c:choose>
                <c:when test="${not empty keyword}">"<strong>${keyword}</strong>" 검색 결과 </c:when>
                <c:when test="${status == 'ONGOING'}">진행중인 공연 </c:when>
                <c:when test="${status == 'UPCOMING'}">예매예정 공연 </c:when>
                <c:when test="${status == 'CLOSED'}">종료된 공연 </c:when>
                <c:otherwise>전체 공연 </c:otherwise>
            </c:choose>
            <strong><c:out value="${fn:length(concertList)}"/></strong>건
        </div>
        <div class="sort-info">📅 예매오픈일 빠른 순</div>
    </div>

    <c:choose>
        <c:when test="${empty concertList}">
            <div class="empty-state">
                <div class="empty-state-icon">🎭</div>
                <h3>해당하는 공연이 없습니다</h3>
                <p>검색 조건이나 필터를 변경해보세요.</p>
            </div>
        </c:when>
        <c:otherwise>
            <div class="concert-grid">
                <c:forEach var="concert" items="${concertList}">
                    <a class="concert-card" href="/concert/detail.do?concertId=${concert.concertId}">
                        <div class="card-thumb" <c:if test="${not empty concert.thumbnail}">style="background-image: url('<c:out value="${concert.thumbnail}"/>');"</c:if>>
                            <c:if test="${empty concert.thumbnail}"><div class="card-thumb-placeholder">🎵 No Image</div></c:if>
                            <c:if test="${not empty concert.status}">
                                <span class="status-badge status-${concert.status}">
                                    <c:choose>
                                        <c:when test="${concert.status == 'ONGOING'}">진행중</c:when>
                                        <c:when test="${concert.status == 'UPCOMING'}">예매예정</c:when>
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
                            <div class="card-periods">
                                <div class="period-row">
                                    <span class="period-label booking">예매</span>
                                    <span class="period-value <c:if test='${empty concert.bookingStartAt}'>muted</c:if>">
                                        <c:choose>
                                            <c:when test="${empty concert.bookingStartAt}">미정</c:when>
                                            <c:when test="${fn:substring(concert.bookingStartAt, 0, 10) == fn:substring(concert.bookingEndAt, 0, 10)}"><c:out value="${fn:substring(concert.bookingStartAt, 0, 10)}"/></c:when>
                                            <c:otherwise><c:out value="${fn:substring(concert.bookingStartAt, 0, 10)}"/> ~ <c:out value="${fn:substring(concert.bookingEndAt, 0, 10)}"/></c:otherwise>
                                        </c:choose>
                                    </span>
                                </div>
                                <div class="period-row">
                                    <span class="period-label perform">공연</span>
                                    <span class="period-value <c:if test='${empty concert.performStartAt}'>muted</c:if>">
                                        <c:choose>
                                            <c:when test="${empty concert.performStartAt}">미정</c:when>
                                            <c:when test="${fn:substring(concert.performStartAt, 0, 10) == fn:substring(concert.performEndAt, 0, 10)}"><c:out value="${fn:substring(concert.performStartAt, 0, 10)}"/></c:when>
                                            <c:otherwise><c:out value="${fn:substring(concert.performStartAt, 0, 10)}"/> ~ <c:out value="${fn:substring(concert.performEndAt, 0, 10)}"/></c:otherwise>
                                        </c:choose>
                                    </span>
                                </div>
                            </div>
                        </div>
                    </a>
                </c:forEach>
            </div>
        </c:otherwise>
    </c:choose>

</div>

<script>
    // [VULN-2c] JavaScript 문자열 컨텍스트에 keyword 직접 출력
    var lastKeyword = "${keyword}";
    if (lastKeyword) { console.log("최근 검색어:", lastKeyword); }

    function setStatus(statusVal) {
        var params = new URLSearchParams(window.location.search);
        if (statusVal) { params.set('status', statusVal); }
        else { params.delete('status'); }
        window.location.href = '/concert/list.do?' + params.toString();
    }
</script>

</body>
</html>
