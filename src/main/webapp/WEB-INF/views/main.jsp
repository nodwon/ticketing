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

<!-- ══ HERO SLIDER ═════════════════════════════ -->
<div class="hero-slider-wrap">
    <ul class="bxslider" id="heroSlider">
        <!-- JS로 동적 생성 -->
    </ul>
</div>

<!-- ══ QUICK LINKS ══════════════════════════════ -->
<div class="quick-section">
    <div class="quick-inner">
        <div class="quick-item" onclick="location.href='/concert/list.do'">
            <div class="quick-icon">🎤</div>
            <span class="quick-label">콘서트</span>
        </div>
        <div class="quick-item" onclick="location.href='/concert/list.do'">
            <div class="quick-icon">🎭</div>
            <span class="quick-label">뮤지컬/연극</span>
        </div>
        <div class="quick-item" onclick="location.href='/concert/list.do'">
            <div class="quick-icon">🎻</div>
            <span class="quick-label">클래식/무용</span>
        </div>
        <div class="quick-item" onclick="location.href='/concert/list.do'">
            <div class="quick-icon">⚽</div>
            <span class="quick-label">전시/스포츠</span>
        </div>
        <div class="quick-item" onclick="location.href='/concert/list.do'">
            <div class="quick-icon">🎪</div>
            <span class="quick-label">가족/어린이</span>
        </div>
        <div class="quick-item" onclick="location.href='/concert/list.do'">
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
        <span class="section-more" onclick="location.href='/concert/list.do'">전체보기</span>
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
        <span class="section-more" onclick="location.href='/concert/list.do'">전체보기</span>
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



<script>
/* ── Canvas로 배너 이미지 생성 ────────────── */
function drawSlide(id, colors) {
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

/* 더미 공연 데이터 (DB 조회 실패 시 fallback) */
var dummyConcerts = [
    { no:1, title:'IU HEREH WORLD TOUR', artist:'IU (아이유)', price:'165,000', colors:['#1a0a2e','#3d1560'], rank:1, tag:'콘서트' },
    { no:2, title:'BTS PERMISSION TO DANCE', artist:'BTS (방탄소년단)', price:'154,000', colors:['#0a1628','#1e3a6e'], rank:2, tag:'콘서트' },
    { no:3, title:'NewJeans Bunnies Camp', artist:'NewJeans', price:'110,000', colors:['#0d2018','#1a5c35'], rank:3, tag:'팬미팅' },
    { no:4, title:'임영웅 전국투어 IM HERO', artist:'임영웅', price:'132,000', colors:['#1a1208','#5c3d0d'], rank:4, tag:'콘서트' },
    { no:5, title:'BLACKPINK BORN PINK', artist:'BLACKPINK', price:'143,000', colors:['#2a0a1e','#8b1a5e'], rank:5, tag:'콘서트' },
    { no:6, title:'Stray Kids MANIAC TOUR', artist:'Stray Kids', price:'121,000', colors:['#0a0a1e','#1a1a5c'], rank:6, tag:'콘서트' }
];

/* 상태별 색상 */
var statusColors = {
    'ONGOING':  ['#0d2018','#1a5c35'],
    'UPCOMING': ['#0a1628','#1e3a6e'],
    'CLOSED':   ['#1a1208','#3d2b0d']
};

/* DB 데이터 → renderGrid 형식으로 변환 */
function convertConcertData(list, offset) {
    return list.map(function(c, i) {
        var statusKey = c.status || 'UPCOMING';
        var colors    = statusColors[statusKey] || ['#1a0a2e','#3d1560'];
        var tagLabel  = statusKey === 'ONGOING'  ? '예매중'  :
                        statusKey === 'UPCOMING' ? '예매예정' : '종료';
        return {
            no:     c.concertId,
            title:  c.title   || '공연명 없음',
            artist: c.artist  || '',
            price:  '가격 미정',
            colors: colors,
            rank:   (offset || 0) + i + 1,
            tag:    tagLabel
        };
    });
}

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
    location.href = '/concert/detail.do?concertId=' + no;
}

/* 슬라이더 색상 팔레트 */
var slideColorPalettes = [
    ['#1a0a2e','#3d1560','#0a0014'],
    ['#0a1628','#1e3a6e','#000a1a'],
    ['#0d1f14','#1a5c35','#000d08'],
    ['#1a0808','#5c1010','#0a0000'],
    ['#0a0a1a','#1a1a5c','#000008'],
    ['#1a1208','#5c3d0d','#0a0800']
];
var statusLabel = { ONGOING:'예매중', UPCOMING:'예매예정', CLOSED:'종료' };

