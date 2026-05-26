<%@ page language="java" contentType="text/html; charset=UTF-8"
   pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="ko">
<head>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>
<%@ taglib prefix="ui" uri="http://tiles.apache.org/tags-tiles"%>
<link rel="stylesheet" type="text/css" href="<c:url value='/css/uii.css'/>" />

<!-- jQuery -->
<script
   src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>
<script src="<c:url value='/js/commonn.js'/>" charset="utf-8"></script>
</head>
<style>
.wrapper3 {
   max-width: 1000px;
   margin: 0 auto;
}

h1 {
    text-align: center;
  padding: 50px 0;
  font-weight: normal;
  font-size: 2em;
  letter-spacing: 10px;
}

li {
   list-style: none;
   float: left;
}

.bar {
   height: 1.5px;
   width: 100%;
   background-color: #DCDCDC;
}

.flex-menu li {
   text-align: center;
   width: 100%;
}
</style>
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
            <li><a href="/faq/openFaqList.do">FAQ</a></li>
         <li><a href="/notice/openNoticeList.do">공지사항</a></li>
         <li><a href="/qna/openQnaList.do" class="tab-active">Q&amp;A</a></li>
      </ul>
   </div>

   <br />
   <br />
   <br />
   <h2 align="center">Q&A</h2>
   <br />
   <br />

   <table class="board_list">
      <colgroup>
         <col width="10%" />
         <col width="*" />
         <col width="20%" />
         <col width="20%" />
      </colgroup>
      <thead>
         <tr>
            <th scope="col">글번호</th>
            <th scope="col">제목</th>
            <th scope="col">글쓴이</th>
            <th scope="col">작성일</th>
         </tr>
      </thead>
      <tbody>

      </tbody>
   </table>
   <br>
   <div class="pageNumber" id="PAGE_NAVI"></div>
   <input type="hidden" id="PAGE_INDEX" name="PAGE_INDEX" />

   <br />
   <p>
      <a href="#this" class="btn" id="write">글쓰기</a>
   </p>

   <form id="commonForm" name="commonForm"></form>
   <script type="text/javascript">
      $(document).ready(function() {
         fn_selectQnaList(1);
         $("#write").on("click", function(e) { //글쓰기 버튼
            e.preventDefault();
            fn_openQnaWrite();
         });
         
         /* 🌟 [수정] 이벤트 위임 방식으로 변경: Ajax로 동적 생성되는 요소에도 클릭 이벤트가 정상 적용되도록 처리 */
         $(document).on("click", ".myButton", function(e) { // 비밀글 확인 버튼
            e.preventDefault();
            
            var $this = $(this);
            var rnumClass = $this.attr('class').split(' ')[1]; // 예: "rnum3"
            var rnumNum = rnumClass.replace('rnum', '');
            var qnaPass = $('#qnaPasswd' + rnumNum).val();
            var qnaNo = $('input.qnaNo.row' + rnumNum).val();
            
            var data = { QNA_PASSWD : qnaPass, QNA_NO : qnaNo };
            
            $.ajax({
               url : "<c:url value='/qna/chkPassword.do'/>",
               type : 'POST',
               data : data,
               success : function(res) {
                  if (res == 1) {
                     fn_openQnaDetail(qnaNo, rnumNum);
                  } else {
                     alert("PASSWORD ERROR!");
                  }
               },
               error : function() {
                  alert("비밀번호 확인 중 오류가 발생했습니다.");
               }
            });
         });
      });

      function fn_openQnaWrite() {
         var comSubmit = new ComSubmit();
         comSubmit.setUrl("<c:url value='/qna/openQnaWrite.do' />");
         comSubmit.submit();
      }
      
      function fn_openQnaDetail(qna_no, rnum){
         var comSubmit = new ComSubmit();
         comSubmit.setUrl("<c:url value='/qna/openQnaDetail.do' />");
         comSubmit.addParam("QNA_NO", qna_no);
         comSubmit.addParam("QNA_ID", qna_no); /* 🌟 [추가] 백엔드 매핑 안정성 강화 */
         comSubmit.addParam("RNUM", rnum);
         comSubmit.submit();
      }

      function fn_selectQnaList(pageNo) {
         var comAjax = new ComAjax();
         comAjax.setUrl("<c:url value='/qna/selectQnaList.do' />");
         comAjax.setCallback("fn_selectQnaListCallback");
         comAjax.addParam("PAGE_INDEX", $("#PAGE_INDEX").val());
         comAjax.addParam("PAGE_ROW", 10);
         comAjax.addParam("QNA_NO_FE", $("#QNA_NO_FE").val());
         comAjax.ajax();
      }

      function fn_selectQnaListCallback(data) {
         var total = data.TOTAL;
         var body = $("table>tbody");
         body.empty();
         if (total == 0) {
            var str = "<tr>" + "<td colspan='4'>조회된 결과가 없습니다.</td>"
                  + "</tr>";
            body.append(str);
         } else {
            var params = {
               divId : "PAGE_NAVI",
               pageIndex : "PAGE_INDEX",
               totalCount : total,
               recordCount : 10,
               eventName : "fn_selectQnaList"
            };
            gfn_renderPaging(params);
            
            /* 🌟 [버그수정] str 변수 선언 누락 보정 */
            var str = '';
            
            $.each(data.list, function(key, value){
               str += '<tr class="list' + value.RNUM + '">'  + 
                        "<td id='rnum" + value.RNUM + "' >" + value.RNUM + "</td>" + 
                        "<td class='title'>" +
                           "<a href='#this' class='chk"+ value.RNUM +"' name='title'>" + value.QNA_TITLE + "</a>" +
                           "<input type='hidden' name='title' class='qnaNo row" + value.RNUM + "' value='" + value.QNA_NO + "'>" + 
                        "</td>" +
                        "<td>" + value.QNA_NAME + "</td>" + 
                        "<td>" + value.QNA_DATE + "</td> </tr><tr>";
               str += '<td style="display:none;" id="chk' + value.RNUM + '" class="list' + value.RNUM + '" colspan="4">Password : ';
               str += '<input type="password" id="qnaPasswd' + value.RNUM + '" value="">';
               str += '<a href="#" class="myButton rnum' + value.RNUM + '">확인</a>';
               str += '</td></tr>';
            });
            body.append(str);
            
            /* 🌟 [수정] 제목 클릭: 비밀번호 영역 토글 후 즉시 상세조회로 진입 */
            $("a[name='title']").off("click").on("click", function(e){
               e.preventDefault();
               
               /* 같은 행(tr)의 hidden input에서 QNA_NO 추출 */
               var $a = $(this);
               var qnaNo = $a.siblings('input.qnaNo').val();
               var chkClass = $a.attr('class'); /* 예: "chk3" */
               var rnumNum = chkClass.replace('chk', '');
               
               /* 비밀번호 입력 영역 토글 */
               var $pwTd = $("#" + chkClass);
               if ($pwTd.is(":visible")) {
                  $pwTd.hide();
               } else {
                  $pwTd.show();
                  /* 🌟 [신규] 토글과 동시에 바로 상세조회 진입 (비밀번호 미입력 케이스 처리) */
                  fn_openQnaDetail(qnaNo, rnumNum);
               }
            });
         }
      }
   </script>
</body>
</html>