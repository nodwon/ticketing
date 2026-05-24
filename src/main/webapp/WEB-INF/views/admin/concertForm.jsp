<%--
============================================================
 Project   : 관제 티켓 (Ticketing System)
 FileName  : concertForm.jsp

 Developer : 김태희 (feature/kth)
 Created   : 2026.05.24
 Modified  : 2026.05.25

 Description :
   - 공연 등록 (mode = create) / 수정 (mode = edit) 통합 폼
   - 등록 → POST /admin/concert/insert.do
   - 수정 → POST /admin/concert/update.do  (concertId 포함)

 History :
   2026.05.25 - URL 팀 규칙 적용 (/admin/concert/xxx.do)
============================================================
--%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="ko">
<head>
	<meta charset="UTF-8">
	<title>
		<c:choose>
			<c:when test="${mode eq 'edit'}">공연 수정</c:when>
			<c:otherwise>공연 등록</c:otherwise>
		</c:choose>
		| 관제 티켓
	</title>
	<style>
		* { margin: 0; padding: 0; box-sizing: border-box; }
		body { font-family: 'Segoe UI', 'Malgun Gothic', sans-serif; background: #f5f6fa; color: #2f3640; padding: 30px; }
		.wrap { max-width: 800px; margin: 0 auto; }
		h1 { font-size: 24px; margin-bottom: 20px; }

		.nav { margin-bottom: 20px; }
		.nav a {
			display: inline-block; padding: 10px 18px; margin-right: 8px;
			background: #fff; color: #2f3640; text-decoration: none;
			border-radius: 6px; border: 1px solid #dcdde1; font-size: 14px;
		}
		.nav a:hover, .nav a.active { background: #487eb0; color: #fff; border-color: #487eb0; }

		.form-card {
			background: #fff; padding: 30px; border-radius: 8px;
			box-shadow: 0 1px 3px rgba(0,0,0,0.05);
		}
		.field { margin-bottom: 20px; }
		.field label {
			display: block; margin-bottom: 6px; font-weight: 600;
			color: #2f3640; font-size: 14px;
		}
		.field label .required { color: #e84118; }
		.field input[type="text"],
		.field textarea,
		.field select {
			width: 100%; padding: 10px 12px; border: 1px solid #dcdde1;
			border-radius: 4px; font-size: 14px; font-family: inherit;
		}
		.field input:focus, .field textarea:focus, .field select:focus {
			outline: none; border-color: #487eb0;
		}
		.field textarea { min-height: 100px; resize: vertical; }
		.field .hint { color: #718093; font-size: 12px; margin-top: 4px; }

		.actions { margin-top: 25px; display: flex; gap: 10px; }
		.actions button, .actions a {
			padding: 10px 22px; border-radius: 4px; font-size: 14px;
			border: none; cursor: pointer; text-decoration: none;
			display: inline-block; text-align: center;
		}
		.actions .save  { background: #487eb0; color: #fff; }
		.actions .save:hover  { background: #40739e; }
		.actions .cancel { background: #dcdde1; color: #2f3640; }
		.actions .cancel:hover { background: #c7c7c7; }
	</style>
</head>
<body>
<div class="wrap">

	<h1>
		<c:choose>
			<c:when test="${mode eq 'edit'}">🎤 공연 수정</c:when>
			<c:otherwise>🎤 공연 등록</c:otherwise>
		</c:choose>
	</h1>

	<div class="nav">
		<a href="/admin/main.do">대시보드</a>
		<a href="/admin/concert/list.do" class="active">공연 관리</a>
		<a href="/admin/member/list.do">회원 관리</a>
		<a href="/admin/booking/list.do">예매 내역</a>
	</div>

	<form method="post"
		action="<c:choose>
			<c:when test='${mode eq \"edit\"}'>/admin/concert/update.do</c:when>
			<c:otherwise>/admin/concert/insert.do</c:otherwise>
		</c:choose>">

		<div class="form-card">

			<c:if test="${mode eq 'edit'}">
				<input type="hidden" name="concertId" value="${concert.CONCERT_ID}" />
			</c:if>

			<div class="field">
				<label>공연명 <span class="required">*</span></label>
				<input type="text" name="title" required maxlength="200"
					value="<c:out value='${concert.TITLE}' />" />
			</div>

			<div class="field">
				<label>아티스트 <span class="required">*</span></label>
				<input type="text" name="artist" required maxlength="100"
					value="<c:out value='${concert.ARTIST}' />" />
			</div>

			<div class="field">
				<label>장소</label>
				<input type="text" name="venue" maxlength="200"
					value="<c:out value='${concert.VENUE}' />" />
			</div>

			<div class="field">
				<label>썸네일 URL</label>
				<input type="text" name="thumbnail" maxlength="500"
					value="<c:out value='${concert.THUMBNAIL}' />" />
				<div class="hint">이미지 URL을 입력하세요. (예: https://...)</div>
			</div>

			<div class="field">
				<label>설명</label>
				<textarea name="description"><c:out value="${concert.DESCRIPTION}" /></textarea>
			</div>

			<div class="field">
				<label>상태</label>
				<select name="status">
					<option value="UPCOMING" <c:if test="${concert.STATUS eq 'UPCOMING'}">selected</c:if>>UPCOMING (예정)</option>
					<option value="ONGOING"  <c:if test="${concert.STATUS eq 'ONGOING'}">selected</c:if>>ONGOING (진행중)</option>
					<option value="CLOSED"   <c:if test="${concert.STATUS eq 'CLOSED'}">selected</c:if>>CLOSED (종료)</option>
				</select>
			</div>

			<div class="actions">
				<button type="submit" class="save">
					<c:choose>
						<c:when test="${mode eq 'edit'}">수정 저장</c:when>
						<c:otherwise>등록</c:otherwise>
					</c:choose>
				</button>
				<a href="/admin/concert/list.do" class="cancel">취소</a>
			</div>
		</div>
	</form>

</div>
</body>
</html>
