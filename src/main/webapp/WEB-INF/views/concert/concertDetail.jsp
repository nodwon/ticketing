<%--
    ============================================================
    Project    : 관제 티켓 (Ticketing System)
    FileName   : concertDetail.jsp
    Developer  : 주재현 (feature/jjh)
    Created    : 2026.05.22
    Modified   : 2026.05.26
    Description: 공연 상세 페이지
                 - 매진/예매대기/공연종료: 개별 비활성화
                 - 스케줄 선택 + 예매 분기
                 - 예매 흐름:
                     로그인 X → 로그인 유도 모달 → /loginForm.do?returnUrl=...
                     로그인 O + 스케줄 선택 → /seat/select.do?scheduleId=...
                     로그인 O + 스케줄 미선택 → 토스트 메시지
    ============================================================
--%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c"   uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn"  uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
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
    .header h1 { font-size: 20px; font-weight: 800; cursor: pointer; letter-spacing:-0.5px; margin-left: 8px; }
    .session-info { font-size: 13px; color: rgba(255,255,255,0.92); display: flex; align-items: center; gap: 6px; }
    .session-info b { font-weight: 700; }

    /* ===== Container ===== */
    .container { max-width: 1200px; margin: 40px auto 60px; padding: 0 24px; }

    /* ===== Detail Card ===== */
    .detail-card {
        background: #fff; border-radius: 20px; overflow: hidden;
        box-shadow: 0 8px 30px rgba(0,0,0,0.08);
        display: grid; grid-template-columns: 1fr 1fr; gap: 0;
        margin-bottom: 28px;
    }
    .detail-thumb {
        height: 580px;
        background: linear-gradient(135deg, #e5e7eb, #cbd5e1);
        background-size: cover; background-position: center;
        position: relative;
    }
    .thumb-placeholder { height: 100%; display: flex; align-items: center; justify-content: center; color: #94a3b8; font-size: 22px; }
    .status-badge-lg {
        position: absolute; top: 20px; right: 20px;
        padding: 8px 18px; border-radius: 24px;
        font-size: 13px; font-weight: 700; color: #fff;
        backdrop-filter: blur(8px);
    }
    .status-UPCOMING { background: rgba(245,158,11,0.95); }
    .status-ONGOING  { background: rgba(34,197,94,0.95); }
    .status-CLOSED   { background: rgba(107,114,128,0.95); }

    .detail-info { padding: 44px; display: flex; flex-direction: column; }
    .detail-artist {
        color: #6a11cb; font-size: 13px; font-weight: 700;
        letter-spacing: 1.5px; text-transform: uppercase; margin-bottom: 10px;
    }
    .detail-title {
        font-size: 28px; font-weight: 800; color: #1a1a1a;
        margin-bottom: 24px; line-height: 1.25; letter-spacing: -1px;
    }
    .info-table { border-top: 1.5px solid #e5e7eb; border-bottom: 1.5px solid #e5e7eb; padding: 20px 0; margin-bottom: 24px; }
    .info-row { display: flex; padding: 7px 0; font-size: 14px; }
    .info-label { width: 110px; color: #9ca3af; font-weight: 500; }
    .info-value { flex: 1; color: #1a1a1a; font-weight: 600; }
    .detail-desc-title {
        font-size: 15px; font-weight: 800; color: #1a1a1a;
        margin-bottom: 12px; padding-bottom: 8px;
        border-bottom: 2.5px solid #6a11cb; display: inline-block;
    }
    .detail-desc {
        font-size: 14px; color: #4b5563; line-height: 1.8;
        white-space: pre-wrap; flex: 1;
    }

    /* ===== Schedule Section ===== */
    .schedule-section {
        background: #fff; border-radius: 20px; padding: 36px;
        box-shadow: 0 8px 30px rgba(0,0,0,0.08);
    }
    .schedule-section-head {
        display: flex; justify-content: space-between; align-items: center;
        margin-bottom: 24px; padding-bottom: 16px;
        border-bottom: 1.5px solid #f3f4f6;
    }
    .schedule-title { font-size: 20px; font-weight: 800; color: #1a1a1a; letter-spacing: -0.5px; }
    .schedule-title-sub {
        font-size: 12px; color: #6a11cb; font-weight: 700;
        letter-spacing: 1px; text-transform: uppercase; margin-bottom: 4px;
    }
    .schedule-count { font-size: 13px; color: #6b7280; }
    .schedule-count strong { color: #6a11cb; font-weight: 700; }

    /* ===== Closed Concert Banner ===== */
    .closed-banner {
        background: linear-gradient(135deg, #f3f4f6 0%, #e5e7eb 100%);
        border: 2px dashed #9ca3af; border-radius: 14px;
        padding: 20px 24px; margin-bottom: 20px;
        display: flex; align-items: center; gap: 16px;
    }
    .closed-banner-icon {
        width: 48px; height: 48px;
        background: #6b7280; border-radius: 50%;
        display: flex; align-items: center; justify-content: center;
        font-size: 22px; color: #fff;
        flex-shrink: 0;
    }
    .closed-banner-text { flex: 1; }
    .closed-banner-title {
        font-size: 15px; font-weight: 800; color: #374151; margin-bottom: 4px;
    }
    .closed-banner-desc {
        font-size: 13px; color: #6b7280;
    }

    .schedule-list {
        display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
        gap: 14px; margin-bottom: 28px;
    }
    .schedule-card {
        border: 2px solid #e5e7eb; border-radius: 14px;
        padding: 20px; cursor: pointer;
        transition: all .15s; position: relative;
        background: #fff;
    }
    .schedule-card:hover { border-color: #c4b5fd; background: #faf5ff; }
    .schedule-card.selected {
        border-color: #6a11cb;
        background: linear-gradient(135deg, #faf5ff 0%, #f3e8ff 100%);
        box-shadow: 0 6px 16px rgba(106,17,203,0.15);
    }
    .schedule-card.disabled {
        opacity: 0.55; cursor: not-allowed; background: #f9fafb;
    }
    .schedule-card.disabled:hover { border-color: #e5e7eb; background: #f9fafb; }

    .schedule-card-radio {
        position: absolute; top: 18px; right: 18px;
        width: 22px; height: 22px;
        border: 2px solid #d1d5db; border-radius: 50%;
        transition: all .15s;
    }
    .schedule-card.selected .schedule-card-radio {
        border-color: #6a11cb; background: #6a11cb;
        box-shadow: inset 0 0 0 4px #fff;
    }

    .schedule-date-line { display: flex; align-items: baseline; gap: 8px; margin-bottom: 6px; }
    .schedule-date { font-size: 18px; font-weight: 800; color: #1a1a1a; letter-spacing: -0.3px; }
    .schedule-weekday { font-size: 14px; font-weight: 700; color: #6a11cb; }
    .schedule-weekday.weekend { color: #ef4444; }
    .schedule-time { font-size: 14px; color: #4b5563; font-weight: 600; margin-bottom: 14px; }

    .schedule-meta { display: flex; flex-direction: column; gap: 6px; font-size: 12px; }
    .schedule-meta-row {
        display: flex; justify-content: space-between; align-items: center;
        color: #6b7280;
    }
    .schedule-meta-row b { color: #1a1a1a; font-weight: 700; }
    .seat-progress-bar {
        width: 100%; height: 6px; background: #f3f4f6;
        border-radius: 3px; overflow: hidden; margin-top: 6px;
    }
    .seat-progress-fill {
        height: 100%;
        background: linear-gradient(90deg, #6a11cb, #2575fc);
        border-radius: 3px;
        transition: width .3s;
    }
    .seat-progress-fill.warn { background: linear-gradient(90deg, #f59e0b, #ef4444); }
    .seat-progress-fill.full { background: #9ca3af; }

    /* Badge variants */
    .badge {
        position: absolute; top: 14px; left: 14px;
        padding: 4px 10px; border-radius: 6px;
        font-size: 11px; font-weight: 800; color: #fff;
        letter-spacing: 0.5px;
    }
    .badge-soldout { background: #ef4444; }
    .badge-waiting { background: #f59e0b; }
    .badge-ended   { background: #6b7280; }
    .badge-closed  { background: #374151; }

    /* ===== Booking Bar ===== */
    .booking-bar {
        display: flex; justify-content: space-between; align-items: center;
        padding: 20px 24px;
        background: linear-gradient(135deg, #f9fafb 0%, #f3f4f6 100%);
        border-radius: 14px;
    }
    .booking-selected-info { font-size: 14px; color: #4b5563; }
    .booking-selected-info strong { color: #6a11cb; font-weight: 700; }
    .booking-selected-info .placeholder { color: #9ca3af; }
    .booking-selected-info .ended { color: #6b7280; }

    .booking-actions { display: flex; gap: 10px; }
    .btn-primary {
        padding: 16px 36px;
        background: linear-gradient(135deg, #6a11cb 0%, #2575fc 100%);
        color: #fff; border: none; border-radius: 12px;
        font-size: 15px; font-weight: 700; cursor: pointer;
        transition: transform .15s, box-shadow .15s, opacity .15s;
    }
    .btn-primary:hover:not(:disabled) {
        transform: translateY(-2px);
        box-shadow: 0 10px 24px rgba(106,17,203,0.4);
    }
    .btn-primary:disabled { background: #d1d5db; cursor: not-allowed; opacity: 0.7; }
    .btn-secondary {
        padding: 16px 24px; background: #fff; color: #4b5563;
        border: 1.5px solid #e5e7eb; border-radius: 12px;
        font-size: 15px; font-weight: 600; cursor: pointer;
        transition: border-color .15s, color .15s;
    }
    .btn-secondary:hover { border-color: #6a11cb; color: #6a11cb; }

    .schedule-empty { text-align: center; padding: 60px 20px; color: #9ca3af; }
    .schedule-empty-icon { font-size: 48px; margin-bottom: 12px; }

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

    /* ===== Login Modal ===== */
    .modal-backdrop {
        display: none;
        position: fixed; top: 0; left: 0; right: 0; bottom: 0;
        background: rgba(0,0,0,0.55); backdrop-filter: blur(4px);
        z-index: 1000;
        align-items: center; justify-content: center; padding: 20px;
        animation: fadeIn .2s ease;
    }
    .modal-backdrop.show { display: flex; }
    @keyframes fadeIn  { from{opacity:0;} to{opacity:1;} }
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
        padding: 32px 20px 20px; text-align: center;
    }
    .modal-icon {
        width: 64px; height: 64px; background: rgba(255,255,255,0.25);
        border-radius: 50%;
        display: inline-flex; align-items: center; justify-content: center;
        font-size: 32px;
    }
    .modal-body { padding: 28px 28px 12px; text-align: center; }
    .modal-title { font-size: 19px; font-weight: 800; color: #1a1a1a; margin-bottom: 10px; }
    .modal-desc  { font-size: 14px; color: #6b7280; line-height: 1.6; }
    .modal-actions { display: flex; gap: 8px; padding: 20px 28px 28px; }
    .modal-btn {
        flex: 1; padding: 14px; border-radius: 10px;
        font-size: 14px; font-weight: 700; cursor: pointer; border: none;
        transition: transform .12s, box-shadow .12s, border-color .15s;
    }
    .modal-btn-cancel { background: #fff; color: #6b7280; border: 1.5px solid #e5e7eb; }
    .modal-btn-cancel:hover { border-color: #9ca3af; color: #4b5563; }
    .modal-btn-ok { background: linear-gradient(135deg, #6a11cb 0%, #2575fc 100%); color: #fff; }
    .modal-btn-ok:hover { transform: translateY(-1px); box-shadow: 0 6px 16px rgba(106,17,203,0.4); }

    /* ===== Toast ===== */
    .toast {
        position: fixed; bottom: 40px; left: 50%; transform: translateX(-50%) translateY(100px);
        padding: 14px 26px; background: #1f2937; color: #fff;
        border-radius: 12px; font-size: 14px; font-weight: 600;
        box-shadow: 0 12px 32px rgba(0,0,0,0.25);
        z-index: 2000; opacity: 0;
        transition: transform .25s, opacity .25s;
    }
    .toast.show { transform: translateX(-50%) translateY(0); opacity: 1; }

    @media (max-width: 900px) {
        .detail-card { grid-template-columns: 1fr; }
        .detail-thumb { height: 360px; }
        .detail-info  { padding: 26px 22px; }
        .detail-title { font-size: 22px; }
        .schedule-section { padding: 22px; }
        .schedule-list { grid-template-columns: 1fr; }
        .booking-bar { flex-direction: column; gap: 16px; align-items: stretch; }
        .booking-actions { flex-direction: column-reverse; }
        .btn-primary, .btn-secondary { width: 100%; padding: 14px; }
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
                    <span class="session-info">👤 <b><c:out value="${sessionScope.SESSION_NAME}"/></b>님</span>
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

        <%-- 공연 종료 여부 판정 (모든 스케줄 비활성 트리거) --%>
        <c:set var="concertClosed" value="${concert.status == 'CLOSED'}"/>

        <!-- ===== Detail Card ===== -->
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
            </div>
        </div>

        <!-- ===== Schedule Section ===== -->
        <div class="schedule-section">
            <div class="schedule-section-head">
                <div>
                    <div class="schedule-title-sub">SELECT YOUR DATE</div>
                    <div class="schedule-title">📅 관람 일자 선택</div>
                </div>
                <div class="schedule-count">
                    총 <strong><c:out value="${fn:length(scheduleList)}"/></strong>개 회차
                </div>
            </div>

            <%-- ★ 공연이 CLOSED 상태면 안내 배너 표시 --%>
            <c:if test="${concertClosed}">
                <div class="closed-banner">
                    <div class="closed-banner-icon">🚫</div>
                    <div class="closed-banner-text">
                        <div class="closed-banner-title">예매가 종료된 공연입니다</div>
                        <div class="closed-banner-desc">
                            본 공연은 모든 회차가 종료되어 예매가 불가능합니다.
                            다른 공연을 둘러보시려면 목록으로 돌아가주세요.
                        </div>
                    </div>
                </div>
            </c:if>

            <c:choose>
                <c:when test="${empty scheduleList}">
                    <div class="schedule-empty">
                        <div class="schedule-empty-icon">📭</div>
                        <h3>등록된 공연 일정이 없습니다</h3>
                        <p>잠시 후 다시 확인해주세요.</p>
                    </div>
                </c:when>
                <c:otherwise>
                    <div class="schedule-list" id="scheduleList">
                        <c:forEach var="s" items="${scheduleList}">
                            <%-- ============================================ --%>
                            <%-- 스케줄 비활성 조건 (4가지 OR)                  --%>
                            <%--   1. 공연 자체가 CLOSED                       --%>
                            <%--   2. 매진 (availableSeats == 0)                --%>
                            <%--   3. 예매오픈 전 (bookingOpenable == 0)        --%>
                            <%--   4. 공연일자 지남 (performanceEnded == 1)    --%>
                            <%-- ============================================ --%>
                            <c:set var="isSoldout"  value="${s.availableSeats == 0}"/>
                            <c:set var="isWaiting"  value="${s.bookingOpenable == 0}"/>
                            <c:set var="isEnded"    value="${s.performanceEnded == 1}"/>
                            <c:set var="isDisabled" value="${concertClosed or isSoldout or isWaiting or isEnded}"/>
                            <c:set var="seatRate"   value="${(s.totalSeats - s.availableSeats) * 100 / s.totalSeats}"/>

                            <div class="schedule-card <c:if test='${isDisabled}'>disabled</c:if>"
                                 data-schedule-id="${s.scheduleId}"
                                 data-disabled="${isDisabled}"
                                 data-date="${s.performanceDate}"
                                 onclick="selectSchedule(this)">

                                <%-- 비활성 사유 뱃지 (우선순위 순) --%>
                                <c:choose>
                                    <c:when test="${concertClosed}">
                                        <div class="badge badge-closed">예매종료</div>
                                    </c:when>
                                    <c:when test="${isEnded}">
                                        <div class="badge badge-ended">공연종료</div>
                                    </c:when>
                                    <c:when test="${isSoldout}">
                                        <div class="badge badge-soldout">매진</div>
                                    </c:when>
                                    <c:when test="${isWaiting}">
                                        <div class="badge badge-waiting">예매대기</div>
                                    </c:when>
                                </c:choose>

                                <div class="schedule-card-radio"></div>

                                <div class="schedule-date-line">
                                    <div class="schedule-date">
                                        <c:out value="${fn:substring(s.performanceDate, 5, 10)}"/>
                                    </div>
                                    <div class="schedule-weekday <c:if test='${s.weekday == "토" or s.weekday == "일"}'>weekend</c:if>">
                                        (<c:out value="${s.weekday}"/>)
                                    </div>
                                </div>
                                <div class="schedule-time">⏰ <c:out value="${s.performanceTime}"/></div>

                                <div class="schedule-meta">
                                    <div class="schedule-meta-row">
                                        <span>잔여좌석</span>
                                        <span>
                                            <b><fmt:formatNumber value="${s.availableSeats}" pattern="#,###"/></b>
                                            / <fmt:formatNumber value="${s.totalSeats}" pattern="#,###"/>
                                        </span>
                                    </div>
                                    <div class="seat-progress-bar">
                                        <c:choose>
                                            <c:when test="${isSoldout}">
                                                <div class="seat-progress-fill full" style="width:100%;"></div>
                                            </c:when>
                                            <c:when test="${seatRate >= 80}">
                                                <div class="seat-progress-fill warn" style="width:${seatRate}%;"></div>
                                            </c:when>
                                            <c:otherwise>
                                                <div class="seat-progress-fill" style="width:${seatRate}%;"></div>
                                            </c:otherwise>
                                        </c:choose>
                                    </div>
                                    <div class="schedule-meta-row" style="margin-top:6px;">
                                        <span>예매오픈</span>
                                        <span><c:out value="${s.bookingOpenAt}"/></span>
                                    </div>
                                </div>
                            </div>
                        </c:forEach>
                    </div>

                    <!-- ===== Booking Bar ===== -->
                    <div class="booking-bar">
                        <div class="booking-selected-info" id="selectedInfo">
                            <c:choose>
                                <c:when test="${concertClosed}">
                                    <span class="ended">⛔ 종료된 공연은 예매할 수 없습니다</span>
                                </c:when>
                                <c:otherwise>
                                    <span class="placeholder">📌 원하시는 관람 일자를 선택해주세요</span>
                                </c:otherwise>
                            </c:choose>
                        </div>
                        <div class="booking-actions">
                            <button class="btn-secondary" onclick="location.href='/concert/list.do'">목록</button>
                            <button class="btn-primary"
                                    id="btnBooking"
                                    <c:if test="${concertClosed}">disabled</c:if>
                                    disabled
                                    onclick="handleBooking()">
                                <c:choose>
                                    <c:when test="${concertClosed}">예매 종료</c:when>
                                    <c:otherwise>🎟️ 예매하기</c:otherwise>
                                </c:choose>
                            </button>
                        </div>
                    </div>
                </c:otherwise>
            </c:choose>
        </div>

    </c:otherwise>
</c:choose>

</div>

<!-- ===== Login Required Modal ===== -->
<div class="modal-backdrop" id="loginModal">
    <div class="modal-card">
        <div class="modal-icon-wrap"><div class="modal-icon">🔐</div></div>
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

<!-- ===== Toast ===== -->
<div class="toast" id="toast"></div>

<script>
    // ============================================================
    // 상태 변수
    // ============================================================
    var isLoggedIn = <c:choose>
                        <c:when test="${not empty sessionScope.SESSION_ID}">true</c:when>
                        <c:otherwise>false</c:otherwise>
                     </c:choose>;
    var isConcertClosed = <c:choose>
                            <c:when test="${concertClosed}">true</c:when>
                            <c:otherwise>false</c:otherwise>
                          </c:choose>;
    var concertId  = '<c:out value="${concert.concertId}"/>';
    var selectedScheduleId = null;
    var selectedDate       = null;

    // ============================================================
    // 스케줄 선택
    // ============================================================
    function selectSchedule(cardEl) {
        // 공연 자체가 종료된 경우 - 안내 메시지만 표시
        if (isConcertClosed) {
            showToast('종료된 공연은 예매할 수 없습니다');
            return;
        }
        // 비활성(매진/대기/공연종료) 카드는 선택 불가
        if (cardEl.getAttribute('data-disabled') === 'true') {
            showToast('이 회차는 선택할 수 없습니다');
            return;
        }

        document.querySelectorAll('.schedule-card').forEach(function(c){
            c.classList.remove('selected');
        });

        cardEl.classList.add('selected');
        selectedScheduleId = cardEl.getAttribute('data-schedule-id');
        selectedDate       = cardEl.getAttribute('data-date');

        document.getElementById('selectedInfo').innerHTML =
            '✅ 선택된 회차: <strong>' + selectedDate + '</strong>';

        document.getElementById('btnBooking').disabled = false;
    }

    // ============================================================
    // 예매 버튼 클릭
    // ============================================================
    function handleBooking() {
        if (isConcertClosed) {
            showToast('종료된 공연은 예매할 수 없습니다');
            return;
        }
        if (!selectedScheduleId) {
            showToast('관람 일자를 먼저 선택해주세요');
            return;
        }
        if (!isLoggedIn) {
            openLoginModal();
            return;
        }
        location.href = '/seat/select.do?scheduleId=' + selectedScheduleId;
    }

    // ============================================================
    // 로그인 모달
    // ============================================================
    function openLoginModal()  { document.getElementById('loginModal').classList.add('show'); }
    function closeLoginModal() { document.getElementById('loginModal').classList.remove('show'); }
    function goToLogin() {
        var returnUrl = encodeURIComponent('/concert/detail.do?concertId=' + concertId);
        location.href = '/loginForm.do?returnUrl=' + returnUrl;
    }
    document.getElementById('loginModal').addEventListener('click', function(e){
        if (e.target === this) closeLoginModal();
    });
    document.addEventListener('keydown', function(e){
        if (e.key === 'Escape') closeLoginModal();
    });

    // ============================================================
    // 토스트
    // ============================================================
    var toastTimer = null;
    function showToast(msg) {
        var t = document.getElementById('toast');
        t.textContent = msg;
        t.classList.add('show');
        if (toastTimer) clearTimeout(toastTimer);
        toastTimer = setTimeout(function(){ t.classList.remove('show'); }, 2500);
    }

    // ============================================================
    // 로그아웃
    // ============================================================
    function doLogout() {
        if (!confirm('로그아웃 하시겠습니까?')) return;
        fetch('/logout.do', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({})
        })
        .then(function(res){ return res.json(); })
        .then(function(data){ location.href = data.URL || '/'; })
        .catch(function(){ location.href = '/'; });
    }
</script>

</body>
</html>
