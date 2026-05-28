<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%
	String sessionId    = (String) session.getAttribute("SESSION_ID");
	String sessionName  = (String) session.getAttribute("SESSION_NAME");
	String sessionGrade = (String) session.getAttribute("SESSION_GRADE");
	if (sessionId    == null) sessionId    = "";
	if (sessionName  == null) sessionName  = "";
	if (sessionGrade == null) sessionGrade = "";
	boolean isLogin = !sessionId.isEmpty();
	boolean isAdmin = "ADMIN".equals(sessionGrade);  // ← GRADE로 체크
%>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@300;400;500;700;900&family=Montserrat:wght@600;700;800&display=swap" rel="stylesheet">
<style>
*, *::before, *::after { margin:0; padding:0; box-sizing:border-box; }
body { font-family: 'Noto Sans KR', sans-serif; }
a { text-decoration: none; color: inherit; }

/* ── 상단 유틸 바 ── */
.hd-top {
    background: #111; border-bottom: 1px solid #222;
    padding: 6px 0;
}
.hd-top-inner {
    max-width: 1280px; margin: 0 auto; padding: 0 24px;
    display: flex; justify-content: space-between; align-items: center;
}
.hd-top a { font-size: 12px; color: #888; margin-left: 16px; transition: color .2s; }
.hd-top a:first-child { margin-left: 0; }
.hd-top a:hover { color: #fff; }

/* ── 메인 헤더 ── */
.hd-main {
    background: #0a0a0a;
    border-bottom: 2px solid #e8001c;
    position: sticky; top: 0; z-index: 999;
}
.hd-main-inner {
    max-width: 1280px; margin: 0 auto; padding: 0 24px;
    display: flex; align-items: center; justify-content: space-between;
    height: 64px; gap: 24px;
}

/* 로고 */
.hd-logo {
    font-family: 'Montserrat', sans-serif;
    font-size: 22px; font-weight: 800;
    letter-spacing: 3px; color: #fff;
    white-space: nowrap; flex-shrink: 0;
}
.hd-logo span { color: #e8001c; }
.hd-logo small {
    display: block; font-family: 'Noto Sans KR', sans-serif;
    font-size: 9px; font-weight: 300;
    letter-spacing: 3px; color: #666; margin-top: 1px;
}

/* GNB */
.hd-gnb { display: flex; align-items: center; flex: 1; justify-content: center; }
.hd-gnb a {
    position: relative; padding: 0 14px; height: 64px;
    display: flex; align-items: center;
    font-size: 13px; font-weight: 600;
    color: #bbb; letter-spacing: 0.5px;
    white-space: nowrap; transition: color .2s;
}
.hd-gnb a::after {
    content: ''; position: absolute;
    bottom: 0; left: 0; right: 0; height: 2px;
    background: #e8001c;
    transform: scaleX(0); transition: transform .2s;
}
.hd-gnb a:hover, .hd-gnb a.active { color: #fff; }
.hd-gnb a:hover::after, .hd-gnb a.active::after { transform: scaleX(1); }

/* 우측 유틸 */
.hd-util { display: flex; align-items: center; gap: 6px; flex-shrink: 0; }

/* 일반 유저용 아이콘 버튼 */
.hd-icon-btn {
    display: flex; flex-direction: column;
    align-items: center; gap: 2px;
    padding: 6px 10px; cursor: pointer;
    color: #aaa; font-size: 11px;
    transition: color .2s; border-radius: 4px;
}
.hd-icon-btn .ico { font-size: 20px; }
.hd-icon-btn:hover { color: #e8001c; }

/* 텍스트 버튼 */
.hd-btn {
    font-size: 12px; font-weight: 600;
    letter-spacing: 0.5px; color: #aaa;
    padding: 6px 12px; border-radius: 2px;
    border: 1px solid #333; cursor: pointer;
    transition: all .2s; white-space: nowrap;
}
.hd-btn:hover { color: #fff; border-color: #666; }
.hd-btn.primary { background: #e8001c; color: #fff; border-color: #e8001c; }
.hd-btn.primary:hover { background: #c00016; }

/* 관리자 전용 */
.hd-admin-bar {
    display: flex; align-items: center; gap: 6px;
}
.hd-admin-label {
    font-size: 11px; font-weight: 700;
    color: #e8001c; letter-spacing: 2px;
    border: 1px solid #e8001c;
    padding: 3px 8px; border-radius: 2px;
    white-space: nowrap;
}
.hd-welcome {
    font-size: 12px; color: #aaa;
    white-space: nowrap;
}
.hd-welcome strong { color: #fff; }
</style>

<div class="hd-top">
    <div class="hd-top-inner">
        <div>
            <a href="/notice/openNoticeList.do">공지사항</a>
            <a href="/faq/openFaqList.do">고객센터</a>
        </div>
    </div>
</div>

<div class="hd-main">
    <div class="hd-main-inner">
        <!-- 로고 -->

        <!-- 로고 -->
        <a href="/main.do" class="hd-logo">
            GWANJE<span>TICKET</span>
            <small>관제 티켓</small>
        </a>

        <!-- GNB -->
        <nav class="hd-gnb">
		    <a href="/concert/list.do" class="active">콘서트</a>
		    <a href="/concert/list.do">뮤지컬</a>
		    <a href="/concert/list.do">연극</a>
		    <a href="/concert/list.do">클래식/무용</a>
		    <a href="/concert/list.do">전시/스포츠</a>
		    <a href="/concert/list.do">가족/어린이</a>
		</nav>

        <!-- 우측 유틸 -->
        <div class="hd-util">
            <%if (!isLogin) {%>
                <!-- 비로그인 -->
                <a href="/my/bookingList.do" class="hd-icon-btn"><span class="ico">🎫</span><span>예매내역</span></a>
                <a href="/qna/openQnaList.do" class="hd-icon-btn"><span class="ico">💬</span><span>Q&amp;A</span></a>
                <a href="/loginForm.do" class="hd-btn">로그인</a>
    			<a href="/joinForm.do" class="hd-btn primary">회원가입</a>
            <%} else if (isAdmin) {%>
                <!-- 관리자 -->
                <div class="hd-admin-bar">
                    <span class="hd-welcome">Hi, <strong><%=sessionName%></strong>님</span>
                    <span class="hd-admin-label">ADMIN</span>
					<a href="/admin/main.do" class="hd-btn primary">관리자 홈</a>
					<a href="/admin/member/list.do" class="hd-btn">회원관리</a>
					<a href="/admin/concert/list.do" class="hd-btn">공연관리</a>
                    <a href="#" onclick="signOut(); return false;" class="hd-btn">로그아웃</a>
                </div>

            <%} else {%>
                <!-- 일반 로그인 -->
                <span style="font-size:12px;color:#aaa;white-space:nowrap;">Hi, <strong style="color:#fff;"><%=sessionName%></strong>님</span>
                <a href="/my/bookingList.do" class="hd-icon-btn"><span class="ico">🎫</span><span>예매내역</span></a>
                <a href="/basket/basketList.do" class="hd-icon-btn"><span class="ico">🛒</span><span>장바구니</span></a>
                <a href="/qna/openQnaList.do" class="hd-icon-btn"><span class="ico">💬</span><span>Q&amp;A</span></a>
                <a href="/my/info.do" class="hd-icon-btn"><span class="ico">👤</span><span>마이페이지</span></a>
                <a href="#" onclick="signOut(); return false;" class="hd-btn">로그아웃</a>
            <%}%>
        </div>

    </div>
</div>

<script>
function signOut() {
    $.ajax({
        url: '/logout.do',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify({}),
        success: function(data) { location.href = data.URL || '/main.do'; },
        error:   function()     { location.href = '/main.do'; }
    });
}
/* GNB active 표시 */
(function() {
    var path = location.pathname;
    document.querySelectorAll('.hd-gnb a').forEach(function(a) {
        a.classList.remove('active');
    });
    var first = document.querySelector('.hd-gnb a');
    if (first) first.classList.add('active');
})();
</script>
