<%--
============================================================
 Project   : 관제 티켓 (Ticketing System)
 FileName  : bookingList.jsp

 Developer : 김태희 (feature/kth)
 Created   : 2026.05.24
 Modified  : 2026.05.28

 Description :
   - 예매 내역 목록
   - 검색 (email / name / concert) / 상태 필터 / 페이징

 History :
   2026.05.25 - 변조 탐지 관련 컬럼 / 필터 / 스타일 모두 제거
   2026.05.25 - URL 팀 규칙 적용 (/admin/xxx/list.do)
   2026.05.28 - 관리자 강제 취소 기능 추가
                · "관리" 컬럼 + 강제취소 버튼 (PENDING/CONFIRMED 만 노출)
                · POST /admin/booking/cancel.do (confirm 확인 후 전송)
                · flash 메시지(msg/msgType) 배너 표시
============================================================
--%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt"  prefix="fmt" %>
<!DOCTYPE html>
<html lang="ko">
<head>
	<meta charset="UTF-8">
	<title>예매 내역 | 관제 티켓</title>
	<style>
		* { margin: 0; padding: 0; box-sizing: border-box; }
		body { font-family: 'Segoe UI', 'Malgun Gothic', sans-serif; background: #f5f6fa; color: #2f3640; padding: 30px; }
		.wrap { max-width: 1300px; margin: 0 auto; }
		h1 { font-size: 24px; margin-bottom: 20px; }

		.nav { margin-bottom: 20px; }
		.nav a {
			display: inline-block; padding: 10px 18px; margin-right: 8px;
			background: #fff; color: #2f3640; text-decoration: none;
			border-radius: 6px; border: 1px solid #dcdde1; font-size: 14px;
		}
		.nav a:hover, .nav a.active { background: #487eb0; color: #fff; border-color: #487eb0; }

		.toolbar {
			background: #fff; padding: 15px 20px; border-radius: 8px;
			margin-bottom: 15px; display: flex; gap: 10px; align-items: center;
			flex-wrap: wrap; box-shadow: 0 1px 3px rgba(0,0,0,0.05);
		}
		.toolbar select, .toolbar input[type="text"] {
			padding: 8px 12px; border: 1px solid #dcdde1; border-radius: 4px;
			font-size: 14px;
		}
		.toolbar input[type="text"] { flex: 1; max-width: 300px; }
		.toolbar button {
			padding: 8px 18px; background: #487eb0; color: #fff;
			border: none; border-radius: 4px; cursor: pointer; font-size: 14px;
		}
		.toolbar button:hover { background: #40739e; }

		table {
			width: 100%; background: #fff; border-collapse: collapse;
			border-radius: 8px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.05);
		}
		th, td { padding: 12px 12px; text-align: left; border-bottom: 1px solid #f1f2f6; font-size: 13px; }
		th { background: #f5f6fa; font-weight: 600; color: #718093; font-size: 11px; text-transform: uppercase; }
		tbody tr:hover { background: #f5f6fa; }

		.status {
			display: inline-block; padding: 3px 10px; border-radius: 12px;
			font-size: 11px; font-weight: 600;
		}
		.status.PENDING   { background: #fff3cd; color: #ff9f1a; }
		.status.CONFIRMED { background: #c8e6c9; color: #2d7a2d; }
		.status.CANCELLED { background: #f5f6fa; color: #718093; }

		.price { text-align: right; font-family: 'Consolas', monospace; }

		.info { margin: 15px 0; color: #718093; font-size: 14px; }
		.empty { padding: 40px; text-align: center; color: #718093; }

		.flash { padding: 12px 18px; border-radius: 6px; margin-bottom: 15px; font-size: 14px; }
		.flash.success { background: #c8e6c9; color: #2d7a2d; }
		.flash.info    { background: #d6eaf8; color: #2471a3; }
		.flash.error   { background: #f8d7da; color: #c0392b; }

		.btn-cancel {
			padding: 5px 12px; background: #e84118; color: #fff;
			border: none; border-radius: 4px; cursor: pointer; font-size: 12px;
		}
		.btn-cancel:hover { background: #c23616; }
		.btn-disabled {
			padding: 5px 12px; background: #dcdde1; color: #888;
			border: none; border-radius: 4px; font-size: 12px; cursor: not-allowed;
		}
	</style>
</head>
<body>
<div class="wrap">
	<a href="/main.do" style="text-decoration: none; color: inherit;">
	    <h1>🎫 관제 티켓 관리자</h1>
	</a>
	<h1>📋 예매 내역</h1>

	<div class="nav">
		<a href="/admin/main.do">대시보드</a>
		<a href="/admin/concert/list.do">공연 관리</a>
		<a href="/admin/member/list.do">회원 관리</a>
		<a href="/admin/booking/list.do" class="active">예매 내역</a>
	</div>

	<form method="get" action="/admin/booking/list.do">
		<div class="toolbar">
			<select name="status">
				<option value=""           <c:if test="${empty status}">selected</c:if>>전체 상태</option>
				<option value="PENDING"    <c:if test="${status eq 'PENDING'}">selected</c:if>>PENDING</option>
				<option value="CONFIRMED"  <c:if test="${status eq 'CONFIRMED'}">selected</c:if>>CONFIRMED</option>
				<option value="CANCELLED"  <c:if test="${status eq 'CANCELLED'}">selected</c:if>>CANCELLED</option>
			</select>
			<select name="searchType">
				<option value=""        <c:if test="${empty searchType}">selected</c:if>>전체</option>
				<option value="email"   <c:if test="${searchType eq 'email'}">selected</c:if>>이메일</option>
				<option value="name"    <c:if test="${searchType eq 'name'}">selected</c:if>>회원명</option>
				<option value="concert" <c:if test="${searchType eq 'concert'}">selected</c:if>>공연명</option>
			</select>
			<input type="text" name="keyword" placeholder="검색어 입력"
				value="<c:out value='${keyword}' />" />
			<button type="submit">🔍 검색</button>
		</div>
	</form>

	<c:if test="${not empty msg}">
		<div class="flash ${empty msgType ? 'info' : msgType}"><c:out value="${msg}" /></div>
	</c:if>

	<div class="info">총 <strong>${TOTAL}</strong>건</div>

	<table>
		<thead>
			<tr>
				<th style="width:60px;">ID</th>
				<th style="width:150px;">회원</th>
				<th>공연</th>
				<th style="width:130px;">아티스트</th>
				<th style="width:150px;">공연일시</th>
				<th style="width:120px;" class="price">예매금액</th>
				<th style="width:110px;">예매상태</th>
				<th style="width:160px;">예매일시</th>
				<th style="width:90px;">관리</th>
			</tr>
		</thead>
		<tbody>
			<c:choose>
				<c:when test="${empty bookingList}">
					<tr><td colspan="9" class="empty">조회된 예매가 없습니다.</td></tr>
				</c:when>
				<c:otherwise>
					<c:forEach var="row" items="${bookingList}">
						<tr>
							<td>${row.BOOKING_ID}</td>
							<td>
								<div><c:out value="${row.MEMBER_NAME}" /></div>
								<div style="font-size:11px;color:#718093;">
									<c:out value="${row.EMAIL}" />
								</div>
							</td>
							<td><c:out value="${row.CONCERT_TITLE}" /></td>
							<td><c:out value="${row.ARTIST}" /></td>
							<td>${row.PERFORMANCE_DATE}</td>
							<td class="price">
								<fmt:formatNumber value="${row.TOTAL_PRICE}" pattern="#,###" /> 원
							</td>
							<td><span class="status ${row.BOOKING_STATUS}">${row.BOOKING_STATUS}</span></td>
							<td>${row.CREATED_AT}</td>
							<td>
								<c:choose>
									<c:when test="${row.BOOKING_STATUS eq 'CANCELLED'}">
										<button type="button" class="btn-disabled" disabled>취소됨</button>
									</c:when>
									<c:otherwise>
										<form method="post" action="/admin/booking/cancel.do"
											onsubmit="return confirm('예매 [${row.BOOKING_ID}] 를 강제 취소하시겠습니까?\n좌석이 예매 가능 상태로 풀리고, 결제는 자동 환불됩니다.');"
											style="margin:0;">
											<input type="hidden" name="bookingId" value="${row.BOOKING_ID}" />
											<button type="submit" class="btn-cancel">강제취소</button>
										</form>
									</c:otherwise>
								</c:choose>
							</td>
						</tr>
					</c:forEach>
				</c:otherwise>
			</c:choose>
		</tbody>
	</table>

</div>
</body>
</html>
