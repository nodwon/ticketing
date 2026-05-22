<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>관제 티켓</title>
<style>
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: 'Malgun Gothic', sans-serif; }
a { text-decoration: none; color: inherit; }

.header { background: #0a0a0a; color: #fff; }

/* 상단 바 */
.header-top { border-bottom: 1px solid #222; padding: 6px 0; }
.header-top-inner { max-width: 1200px; margin: 0 auto; padding: 0 20px; display: flex; justify-content: space-between; align-items: center; }
.header-top-left { display: flex; gap: 16px; }
.header-top-left a { color: #aaa; font-size: 12px; }
.header-top-left a:hover { color: #fff; }
.header-top-right { display: flex; gap: 16px; align-items: center; }
.header-top-right a { color: #aaa; font-size: 12px; }
.header-top-right a:hover { color: #fff; }

/* 로고 + 검색 + 아이콘 */
.header-main { padding: 14px 0; }
.header-main-inner { max-width: 1200px; margin: 0 auto; padding: 0 20px; display: flex; align-items: center; justify-content: space-between; gap: 24px; }

.logo { display: flex; flex-direction: column; line-height: 1; }
.logo-team { font-size: 10px; color: #888; letter-spacing: 3px; }
.logo-name { font-size: 26px; font-weight: 700; color: #fff; letter-spacing: 2px; }
.logo-sub { font-size: 10px; color: #666; letter-spacing: 1px; }

.header-search { flex: 1; max-width: 420px; }
.header-search form { display: flex; border: 1px solid #444; border-radius: 4px; overflow: hidden; }
.header-search input { flex: 1; background: #1a1a1a; border: none; padding: 8px 14px; color: #fff; font-size: 13px; outline: none; }
.header-search input::placeholder { color: #666; }
.header-search button { background: #e8001c; border: none; padding: 8px 14px; color: #fff; cursor: pointer; font-size: 16px; }

.header-nav-right { display: flex; gap: 20px; align-items: center; }
.header-nav-right a { color: #ccc; font-size: 12px; display: flex; flex-direction: column; align-items: center; gap: 3px; }
.header-nav-right a .icon { font-size: 22px; }
.header-nav-right a:hover { color: #e8001c; }

/* GNB */
.gnb { background: #0a0a0a; border-top: 1px solid #222; }
.gnb-inner { max-width: 1200px; margin: 0 auto; padding: 0 20px; display: flex; }
.gnb a { color: #ccc; font-size: 14px; padding: 12px 18px; display: block; white-space: nowrap; border-bottom: 2px solid transparent; }
.gnb a:hover, .gnb a.active { color: #fff; border-bottom-color: #e8001c; }
</style>
</head>
<body>

<div class="header">

  <!-- 상단 바 -->
  <div class="header-top">
    <div class="header-top-inner">
      <div class="header-top-left">
        <a href="/notice/openNoticeList.do">공지사항</a>
        <a href="/faq/openFaqList.do">고객센터</a>
      </div>
      <div class="header-top-right">
        <c:choose>
          <c:when test="${SESSION_NO eq null}">
            <a href="/joinForm.do">회원가입</a>
            <a href="/loginForm.do">마이페이지</a>
          </c:when>
          <c:otherwise>
            <a href="#">Hi, ${SESSION_NAME}님!</a>
            <a href="#" onclick="signOut();">로그아웃</a>
            <a href="/myOrderList.do">마이페이지</a>
          </c:otherwise>
        </c:choose>
      </div>
    </div>
  </div>

  <!-- 로고 + 검색 + 메뉴 아이콘 -->
  <div class="header-main">
    <div class="header-main-inner">

      <a href="/main.do" class="logo">
        <span class="logo-team">TEAM JANUS</span>
        <span class="logo-name">관제 티켓</span>
        <span class="logo-sub">Guardian of Beginnings and Endings</span>
      </a>

      <div class="header-search">
        <form method="post" action="/shop/openMainSearch.do">
          <input type="text" name="keyword" placeholder="공연명, 아티스트, 장르 검색" value="${keyword1}" />
          <button type="submit">&#128269;</button>
        </form>
      </div>

      <div class="header-nav-right">
        <a href="/myOrderList.do">
          <span class="icon">🎫</span>
          <span>예매내역</span>
        </a>
        <a href="/basket/basketList.do">
          <span class="icon">🛒</span>
          <span>장바구니</span>
        </a>
        <a href="/qna/openQnaList.do">
          <span class="icon">💬</span>
          <span>Q&amp;N</span>
        </a>
        <c:choose>
          <c:when test="${SESSION_NO eq null}">
            <a href="/loginForm.do">
              <span class="icon">👤</span>
              <span>로그인</span>
            </a>
          </c:when>
          <c:otherwise>
            <a href="/myOrderList.do">
              <span class="icon">👤</span>
              <span>마이페이지</span>
            </a>
          </c:otherwise>
        </c:choose>
      </div>

    </div>
  </div>

  <!-- GNB 메뉴 -->
  <nav class="gnb">
    <div class="gnb-inner">
      <a href="/concert/list.do">콘서트</a>
      <a href="/musical/list.do">뮤지컬</a>
      <a href="/play/list.do">연극</a>
      <a href="/classic/list.do">클래식/무용</a>
      <a href="/exhibition/list.do">전시/스포츠</a>
      <a href="/family/list.do">가족/어린이</a>
      <a href="/ranking/list.do">랭킹</a>
      <a href="/event/list.do">이벤트</a>
    </div>
  </nav>

</div>
