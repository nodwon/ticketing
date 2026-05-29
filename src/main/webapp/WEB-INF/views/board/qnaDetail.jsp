<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%
	// 비밀글 접근 제어 — HTML 출력 전에 처리해야 redirect가 동작함
	Object _mapAttr = request.getAttribute("map");
	if (_mapAttr instanceof java.util.Map) {
		java.util.Map _dm = (java.util.Map) _mapAttr;
		Object _isSecret = _dm.get("IS_SECRET");
		int _secretVal = 0;
		if (_isSecret != null) {
			try { _secretVal = Integer.parseInt(String.valueOf(_isSecret).split("\\.")[0]); } catch (Exception _e) {}
		}
		if (_secretVal == 1) {
			String _adminName = (String) session.getAttribute("SESSION_NAME");
			if (!"관리자".equals(_adminName)) {
				response.sendRedirect(request.getContextPath() + "/qna/openQnaList.do?accessDenied=1");
				return;
			}
		}
	}
%>
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
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>
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

/* 🌟 [신규] 첨부파일 영역 스타일 */
.attach-list { padding: 5px 0; }
.attach-list .file-item {
    display: inline-block;
    margin: 3px 8px 3px 0;
    padding: 5px 10px;
    background-color: #f5f5f5;
    border: 1px solid #ddd;
    border-radius: 3px;
    font-size: 13px;
}
.attach-list .file-item a {
    color: #2b2b2b;
    font-weight: 500;
}
.attach-list .file-item a:hover {
    color: #c00;
    text-decoration: underline;
}
.attach-list .file-size {
    color: #888;
    margin-left: 6px;
    font-size: 12px;
}
.attach-empty {
    color: #999;
    font-style: italic;
    padding: 5px 0;
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
			
			<%-- 🌟 [신규 추가] 첨부파일 표시 영역 --%>
			<tr>
				<th scope="row">첨부파일</th>
				<td colspan="4" align="left">
					<div class="attach-list">
						<c:choose>
							<c:when test="${empty list}">
								<span class="attach-empty">첨부파일이 없습니다.</span>
							</c:when>
							<c:otherwise>
								<c:forEach var="row" items="${list}">
									<span class="file-item">
										<a href="<c:url value='/qna/downloadFile.do'/>?fileId=${row.FILE_ID}">
											${row.ORIGINAL_FILE_NAME}
										</a>
										<a href="<c:url value='/upload/'/>${row.UPLOAD_SAVE_NAME}">[직접열기]</a>
										<span class="file-size">
											<c:choose>
												<c:when test="${row.FILE_SIZE >= 1048576}">
													(<fmt:formatNumber value="${row.FILE_SIZE / 1048576}" pattern="#,##0.0"/> MB)
												</c:when>
												<c:when test="${row.FILE_SIZE >= 1024}">
													(<fmt:formatNumber value="${row.FILE_SIZE / 1024}" pattern="#,##0"/> KB)
												</c:when>
												<c:otherwise>
													(${row.FILE_SIZE} B)
												</c:otherwise>
											</c:choose>
										</span>
									</span>
								</c:forEach>
							</c:otherwise>
						</c:choose>
					</div>
				</td>
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