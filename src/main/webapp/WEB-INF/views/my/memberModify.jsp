<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>

<%--
============================================================
Project    : 관제 티켓 (Ticketing System)
FileName   : memberModify.jsp
Developer  : 김희재 (feature/khj)
Modified   : 2026.05.25

Description :
  - 마이페이지 회원정보 조회 + 수정 + 탈퇴
  - URL: GET /my/info.do (조회), POST /my/info.do (수정), POST /my/delete.do (탈퇴)
  - 수정 가능: 이름, 휴대폰, 생년월일
  - 이메일/권한은 표시만
============================================================
--%>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>마이페이지 - 회원정보</title>

<link rel="stylesheet" href="${pageContext.request.contextPath}/css/bootstrap.min.css">
<link href="${pageContext.request.contextPath}/css/dashboard.css" rel="stylesheet">
<link href="${pageContext.request.contextPath}/css/justified-nav.css" rel="stylesheet">
<script src="http://code.jquery.com/jquery-3.5.1.js"></script>
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/bootstrap-theme.min.css">
<script src="/js/bootstrap.min.js"></script>

<style>
a { text-decoration: none; color: #666; }
.container { width: 100%; display: flex; padding: 0; }
.contents { width: 100%; margin: 10px; }
.member-info { max-width: 700px; margin: 20px auto; }
.form-readonly { background-color: #f5f5f5; color: #666; }
.badge-user  { display: inline-block; padding: 4px 10px; background: #e8f4ff; color: #0066ff; border-radius: 4px; font-size: 13px; }
.badge-admin { display: inline-block; padding: 4px 10px; background: #fff0e0; color: #c66; border-radius: 4px; font-size: 13px; }
.delete-section { background: #fff5f5; padding: 20px; border-radius: 8px; margin-top: 30px; }
.delete-section h4 { color: #c00; margin-top: 0; }
.birth-group { display: flex; gap: 6px; }
.birth-group input { width: 100px; }
</style>
</head>
<body>
<div class="container">
    <%@include file="/WEB-INF/tiles/mySide.jsp" %>

    <div class="contents">
        <div class="member-info">
            <h3>회원정보 수정</h3>

            <%-- BIRTH_DATE 분해 (YYYY-MM-DD) --%>
            <c:set var="birth" value="${member.BIRTH_DATE}" />
            <c:set var="birthYear"  value="${fn:substring(birth, 0, 4)}" />
            <c:set var="birthMonth" value="${fn:substring(birth, 5, 7)}" />
            <c:set var="birthDay"   value="${fn:substring(birth, 8, 10)}" />

            <!-- 회원정보 수정 폼 -->
            <form id="memberInfoForm" method="post" action="${pageContext.request.contextPath}/my/info.do">

                <div class="form-group">
                    <label>회원번호</label>
                    <input type="text" class="form-control form-readonly"
                           value="${member.MEMBER_ID}" readonly>
                </div>

                <div class="form-group">
                    <label>이메일</label>
                    <input type="text" class="form-control form-readonly"
                           value="${member.EMAIL}" readonly>
                </div>

                <div class="form-group">
                    <label>권한</label><br>
                    <c:choose>
                        <c:when test="${member.ROLE eq 'ADMIN'}">
                            <span class="badge-admin">${member.ROLE}</span>
                        </c:when>
                        <c:otherwise>
                            <span class="badge-user">${member.ROLE}</span>
                        </c:otherwise>
                    </c:choose>
                </div>

                <hr>

                <div class="form-group">
                    <label for="NAME">이름 *</label>
                    <input type="text" class="form-control" id="NAME" name="NAME"
                           value="${member.NAME}" placeholder="이름" required maxlength="50">
                </div>

                <div class="form-group">
                    <label for="PHONE">휴대폰</label>
                    <input type="tel" class="form-control" id="PHONE" name="PHONE"
                           value="${member.PHONE}" placeholder="010-1234-5678" maxlength="20">
                </div>

                <div class="form-group">
                    <label>생년월일 (YYYY MM DD)</label>
                    <div class="birth-group">
                        <input type="text" class="form-control" name="BIRTH_YEAR"
                               value="${birthYear}" placeholder="YYYY" maxlength="4">
                        <input type="text" class="form-control" name="BIRTH_MONTH"
                               value="${birthMonth}" placeholder="MM" maxlength="2">
                        <input type="text" class="form-control" name="BIRTH_DAY"
                               value="${birthDay}" placeholder="DD" maxlength="2">
                    </div>
                </div>

                <button type="submit" class="btn btn-primary btn-lg" style="margin-top:20px;">
                    정보 수정
                </button>
                <a href="${pageContext.request.contextPath}/my/bookingList.do" class="btn btn-default btn-lg" style="margin-top:20px;">
                    예매내역 보기
                </a>
            </form>
			
            <!-- 회원 탈퇴 (별도 폼) -->
            <div class="delete-section">
	            <c:if test="${not empty deleteError}">
				    <div class="alert alert-warning" style="
				        background: #fff3cd; 
				        border: 1px solid #ffc107; 
				        color: #856404;
				        padding: 12px 16px; 
				        border-radius: 6px; 
				        margin-bottom: 20px;
				        white-space: pre-line;">
				        ⚠️ ${deleteError}
				    </div>
				</c:if>
                <h4>⚠️ 회원 탈퇴</h4>
                <p>탈퇴 시 회원정보가 즉시 삭제되며, 복구할 수 없습니다.</p>
                <form method="post" action="${pageContext.request.contextPath}/my/delete.do"
                      onsubmit="return confirm('정말 탈퇴하시겠습니까?\n모든 정보가 삭제되며, 복구할 수 없습니다.\n예매 내역이 있는 경우 탈퇴가 제한됩니다.');">
                    <button type="submit" class="btn btn-danger">회원 탈퇴</button>
                </form>
            </div>
        </div>
    </div>
</div>
</body>
</html>
