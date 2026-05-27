<%--
============================================================
 Project   : 관제 티켓 (Ticketing System)
 FileName  : memberList.jsp

 Developer : 김태희 (feature/kth)
 Created   : 2026.05.24
 Modified  : 2026.05.27

 Description :
   - 회원 목록 / 검색 (email, name) / 권한 필터 / 페이징
   - 권한 변경 액션 버튼 (정지 / 활성화 / 승격 / 강등)
   - Flash Message 배너 (success / info / error)

 History :
   2026.05.25 - URL 팀 규칙 적용 (/admin/xxx/list.do)
   2026.05.27 - 회원 권한 변경 액션 버튼 추가
                · USER         → [정지] [관리자 승격]
                · USER_BANNED  → [활성화] [관리자 승격]
                · ADMIN        → [일반 회원으로 강등]
                · 각 액션에 confirm 다이얼로그 (마지막 관리자 보호 안내 포함)
   2026.05.27 - Flash Message 배너 UI 추가 (success / info / error)
   2026.05.27 - role 필터에 USER_BANNED 옵션 추가
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
		.wrap { max-width: 1300px; margin: 0 auto; }
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
		.role.USER         { background: #dff9fb; color: #00a8ff; }
		.role.USER_BANNED  { background: #fff5f5; color: #c23616; text-decoration: line-through; }
		.role.ADMIN        { background: #fff3cd; color: #ff9f1a; }

		/* 액션 버튼 */
		.actions { white-space: nowrap; }
		.actions form { display: inline-block; margin-right: 4px; }
		.actions button {
			padding: 5px 10px; font-size: 12px;
			border: 1px solid #dcdde1; background: #fff;
			border-radius: 4px; color: #2f3640; cursor: pointer;
		}
		.actions button:hover { background: #487eb0; color: #fff; border-color: #487eb0; }
		.actions button.danger        { color: #e84118; border-color: #e84118; }
		.actions button.danger:hover  { background: #e84118; color: #fff; }
		.actions button.warn          { color: #ff9f1a; border-color: #ff9f1a; }
		.actions button.warn:hover    { background: #ff9f1a; color: #fff; }
		.actions button.success       { color: #2d7a2d; border-color: #44bd32; }
		.actions button.success:hover { background: #44bd32; color: #fff; }

		.info { margin: 15px 0; color: #718093; font-size: 14px; }
		.empty { padding: 40px; text-align: center; color: #718093; }
	</style>
</head>
<body>
<div class="wrap">

	<h1>👥 회원 관리</h1>

	<div class="nav">
		<a href="/admin/main.do">대시보드</a>
		<a href="/admin/concert/list.do">공연 관리</a>
		<a href="/admin/member/list.do" class="active">회원 관리</a>
		<a href="/admin/booking/list.do">예매 내역</a>
	</div>

	<%-- Flash Message 배너 (권한 변경 결과) --%>
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

	<form method="get" action="/admin/member/list.do">
		<div class="toolbar">
			<select name="role">
				<option value=""             <c:if test="${empty role}">selected</c:if>>전체 권한</option>
				<option value="USER"         <c:if test="${role eq 'USER'}">selected</c:if>>USER (활성)</option>
				<option value="USER_BANNED"  <c:if test="${role eq 'USER_BANNED'}">selected</c:if>>USER_BANNED (정지)</option>
				<option value="ADMIN"        <c:if test="${role eq 'ADMIN'}">selected</c:if>>ADMIN</option>
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
				<th style="width:130px;">권한</th>
				<th style="width:280px;">권한 관리</th>
			</tr>
		</thead>
		<tbody>
			<c:choose>
				<c:when test="${empty memberList}">
					<tr><td colspan="7" class="empty">조회된 회원이 없습니다.</td></tr>
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
							<td class="actions">
								<%--
									상태별 액션 버튼 분기
									 USER         → [정지] [관리자 승격]
									 USER_BANNED  → [활성화] [관리자 승격]
									 ADMIN        → [일반 회원으로 강등]
								--%>
								<c:choose>
									<%-- 일반 회원 (활성) --%>
									<c:when test="${row.ROLE eq 'USER'}">
										<form method="post" action="/admin/member/ban.do"
											onsubmit="return confirm('회원 [${row.NAME}] 님을 정지 처리하시겠습니까?\n\n정지된 회원은 로그인 차단됩니다.');">
											<input type="hidden" name="memberId" value="${row.MEMBER_ID}" />
											<button type="submit" class="danger">정지</button>
										</form>
										<form method="post" action="/admin/member/promote.do"
											onsubmit="return confirm('회원 [${row.NAME}] 님을 관리자(ADMIN) 로 승격하시겠습니까?\n\n관리자는 모든 admin 기능에 접근할 수 있습니다.');">
											<input type="hidden" name="memberId" value="${row.MEMBER_ID}" />
											<button type="submit" class="warn">관리자 승격</button>
										</form>
									</c:when>

									<%-- 정지된 회원 --%>
									<c:when test="${row.ROLE eq 'USER_BANNED'}">
										<form method="post" action="/admin/member/unban.do"
											onsubmit="return confirm('회원 [${row.NAME}] 님을 활성화하시겠습니까?');">
											<input type="hidden" name="memberId" value="${row.MEMBER_ID}" />
											<button type="submit" class="success">활성화</button>
										</form>
										<form method="post" action="/admin/member/promote.do"
											onsubmit="return confirm('회원 [${row.NAME}] 님을 관리자(ADMIN) 로 승격하시겠습니까?\n\n정지가 해제되면서 관리자 권한이 부여됩니다.');">
											<input type="hidden" name="memberId" value="${row.MEMBER_ID}" />
											<button type="submit" class="warn">관리자 승격</button>
										</form>
									</c:when>

									<%-- 관리자 --%>
									<c:when test="${row.ROLE eq 'ADMIN'}">
										<form method="post" action="/admin/member/demote.do"
											onsubmit="return confirm('관리자 [${row.NAME}] 님을 일반 회원(USER) 으로 강등하시겠습니까?\n\n관리자가 1명만 남은 경우 강등이 차단됩니다.');">
											<input type="hidden" name="memberId" value="${row.MEMBER_ID}" />
											<button type="submit" class="danger">일반 회원으로 강등</button>
										</form>
									</c:when>
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
