<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>
<%
    String sessionId   = (String) session.getAttribute("SESSION_ID");
    String sessionName = (String) session.getAttribute("SESSION_NAME");
    if (sessionId   == null) sessionId   = "";
    if (sessionName == null) sessionName = "";
    boolean isLogin = !sessionId.isEmpty();
    boolean isAdmin = "admin".equals(sessionId);
%>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>관제 티켓 – GWANJE TICKET</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@300;400;500;700;900&family=Bebas+Neue&family=Montserrat:wght@400;600;700;800&display=swap" rel="stylesheet">
<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/bxslider/4.2.12/jquery.bxslider.css">
<script src="https://cdn.jsdelivr.net/bxslider/4.2.12/jquery.bxslider.min.js"></script>
<style>
:root {
    --red:    #e8001c;
    --dark:   #0a0a0a;
    --mid:    #1a1a1a;
    --gray:   #f4f4f4;
    --border: #e0e0e0;
    --text:   #222;
    --muted:  #888;
    --white:  #fff;
    --font-en: 'Montserrat', 'Bebas Neue', sans-serif;
    --font-kr: 'Noto Sans KR', sans-serif;
}
*, *::before, *::after { margin:0; padding:0; box-sizing:border-box; }
html { scroll-behavior: smooth; }
body { font-family: var(--font-kr); background: var(--white); color: var(--text); }
a { text-decoration: none; color: inherit; }
ul { list-style: none; }
img { display: block; }

/* ═══════════════════════════════════
   HEADER / NAV
═══════════════════════════════════ */
.site-header {
    position: sticky; top: 0; z-index: 999;
    background: var(--dark);
    border-bottom: 2px solid var(--red);
}
.header-inner {
    max-width: 1280px; margin: 0 auto;
    padding: 0 24px;
    display: flex; align-items: center; justify-content: space-between;
    height: 64px;
}
.logo {
    font-family: var(--font-en);
    font-size: 26px; font-weight: 800;
    letter-spacing: 4px; color: var(--white);
    display: flex; align-items: center; gap: 10px;
}
.logo span { color: var(--red); }
.logo .logo-sub {
    font-family: var(--font-kr);
    font-size: 10px; font-weight: 300;
    letter-spacing: 3px; color: #aaa;
    display: block; line-height: 1.2;
    margin-top: 2px;
}

.gnb { display: flex; align-items: center; gap: 6px; }
.gnb-item {
    position: relative;
    padding: 0 14px; height: 64px;
    display: flex; align-items: center;
    font-size: 13px; font-weight: 600;
    color: #ccc; letter-spacing: 1px;
    transition: color .2s;
    cursor: pointer;
}
.gnb-item:hover, .gnb-item.active { color: var(--white); }
.gnb-item::after {
    content: ''; position: absolute;
    bottom: 0; left: 0; right: 0;
    height: 2px; background: var(--red);
    transform: scaleX(0); transition: transform .2s;
}
.gnb-item:hover::after, .gnb-item.active::after { transform: scaleX(1); }

