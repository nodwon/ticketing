<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c"   uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>

<%--
============================================================
Project    : 관제 티켓 (Ticketing System)
FileName   : payment/form.jsp
Developer  : 이규왕 (feature/king)
Modified   : 2026.05.28 (UI 공통 테마 통일 - theme.css 적용)

Description :
  - 결제 정보 확인 + 결제 수단 선택 화면
  - 진입: GET /payment/form.do?bookingId=N (BookingController 가 redirect)
  - 제출: POST /payment/result.do
  - 사이트 메인 컬러(#e8001c) 톤으로 통일
============================================================
--%>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>결제하기 | GWANJE TICKET</title>

<link rel="stylesheet" href="${pageContext.request.contextPath}/css/theme.css">

<style>
body { background: var(--gray); }

.pay-wrap { max-width: 760px; margin: 0 auto 60px; padding: 0 20px; }

.pay-card {
    background: var(--white);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    padding: 24px 26px;
    margin-bottom: 16px;
    box-shadow: var(--shadow);
}
.pay-card h3 {
    margin: 0 0 18px;
    font-size: 17px; font-weight: 700; color: var(--dark);
    padding-bottom: 12px; border-bottom: 2px solid var(--gray);
}

/* 예매 정보 */
.info-row {
    display: flex; padding: 11px 0; font-size: 14px;
    border-bottom: 1px solid var(--gray);
}
.info-row:last-child { border-bottom: none; }
.info-row .label { width: 110px; color: var(--muted); flex-shrink: 0; }
.info-row .value { color: var(--text); flex: 1; font-weight: 500; }
.info-row.price {
    margin-top: 8px; padding-top: 16px;
    border-top: 2px solid var(--border); border-bottom: none; font-size: 15px;
}
.info-row.price .value { color: var(--red); font-size: 22px; font-weight: 800; }

/* 약관 */
.agree-row { display: flex; align-items: center; padding: 9px 0; font-size: 13px; color: #555; }
.agree-row input[type=checkbox] { margin-right: 8px; transform: scale(1.1); accent-color: var(--red); }
.agree-row.all {
    font-weight: 700; font-size: 14px; color: var(--text);
    padding-bottom: 12px; border-bottom: 1px solid var(--gray); margin-bottom: 8px;
}

/* 버튼 영역 */
.btn-area { display: flex; gap: 10px; margin-top: 24px; }
.btn-area .tk-btn { height: 54px; font-size: 16px; }
.btn-area .btn-back { flex: 0 0 140px; }
.btn-area .btn-pay { flex: 1; }

/* 안내 박스 */
.notice {
    background: #fde8ea;
    border-left: 3px solid var(--red);
    padding: 13px 16px; font-size: 13px; color: #7a2230;
    border-radius: 0 var(--radius) var(--radius) 0;
    line-height: 1.6; margin-top: 16px;
}

/* 데이터 없는 경우 */
.empty-msg {
    background: var(--white);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    padding: 60px 20px; text-align: center; color: var(--muted);
}
.empty-msg .icon { font-size: 48px; margin-bottom: 16px; }
.empty-msg a { display: inline-block; margin-top: 16px; color: var(--red); font-weight: 700; }
</style>
</head>
<body>

<!-- 페이지 헤더 (공통 톤) -->
<div class="tk-page-head">
    <div class="tk-page-head-inner">
        <div class="brand">PAYMENT</div>
        <h1>결제하기</h1>
        <p>예매하신 공연 정보를 확인하고 결제를 진행해주세요.</p>
        <div class="tk-steps">
            <span class="tk-step"><span class="num">1</span>공연 선택</span>
            <span class="tk-step-sep">›</span>
            <span class="tk-step"><span class="num">2</span>좌석 선택</span>
            <span class="tk-step-sep">›</span>
            <span class="tk-step active"><span class="num">3</span>결제</span>
            <span class="tk-step-sep">›</span>
            <span class="tk-step"><span class="num">4</span>완료</span>
        </div>
    </div>
</div>

<div class="pay-wrap" style="margin-top:24px;">

    <c:choose>
        <c:when test="${empty booking}">
            <div class="empty-msg">
                <div class="icon">⚠️</div>
                <p>예매 정보를 찾을 수 없습니다.</p>
                <p style="font-size:13px; color:#aaa;">예매 번호: ${bookingId}</p>
                <a href="${pageContext.request.contextPath}/main.do">메인으로 돌아가기</a>
            </div>
        </c:when>
        <c:otherwise>

            <!-- 예매 정보 카드 -->
            <div class="pay-card">
                <h3>예매 정보</h3>
                <div class="info-row">
                    <div class="label">예매번호</div>
                    <div class="value">#${bookingId}</div>
                </div>
                <div class="info-row">
                    <div class="label">공연명</div>
                    <div class="value">${booking.CONCERTTITLE}</div>
                </div>
                <div class="info-row">
                    <div class="label">아티스트</div>
                    <div class="value">${booking.ARTIST}</div>
                </div>
                <div class="info-row">
                    <div class="label">공연장</div>
                    <div class="value">${booking.VENUE}</div>
                </div>
                <div class="info-row">
                    <div class="label">관람일시</div>
                    <div class="value">${booking.PERFORMANCEDATE}</div>
                </div>
                <div class="info-row price">
                    <div class="label">최종 결제금액</div>
                    <div class="value">
                        <fmt:formatNumber value="${booking.TOTALPRICE}" pattern="#,###"/>원
                    </div>
                </div>
            </div>

            <!-- 결제 폼 -->
            <form id="payForm" action="${pageContext.request.contextPath}/payment/result.do" method="post">
                <input type="hidden" name="bookingId" value="${bookingId}">
                <input type="hidden" name="amount"    value="${booking.TOTALPRICE}">
                <input type="hidden" name="memberId"  value="${booking.MEMBERID}">

                <!-- 약관 동의 -->
                <div class="pay-card">
                    <h3>결제 약관 동의</h3>
                    <div class="agree-row all">
                        <input type="checkbox" id="agree-all">
                        <label for="agree-all" style="cursor:pointer; margin:0;">전체 동의</label>
                    </div>
                    <div class="agree-row">
                        <input type="checkbox" class="agree" id="a1">
                        <label for="a1" style="cursor:pointer; margin:0;">[필수] 결제 진행 및 환불 정책에 동의합니다.</label>
                    </div>
                    <div class="agree-row">
                        <input type="checkbox" class="agree" id="a2">
                        <label for="a2" style="cursor:pointer; margin:0;">[필수] 개인정보 제3자 제공(결제대행사)에 동의합니다.</label>
                    </div>
                    <div class="agree-row">
                        <input type="checkbox" class="agree" id="a3">
                        <label for="a3" style="cursor:pointer; margin:0;">[필수] 만 14세 이상이며 결제 정보 입력에 동의합니다.</label>
                    </div>
                </div>

                <!-- 안내 -->
                <div class="notice">
                    ⓘ 본 결제는 테스트용 가짜 결제 시스템입니다. 실제 금액이 청구되지 않습니다.<br>
                    결제 완료 후 예매 상태가 자동으로 확정 처리됩니다.
                </div>

                <!-- 버튼 -->
                <div class="btn-area">
                    <button type="button" class="tk-btn tk-btn-ghost btn-back"
                            onclick="if(confirm('결제를 취소하고 이전 화면으로 돌아가시겠습니까?')) history.back();">
                        취소
                    </button>
                    <button type="submit" class="tk-btn tk-btn-primary btn-pay" id="btnPay" disabled>
                        <fmt:formatNumber value="${booking.TOTALPRICE}" pattern="#,###"/>원 결제하기
                    </button>
                </div>
            </form>

        </c:otherwise>
    </c:choose>

</div>

<script>
(function(){
    var checkboxes = document.querySelectorAll('.agree');
    var allBox     = document.getElementById('agree-all');
    var btnPay     = document.getElementById('btnPay');
    var form       = document.getElementById('payForm');

    if (!form) return;

    function updateBtn() {
        var allChecked = true;
        checkboxes.forEach(function(cb){ if (!cb.checked) allChecked = false; });
        btnPay.disabled = !allChecked;
    }

    if (allBox) {
        allBox.addEventListener('change', function(){
            checkboxes.forEach(function(cb){ cb.checked = allBox.checked; });
            updateBtn();
        });
    }

    checkboxes.forEach(function(cb){
        cb.addEventListener('change', function(){
            var allChecked = true;
            checkboxes.forEach(function(c){ if (!c.checked) allChecked = false; });
            if (allBox) allBox.checked = allChecked;
            updateBtn();
        });
    });

    form.addEventListener('submit', function(e){
        if (btnPay.disabled) { e.preventDefault(); return; }
        if (!confirm('결제를 진행하시겠습니까?')) {
            e.preventDefault();
            return;
        }
        btnPay.disabled = true;
        btnPay.textContent = '결제 처리 중...';

        // [중요] 결제 진행 중에는 unload 가 발생해도 abandon 보내지 않음
        //         (결제 결과 페이지로의 정상 전환을 강제종료로 오인 방지)
        window.__paymentInProgress = true;
    });
})();


// ============================================================
//  PENDING lifecycle 신호 (heartbeat + beacon)
//  서버: /booking/heartbeat.do, /booking/abandon.do
//  목적: 사용자가 결제 페이지를 닫거나 강제 종료하면
//        PENDING 예매를 즉시(또는 60초 이내) 자동 취소.
// ============================================================
(function(){
    var bookingId = '${bookingId}';
    if (!bookingId) return;

    // 1) Heartbeat - 30초마다
    function sendHeartbeat() {
        try {
            var xhr = new XMLHttpRequest();
            xhr.open('POST', '/booking/heartbeat.do', true);
            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
            xhr.send('bookingId=' + encodeURIComponent(bookingId));
        } catch (e) { /* 무시 */ }
    }
    sendHeartbeat();
    var heartbeatTimer = setInterval(sendHeartbeat, 30000);

    // 2) Beacon - 페이지가 닫히는 순간 정리 신호
    //    pagehide 가 unload 보다 모바일 사파리 호환성 좋음
    function sendAbandonBeacon() {
        if (window.__paymentInProgress) return;  // 정상 결제 진행 중이면 보내지 않음
        try {
            var data = new Blob(
                ['bookingId=' + encodeURIComponent(bookingId)],
                { type: 'application/x-www-form-urlencoded' }
            );
            // sendBeacon 은 페이지가 닫혀도 전송 보장
            if (navigator.sendBeacon) {
                navigator.sendBeacon('/booking/abandon.do', data);
            } else {
                // 폴백: 동기 XHR (구형 브라우저)
                var xhr = new XMLHttpRequest();
                xhr.open('POST', '/booking/abandon.do', false);
                xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
                xhr.send('bookingId=' + encodeURIComponent(bookingId));
            }
        } catch (e) { /* 무시 */ }
        clearInterval(heartbeatTimer);
    }
    window.addEventListener('pagehide', sendAbandonBeacon);
    window.addEventListener('beforeunload', sendAbandonBeacon);
})();
</script>

</body>
</html>
