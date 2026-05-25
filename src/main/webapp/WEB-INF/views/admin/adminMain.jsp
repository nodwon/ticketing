<%--
============================================================
 Project   : 관제 티켓 (Ticketing System)
 FileName  : adminMain.jsp

 Developer : 김태희 (feature/kth)
 Created   : 2026.05.24
 Modified  : 2026.05.25

 Description :
   - 관리자 대시보드
   - 회원 / 공연 / 예매 건수 카드 표시

 History :
   2026.05.25 - 탬퍼 탐지 카드 / 알림 제거
   2026.05.25 - 네비 URL 팀 규칙 적용 (/admin/xxx/list.do)
============================================================
--%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt"  prefix="fmt" %>
<!DOCTYPE html>
<html lang="ko">
<head>
	<meta charset="UTF-8">
	<title>관리자 대시보드 | 관제 티켓</title>
	<style>
		* { margin: 0; padding: 0; box-sizing: border-box; }
		body {
			font-family: 'Segoe UI', 'Malgun Gothic', sans-serif;
			background: #f5f6fa;
			color: #2f3640;
			padding: 30px;
		}
		.wrap { max-width: 1200px; margin: 0 auto; }
		h1 { font-size: 26px; margin-bottom: 6px; }
		.subtitle { color: #718093; margin-bottom: 30px; font-size: 14px; }

		.nav { margin-bottom: 30px; }
		.nav a {
			display: inline-block;
			padding: 10px 18px;
			margin-right: 8px;
			background: #fff;
			color: #2f3640;
			text-decoration: none;
			border-radius: 6px;
			border: 1px solid #dcdde1;
			font-size: 14px;
			transition: all 0.2s;
		}
		.nav a:hover { background: #487eb0; color: #fff; border-color: #487eb0; }
		.nav a.active { background: #487eb0; color: #fff; border-color: #487eb0; }

		.cards {
			display: grid;
			grid-template-columns: repeat(3, 1fr);
			gap: 20px;
			margin-bottom: 30px;
		}
		.card {
			background: #fff;
			border-radius: 10px;
			padding: 28px;
			box-shadow: 0 2px 8px rgba(0,0,0,0.05);
			border-top: 4px solid #487eb0;
		}
		.card .label {
			color: #718093;
			font-size: 13px;
			margin-bottom: 12px;
		}
		.card .value {
			font-size: 40px;
			font-weight: bold;
			color: #2f3640;
		}
		.card .unit { font-size: 14px; color: #718093; margin-left: 4px; }
	</style>
</head>
<body>
<div class="wrap">

	<h1>🎫 관제 티켓 관리자</h1>
	<p class="subtitle">티켓팅 시스템 관리 페이지</p>

	<div class="nav">
		<a href="/admin/main.do" class="active">대시보드</a>
		<a href="/admin/concert/list.do">공연 관리</a>
		<a href="/admin/member/list.do">회원 관리</a>
		<a href="/admin/booking/list.do">예매 내역</a>
	</div>

	<div class="cards">
		<div class="card">
			<div class="label">총 회원</div>
			<div class="value">
				<fmt:formatNumber value="${dashboard.MEMBER_CNT}" pattern="#,###" />
				<span class="unit">명</span>
			</div>
		</div>

		<div class="card">
			<div class="label">총 공연</div>
			<div class="value">
				<fmt:formatNumber value="${dashboard.CONCERT_CNT}" pattern="#,###" />
				<span class="unit">건</span>
			</div>
		</div>

		<div class="card">
			<div class="label">총 예매</div>
			<div class="value">
				<fmt:formatNumber value="${dashboard.BOOKING_CNT}" pattern="#,###" />
				<span class="unit">건</span>
			</div>
		</div>
	</div>

</div>
</body>
</html>