.header-util {
    display: flex; align-items: center; gap: 16px;
}
.util-btn {
    font-size: 12px; font-weight: 600;
    letter-spacing: 1px; color: #aaa;
    padding: 6px 14px; border-radius: 2px;
    border: 1px solid #333; cursor: pointer;
    transition: all .2s;
}
.util-btn:hover { color: var(--white); border-color: var(--white); }
.util-btn.primary {
    background: var(--red); color: var(--white);
    border-color: var(--red);
}
.util-btn.primary:hover { background: #c00016; }

/* ═══════════════════════════════════
   CATEGORY BAR
═══════════════════════════════════ */
.cat-bar {
    background: var(--white);
    border-bottom: 1px solid var(--border);
}
.cat-inner {
    max-width: 1280px; margin: 0 auto;
    padding: 0 24px;
    display: flex; gap: 0;
    overflow-x: auto;
}
.cat-inner::-webkit-scrollbar { display: none; }
.cat-item {
    flex-shrink: 0;
    padding: 14px 20px;
    font-size: 13px; font-weight: 600;
    color: var(--muted); cursor: pointer;
    border-bottom: 2px solid transparent;
    transition: all .2s; white-space: nowrap;
}
.cat-item:hover { color: var(--text); }
.cat-item.active { color: var(--red); border-bottom-color: var(--red); }

/* ═══════════════════════════════════
   HERO SLIDER
═══════════════════════════════════ */
.hero-slider-wrap {
    position: relative;
    background: var(--dark);
    overflow: hidden;
}

/* SVG로 만든 배너 대용 - canvas 기반 */
.hero-slide {
    width: 100%; height: 480px;
    display: flex; align-items: center; justify-content: center;
    position: relative; overflow: hidden;
}
.slide-bg {
    position: absolute; inset: 0;
    background-size: cover; background-position: center;
}
.slide-overlay {
    position: absolute; inset: 0;
    background: linear-gradient(90deg, rgba(0,0,0,.7) 0%, rgba(0,0,0,.2) 60%, transparent 100%);
}
.slide-content {
    position: relative; z-index: 2;
    max-width: 1280px; width: 100%; margin: 0 auto;
    padding: 0 60px;
}
.slide-tag {
    display: inline-block;
    background: var(--red); color: var(--white);
    font-size: 11px; font-weight: 700;
    letter-spacing: 3px; padding: 5px 12px;
    margin-bottom: 16px;
}
.slide-title {
    font-family: var(--font-kr);
    font-size: 48px; font-weight: 900;
    color: var(--white); line-height: 1.2;
    margin-bottom: 12px;
}
.slide-subtitle {
    font-size: 16px; color: rgba(255,255,255,.75);
    font-weight: 400; margin-bottom: 28px;
}
.slide-btn {
    display: inline-flex; align-items: center; gap: 8px;
    background: var(--white); color: var(--dark);
    font-size: 13px; font-weight: 700;
    padding: 12px 28px; letter-spacing: 1px;
    transition: all .25s; cursor: pointer;
}
.slide-btn:hover { background: var(--red); color: var(--white); }

/* bxslider 커스텀 */
.bx-wrapper { box-shadow: none !important; border: none !important; background: none !important; margin: 0 !important; }
.bx-wrapper .bx-controls-direction a {
    width: 44px; height: 44px; margin-top: -22px;
    background: rgba(255,255,255,.1);
    border: 1px solid rgba(255,255,255,.2);
    border-radius: 2px;
    display: flex; align-items: center; justify-content: center;
}
.bx-wrapper .bx-prev { left: 20px; }
.bx-wrapper .bx-next { right: 20px; }
.bx-wrapper .bx-prev::before { content: '‹'; font-size: 28px; color: #fff; }
.bx-wrapper .bx-next::before { content: '›'; font-size: 28px; color: #fff; }
.bx-wrapper .bx-pager { bottom: 16px; }
.bx-wrapper .bx-pager-item a {
    width: 8px; height: 8px; background: rgba(255,255,255,.4); border-radius: 50%;
}
.bx-wrapper .bx-pager-item a.active { background: var(--red); width: 24px; border-radius: 4px; }

/* ═══════════════════════════════════
   QUICK LINKS
═══════════════════════════════════ */
.quick-section {
    background: var(--dark);
    border-top: 1px solid #222;
    padding: 0;
}
.quick-inner {
    max-width: 1280px; margin: 0 auto;
    padding: 0 24px;
    display: grid; grid-template-columns: repeat(6, 1fr);
}
.quick-item {
    padding: 20px 0;
    display: flex; flex-direction: column;
    align-items: center; gap: 8px;
    border-right: 1px solid #222;
    cursor: pointer; transition: background .2s;
}
.quick-item:last-child { border-right: none; }
.quick-item:hover { background: #1a1a1a; }
.quick-icon {
    width: 36px; height: 36px;
    display: flex; align-items: center; justify-content: center;
    font-size: 22px;
}
.quick-label { font-size: 12px; color: #aaa; font-weight: 500; letter-spacing: 1px; }

/* ═══════════════════════════════════
   SECTION COMMON
═══════════════════════════════════ */
.section { max-width: 1280px; margin: 0 auto; padding: 56px 24px 60px; }
.section-header {
    display: flex; align-items: flex-end; justify-content: space-between;
    margin-bottom: 28px;
}
.section-title {
    font-family: var(--font-kr);
    font-size: 22px; font-weight: 900;
    letter-spacing: 2px; color: var(--dark);
    display: flex; align-items: center; gap: 12px;
}
.section-title .en {
    font-family: var(--font-en);
    font-size: 13px; font-weight: 600;
    color: var(--red); letter-spacing: 4px;
    border: 1px solid var(--red);
    padding: 2px 8px;
}
.section-more {
    font-size: 12px; color: var(--muted); font-weight: 500;
    letter-spacing: 1px; display: flex; align-items: center; gap: 4px;
    cursor: pointer; transition: color .2s;
}
.section-more:hover { color: var(--red); }
.section-more::after { content: '›'; font-size: 16px; }

.section-divider { border: none; border-top: 8px solid #f4f4f4; margin: 0; }

/* ═══════════════════════════════════
   POSTER GRID
═══════════════════════════════════ */
.poster-grid {
    display: grid;
    grid-template-columns: repeat(5, 1fr);
    gap: 16px;
}
.poster-grid.col6 { grid-template-columns: repeat(6, 1fr); }

.poster-card {
    cursor: pointer;
    transition: transform .25s;
}
.poster-card:hover { transform: translateY(-4px); }

.poster-thumb {
    position: relative;
    aspect-ratio: 3/4;
    overflow: hidden;
    background: #e8e8e8;
    border-radius: 4px;
    margin-bottom: 10px;
}
.poster-thumb canvas,
.poster-thumb img {
    width: 100%; height: 100%;
    object-fit: cover; border-radius: 4px;
    transition: transform .4s;
}
.poster-card:hover .poster-thumb canvas,
.poster-card:hover .poster-thumb img { transform: scale(1.05); }

.poster-thumb .rank-badge {
    position: absolute; top: 8px; left: 8px;
    font-family: var(--font-en);
    font-size: 22px; font-weight: 800;
    color: var(--white);
    text-shadow: 0 2px 8px rgba(0,0,0,.5);
    line-height: 1;
}
.poster-thumb .tag-badge {
    position: absolute; bottom: 8px; left: 8px;
    background: var(--red); color: var(--white);
    font-size: 10px; font-weight: 700;
    padding: 3px 7px; border-radius: 2px;
    letter-spacing: 1px;
}
.poster-thumb .new-badge {
    position: absolute; top: 8px; right: 8px;
    background: #111; color: var(--white);
    font-size: 10px; font-weight: 700;
    padding: 3px 7px; border-radius: 2px;
    letter-spacing: 1px;
}

.poster-info .title {
    font-size: 13px; font-weight: 600;
    color: var(--dark); line-height: 1.5;
    overflow: hidden; display: -webkit-box;
    -webkit-line-clamp: 2; -webkit-box-orient: vertical;
    margin-bottom: 4px;
}
.poster-info .sub {
    font-size: 11px; color: var(--muted);
    margin-bottom: 4px;
}
.poster-info .price {
    font-size: 14px; font-weight: 700;
    color: var(--red);
}

/* ═══════════════════════════════════
   BANNER STRIP
═══════════════════════════════════ */
.banner-strip {
    background: var(--dark);
    padding: 40px 0;
}
.banner-strip-inner {
    max-width: 1280px; margin: 0 auto;
    padding: 0 24px;
    display: grid; grid-template-columns: 1fr 1fr;
    gap: 16px;
}
.banner-block {
    position: relative; overflow: hidden;
    height: 160px; border-radius: 4px; cursor: pointer;
    display: flex; align-items: center; padding: 0 36px;
}
.banner-block .bg-canvas { position: absolute; inset: 0; }
.banner-block .bb-content { position: relative; z-index: 1; }
.banner-block .bb-tag {
    font-size: 10px; font-weight: 700;
    letter-spacing: 3px; color: rgba(255,255,255,.6);
    margin-bottom: 8px;
}
.banner-block .bb-title {
    font-size: 22px; font-weight: 900;
    color: var(--white); line-height: 1.3;
    margin-bottom: 10px;
}
.banner-block .bb-btn {
    font-size: 11px; font-weight: 700;
    color: var(--white); letter-spacing: 2px;
    border-bottom: 1px solid rgba(255,255,255,.4);
    padding-bottom: 2px; display: inline-block;
}

/* ═══════════════════════════════════
   NOTICE STRIP
═══════════════════════════════════ */
.notice-strip {
    background: var(--gray);
    border-top: 1px solid var(--border);
    border-bottom: 1px solid var(--border);
}
.notice-inner {
    max-width: 1280px; margin: 0 auto;
    padding: 20px 24px;
    display: flex; align-items: center; gap: 32px;
}
.notice-label {
    font-size: 11px; font-weight: 800;
    letter-spacing: 3px; color: var(--red);
    white-space: nowrap;
}
.notice-list {
    display: flex; gap: 28px; overflow: hidden; flex: 1;
}
.notice-list a {
    font-size: 13px; color: #444;
    white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
    transition: color .2s;
}
.notice-list a:hover { color: var(--red); }
.notice-more {
    font-size: 11px; color: var(--muted);
    white-space: nowrap; cursor: pointer;
    transition: color .2s;
}
.notice-more:hover { color: var(--red); }

/* ═══════════════════════════════════
   FOOTER
═══════════════════════════════════ */
.site-footer { background: #0d0d0d; color: #999; margin-top: 0; }
.footer-top { border-bottom: 1px solid #1e1e1e; padding: 50px 0; }
.footer-top-inner {
    max-width: 1280px; margin: 0 auto; padding: 0 24px;
    display: grid; grid-template-columns: 240px 1fr 1fr 1fr; gap: 40px;
}
.footer-brand .logo-footer {
    font-family: var(--font-en);
    font-size: 24px; font-weight: 800;
    color: var(--white); letter-spacing: 4px;
    margin-bottom: 6px;
}
.footer-brand .logo-footer span { color: var(--red); }
.footer-brand p { font-size: 11px; color: #555; margin-bottom: 20px; letter-spacing: 2px; }
.footer-link-group {
    display: flex; gap: 10px; flex-wrap: wrap; margin-bottom: 16px;
}
.footer-link-group a {
    font-size: 11px; color: #444;
    border: 1px solid #333; padding: 5px 10px;
    border-radius: 2px; transition: all .2s;
    display: flex; align-items: center; gap: 5px;
}
.footer-link-group a:hover { color: var(--white); border-color: #666; }

.footer-col h5 {
    font-size: 12px; font-weight: 700;
    color: #ddd; letter-spacing: 2px;
    margin-bottom: 16px; padding-bottom: 10px;
    border-bottom: 1px solid #1e1e1e;
}
.footer-col ul li { margin-bottom: 10px; }
.footer-col ul li a { font-size: 12px; color: #666; transition: color .2s; }
.footer-col ul li a:hover { color: #ccc; }

.footer-cs .cs-num {
    font-family: var(--font-en);
    font-size: 28px; font-weight: 700;
    color: var(--white); letter-spacing: 2px;
    margin-bottom: 6px;
}
.footer-cs .cs-time { font-size: 12px; color: #555; line-height: 2; }

.footer-bottom {
    max-width: 1280px; margin: 0 auto;
    padding: 24px;
    display: flex; justify-content: space-between; align-items: center;
    flex-wrap: wrap; gap: 12px;
}
.footer-bottom-links { display: flex; gap: 16px; flex-wrap: wrap; }
.footer-bottom-links a { font-size: 11px; color: #555; transition: color .2s; }
.footer-bottom-links a:hover { color: #aaa; }
.footer-bottom-links a.em { color: #777; font-weight: 600; }
.footer-copy { font-size: 11px; color: #444; }
.footer-info { font-size: 11px; color: #444; line-height: 2; margin-top: 12px; }
.footer-info span { margin-right: 12px; }

/* ═══════════════════════════════════
   SKELETON
═══════════════════════════════════ */
.skeleton-card .poster-thumb { background: #e8e8e8; }
.skeleton-card .s-line {
    height: 12px; background: #e8e8e8; border-radius: 2px; margin-bottom: 8px;
    animation: skeleton-pulse 1.4s ease-in-out infinite;
}
.skeleton-card .s-line.short { width: 60%; }
@keyframes skeleton-pulse {
    0%,100% { opacity: 1; } 50% { opacity: .5; }
}

/* ═══════════════════════════════════
   RESPONSIVE
═══════════════════════════════════ */
@media (max-width: 1024px) {
    .poster-grid { grid-template-columns: repeat(4, 1fr); }
    .poster-grid.col6 { grid-template-columns: repeat(4, 1fr); }
    .quick-inner { grid-template-columns: repeat(3, 1fr); }
}
@media (max-width: 768px) {
    .gnb { display: none; }
    .poster-grid { grid-template-columns: repeat(2, 1fr); }
    .hero-slide { height: 300px; }
    .slide-title { font-size: 28px; }
    .footer-top-inner { grid-template-columns: 1fr 1fr; }
    .banner-strip-inner { grid-template-columns: 1fr; }
    .cat-inner { padding: 0 12px; }
}
</style>
</head>
<body>

<!-- ══ HEADER ══════════════════════════════════ -->
<header class="site-header">
    <div class="header-inner">
        <a href="/main.do" class="logo">
            <div>
                GWANJE<span>TICKET</span>
                <small class="logo-sub">관제 티켓</small>
            </div>
        </a>

        <nav class="gnb">
            <a href="#" class="gnb-item active">콘서트</a>
            <a href="#" class="gnb-item">뮤지컬</a>
            <a href="#" class="gnb-item">연극</a>
            <a href="#" class="gnb-item">클래식/무용</a>
            <a href="#" class="gnb-item">전시/스포츠</a>
            <a href="#" class="gnb-item">가족/어린이</a>
            <a href="#" class="gnb-item">이벤트</a>
        </nav>

        <div class="header-util">
            <%if (isLogin) {%>
                <span style="font-size:12px;color:#aaa;">Hi, <strong style="color:#fff;"><%=sessionName%></strong>님!</span>
                <%if (isAdmin) {%>
                    <a href="/adminMain.do" class="util-btn">관리자</a>
                <%}%>
                <a href="/my/info.do" class="util-btn">마이페이지</a>
                <a href="#" class="util-btn" id="logoutBtn">로그아웃</a>
            <%} else {%>
                <a href="/loginForm.do" class="util-btn">로그인</a>
                <a href="/joinForm.do" class="util-btn primary">회원가입</a>
            <%}%>
        </div>
    </div>
</header>

<!-- ══ CATEGORY BAR ════════════════════════════ -->
<div class="cat-bar">
    <div class="cat-inner">
        <div class="cat-item active" onclick="filterGoods('ALL')">전체</div>
        <div class="cat-item" onclick="filterGoods('POP')">K-POP</div>
        <div class="cat-item" onclick="filterGoods('ROCK')">록/인디</div>
        <div class="cat-item" onclick="filterGoods('TROT')">트로트</div>
        <div class="cat-item" onclick="filterGoods('JAZZ')">재즈</div>
        <div class="cat-item" onclick="filterGoods('CLASSIC')">클래식</div>
        <div class="cat-item" onclick="filterGoods('MUSICAL')">뮤지컬</div>
        <div class="cat-item" onclick="filterGoods('PLAY')">연극</div>
        <div class="cat-item" onclick="filterGoods('FAMILY')">가족</div>
        <div class="cat-item" onclick="filterGoods('SPORT')">스포츠</div>
    </div>
</div>

<!-- ══ HERO SLIDER ═════════════════════════════ -->
<div class="hero-slider-wrap">
    <ul class="bxslider" id="heroSlider">
        <li>
            <div class="hero-slide" id="slide1">
                <canvas id="canvas1" style="position:absolute;inset:0;width:100%;height:100%;"></canvas>
                <div class="slide-overlay"></div>
                <div class="slide-content">
                    <span class="slide-tag">WORLD TOUR 2026</span>
                    <h1 class="slide-title">IU HEREH<br>WORLD TOUR</h1>
                    <p class="slide-subtitle">서울올림픽주경기장 · 2026.08.15~16</p>
                    <div class="slide-btn" onclick="goDetail(1)">예매하기 →</div>
                </div>
            </div>
        </li>
        <li>
            <div class="hero-slide" id="slide2">
                <canvas id="canvas2" style="position:absolute;inset:0;width:100%;height:100%;"></canvas>
                <div class="slide-overlay"></div>
                <div class="slide-content">
                    <span class="slide-tag">CONCERT 2026</span>
                    <h1 class="slide-title">BTS<br>PERMISSION TO DANCE</h1>
                    <p class="slide-subtitle">KSPO DOME · 2026.09.05~06</p>
                    <div class="slide-btn" onclick="goDetail(2)">예매하기 →</div>
                </div>
            </div>
        </li>
        <li>
            <div class="hero-slide" id="slide3">
                <canvas id="canvas3" style="position:absolute;inset:0;width:100%;height:100%;"></canvas>
                <div class="slide-overlay"></div>
                <div class="slide-content">
                    <span class="slide-tag">FAN MEETING 2026</span>
                    <h1 class="slide-title">NewJeans<br>BUNNIES CAMP</h1>
                    <p class="slide-subtitle">잠실실내체육관 · 2026.11.22</p>
                    <div class="slide-btn" onclick="goDetail(3)">예매하기 →</div>
                </div>
            </div>
        </li>
    </ul>
</div>

<!-- ══ QUICK LINKS ══════════════════════════════ -->
<div class="quick-section">
    <div class="quick-inner">
        <div class="quick-item" onclick="location.href='#'">
            <div class="quick-icon">🎤</div>
            <span class="quick-label">콘서트</span>
        </div>
        <div class="quick-item" onclick="location.href='#'">
            <div class="quick-icon">🎭</div>
            <span class="quick-label">뮤지컬/연극</span>
        </div>
        <div class="quick-item" onclick="location.href='#'">
            <div class="quick-icon">🎻</div>
            <span class="quick-label">클래식/무용</span>
        </div>
        <div class="quick-item" onclick="location.href='#'">
            <div class="quick-icon">⚽</div>
            <span class="quick-label">전시/스포츠</span>
        </div>
        <div class="quick-item" onclick="location.href='#'">
            <div class="quick-icon">🎪</div>
            <span class="quick-label">가족/어린이</span>
        </div>
        <div class="quick-item" onclick="location.href='#'">
            <div class="quick-icon">🎟</div>
            <span class="quick-label">이벤트</span>
        </div>
    </div>
</div>

<!-- ══ NOTICE STRIP ════════════════════════════ -->
<div class="notice-strip">
    <div class="notice-inner">
        <span class="notice-label">NOTICE</span>
        <div class="notice-list">
            <a href="/notice/openNoticeList.do">서비스 이용 안내</a>
            <a href="/notice/openNoticeList.do">2026 상반기 공연 예매 오픈 안내</a>
            <a href="/notice/openNoticeList.do">개인정보 처리방침 개정 안내</a>
        </div>
        <a href="/notice/openNoticeList.do" class="notice-more">전체보기</a>
    </div>
</div>

<!-- ══ WHAT'S HOT ══════════════════════════════ -->
<div class="section">
    <div class="section-header">
        <h2 class="section-title">
            지금 가장 뜨거운 공연
            <span class="en">WHAT'S HOT</span>
        </h2>
        <span class="section-more" onclick="location.href='#'">전체보기</span>
    </div>
    <div class="poster-grid" id="newGrid">
        <!-- 스켈레톤 -->
        <div class="skeleton-card poster-card"><div class="poster-thumb"></div><div class="s-line"></div><div class="s-line short"></div></div>
        <div class="skeleton-card poster-card"><div class="poster-thumb"></div><div class="s-line"></div><div class="s-line short"></div></div>
        <div class="skeleton-card poster-card"><div class="poster-thumb"></div><div class="s-line"></div><div class="s-line short"></div></div>
        <div class="skeleton-card poster-card"><div class="poster-thumb"></div><div class="s-line"></div><div class="s-line short"></div></div>
        <div class="skeleton-card poster-card"><div class="poster-thumb"></div><div class="s-line"></div><div class="s-line short"></div></div>
    </div>
</div>

<hr class="section-divider">

<!-- ══ BANNER STRIP ════════════════════════════ -->
<div class="banner-strip">
    <div class="banner-strip-inner">
        <div class="banner-block" onclick="location.href='/faq/openFaqList.do'">
            <canvas class="bg-canvas" id="bnr1"></canvas>
            <div class="bb-content">
                <div class="bb-tag">EARLY BOOKING</div>
                <div class="bb-title">선예매 혜택<br>최대 20% 할인</div>
                <span class="bb-btn">지금 확인하기</span>
            </div>
        </div>
        <div class="banner-block" onclick="location.href='/notice/openNoticeList.do'">
            <canvas class="bg-canvas" id="bnr2"></canvas>
            <div class="bb-content">
                <div class="bb-tag">MEMBERSHIP</div>
                <div class="bb-title">회원가입 시<br>10,000P 즉시 지급</div>
                <span class="bb-btn">혜택 알아보기</span>
            </div>
        </div>
    </div>
</div>

<!-- ══ BEST ════════════════════════════════════ -->
<div class="section">
    <div class="section-header">
        <h2 class="section-title">
            인기 공연 랭킹
            <span class="en">BEST</span>
        </h2>
        <span class="section-more" onclick="location.href='#'">전체보기</span>
    </div>
    <div class="poster-grid col6" id="bestGrid">
        <div class="skeleton-card poster-card"><div class="poster-thumb"></div><div class="s-line"></div><div class="s-line short"></div></div>
        <div class="skeleton-card poster-card"><div class="poster-thumb"></div><div class="s-line"></div><div class="s-line short"></div></div>
        <div class="skeleton-card poster-card"><div class="poster-thumb"></div><div class="s-line"></div><div class="s-line short"></div></div>
        <div class="skeleton-card poster-card"><div class="poster-thumb"></div><div class="s-line"></div><div class="s-line short"></div></div>
        <div class="skeleton-card poster-card"><div class="poster-thumb"></div><div class="s-line"></div><div class="s-line short"></div></div>
        <div class="skeleton-card poster-card"><div class="poster-thumb"></div><div class="s-line"></div><div class="s-line short"></div></div>
    </div>
</div>

<hr class="section-divider">

<form id="commonForm" name="commonForm"></form>

<!-- ══ FOOTER ═════════════════════════════════ -->
<footer class="site-footer">
    <div class="footer-top">
        <div class="footer-top-inner">
            <div class="footer-brand">
                <div class="logo-footer">GWANJE<span>TICKET</span></div>
                <p>30기 최종 프로젝트 · TEAM JANUS</p>
                <div class="footer-link-group">
                    <a href="https://github.com/nodwon/ticketing" target="_blank">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M12 0C5.37 0 0 5.37 0 12c0 5.3 3.44 9.8 8.2 11.38.6.11.82-.26.82-.58v-2.04c-3.34.72-4.04-1.61-4.04-1.61-.54-1.38-1.33-1.75-1.33-1.75-1.09-.74.08-.73.08-.73 1.2.09 1.84 1.24 1.84 1.24 1.07 1.83 2.8 1.3 3.48 1 .11-.78.42-1.3.76-1.6-2.67-.3-5.47-1.33-5.47-5.93 0-1.31.47-2.38 1.24-3.22-.13-.3-.54-1.52.12-3.17 0 0 1.01-.32 3.3 1.23a11.5 11.5 0 013-.4c1.02 0 2.04.14 3 .4 2.28-1.55 3.29-1.23 3.29-1.23.66 1.65.24 2.87.12 3.17.77.84 1.24 1.91 1.24 3.22 0 4.61-2.81 5.63-5.48 5.92.43.37.81 1.1.81 2.22v3.29c0 .32.22.7.83.58C20.57 21.8 24 17.3 24 12c0-6.63-5.37-12-12-12z"/></svg>
                        GitHub
                    </a>
                    <a href="https://www.notion.so/30-362e2b387a8680b7bbbdc394878a7215" target="_blank">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M4.46 2.43C5.1 2.96 5.35 2.92 6.58 2.85l12.1-.71c.24 0 .02-.24-.04-.28L16.4.27C15.88-.08 15.17 0 14.52 0L2.88.75C2.17.8 1.99 1.14 2.27 1.4l2.19 1.03zM5.63 5.1V19.4c0 .71.35 1.03 1.15 1l13.25-.75c.8-.05 1-.47 1-1.05V4.37c0-.57-.24-.87-.75-.83l-13.7.79c-.54.04-.95.42-.95.77zm12.7.65v12.45l-11.4.65V5.9l11.4-.15zM17.28 6.2c.08.35 0 .7-.35.75l-.6.12v8.77c-.52.28-.99.44-1.4.44-.65 0-.8-.2-1.3-.79l-3.96-6.23v6.03l1.26.28s0 .7-.97.7L7.85 16.4c-.08-.19 0-.65.28-.71l.73-.2V8.2L7.85 8.1c-.08-.35.12-.83.7-.87l2.64-.16 4.1 6.28V7.66L14.1 7.5c-.08-.43.2-.75.6-.79l2.58-.51z"/></svg>
                        Notion
                    </a>
                </div>
            </div>

            <div class="footer-col">
                <h5>고객지원</h5>
                <ul>
                    <li><a href="/notice/openNoticeList.do">공지사항</a></li>
                    <li><a href="/faq/openFaqList.do">FAQ</a></li>
                    <li><a href="/qna/openQnaList.do">1:1 문의</a></li>
                    <li><a href="#">이용약관</a></li>
                    <li><a href="#">개인정보처리방침</a></li>
                </ul>
            </div>

            <div class="footer-col">
                <h5>서비스</h5>
                <ul>
                    <li><a href="#">콘서트</a></li>
                    <li><a href="#">뮤지컬/연극</a></li>
                    <li><a href="#">전시/스포츠</a></li>
                    <li><a href="#">이벤트</a></li>
                    <li><a href="#">티켓 판매 안내</a></li>
                </ul>
            </div>

            <div class="footer-col footer-cs">
                <h5>CS CENTER</h5>
                <div class="cs-num">070-7111-2427</div>
                <div class="cs-time">
                    평일 10:00 ~ 17:00<br>
                    토·일·공휴일 휴무<br>
                    점심시간 13:00 ~ 14:00
                </div>
            </div>
        </div>
        <div style="max-width:1280px;margin:0 auto;padding:20px 24px 0;">
            <div class="footer-info">
                <span>팀명: TEAM JANUS</span>
                <span>30기 최종 프로젝트</span>
                <span>사업자등록번호: 111-81-01111</span>
                <span>주소: 서울 금천구 중구 동호로 256</span>
                <span>개인정보관리책임자: 전형준 (a@a.co.kr)</span>
            </div>
        </div>
    </div>
    <div class="footer-bottom">
        <div class="footer-bottom-links">
            <a href="#">회사소개</a>
            <a href="#">이용약관</a>
            <a href="#" class="em">개인정보처리방침</a>
            <a href="#">청소년보호정책</a>
            <a href="https://github.com/nodwon/ticketing" target="_blank">GitHub</a>
            <a href="https://www.notion.so/30-362e2b387a8680b7bbbdc394878a7215" target="_blank">Notion</a>
        </div>
        <div class="footer-copy">© 2026 TEAM JANUS · GWANJE TICKET. ALL RIGHTS RESERVED.</div>
    </div>
</footer>

<script>
/* ── Canvas로 배너 이미지 생성 ────────────── */
function drawSlide(id, colors, title) {
    var el = document.getElementById(id);
    if (!el) return;
    var parent = el.parentElement;
    el.width  = parent.offsetWidth  || 1280;
    el.height = parent.offsetHeight || 480;
    var ctx = el.getContext('2d');
    var g = ctx.createLinearGradient(0, 0, el.width, el.height);
    g.addColorStop(0, colors[0]);
    g.addColorStop(0.5, colors[1]);
    g.addColorStop(1, colors[2]);
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, el.width, el.height);
    /* 장식 원 */
    ctx.beginPath();
    ctx.arc(el.width * 0.85, el.height * 0.5, el.height * 0.7, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(255,255,255,0.04)';
    ctx.fill();
    ctx.beginPath();
    ctx.arc(el.width * 0.9, el.height * 0.3, el.height * 0.4, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(255,255,255,0.03)';
    ctx.fill();
}

function drawBanner(id, colors) {
    var el = document.getElementById(id);
    if (!el) return;
    var parent = el.parentElement;
    el.width  = parent.offsetWidth  || 600;
    el.height = parent.offsetHeight || 160;
    var ctx = el.getContext('2d');
    var g = ctx.createLinearGradient(0, 0, el.width, 0);
    g.addColorStop(0, colors[0]);
    g.addColorStop(1, colors[1]);
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, el.width, el.height);
    ctx.beginPath();
    ctx.arc(el.width * 0.9, el.height * 0.5, el.height, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(255,255,255,0.05)';
    ctx.fill();
}

/* 포스터 Canvas 생성 */
function makeCanvasPoster(idx, colors, title, artist, price) {
    var id = 'pc_' + idx;
    var c = document.createElement('canvas');
    c.id = id;
    c.width = 200; c.height = 267;
    var ctx = c.getContext('2d');
    var g = ctx.createLinearGradient(0, 0, 200, 267);
    g.addColorStop(0, colors[0]);
    g.addColorStop(1, colors[1]);
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, 200, 267);
    /* 장식 */
    ctx.beginPath();
    ctx.arc(160, 220, 90, 0, Math.PI*2);
    ctx.fillStyle = 'rgba(255,255,255,0.06)';
    ctx.fill();
    ctx.beginPath();
    ctx.arc(30, 50, 50, 0, Math.PI*2);
    ctx.fillStyle = 'rgba(255,255,255,0.04)';
    ctx.fill();
    /* 텍스트 */
    ctx.fillStyle = 'rgba(255,255,255,0.9)';
    ctx.font = 'bold 13px "Noto Sans KR", sans-serif';
    var words = title.split(' ');
    var y = 110;
    var line = '';
    for (var i=0; i<words.length; i++) {
        var test = line + words[i] + ' ';
        if (ctx.measureText(test).width > 170 && i > 0) {
            ctx.fillText(line, 16, y); y += 18; line = words[i] + ' ';
        } else { line = test; }
    }
    ctx.fillText(line, 16, y);
    ctx.fillStyle = 'rgba(255,255,255,0.5)';
    ctx.font = '11px "Noto Sans KR", sans-serif';
    ctx.fillText(artist, 16, y + 20);
    return c;
}

/* 더미 공연 데이터 */
var dummyConcerts = [
    { no:1, title:'IU HEREH WORLD TOUR', artist:'IU (아이유)', price:'165,000', colors:['#1a0a2e','#3d1560'], rank:1, tag:'콘서트' },
    { no:2, title:'BTS PERMISSION TO DANCE', artist:'BTS (방탄소년단)', price:'154,000', colors:['#0a1628','#1e3a6e'], rank:2, tag:'콘서트' },
    { no:3, title:'NewJeans Bunnies Camp', artist:'NewJeans', price:'110,000', colors:['#0d2018','#1a5c35'], rank:3, tag:'팬미팅' },
    { no:4, title:'임영웅 전국투어 IM HERO', artist:'임영웅', price:'132,000', colors:['#1a1208','#5c3d0d'], rank:4, tag:'콘서트' },
    { no:5, title:'BLACKPINK BORN PINK', artist:'BLACKPINK', price:'143,000', colors:['#2a0a1e','#8b1a5e'], rank:5, tag:'콘서트' },
    { no:6, title:'Stray Kids MANIAC TOUR', artist:'Stray Kids', price:'121,000', colors:['#0a0a1e','#1a1a5c'], rank:6, tag:'콘서트' }
];

function renderGrid(gridId, data, showRank) {
    var grid = document.getElementById(gridId);
    grid.innerHTML = '';
    if (!data || data.length === 0) {
        grid.innerHTML = "<div style='grid-column:1/-1;text-align:center;padding:60px;color:#bbb;font-size:14px;'>등록된 공연이 없습니다.</div>";
        return;
    }
    data.forEach(function(item, i) {
        var canvas = makeCanvasPoster(gridId + i, item.colors, item.title, item.artist, item.price);
        var card = document.createElement('div');
        card.className = 'poster-card';
        card.setAttribute('onclick', 'goDetail(' + item.no + ')');

        var thumb = document.createElement('div');
        thumb.className = 'poster-thumb';
        thumb.appendChild(canvas);

        if (showRank) {
            var rank = document.createElement('span');
            rank.className = 'rank-badge';
            rank.textContent = item.rank;
            thumb.appendChild(rank);
        }
        if (item.tag) {
            var tag = document.createElement('span');
            tag.className = 'tag-badge';
            tag.textContent = item.tag;
            thumb.appendChild(tag);
        }
        if (i < 2) {
            var nbadge = document.createElement('span');
            nbadge.className = 'new-badge';
            nbadge.textContent = 'NEW';
            thumb.appendChild(nbadge);
        }

        var info = document.createElement('div');
        info.className = 'poster-info';
        info.innerHTML =
            "<div class='title'>" + item.title + "</div>" +
            "<div class='sub'>" + item.artist + "</div>" +
            "<div class='price'>" + item.price + "원~</div>";

        card.appendChild(thumb);
        card.appendChild(info);
        grid.appendChild(card);
    });
}

function goDetail(no) {
    var comSubmit = new ComSubmit();
    comSubmit.setUrl('<c:url value="/shop/goodsDetail.do"/>');
    comSubmit.addParam('IDX', no);
    comSubmit.submit();
}

function filterGoods(cate) {
    $('.cat-item').removeClass('active');
    $(event.currentTarget).addClass('active');
}

/* 로그아웃 */
document.getElementById && $('#logoutBtn') && $('#logoutBtn').on('click', function(e) {
    e.preventDefault();
    $.ajax({
        url: '<c:url value="/logout.do"/>',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify({}),
        success: function(data) { location.href = data.URL || '/main.do'; }
    });
});

$(document).ready(function() {
    /* 슬라이더 배경 */
    drawSlide('canvas1', ['#1a0a2e','#3d1560','#0a0014'], 'IU');
    drawSlide('canvas2', ['#0a1628','#1e3a6e','#000a1a'], 'BTS');
    drawSlide('canvas3', ['#0d1f14','#1a5c35','#000d08'], 'NewJeans');
    drawBanner('bnr1', ['#1a0a0a','#5c1010']);
    drawBanner('bnr2', ['#0a1020','#102040']);

    /* 메인 슬라이더 */
    $('#heroSlider').bxSlider({
        auto: true, speed: 700, pause: 5000,
        mode: 'horizontal', pager: true, controls: true,
        responsive: true
    });

    /* Ajax로 실제 데이터 시도, 실패 시 더미 렌더 */
    $.ajax({
        url: '<c:url value="/mainList.do"/>',
        type: 'POST',
        dataType: 'json',
        data: { PAGE_INDEX: 1, PAGE_ROW: 8 },
        success: function(data) {
            if (data.NewList && data.NewList.length > 0) {
                renderGridFromServer('newGrid', data.NewList, false);
            } else {
                renderGrid('newGrid', dummyConcerts.slice(0,5), false);
            }
            if (data.BestList && data.BestList.length > 0) {
                renderGridFromServer('bestGrid', data.BestList, true);
            } else {
                renderGrid('bestGrid', dummyConcerts, true);
            }
        },
        error: function() {
            renderGrid('newGrid', dummyConcerts.slice(0,5), false);
            renderGrid('bestGrid', dummyConcerts, true);
        }
    });
});
</script>
</body>
</html>
