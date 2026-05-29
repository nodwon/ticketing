<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<meta charset="UTF-8" />
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta name="viewport" content="width=device-width, initial-scale=1">
<link rel="stylesheet" href="/css/login.css">
<link rel="stylesheet" href="//cdn.jsdelivr.net/npm/xeicon@2.3.3/xeicon.min.css">
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.2/js/bootstrap.min.js"></script>

<style>
#loginform {
	width: 500px;
	margin: 0 auto;
	margin-top: 50px;
	text-align: center;
	margin-bottom: 100px
}

.contents {
	font-size : 40px;
}

.logintable>#frm>a {
	float: right;
	padding-left: 24px;
}

.logintable>#frm>.form-control {
	width: 100%;
	height: 50px;
	border: 1px solid #e0e0e0;
	margin-bottom: 20px;
}

#login {
	width: 100%;
	height: 50px;
	display: block;
	border: none;
	margin-top: 10px;
	font-size: 20px;
}


h1 {
	text-align: center;
	padding: 50px 0;
	font-weight: normal;
	font-size: 2em;
	letter-spacing: 10px;
}

</style>


	<div id="loginform">
		<h3 class="contents">로그인</h3>
		<div class="logintable">
		<form action="/loginAction.do" method="POST" id="frm">
			<input type="hidden" name="returnUrl" value="${returnUrl}">
			<input type="text" class="form-control" name="MEMBER_ID"
    			id="MEMBER_ID" placeholder="이메일">
			<input type="password" class="form-control" name="MEMBER_PASSWD"
				id="MEMBER_PASSWD" placeholder="비밀번호">
			<a href="/findPw.do">비밀번호
					재설정</a>
			<a href="/findId.do">아이디
					찾기</a>
			<button type="submit" class="defaultBtn loginBtn" id="login">로그인</button>
		</form>
			<p>
			아직 회원이 아니신가요? <a href="/joinForm.do">회원가입하기</a>

		</p>

		</div>



	</div>


<script type="text/javascript">
if('${message}' != "") {
	alert('${message}');
}
//공란 확인
$(document).ready(function() {

	$("#login").unbind("click").click(function(e) {
		e.preventDefault();
		fn_login();
	});

	function fn_login() {
		if($("#MEMBER_ID").val()==""){
			alert("이메일을 입력해주세요");
			$("#MEMBER_ID").focus();
		} else if($("#MEMBER_PASSWD").val()==""){
			alert("비밀번호를 입력해주세요");
			$("#MEMBER_PASSWD").focus();
		} else {
			$("#frm").submit();
		}
	}
});
</script>
