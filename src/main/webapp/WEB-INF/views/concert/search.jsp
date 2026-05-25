<%--
    ============================================================
    Project    : 관제 티켓 (Ticketing System)
    FileName   : search.jsp
    Developer  : 주재현 (feature/jjh)
    Created    : 2026.05.22
    Modified   : 2026.05.25
    Description: 공연 검색 결과 페이지
                 - 대소문자 무관 검색
                 - 키워드 하이라이트
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
<title>검색 결과 | STU Concert</title>
<style>
    *,*::before,*::after { margin:0; padding:0; box-sizing:border-box; }
    body {
        font-family: 'Pretendard', -apple-system, BlinkMacSystemFont, 'Noto Sans KR', sans-serif;
        background: #f5f6fa; color: #1a1a1a; -webkit-font-smoothing: antialiased;
    }
    a { text-decoration:none; color:inherit; }
    button { font-family: inherit; }

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
    .header h1 { font-size: 20px; font-weight: 800; cursor: pointer; letter-spacing:-0.5px; margin-left: 8px; }

    .container { max-width: 1200px; margin: 40px auto 60px; padding: 0 24px; }

    .search-hero {
        background: #fff; border-radius: 20px; padding: 36px;
        box-shadow: 0 8px 30px rgba(0,0,0,0.08); margin-bottom: 28px;
    }
    .search-hero-title {
        font-size: 14px; color: #9ca3af; font-weight: 600;
        letter-spacing: 1px; text-transform: uppercase; margin-bottom: 8px;
    }
    .search-hero-keyword {
        font-size: 28px; font-weight: 800; color: #1a1a1a;
        margin-bottom: 24px; letter-spacing: -0.5px;
    }
    .search-hero-keyword .accent {
        background: linear-gradient(135deg, #6a11cb, #2575fc);
        -webkit-background-clip: text; background-clip: text; color: transparent;
    }
    .search-form { display: flex; gap: 10px; }
    .search-input {
        flex: 1; padding: 14px 18px;
        border: 1.5px solid #e5e7eb; border-radius: 10px;
        font-size: 14px; outline: none;
        transition: border-color .15s, box-shadow .15s;
    }
    .search-input:focus {
        border-color: #6a11cb;
        box-shadow: 0 0 0 3px rgba(106,17,203,0.1);
    }
    .btn-search-go {
        padding: 14px 28px;
        background: linear-gradient(135deg, #6a11cb 0%, #2575fc 100%);
        color: #fff; border: none; border-radius: 10px;
        font-size: 14px; font-weight: 700; cursor: pointer;
    }

    .result-count { font-size: 14px; color: #6b7280; margin-bottom: 16px; padding: 0 4px; }
    .result-count strong { color: #6a11cb; font-weight: 700; }

    .concert-grid {
        display: grid; gap: 22px;
        grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
    }
    .concert-card {
        background: #fff; border-radius: 14px; overflow: hidden;
        box-shadow: 0 2px 10px rgba(0,0,0,0.06);
        transition: transform .2s, box-shadow .2s;
        display: flex; flex-direction: column;
    }
    .concert-card:hover { transform: translateY(-6px); box-shadow: 0 14px 32px rgba(0,0,0,0.13); }
    .card-thumb { width:100%; height:320px;
        background: linear-gradient(135deg, #e5e7eb, #cbd5e1);
        background-size: cover; background-position: center; position: relative;
    }
    .card-thumb-placeholder { height:100%; display:flex; align-items:center; justify-content:center;
        color:#94a3b8; font-size:14px;
    }
    .status-badge {
        position:absolute; top:12px; right:12px;
        padding:5px 12px; border-radius:20px;
        font-size:11px; font-weight:700; color:#fff; backdrop-filter: blur(8px);
    }
    .status-UPCOMING { background: rgba(245,158,11,0.95); }
    .status-ONGOING  { background: rgba(34,197,94,0.95); }
    .status-CLOSED   { background: rgba(107,114,128,0.95); }

    .card-body { padding:16px 18px 18px; flex:1; display:flex; flex-direction:column; }
    .card-artist {
        font-size:12px; color:#6a11cb; font-weight:700;
        letter-spacing:0.3px; margin-bottom:6px; text-transform:uppercase;
    }
    .card-title {
        font-size:15px; font-weight:700; color:#1a1a1a; line-height:1.4;
        margin-bottom:8px; min-height:42px;
        display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden;
    }
    .card-venue { font-size:12px; color:#6b7280; }

    .highlight { background: linear-gradient(180deg, transparent 60%, #fde68a 60%); font-weight: 700; }

    .empty-state {
        background: #fff; border-radius: 16px; padding: 80px 20px; text-align: center;
        color: #9ca3af; box-shadow: 0 2px 10px rgba(0,0,0,0.04);
    }
    .empty-state-icon { font-size: 56px; margin-bottom: 16px; }
    .empty-state h3 { color: #4b5563; margin-bottom: 8px; font-size: 18px; }

    @media (max-width: 768px) {
        .search-hero { padding: 24px; }
        .search-hero-keyword { font-size: 20px; }
        .search-form { flex-direction: column; }
        .concert-grid { grid-template-columns: repeat(2, 1fr); gap: 12px; }
        .card-thumb { height: 220px; }
        .header h1 { display: none; }
    }
</style>
</head>
<body>

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

    <div class="search-hero">
        <div class="search-hero-title">SEARCH RESULTS</div>
        <div class="search-hero-keyword">
            <c:choose>
                <c:when test="${not empty keyword}">
                    "<span class="accent"><c:out value="${keyword}"/></span>" 검색 결과
                </c:when>
                <c:otherwise>공연 검색</c:otherwise>
            </c:choose>
        </div>
        <form class="search-form" action="/concert/search.do" method="get">
            <input class="search-input" type="text" name="keyword"
                   placeholder="공연명 / 아티스트 / 공연장 (대소문자 구분 없음)"
                   value="<c:out value='${keyword}'/>"/>
            <button class="btn-search-go" type="submit">🔍 검색</button>
        </form>
    </div>

    <div class="result-count">
        전체 <strong><c:out value="${fn:length(concertList)}"/></strong>건이 검색되었습니다
    </div>

    <c:choose>
        <c:when test="${empty concertList}">
            <div class="empty-state">
                <div class="empty-state-icon">🔎</div>
                <h3>검색 결과가 없습니다</h3>
                <p>다른 키워드로 검색해보세요.</p>
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
    // 검색어 하이라이트 (대소문자 구분 없이)
    (function(){
        var kw = "<c:out value='${keyword}' default=''/>".trim();
        if (!kw) return;
        var safeKw = kw.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        var regex = new RegExp('(' + safeKw + ')', 'gi');
        document.querySelectorAll('.card-title, .card-artist, .card-venue').forEach(function(el){
            el.innerHTML = el.innerHTML.replace(regex, '<span class="highlight">$1</span>');
        });
    })();
</script>

</body>
</html>
