<%--
============================================================
 Project   : 관제 티켓 (Ticketing System)
 FileName  : concertList.jsp

 Developer : 김태희 (feature/kth)
 Created   : 2026.05.24
 Modified  : 2026.05.25

 Description :
   - 공연 목록 / 검색 (title, artist) / 페이징
   - 등록 / 수정 / 삭제 진입점
   - 등록/수정/삭제 후 Flash Message 배너 표시

 History :
   2026.05.25 - URL 팀 규칙 적용 (/admin/concert/xxx.do)
   2026.05.25 - Flash Message 배너 UI 추가 (success / info / error)
   2026.05.25 - 스마트 삭제 confirm 메시지 개선
                (예매 있으면 비활성, 없으면 완전 삭제됨을 미리 안내)
============================================================
--%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="ko">
<head>
	<meta charset="UTF-8">
	<title>공연 관리 | 관제 티켓</title>
	<style>
		* { margin: 0; padding: 0; box-sizing: border-box; }
		body { font-family: 'Segoe UI', 'Malgun Gothic', sans-serif; background: #f5f6fa; color: #2f3640; padding: 30px; }
		.wrap { max-width: 1200px; margin: 0 auto; }
		h1 { font-size: 24px; margin-bottom: 20px; }

		.nav { margin-bottom: 20px; }
		.nav a {
			display: inline-block; padding: 10px 18px; margin-right: 8px;
			background: #fff; color: #2f3640; text-decoration: none;
			border-radius: 6px; border: 1px solid #dcdde1; font-size: 14px;
		}
		.nav a:hover, .nav a.active { background: #487eb0; color: #fff; border-color: #487eb0; }

		/* Flash Message 배너 */
		.flash {
			padding: 14px 20px; border-radius: 6px; margin-bottom: 15px;
			font-size: 14px; display: flex; align-items: center;
			border-left: 4px solid;
		}
		.flash.success { background: #e8f5e9; color: #2d7a2d; border-color: #44bd32; }
		.flash.info    { background: #e3f2fd; color: #1565c0; border-color: #487eb0; }
		.flash.error   { background: #fff5f5; color: #c23616; border-color: #e84118; }
		.flash .icon   { font-size: 18px; margin-right: 10px; }

		.toolbar {
			background: #fff; padding: 15px 20px; border-radius: 8px;
			margin-bottom: 15px; display: flex; gap: 10px; align-items: center;
			box-shadow: 0 1px 3px rgba(0,0,0,0.05);
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
		.toolbar .right { margin-left: auto; }
		.btn-create {
			padding: 8px 18px; background: #44bd32; color: #fff;
			border: none; border-radius: 4px; text-decoration: none;
			font-size: 14px; display: inline-block;
		}
		.btn-create:hover { background: #389e2a; }

		table {
			width: 100%; background: #fff; border-collapse: collapse;
			border-radius: 8px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.05);
		}
		th, td { padding: 12px 15px; text-align: left; border-bottom: 1px solid #f1f2f6; font-size: 14px; }
		th { background: #f5f6fa; font-weight: 600; color: #718093; font-size: 12px; text-transform: uppercase; }
		tbody tr:hover { background: #f5f6fa; }

		.status {
			display: inline-block; padding: 3px 10px; border-radius: 12px;
			font-size: 12px; font-weight: 600;
		}
		.status.UPCOMING { background: #c7ecee; color: #0a3d62; }
		.status.ONGOING  { background: #dff9fb; color: #00a8ff; }
		.status.CLOSED   { background: #f5f6fa; color: #718093; }

		.actions a, .actions button {
			padding: 5px 10px; font-size: 12px; margin-right: 4px;
			border: 1px solid #dcdde1; background: #fff;
			border-radius: 4px; text-decoration: none; color: #2f3640;
			cursor: pointer;
		}
		.actions a:hover { background: #487eb0; color: #fff; border-color: #487eb0; }
		.actions button.delete { color: #e84118; border-color: #e84118; }
		.actions button.delete:hover { background: #e84118; color: #fff; }

		.info { margin: 15px 0; color: #718093; font-size: 14px; }
		.empty { padding: 40px; text-align: center; color: #718093; }
	</style>
</head>
<body>
<div class="wrap">

	<h1>🎤 공연 관리</h1>

	<div class="nav">
		<a href="/admin/main.do">대시보드</a>
		<a href="/admin/concert/list.do" class="active">공연 관리</a>
		<a href="/admin/member/list.do">회원 관리</a>
		<a href="/admin/booking/list.do">예매 내역</a>
	</div>

	<%-- Flash Message 배너 (등록/수정/삭제 결과) --%>
	<c:if test="${not empty msg}">
		<div class="flash ${empty msgType ? 'success' : msgType}">
			<span class="icon">
				<c:choose>
					<c:when test="${msgType eq 'info'}">ⓘ</c:when>
					<c:when test="${msgType eq 'error'}">⚠</c:when>
					<c:otherwise>✅</c:otherwise>
				</c:choose>
			</span>
			<span><c:out value="${msg}" /></span>
		</div>
	</c:if>

	<form method="get" action="/admin/concert/list.do">
		<div class="toolbar">
			<select name="searchType">
				<option value=""        <c:if test="${empty searchType}">selected</c:if>>전체</option>
				<option value="title"   <c:if test="${searchType eq 'title'}">selected</c:if>>공연명</option>
				<option value="artist"  <c:if test="${searchType eq 'artist'}">selected</c:if>>아티스트</option>
			</select>
			<input type="text" name="keyword" placeholder="검색어 입력"
				value="<c:out value='${keyword}' />" />
			<button type="submit">🔍 검색</button>

			<div class="right">
				<a href="/admin/concert/form.do" class="btn-create">+ 공연 등록</a>
			</div>
		</div>
	</form>

	<div class="info">총 <strong>${TOTAL}</strong>건</div>

	<table>
		<thead>
			<tr>
				<th style="width:60px;">ID</th>
				<th>공연명</th>
				<th>아티스트</th>
				<th>장소</th>
				<th style="width:100px;">상태</th>
				<th style="width:160px;">관리</th>
			</tr>
		</thead>
		<tbody>
			<c:choose>
				<c:when test="${empty concertList}">
					<tr><td colspan="6" class="empty">조회된 공연이 없습니다.</td></tr>
				</c:when>
				<c:otherwise>
					<c:forEach var="row" items="${concertList}">
						<tr>
							<td>${row.CONCERT_ID}</td>
							<td><c:out value="${row.TITLE}" /></td>
							<td><c:out value="${row.ARTIST}" /></td>
							<td><c:out value="${row.VENUE}" /></td>
							<td><span class="status ${row.STATUS}">${row.STATUS}</span></td>
							<td class="actions">
								<a href="/admin/concert/form.do?concertId=${row.CONCERT_ID}">수정</a>
								<form method="post" action="/admin/concert/delete.do" style="display:inline;">
									<input type="hidden" name="concertId" value="${row.CONCERT_ID}" />
									<button type="submit" class="delete"
										onclick="return confirm('이 공연을 삭제하시겠습니까?\n\n• 예매 내역이 없으면 완전히 삭제됩니다.\n• 예매 내역이 있으면 비활성 처리(CLOSED)됩니다.');">
										삭제
									</button>
								</form>
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
