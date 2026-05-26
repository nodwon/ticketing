<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="ko">
<head>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>
<%
    String sessionName = (String) session.getAttribute("SESSION_NAME");
    if (sessionName == null || sessionName.equals("")) { sessionName = "nomal"; }
%>
<link rel="stylesheet" type="text/css" href="<c:url value='/css/uii.css'/>" />
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>
<script src="<c:url value='/js/commonn.js'/>" charset="utf-8"></script>
<style>
.wrapper3 { max-width: 1000px; margin: 0 auto; }
h2 { text-align: center; padding: 30px 0; font-weight: normal; font-size: 1.8em; letter-spacing: 6px; }
li { list-style: none; float: left; }
.bar { height: 1.5px; width: 100%; background-color: #DCDCDC; }
.flex-menu li { text-align: center; width: 100%; }
</style>
</head>
<body>
   <style>
   .board-tab-wrap { max-width: 1000px; margin: 28px auto 0; padding: 0 20px; }
   .board-tab-list { display: flex; list-style: none; margin: 0; padding: 0; border-bottom: 2px solid #e0e0e0; }
   .board-tab-list li { float: none; }
   .board-tab-list li a { display: block; padding: 12px 28px; font-size: 14px; font-weight: 600; color: #999; text-decoration: none; letter-spacing: 0.5px; border-bottom: 3px solid transparent; margin-bottom: -2px; transition: color .18s, border-color .18s; }
   .board-tab-list li a:hover { color: #222; }
   .board-tab-list li a.tab-active { color: #e8001c; border-bottom-color: #e8001c; }
   </style>
   <div class="board-tab-wrap">
      <ul class="board-tab-list">
            <li><a href="/faq/openFaqList.do" class="tab-active">FAQ</a></li>
         <li><a href="/notice/openNoticeList.do">공지사항</a></li>
         <li><a href="/qna/openQnaList.do">Q&amp;A</a></li>
      </ul>
   </div>
<br/><br/><br/>
<h2>FAQ 자주묻는질문</h2>
<br/><br/>

<table class="board_list">
    <colgroup>
        <col width="10%"/>
        <col width="*"/>
        <col width="20%"/>
        <col width="5%"/>
    </colgroup>
    <thead>
        <tr>
            <th scope="col">글번호</th>
            <th scope="col">제목</th>
            <th scope="col">작성일</th>
            <th scope="col" class="deleteBtn" style="display:none;">관리</th>
        </tr>
    </thead>
    <tbody></tbody>
</table>

<div class="pageNumber" id="PAGE_NAVI"></div>
<input type="hidden" id="PAGE_INDEX" name="PAGE_INDEX"/>

<br/>
<p id="wrapBtn" style="display:none;">
    <a href="#this" class="btn" id="write">글쓰기</a>
</p>

<form id="commonForm" name="commonForm"></form>

<script type="text/javascript">
$(document).ready(function() {
    fn_selectFaqList(1);

    $("#write").on("click", function(e) {
        e.preventDefault();
        fn_openFaqWrite();
    });
    <%
    String sessionGrade = (String) session.getAttribute("SESSION_GRADE");
    if (sessionGrade == null) sessionGrade = "";
	%>
    // 버그수정: admin 세션 비교 정확하게
	<% if ("ADMIN".equals(sessionGrade)) { %>
        $("#wrapBtn").show();
        $(".deleteBtn").show();
    <% } %>
});

function fn_openFaqWrite() {
    var comSubmit = new ComSubmit();
    comSubmit.setUrl("<c:url value='/faq/openFaqWrite.do'/>");
    comSubmit.submit();
}

function fn_selectFaqList(pageNo) {
    $("#PAGE_INDEX").val(pageNo);
    var comAjax = new ComAjax();
    comAjax.setUrl("<c:url value='/faq/selectFaqList.do'/>");
    comAjax.setCallback("fn_selectFaqListCallback");
    comAjax.addParam("PAGE_INDEX", pageNo);
    comAjax.addParam("PAGE_ROW", 10);
    comAjax.ajax();
}

function fn_selectFaqListCallback(data) {
    var total = data.TOTAL;
    var body  = $("table>tbody");
    body.empty();

    if (total == 0) {
        body.append("<tr><td colspan='4'>조회된 결과가 없습니다.</td></tr>");
        return;
    }

    var params = {
        divId       : "PAGE_NAVI",
        pageIndex   : "PAGE_INDEX",
        totalCount  : total,
        recordCount : 10,
        eventName   : "fn_selectFaqList"
    };
    gfn_renderPaging(params);

    var str = "";
    $.each(data.list, function(key, value) {
        str += "<tr id='off'>"
            + "<td>" + value.RNUM + "</td>"
            + "<td class='title'>"
            +   "<a href='#this' name='title' class='chk" + value.RNUM + "'>" + value.NOTICE_TITLE + "</a>"
            +   "<input type='hidden' name='title' value='" + value.NOTICE_NO + "'>"
            + "</td>"
            + "<td>" + value.NOTICE_DATE + "</td>"
            /* 버그수정: 삭제버튼 input value 올바르게 */
            + "<td class='deleteBtn' style='display:none;'>"
            +   "<a href='#this' name='delete' data-no='" + value.NOTICE_NO + "'>삭제</a>"
            +   "<input type='hidden' name='delete' value='" + value.NOTICE_NO + "'>"
            + "</td>"
            + "</tr>"
            + "<tr>"
            + "<td colspan='4' style='display:none;' id='chk" + value.RNUM + "'>"
            +   value.NOTICE_CONTENT
            + "</td>"
            + "</tr>";
    });
    body.append(str);

    /* 제목 클릭 → 내용 토글 */
    $("a[name='title']").on("click", function(e) {
        e.preventDefault();
        var cls = $(this).attr("class");          // chkN
        var row = $(this).closest("tr");
        if (row.attr("id") === "on") {
            $("#" + cls).hide();
            row.attr("id", "off");
        } else {
            $("#" + cls).show();
            row.attr("id", "on");
        }
    });

    /* 삭제 버튼 */
    $("a[name='delete']").on("click", function(e) {
        e.preventDefault();
        fn_deleteFaq($(this).data("no"));
    });
}

function fn_deleteFaq(noticeNo) {
    if (!confirm("삭제하시겠습니까?")) return;
    var comSubmit = new ComSubmit();
    comSubmit.setUrl("<c:url value='/faq/deleteFaq.do'/>");
    comSubmit.addParam("NOTICE_NO", noticeNo);
    comSubmit.submit();
}
</script>
</body>
</html>