function buildHeroSlider(concerts) {
    var ul = document.getElementById('heroSlider');
    ul.innerHTML = '';

    concerts.forEach(function(c, i) {
        var concertId = c.concertId;
        var canvasId  = 'slide_canvas_' + i;
        var colors    = slideColorPalettes[i % slideColorPalettes.length];
        var tag       = statusLabel[c.status] || '공연';
        var title     = (c.title || '').replace(/(.{10})/g, '$1<br>');  /* 10자 줄바꿈 */
        var sub       = (c.venue || '') + (c.perform_start_at ? ' · ' + c.perform_start_at.substring(0,10) : '');
        var btnDisabled = (c.status === 'CLOSED') ? 'style="opacity:.5;cursor:not-allowed;"' : '';
        var btnOnclick  = (c.status === 'CLOSED')
            ? ''
            : 'onclick="location.href=\'/concert/detail.do?concertId=' + concertId + '\'"';

        var li = document.createElement('li');
        li.innerHTML =
            '<div class="hero-slide">' +
              '<canvas id="' + canvasId + '" style="position:absolute;inset:0;width:100%;height:100%;"></canvas>' +
              '<div class="slide-overlay"></div>' +
              '<div class="slide-content">' +
                '<span class="slide-tag">' + tag.toUpperCase() + ' 2026</span>' +
                '<h1 class="slide-title">' + (c.artist || c.title) + '</h1>' +
                '<p class="slide-subtitle">' + sub + '</p>' +
                '<div class="slide-btn" ' + btnOnclick + ' ' + btnDisabled + '>예매하기 →</div>' +
              '</div>' +
            '</div>';
        ul.appendChild(li);

        /* canvas 배경 그리기 */
        setTimeout(function(id, cols) {
            drawSlide(id, cols);
        }.bind(null, canvasId, colors), 50);
    });

    /* bxSlider 초기화 */
    if ($.fn.bxSlider) {
        $('#heroSlider').bxSlider({
            auto: true, speed: 700, pause: 5000,
            mode: 'horizontal', pager: true, controls: true,
            responsive: true
        });
    }
}

function buildHeroSliderDummy() {
    var dummySlides = [
        { concertId:1, title:'IU HEREH WORLD TOUR',       artist:'IU (아이유)',      status:'UPCOMING', venue:'서울올림픽주경기장', perform_start_at:'2026-08-15' },
        { concertId:2, title:'BTS PERMISSION TO DANCE',   artist:'BTS',              status:'UPCOMING', venue:'KSPO DOME',         perform_start_at:'2026-09-05' },
        { concertId:3, title:'NewJeans Bunnies Camp',      artist:'NewJeans',         status:'ONGOING',  venue:'잠실실내체육관',    perform_start_at:'2026-11-22' }
    ];
    buildHeroSlider(dummySlides);
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
    drawBanner('bnr1', ['#1a0a0a','#5c1010']);
    drawBanner('bnr2', ['#0a1020','#102040']);

    /* DB에서 실제 공연 데이터 조회 → 슬라이더 + 그리드 모두 세팅 */
    $.ajax({
        url: '<c:url value="/concert/listJson.do"/>',
        type: 'GET',
        dataType: 'json',
        data: { limit: 6 },
        success: function(data) {
            if (data.list && data.list.length > 0) {
                /* ── 히어로 슬라이더 동적 생성 ── */
                buildHeroSlider(data.list.slice(0, 3));

                /* ── 포스터 그리드 ── */
                var hotData  = convertConcertData(data.list.slice(0, 5), 0);
                var bestData = convertConcertData(data.list, 0);
                renderGrid('newGrid',  hotData,  false);
                renderGrid('bestGrid', bestData, true);
            } else {
                buildHeroSliderDummy();
                renderGrid('newGrid',  dummyConcerts.slice(0,5), false);
                renderGrid('bestGrid', dummyConcerts,            true);
            }
        },
        error: function() {
            buildHeroSliderDummy();
            renderGrid('newGrid',  dummyConcerts.slice(0,5), false);
            renderGrid('bestGrid', dummyConcerts,            true);
        }
    });
});
</script>
</body>
</html>
