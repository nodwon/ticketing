<%--
============================================================
 Project   : 관제 티켓 (Ticketing System)
 FileName  : memberList.jsp

 Developer : 김태희 (feature/kth)
 Created   : 2026.05.24
 Modified  : 2026.05.25

 Description :
   - 회원 목록 / 검색 (email, name) / 권한 필터 / 페이징

 History :
   2026.05.25 - URL 팀 규칙 적용 (/admin/xxx/list.do)
============================================================
--%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt"  prefix="fmt" %>
<!DOCTYPE html>
<html lang="ko">
<head>
	<meta charset="UTF-8">
	<title>회원 관리 | 관제 티켓</title>
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

		table {
			width: 100%; background: #fff; border-collapse: collapse;
			border-radius: 8px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.05);
		}
		th, td { padding: 12px 15px; text-align: left; border-bottom: 1px solid #f1f2f6; font-size: 14px; }
		th { background: #f5f6fa; font-weight: 600; color: #718093; font-size: 12px; text-transform: uppercase; }
		tbody tr:hover { background: #f5f6fa; }

		.role {
			display: inline-block; padding: 3px 10px; border-radius: 12px;
			font-size: 12px; font-weight: 600;
		}
		.role.USER  { background: #dff9fb; color: #00a8ff; }
		.role.ADMIN { background: #fff3cd; color: #ff9f1a; }

		.info { margin: 15px 0; color: #718093; font-size: 14px; }
		.empty { padding: 40px; text-align: center; color: #718093; }
	</style>
</head>
<body>
<div class="wrap">
	<a href="/main.do" style="text-decoration: none; color: inherit;">
	    <h1>🎫 관제 티켓 관리자</h1>
	</a>
	<h1>👥 회원 관리</h1>

	<div class="nav">
		<a href="/admin/main.do">대시보드</a>
		<a href="/admin/concert/list.do">공연 관리</a>
		<a href="/admin/member/list.do" class="active">회원 관리</a>
		<a href="/admin/booking/list.do">예매 내역</a>
	</div>

	<form method="get" action="/admin/member/list.do">
		<div class="toolbar">
			<select name="role">
				<option value=""       <c:if test="${empty role}">selected</c:if>>전체 권한</option>
				<option value="USER"   <c:if test="${role eq 'USER'}">selected</c:if>>USER</option>
				<option value="ADMIN"  <c:if test="${role eq 'ADMIN'}">selected</c:if>>ADMIN</option>
			</select>
			<select name="searchType">
				<option value=""       <c:if test="${empty searchType}">selected</c:if>>전체</option>
				<option value="email"  <c:if test="${searchType eq 'email'}">selected</c:if>>이메일</option>
				<option value="name"   <c:if test="${searchType eq 'name'}">selected</c:if>>이름</option>
			</select>
			<input type="text" name="keyword" placeholder="검색어 입력"
				value="<c:out value='${keyword}' />" />
			<button type="submit">🔍 검색</button>
		</div>
	</form>

	<div class="info">총 <strong>${TOTAL}</strong>명</div>

	<table>
		<thead>
			<tr>
				<th style="width:60px;">ID</th>
				<th>이메일</th>
				<th>이름</th>
				<th>전화번호</th>
				<th>생년월일</th>
				<th style="width:100px;">권한</th>
			</tr>
		</thead>
		<tbody>
			<c:choose>
				<c:when test="${empty memberList}">
					<tr><td colspan="6" class="empty">조회된 회원이 없습니다.</td></tr>
				</c:when>
				<c:otherwise>
					<c:forEach var="row" items="${memberList}">
						<tr>
							<td>${row.MEMBER_ID}</td>
							<td><c:out value="${row.EMAIL}" /></td>
							<td><c:out value="${row.NAME}" /></td>
							<td><c:out value="${row.PHONE}" /></td>
							<td>
								<c:if test="${not empty row.BIRTH_DATE}">
									<fmt:formatDate value="${row.BIRTH_DATE}" pattern="yyyy-MM-dd" />
								</c:if>
							</td>
							<td><span class="role ${row.ROLE}">${row.ROLE}</span></td>
						</tr>
					</c:forEach>
				</c:otherwise>
			</c:choose>
		</tbody>
	</table>

</div>
</body>
</html>
