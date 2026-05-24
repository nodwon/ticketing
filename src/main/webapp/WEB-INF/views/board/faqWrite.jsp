<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="ko">
<head>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<link rel="stylesheet" type="text/css" href="<c:url value='/css/uii.css'/>" />
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>
<script src="<c:url value='/js/commonn.js'/>" charset="utf-8"></script>
<style>
h2 { text-align: center; padding: 30px 0; font-weight: normal; font-size: 1.8em; }
</style>
</head>
<body>
<br/><br/><br/>
<h2>FAQ 글쓰기</h2>
<br/><br/>

<form id="frm" name="frm">
    <!-- 버그수정: SESSION_NO → 세션에서 MEMBER_NO 전달 -->
	<input type="hidden" id="member_no" name="MEMBER_NO" value="${sessionScope.SESSION_NO}">
    <table class="board_view">
        <colgroup>
            <col width="15%"/>
            <col width="*"/>
        </colgroup>
        <caption>글쓰기</caption>
        <tbody>
            <tr>
                <th scope="row">제목</th>
                <td>
                    <input type="text" id="NOTICE_TITLE" name="NOTICE_TITLE" class="wdp_90" placeholder="제목을 입력하세요"/>
                </td>
            </tr>
            <tr>
                <th scope="row">내용</th>
                <td>
                    <textarea rows="20" cols="100" id="NOTICE_CONTENT" name="NOTICE_CONTENT" placeholder="내용을 입력하세요"></textarea>
                </td>
            </tr>
        </tbody>
    </table>
</form>

<p>
    <a href="#this" class="btn" id="write">작성하기</a>
    <a href="#this" class="btn" id="list">목록으로</a>
</p>

<form id="commonForm" name="commonForm"></form>
<script type="text/javascript">
$(document).ready(function() {
    $("#write").on("click", function(e) {
        e.preventDefault();
        /* 유효성 검사 */
        if ($.trim($("#NOTICE_TITLE").val()) === "") {
            alert("제목을 입력해주세요.");
            $("#NOTICE_TITLE").focus();
            return;
        }
        if ($.trim($("#NOTICE_CONTENT").val()) === "") {
            alert("내용을 입력해주세요.");
            $("#NOTICE_CONTENT").focus();
            return;
        }
        fn_insertFaq();
    });

    $("#list").on("click", function(e) {
        e.preventDefault();
        fn_openFaqList();
    });
});

function fn_insertFaq() {
    var comSubmit = new ComSubmit("frm");
    comSubmit.setUrl("<c:url value='/faq/insertFaq.do'/>");
    comSubmit.submit();
}

function fn_openFaqList() {
    var comSubmit = new ComSubmit();
    comSubmit.setUrl("<c:url value='/faq/openFaqList.do'/>");
    comSubmit.submit();
}
</script>
</body>
</html>
