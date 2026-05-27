<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c"   uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>

<%--
============================================================
Project    : 관제 티켓 (Ticketing System)
FileName   : payment/result.jsp
Developer  : 이규왕 (feature/king)
Modified   : 2026.05.26

Description :
  - 결제 결과 화면 (SUCCESS / FAILED 분기)
  - 진입: POST /payment/result.do 처리 후 forward
  - 모델 속성: status, transactionId, bookingId, amount
  - 보안: payments 테이블 컬럼값을 그대로 노출하지 않음
  - 표시 정보는 모두 payments 테이블 컬럼 기반 (payMethod 는 DB 없음 → 미표시)
============================================================
--%>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>결제 결과 - GWANJE TICKET</title>

<link rel="stylesheet" href="${pageContext.request.contextPath}/css/bootstrap.min.css">

<style>
* { box-sizing: border-box; }
body {
    font-family: 'Malgun Gothic', 'Apple SD Gothic Neo', sans-serif;
    background: #f7f7f9;
    margin: 0;
    color: #222;
}

.result-wrap {
    max-width: 560px;
    margin: 60px auto;
    padding: 0 20px;
}

.result-card {
    background: #fff;
    border-radius: 14px;
    padding: 48px 32px;
    text-align: center;
    box-shadow: 0 2px 12px rgba(0,0,0,0.06);
}

/* 상태 아이콘 */
.status-icon {
    width: 80px;
    height: 80px;
    border-radius: 50%;
    margin: 0 auto 20px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 42px;
    color: #fff;
}
.status-icon.success { background: #ff4f6b; }
.status-icon.fail    { background: #888; }

.status-title {
    font-size: 24px;
    font-weight: 700;
    margin: 0 0 8px;
    color: #222;
}
.status-sub {
    font-size: 14px;
    color: #888;
    margin: 0 0 32px;
}

/* 결과 정보 */
.detail-box {
    background: #fafafa;
    border-radius: 10px;
    padding: 20px 24px;
    text-align: left;
    margin-bottom: 24px;
}
.detail-row {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 10px 0;
    font-size: 14px;
    border-bottom: 1px dashed #eee;
}
.detail-row:last-child { border-bottom: none; }
.detail-row .label {
    color: #888;
}
.detail-row .value {
    color: #222;
    font-weight: 500;
    font-family: 'Courier New', monospace;
}
.detail-row.amount .value {
    font-family: 'Malgun Gothic', sans-serif;
    color: #ff4f6b;
    font-size: 18px;
    font-weight: 700;
}

.notice {
    background: #fff8f9;
    border-left: 3px solid #ff4f6b;
    padding: 10px 14px;
    font-size: 12px;
    color: #777;
    border-radius: 0 6px 6px 0;
    text-align: left;
    line-height: 1.6;
    margin-bottom: 24px;
}
.notice.fail {
    background: #f5f5f5;
    border-left-color: #888;
}

/* 버튼 */
.btn-area {
    display: flex;
    gap: 10px;
}
.btn-area a, .btn-area button {
    flex: 1;
    height: 50px;
    border: none;
    border-radius: 8px;
    font-size: 15px;
    font-weight: 700;
    cursor: pointer;
    text-decoration: none;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.15s;
}
.btn-secondary {
    background: #fff;
    color: #555;
    border: 1.5px solid #ddd;
}
.btn-secondary:hover { background: #f5f5f5; color: #333; }
.btn-primary {
    background: #ff4f6b;
    color: #fff;
}
.btn-primary:hover { background: #e63e58; color: #fff; }
</style>
</head>
<body>

<div class="result-wrap">

    <c:choose>
        <c:when test="${status eq 'SUCCESS'}">
            <!-- ====================== 결제 성공 ====================== -->
            <div class="result-card">
                <div class="status-icon success">✓</div>
                <h2 class="status-title">결제가 완료되었습니다</h2>
                <p class="status-sub">예매가 정상적으로 확정되었습니다</p>

                <div class="detail-box">
                    <div class="detail-row">
                        <span class="label">예매번호</span>
                        <span class="value">#${bookingId}</span>
                    </div>
                    <div class="detail-row">
                        <span class="label">거래번호</span>
                        <span class="value">${transactionId}</span>
                    </div>
                    <div class="detail-row amount">
                        <span class="label">결제금액</span>
                        <span class="value">
                            <fmt:formatNumber value="${amount}" pattern="#,###"/>원
                        </span>
                    </div>
                </div>

                <div class="notice">
                    ⓘ 본 결제는 테스트용 가짜 결제 시스템입니다.<br>
                    예매 내역은 마이페이지에서 확인하실 수 있습니다.
                </div>

                <div class="btn-area">
                    <a href="${pageContext.request.contextPath}/main.do" class="btn-secondary">메인으로</a>
                    <a href="${pageContext.request.contextPath}/my/bookingList.do" class="btn-primary">예매내역 보기</a>
                </div>
            </div>
        </c:when>

        <c:otherwise>
            <!-- ====================== 결제 실패 ====================== -->
            <div class="result-card">
                <div class="status-icon fail">✕</div>
                <h2 class="status-title">결제에 실패했습니다</h2>
                <p class="status-sub">
                    <c:choose>
                        <c:when test="${status eq 'FAILED'}">결제 승인이 거절되었습니다</c:when>
                        <c:otherwise>처리 중 오류가 발생했습니다</c:otherwise>
                    </c:choose>
                </p>

                <c:if test="${not empty transactionId}">
                    <div class="detail-box">
                        <div class="detail-row">
                            <span class="label">거래번호</span>
                            <span class="value">${transactionId}</span>
                        </div>
                        <c:if test="${not empty bookingId}">
                            <div class="detail-row">
                                <span class="label">예매번호</span>
                                <span class="value">#${bookingId}</span>
                            </div>
                        </c:if>
                    </div>
                </c:if>

                <div class="notice fail">
                    ⓘ 결제가 실패한 경우 예매는 자동 취소되며, 좌석은 다시 예매 가능 상태로 돌아갑니다.<br>
                    문제가 계속되면 고객센터로 문의해주세요.
                </div>

                <div class="btn-area">
                    <a href="${pageContext.request.contextPath}/main.do" class="btn-secondary">메인으로</a>
                    <a href="${pageContext.request.contextPath}/concert/list.do" class="btn-primary">공연 다시 보기</a>
                </div>
            </div>
        </c:otherwise>
    </c:choose>

</div>

</body>
</html>
