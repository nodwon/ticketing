<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="ko">
<head>
<%
	String sessionId = (String) session.getAttribute("SESSION_NAME");
	String sessionName = (String) session.getAttribute("SESSION_ID");
	
	// 💡 [1차 Null 방어막] 비회원 접속 시 sessionId가 null이 되는 것을 방지
	if (sessionId == null) {
		sessionId = "";
	}
%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>
<%@ taglib prefix="ui" uri="http://tiles.apache.org/tags-tiles"%>
<link rel="stylesheet" type="text/css"
	href="<c:url value='/css/uii.css'/>" />

<script
	src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>
<script src="<c:url value='/js/commonn.js'/>" charset="utf-8"></script>
</head>
<style>

a {
  text-decoration: none;
  color: #666;
}

h1 {
    text-align: center;
    padding: 50px 0;
    font-weight: normal;
    font-size: 2em;
    letter-spacing: 10px;
}  
</style>
<body>
	<br />
	<br />
	<br />
	<h2>문의보기</h2>
	<br />
	<br />

	<table class="board_view">
		<colgroup>
			<col width="15%" />
			<col width="35%" />
			<col width="15%" />
			<col width="35%" />
		</colgroup>
		<tbody>
			<tr>
				<th scope="row">글 번호</th>
				<td align="center">${map.RNUM}</td>
				<th scope="row">문의내용</th>
				<td id="qna_gubunaa" align="center"></td>
			</tr>
			<tr>
				<th scope="row">작성자</th>
				<td align="center">${map.QNA_NAME}</td>
				<th scope="row">작성시간</th>
				<td align="center">${map.QNA_DATE}</td>
			</tr>
			<tr>
				<th scope="row">제목</th>
				<td colspan="3" align="left">${map.QNA_TITLE}</td>
			</tr>
			<tr>
				<th scope="row">내용</th>
				<td colspan="4" align="left">${map.QNA_CONTENT}</td>
			</tr>
		</tbody>
		<tr rows="10" cols="140" title="답변">
			<th scope="row">답변</th>
			<td colspan="4" align="left" id="qna_an">
				<c:choose>
					<%-- 세션 ID(SESSION_ID)가 admin이거나 세션 이름이 관리자인 경우 처리 --%>
					<c:when test="${sessionScope.SESSION_ID eq 'admin' || sessionScope.SESSION_NAME eq '관리자'}">
						<div style="display: flex; gap: 10px; width: 100%; align-items: center;">
							<textarea id="QNA_ANSWER_INPUT" rows="3" style="width: 85%; padding: 8px; border: 1px solid #ccc; font-size: 14px; resize: none;" placeholder="관리자 답변을 입력해 주세요.">${map.QNA_AN}</textarea>
							<button type="button" id="btn_submit_answer" class="btn" style="width: 12%; height: 55px; background-color: #2b2b2b; color: white; border: none; font-size: 14px; font-weight: bold; cursor: pointer; border-radius: 4px;">답변등록</button>
						</div>
					</c:when>
					<%-- 일반 사용자단 접속 시: 기존처럼 등록된 답변 바인딩 출력 --%>
					<c:otherwise>
						<font color="blue" size="5px">${map.QNA_AN}</font>
					</c:otherwise>
				</c:choose>
			</td>
		</tr>
	</table>
	<br />

	<p>
		<a href="/qna/openQnaList.do" class="btn" id="list">목록으로</a> <a href="#this"
			style="display: none;" class="btn" id="update">수정/답변하기</a>
	</p>

	<form id="commonForm" name="commonForm"></form>
	<script type="text/javascript">
		$(document).ready(function() {
			$("#list").on("click", function(e) { //목록으로 버튼
				e.preventDefault();
				fn_openQnaList();
			});

			$("#update").on("click", function(e) { //수정하기 버튼
				e.preventDefault();
				fn_openQnaUpdate();
			});
			
			// 🌟 [신규 추가] 관리자 답변 작성 후 [답변등록] 버튼 클릭 시 백엔드 42번 API 연동 처리
			$("#btn_submit_answer").on("click", function(e) {
				e.preventDefault();
				
				var answerText = $("#QNA_ANSWER_INPUT").val();
				var qnaIdNum = "${map.QNA_NO}"; // 백엔드가 넘겨준 글 고유 번호
				
				if($.trim(answerText) == "") {
					alert("답변 내용을 입력해 주세요.");
					return false;
				}
				
				if(!confirm("이 Q&A 게시글에 답변을 저장하시겠습니까?")) {
					return false;
				}
				
				// QnaController에 만들어둔 명세서 호환용 매핑 주소로 비동기(Ajax) 전송
				$.ajax({
					url : "<c:url value='/qna/updateQnaAnswer.do'/>",
					type : "POST",
					data : {
						qnaId : qnaIdNum,
						answer : answerText
					},
					success : function(data) {
						alert("답변이 성공적으로 등록되었습니다.");
						window.location.reload(); // 성공 시 즉시 페이지 리로드하여 결과 렌더링
					},
					error : function(xhr, status, error) {
						alert("답변 등록 중 통신 오류가 발생했습니다.");
					}
				});
			});

	<%
	// 💡 [2차 안전 연산] trim()을 수행하기 전 한 번 더 null 체크 안전성 보장
	if (sessionId != null && sessionId.trim().equals("admin")) {
	%>
		$("#update").show();
	<%
	} else {
		
	}
	%>
		});

		function fn_openQnaList() {
			var comSubmit = new ComSubmit();
			comSubmit.setUrl("<c:url value='/qna/openQnaList.do' />");
			comSubmit.submit();
		}

		function fn_openQnaUpdate() {
			var idx = "${map.QNA_NO}";
			var comSubmit = new ComSubmit();
			comSubmit.setUrl("<c:url value='/qna/openQnaUpdate.do' />");
			comSubmit.addParam("QNA_NO", idx);
			comSubmit.submit();
		}

		function init() {
			fn_QNA_GUBUN();
		}
		function fn_QNA_GUBUN() {
			var gubn = "${map.QNA_CATEGORY}";
			html = ''
			if (gubn == "61") {
				html += '<span>상품문의 드려요~♥</span>';
				$("#qna_gubunaa").append(html);
			} else if (gubn == "62") {
				html += '<span>배송문의 드려요~♥</span>';
				$("#qna_gubunaa").append(html);
			} else if (gubn == "63") {
				html += '<span>배송전 변경, 취소 문의드려요~♥</span>';
				$("#qna_gubunaa").append(html);
			} else if (gubn == "64") {
				html += '<span>교환, 반품 문의드려요~♥</span>';
				$("#qna_gubunaa").append(html);
			} else if (gubn == "65") {
				html += '<span>입금결제 문의드려요~♥</span>';
				$("#qna_gubunaa").append(html);
			} else if (gubn == "66") {
				html += '<span>기타문의드려요~♥</span>';
				$("#qna_gubunaa").append(html);
			}
		}

		init();
	</script>
</body>
</html>