<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="ko">
<head>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%
    String sessionName = (String) session.getAttribute("SESSION_NAME");
    if (sessionName == null) sessionName = "nomal";
%>
<link rel="stylesheet" type="text/css" href="<c:url value='/css/uii.css'/>" />
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>
<script src="<c:url value='/js/commonn.js'/>" charset="utf-8"></script>
<style>
h2 { text-align: center; padding: 30px 0; font-weight: normal; font-size: 1.8em; }
a { text-decoration: none; color: #666; }
</style>
</head>
<body>
<br/><br/><br/>
<!-- 버그수정: h2 타이틀 "공지사항" → "FAQ" -->
<h2>FAQ 상세</h2>
<br/><br/>

<table class="board_view">
    <colgroup>
        <col width="15%"/>
        <col width="35%"/>
        <col width="15%"/>
        <col width="35%"/>
    </colgroup>
    <caption>FAQ 상세보기</caption>
    <tbody>
        <tr>
            <th scope="row">글 번호</th>
            <td>${map.NOTICE_NO}</td>
        </tr>
        <tr>
            <th scope="row">작성자</th>
            <td>관리자</td>
            <th scope="row">작성시간</th>
            <td>${map.NOTICE_DATE}</td>
        </tr>
        <tr>
            <th scope="row">제목</th>
            <td colspan="3">${map.NOTICE_TITLE}</td>
        </tr>
        <tr>
            <td colspan="4" class="view_text">${map.NOTICE_CONTENT}</td>
        </tr>
    </tbody>
</table>
<br/>

<a href="#this" class="btn" id="list">목록으로</a>
<!-- 버그수정: admin만 수정/삭제 버튼 표시 -->
<% if ("admin".equals(sessionName.trim())) { %>
<a href="#this" class="btn" id="update">수정하기</a>
<a href="#this" class="btn" id="delete">삭제하기</a>
<% } %>

<form id="commonForm" name="commonForm"></form>
<script type="text/javascript">
$(document).ready(function() {
    $("#list").on("click", function(e) {
        e.preventDefault();
        fn_openFaqList();
    });

    $("#update").on("click", function(e) {
        e.preventDefault();
        fn_openFaqUpdate();
    });

    $("#delete").on("click", function(e) {
        e.preventDefault();
        if (!confirm("삭제하시겠습니까?")) return;
        fn_deleteFaq();
    });
});

function fn_openFaqList() {
    var comSubmit = new ComSubmit();
    /* 버그수정: notice URL → faq URL */
    comSubmit.setUrl("<c:url value='/faq/openFaqList.do'/>");
    comSubmit.submit();
}

function fn_openFaqUpdate() {
    var comSubmit = new ComSubmit();
    /* 버그수정: notice URL → faq URL */
    comSubmit.setUrl("<c:url value='/faq/openFaqUpdate.do'/>");
    comSubmit.addParam("NOTICE_NO", "${map.NOTICE_NO}");
    comSubmit.submit();
}

function fn_deleteFaq() {
    var comSubmit = new ComSubmit();
    comSubmit.setUrl("<c:url value='/faq/deleteFaq.do'/>");
    comSubmit.addParam("NOTICE_NO", "${map.NOTICE_NO}");
    comSubmit.submit();
}
</script>
</body>
</html>
