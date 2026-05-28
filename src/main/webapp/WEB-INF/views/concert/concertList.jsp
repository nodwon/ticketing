<%--
 * ============================================================
 * Project  : 관제 티켓 (Ticketing System)
 * FileName : concertList.jsp
 * Developer : 주재현 (feature/jjh)
 * Created  : 2026.05.22
 * Modified  : 2026.05.28 (UI 공통 테마 통일 - theme.css 적용)
 *
 * Description :
 *   - 공연 목록 조회 / 검색 / 상태 필터
 *
 * ⚠️ SECURITY LAB - concertList.jsp
 *   [VULN-2a] XSS Reflected - HTML 컨텍스트
 *   [VULN-2b] XSS Reflected - Attribute 컨텍스트
 *   [VULN-2c] XSS DOM-based - JavaScript 문자열
 *   [VULN-4] SQL Error 화면 노출
 *   ※ 보안 실습용 취약점이므로 의도적으로 유지함
 * ============================================================
--%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c"   uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn"  uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>공연 목록 | GWANJE TICKET</title>
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/theme.css">
<style>
    /* 콘서트 목록 전용 (공통 theme.css 기반 확장) */
    body { background: var(--gray); }

    .cl-toolbar-top { background: var(--mid); padding: 12px 0; }
    .cl-toolbar-top .tk-container { display: flex; align-items: center; }

    .cl-search-box { background: var(--white); border:1px solid var(--border); border-radius: var(--radius-lg); padding: 22px 26px; box-shadow: var(--shadow); margin: 24px 0 18px; }
    .cl-search-form { display: grid; grid-template-columns: 1fr 110px 90px; gap: 10px; }

    .cl-filter-bar { background: var(--white); border:1px solid var(--border); border-radius: var(--radius-lg); padding: 6px; box-shadow: var(--shadow); display: flex; gap: 4px; margin-bottom: 24px; }
    .cl-filter-tab { flex: 1; padding: 13px 16px; border-radius: var(--radius); font-size: 14px; font-weight: 600; color: var(--muted); cursor: pointer; text-align: center; display: flex; align-items: center; justify-content: center; gap: 8px; transition: all .2s; }
    .cl-filter-tab:hover { color: var(--text); background: var(--gray); }
    .cl-filter-tab.active { background: var(--dark); color: var(--white); font-weight: 700; }

    .cl-toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; padding: 0 4px; }
    .cl-result-count { font-size: 14px; color: var(--muted); }
    .cl-result-count strong { color: var(--red); font-weight: 700; }
    .cl-sort-info { font-size: 12px; color: var(--muted); }

    .cl-thumb { width: 100%; aspect-ratio: 3/4; background: linear-gradient(135deg,#e8e8e8,#d4d4d4); background-size: cover; background-position: center; position: relative; }
    .cl-thumb-ph { height: 100%; display: flex; align-items: center; justify-content: center; color: #aaa; font-size: 14px; }
    .cl-status { position: absolute; top: 12px; right: 12px; }

    .cl-card-artist { font-size: 12px; color: var(--red); font-weight: 700; margin-bottom: 6px; text-transform: uppercase; }
    .cl-card-title { font-size: 16px; font-weight: 700; color: var(--dark); line-height: 1.4; margin-bottom: 10px; min-height: 44px; }
    .cl-card-venue { font-size: 13px; color: #555; font-weight: 500; margin-bottom: 14px; }
    .cl-periods { border-top: 1px solid var(--border); padding-top: 12px; display: flex; flex-direction: column; gap: 8px; margin-top: auto; }
    .cl-period-row { display: flex; align-items: flex-start; gap: 8px; font-size: 12px; }
    .cl-period-label { flex-shrink: 0; padding: 2px 8px; border-radius: var(--radius); font-size: 10px; font-weight: 800; background: var(--gray); color: var(--muted); }
    .cl-period-label.booking { background: #fde8ea; color: var(--red); }
    .cl-period-label.perform { background: #eee; color: #444; }
    .cl-period-value { flex: 1; color: var(--text); font-weight: 500; }
    .cl-period-value.muted { color: #aaa; font-weight: 400; }

    .cl-sql-error { background: #fef2f2; border: 2px solid #fca5a5; border-radius: var(--radius); padding: 16px 20px; margin: 24px 0 0; font-family: 'Courier New', monospace; font-size: 13px; color: #991b1b; line-height: 1.6; word-break: break-all; white-space: pre-wrap; }
    .cl-sql-error-title { font-weight: 800; font-size: 14px; margin-bottom: 8px; font-family: var(--font-kr); }

    .cl-empty { background: var(--white); border:1px solid var(--border); border-radius: var(--radius-lg); padding: 80px 20px; text-align: center; color: var(--muted); }
    .cl-empty-icon { font-size: 56px; margin-bottom: 16px; }
    .cl-empty h3 { color: var(--text); margin-bottom: 8px; font-size: 18px; }
</style>
</head>
<body>

<!-- 상단 홈 이동 바 -->
<div class="cl-toolbar-top">
    <div class="tk-container">
        <a href="/" class="tk-btn tk-btn-sm tk-btn-dark">🏠 홈으로</a>
    </div>
</div>

<!-- 페이지 헤더 (공통 톤) -->
<div class="tk-page-head">
    <div class="tk-page-head-inner">
        <div class="brand">STU CONCERT · TICKETING</div>
        <h1>지금 만날 수 있는 공연</h1>
        <p>당신만의 특별한 순간, GWANJE TICKET에서 만나보세요.</p>
        <div class="tk-steps">
            <span class="tk-step active"><span class="num">1</span>공연 선택</span>
            <span class="tk-step-sep">›</span>
            <span class="tk-step"><span class="num">2</span>좌석 선택</span>
            <span class="tk-step-sep">›</span>
            <span class="tk-step"><span class="num">3</span>결제</span>
            <span class="tk-step-sep">›</span>
            <span class="tk-step"><span class="num">4</span>완료</span>
        </div>
    </div>
</div>

<div class="tk-container" style="padding-bottom:60px;">

    <%-- [VULN-4] SQL 에러 그대로 노출 --%>
    <c:if test="${not empty sqlError}">
        <div class="cl-sql-error">
            <div class="cl-sql-error-title">⚠️ SQL Error</div>${sqlError}
        </div>
    </c:if>

    <%-- [VULN-2b] input value 속성에 ${keyword} 직접 출력 --%>
    <div class="cl-search-box">
        <form class="cl-search-form" action="/concert/list.do" method="get">
            <input type="text" name="keyword" class="tk-input" placeholder="공연명 / 아티스트 / 공연장 (대소문자 구분 없음)" value="${keyword}"/>
            <input type="hidden" name="status" value="${status}"/>
            <button type="submit" class="tk-btn tk-btn-primary">🔍 검색</button>
            <button type="button" class="tk-btn tk-btn-ghost" onclick="location.href='/concert/list.do'">초기화</button>
        </form>
    </div>

    <div class="cl-filter-bar">
        <div class="cl-filter-tab <c:if test='${empty status}'>active</c:if>" onclick="setStatus('')"><span>🎫</span><span>전체</span></div>
        <div class="cl-filter-tab <c:if test='${status == "ONGOING"}'>active</c:if>" onclick="setStatus('ONGOING')"><span>🔥</span><span>진행중</span></div>
        <div class="cl-filter-tab <c:if test='${status == "UPCOMING"}'>active</c:if>" onclick="setStatus('UPCOMING')"><span>⏳</span><span>예매예정</span></div>
        <div class="cl-filter-tab <c:if test='${status == "CLOSED"}'>active</c:if>" onclick="setStatus('CLOSED')"><span>✓</span><span>종료</span></div>
    </div>

    <%-- [VULN-2a] HTML 컨텍스트에 ${keyword} 직접 출력 --%>
    <div class="cl-toolbar">
        <div class="cl-result-count">
            <c:choose>
                <c:when test="${not empty keyword}">"<strong>${keyword}</strong>" 검색 결과 </c:when>
                <c:when test="${status == 'ONGOING'}">진행중인 공연 </c:when>
                <c:when test="${status == 'UPCOMING'}">예매예정 공연 </c:when>
                <c:when test="${status == 'CLOSED'}">종료된 공연 </c:when>
                <c:otherwise>전체 공연 </c:otherwise>
            </c:choose>
            <strong><c:out value="${fn:length(concertList)}"/></strong>건
        </div>
        <div class="cl-sort-info">📅 예매오픈일 빠른 순</div>
    </div>

    <c:choose>
        <c:when test="${empty concertList}">
            <div class="cl-empty">
                <div class="cl-empty-icon">🎭</div>
                <h3>해당하는 공연이 없습니다</h3>
                <p>검색 조건이나 필터를 변경해보세요.</p>
            </div>
        </c:when>
        <c:otherwise>
            <div class="tk-poster-grid">
                <c:forEach var="concert" items="${concertList}">
                    <a class="tk-poster" href="/concert/detail.do?concertId=${concert.concertId}">
                        <div class="cl-thumb" <c:if test="${not empty concert.thumbnail}">style="background-image: url('<c:out value="${concert.thumbnail}"/>');"</c:if>>
                            <c:if test="${empty concert.thumbnail}"><div class="cl-thumb-ph">🎵 No Image</div></c:if>
                            <c:if test="${not empty concert.status}">
                                <span class="cl-status tk-badge tk-badge-${concert.status == 'ONGOING' ? 'ongoing' : (concert.status == 'UPCOMING' ? 'upcoming' : 'closed')}">
                                    <c:choose>
                                        <c:when test="${concert.status == 'ONGOING'}">진행중</c:when>
                                        <c:when test="${concert.status == 'UPCOMING'}">예매예정</c:when>
                                        <c:when test="${concert.status == 'CLOSED'}">종료</c:when>
                                        <c:otherwise><c:out value="${concert.status}"/></c:otherwise>
                                    </c:choose>
                                </span>
                            </c:if>
                        </div>
                        <div class="tk-poster-body">
                            <div class="cl-card-artist"><c:out value="${concert.artist}"/></div>
                            <div class="cl-card-title"><c:out value="${concert.title}"/></div>
                            <div class="cl-card-venue">📍 <c:out value="${concert.venue}"/></div>
                            <div class="cl-periods">
                                <div class="cl-period-row">
                                    <span class="cl-period-label booking">예매</span>
                                    <span class="cl-period-value <c:if test='${empty concert.bookingStartAt}'>muted</c:if>">
                                        <c:choose>
                                            <c:when test="${empty concert.bookingStartAt}">미정</c:when>
                                            <c:when test="${fn:substring(concert.bookingStartAt, 0, 10) == fn:substring(concert.bookingEndAt, 0, 10)}"><c:out value="${fn:substring(concert.bookingStartAt, 0, 10)}"/></c:when>
                                            <c:otherwise><c:out value="${fn:substring(concert.bookingStartAt, 0, 10)}"/> ~ <c:out value="${fn:substring(concert.bookingEndAt, 0, 10)}"/></c:otherwise>
                                        </c:choose>
                                    </span>
                                </div>
                                <div class="cl-period-row">
                                    <span class="cl-period-label perform">공연</span>
                                    <span class="cl-period-value <c:if test='${empty concert.performStartAt}'>muted</c:if>">
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
