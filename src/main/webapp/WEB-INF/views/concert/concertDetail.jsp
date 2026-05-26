<%--
    ============================================================
    Project    : 관제 티켓 (Ticketing System)
    FileName   : concertDetail.jsp
    Developer  : 주재현 (feature/jjh)
    Created    : 2026.05.22
    Modified   : 2026.05.26
    Description: 공연 상세 페이지
                 - 예매하기 버튼: 세션(SESSION_ID) 존재 시 /seat/select.do
                                 미존재 시 로그인 유도 팝업 → /loginForm.do
                 - CLOB(description) 정상 표시
                 - 보안 취약: 클라이언트 분기 only -> 서버 사이드 검증 없음
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

    /* ===== Header ===== */
    .header { background: linear-gradient(135deg, #6a11cb 0%, #2575fc 100%); color: #fff; padding: 18px 0; }
    .header-inner {
        max-width: 1200px; margin: 0 auto; padding: 0 24px;
        display: flex; justify-content: space-between; align-items: center;
    }
    .header-left { display: flex; align-items: center; gap: 10px; }
    .header-right { display: flex; align-items: center; gap: 10px; }
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
    .session-info {
        font-size: 13px; color: rgba(255,255,255,0.92);
        display: flex; align-items: center; gap: 6px;
    }
    .session-info b { font-weight: 700; }

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

    /* ============================================================ */
    /* ===== Login Modal (커스텀 팝업) ===== */
    /* ============================================================ */
    .modal-backdrop {
        display: none;
        position: fixed; top: 0; left: 0; right: 0; bottom: 0;
        background: rgba(0,0,0,0.55);
        backdrop-filter: blur(4px);
        z-index: 1000;
        align-items: center; justify-content: center;
        padding: 20px;
        animation: fadeIn .2s ease;
    }
    .modal-backdrop.show { display: flex; }
    @keyframes fadeIn { from{opacity:0;} to{opacity:1;} }
    @keyframes slideUp { from{transform:translateY(20px); opacity:0;} to{transform:translateY(0); opacity:1;} }

    .modal-card {
        background: #fff; border-radius: 20px;
        max-width: 420px; width: 100%;
        box-shadow: 0 20px 60px rgba(0,0,0,0.3);
        overflow: hidden;
        animation: slideUp .25s ease;
    }
    .modal-icon-wrap {
        background: linear-gradient(135deg, #6a11cb 0%, #2575fc 100%);
        padding: 32px 20px 20px;
        text-align: center;
    }
    .modal-icon {
        width: 64px; height: 64px;
        background: rgba(255,255,255,0.25);
        border-radius: 50%;
        display: inline-flex; align-items: center; justify-content: center;
        font-size: 32px; margin: 0 auto;
    }
    .modal-body {
        padding: 28px 28px 12px; text-align: center;
    }
    .modal-title {
        font-size: 19px; font-weight: 800; color: #1a1a1a;
        margin-bottom: 10px; letter-spacing: -0.3px;
    }
    .modal-desc {
        font-size: 14px; color: #6b7280; line-height: 1.6;
    }
    .modal-actions {
        display: flex; gap: 8px; padding: 20px 28px 28px;
    }
    .modal-btn {
        flex: 1; padding: 14px;
        border-radius: 10px; font-size: 14px; font-weight: 700;
        cursor: pointer; border: none;
        transition: transform .12s, box-shadow .12s, border-color .15s;
    }
    .modal-btn-cancel {
        background: #fff; color: #6b7280;
        border: 1.5px solid #e5e7eb;
    }
    .modal-btn-cancel:hover { border-color: #9ca3af; color: #4b5563; }
    .modal-btn-ok {
        background: linear-gradient(135deg, #6a11cb 0%, #2575fc 100%);
        color: #fff;
    }
    .modal-btn-ok:hover {
        transform: translateY(-1px);
        box-shadow: 0 6px 16px rgba(106,17,203,0.4);
    }

    @media (max-width: 900px) {
        .detail-card { grid-template-columns: 1fr; }
        .detail-thumb { height: 380px; }
        .detail-info  { padding: 28px 22px; }
        .detail-title { font-size: 22px; }
        .header h1 { display: none; }
        .session-info { display: none; }
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
        <div class="header-right">
            <c:choose>
                <c:when test="${not empty sessionScope.SESSION_ID}">
                    <span class="session-info">
                        👤 <b><c:out value="${sessionScope.SESSION_NAME}"/></b>님
                    </span>
                    <a href="javascript:doLogout();" class="btn-icon">로그아웃</a>
                </c:when>
                <c:otherwise>
                    <a href="/loginForm.do" class="btn-icon">🔑 로그인</a>
                </c:otherwise>
            </c:choose>
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

                <!-- ============================================================ -->
                <!-- 예매하기 버튼: 세션 분기                                      -->
                <!--  - 로그인 O → /seat/select.do?concertId=...                  -->
                <!--  - 로그인 X → 로그인 유도 팝업 표시                          -->
                <!-- ============================================================ -->
                <div class="action-buttons">
                    <c:choose>
                        <c:when test="${concert.status == 'ONGOING' or concert.status == 'UPCOMING'}">
                            <button class="btn-primary" onclick="handleBooking()">
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

<!-- ===== Login Required Modal ===== -->
<div class="modal-backdrop" id="loginModal">
    <div class="modal-card">
        <div class="modal-icon-wrap">
            <div class="modal-icon">🔐</div>
        </div>
        <div class="modal-body">
            <div class="modal-title">로그인이 필요합니다</div>
            <div class="modal-desc">
                예매 서비스 이용을 위해 로그인이 필요합니다.<br>
                로그인 페이지로 이동하시겠습니까?
            </div>
        </div>
        <div class="modal-actions">
            <button class="modal-btn modal-btn-cancel" onclick="closeLoginModal()">취소</button>
            <button class="modal-btn modal-btn-ok" onclick="goToLogin()">로그인하기</button>
        </div>
    </div>
</div>

<script>
    // ============================================================
    // 세션 상태: JSP 에서 서버 사이드로 boolean 주입
    // (클라이언트에서 sessionScope.SESSION_ID 직접 접근 불가)
    // ============================================================
    var isLoggedIn = <c:choose>
                        <c:when test="${not empty sessionScope.SESSION_ID}">true</c:when>
                        <c:otherwise>false</c:otherwise>
                     </c:choose>;
    var concertId  = '<c:out value="${concert.concertId}"/>';

    // ============================================================
    // 예매 버튼 클릭 핸들러
    // ============================================================
    function handleBooking() {
        if (isLoggedIn) {
            // 로그인 상태: 예매 페이지로 이동
            location.href = '/seat/select.do?concertId=' + concertId;
        } else {
            // 비로그인 상태: 로그인 유도 팝업
            openLoginModal();
        }
    }

    function openLoginModal() {
        document.getElementById('loginModal').classList.add('show');
    }

    function closeLoginModal() {
        document.getElementById('loginModal').classList.remove('show');
    }

    function goToLogin() {
        // 로그인 후 다시 이 페이지로 돌아오도록 returnUrl 전달
        // (LoginController 측에서 returnUrl 처리 시 활용 가능)
        var returnUrl = encodeURIComponent('/concert/detail.do?concertId=' + concertId);
        location.href = '/loginForm.do?returnUrl=' + returnUrl;
    }

    // 백드롭 클릭 시 닫기
    document.getElementById('loginModal').addEventListener('click', function(e){
        if (e.target === this) closeLoginModal();
    });

    // ESC 키로 닫기
    document.addEventListener('keydown', function(e){
        if (e.key === 'Escape') closeLoginModal();
    });

    // ============================================================
    // 로그아웃 (LoginController.logout 규약에 맞춤: POST + JSON)
    // ============================================================
    function doLogout() {
        if (!confirm('로그아웃 하시겠습니까?')) return;
        fetch('/logout.do', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({})
        })
        .then(function(res){ return res.json(); })
        .then(function(data){
            location.href = data.URL || '/';
        })
        .catch(function(){
            // 실패 시에도 메인으로 강제 이동
            location.href = '/';
        });
    }
</script>

</body>
</html>
