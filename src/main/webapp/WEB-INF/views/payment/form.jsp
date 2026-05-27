<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c"   uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>

<%--
============================================================
Project    : 관제 티켓 (Ticketing System)
FileName   : payment/form.jsp
Developer  : 이규왕 (feature/king)
Modified   : 2026.05.26

Description :
  - 결제 정보 확인 + 결제 수단 선택 화면
  - 진입: GET /payment/form.do?bookingId=N (BookingController 가 redirect)
  - 제출: POST /payment/result.do
  - 사이트 메인 컬러(#ff4f6b) 톤에 맞춤
============================================================
--%>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>결제하기 - GWANJE TICKET</title>

<link rel="stylesheet" href="${pageContext.request.contextPath}/css/bootstrap.min.css">

<style>
* { box-sizing: border-box; }
body {
    font-family: 'Malgun Gothic', 'Apple SD Gothic Neo', sans-serif;
    background: #f7f7f9;
    margin: 0;
    color: #222;
}

.pay-wrap {
    max-width: 720px;
    margin: 40px auto;
    padding: 0 20px;
}

.pay-header {
    border-bottom: 2px solid #ff4f6b;
    padding-bottom: 12px;
    margin-bottom: 24px;
}
.pay-header h2 {
    margin: 0;
    font-size: 24px;
    font-weight: 700;
    color: #222;
}
.pay-header .sub {
    color: #888;
    font-size: 14px;
    margin: 6px 0 0;
}

.pay-card {
    background: #fff;
    border: 1px solid #eee;
    border-radius: 10px;
    padding: 24px;
    margin-bottom: 16px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.04);
}
.pay-card h3 {
    margin: 0 0 16px;
    font-size: 17px;
    font-weight: 700;
    color: #333;
    padding-bottom: 10px;
    border-bottom: 1px solid #f0f0f0;
}

/* 예매 정보 */
.info-row {
    display: flex;
    padding: 10px 0;
    font-size: 14px;
    border-bottom: 1px dashed #f0f0f0;
}
.info-row:last-child { border-bottom: none; }
.info-row .label {
    width: 110px;
    color: #888;
    flex-shrink: 0;
}
.info-row .value {
    color: #222;
    flex: 1;
    font-weight: 500;
}
.info-row.price {
    margin-top: 8px;
    padding-top: 16px;
    border-top: 2px solid #f0f0f0;
    border-bottom: none;
    font-size: 15px;
}
.info-row.price .value {
    color: #ff4f6b;
    font-size: 22px;
    font-weight: 700;
}

/* 약관 */
.agree-row {
    display: flex;
    align-items: center;
    padding: 8px 0;
    font-size: 13px;
    color: #555;
}
.agree-row input[type=checkbox] {
    margin-right: 8px;
    transform: scale(1.1);
    accent-color: #ff4f6b;
}
.agree-row.all {
    font-weight: 700;
    font-size: 14px;
    color: #222;
    padding-bottom: 12px;
    border-bottom: 1px solid #f0f0f0;
    margin-bottom: 8px;
}

/* 버튼 */
.btn-area {
    display: flex;
    gap: 10px;
    margin-top: 24px;
}
.btn-back, .btn-pay {
    flex: 1;
    height: 54px;
    border: none;
    border-radius: 8px;
    font-size: 16px;
    font-weight: 700;
    cursor: pointer;
    transition: all 0.15s;
}
.btn-back {
    background: #fff;
    color: #555;
    border: 1.5px solid #ddd;
    flex: 0 0 140px;
}
.btn-back:hover { background: #f5f5f5; }
.btn-pay {
    background: #ff4f6b;
    color: #fff;
}
.btn-pay:hover { background: #e63e58; }
.btn-pay:disabled {
    background: #ddd;
    color: #888;
    cursor: not-allowed;
}

/* 안내 박스 */
.notice {
    background: #fff8f9;
    border-left: 3px solid #ff4f6b;
    padding: 12px 16px;
    font-size: 13px;
    color: #666;
    border-radius: 0 6px 6px 0;
    line-height: 1.6;
    margin-top: 16px;
}

/* 데이터 없는 경우 */
.empty-msg {
    background: #fff;
    border: 1px solid #eee;
    border-radius: 10px;
    padding: 60px 20px;
    text-align: center;
    color: #888;
}
.empty-msg .icon { font-size: 48px; margin-bottom: 16px; }
.empty-msg a {
    display: inline-block;
    margin-top: 16px;
    color: #ff4f6b;
    font-weight: 700;
}
</style>
</head>
<body>

<div class="pay-wrap">

    <div class="pay-header">
        <h2>결제하기</h2>
        <p class="sub">예매하신 공연 정보를 확인하고 결제를 진행해주세요</p>
    </div>

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
                    <button type="button" class="btn-back"
                            onclick="if(confirm('결제를 취소하고 이전 화면으로 돌아가시겠습니까?')) history.back();">
                        취소
                    </button>
                    <button type="submit" class="btn-pay" id="btnPay" disabled>
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
    });
})();
</script>

</body>
</html>
