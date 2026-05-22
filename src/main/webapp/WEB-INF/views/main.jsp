<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>관제 티켓 - 메인</title>

<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.1.1/jquery.min.js"></script>
<script src="<c:url value='/js/common1.js'/>" charset="utf-8"></script>
<link href="<c:url value='/css/board.css'/>" rel="stylesheet">
<link href="<c:url value='/css/goods.css'/>" rel="stylesheet">
<link href="<c:url value='/css/btn.css'/>" rel="stylesheet">
<link rel="stylesheet" href="<c:url value='/css/ui.css'/>">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/bxslider/4.2.12/jquery.bxslider.css">
<script src="https://cdn.jsdelivr.net/bxslider/4.2.12/jquery.bxslider.min.js"></script>

<style>
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: 'Malgun Gothic', sans-serif; background: #f8f8f8; }
a { text-decoration: none; color: inherit; }

/* ── 슬라이더 ── */
.slider-wrap { width: 100%; background: #000; }
.bx-wrapper { box-shadow: none !important; border: none !important; background: #000 !important; margin: 0 !important; }
.bxslider li img { width: 100%; height: 420px; object-fit: cover; display: block; }

/* ── 섹션 공통 ── */
.section { max-width: 1200px; margin: 0 auto; padding: 50px 20px 60px; }

.section-title {
    font-size: 20px;
    font-weight: 700;
    color: #111;
    letter-spacing: 4px;
    text-align: center;
    margin-bottom: 30px;
    position: relative;
    padding-bottom: 14px;
}
.section-title::after {
    content: '';
    position: absolute;
    bottom: 0; left: 50%;
    transform: translateX(-50%);
    width: 36px; height: 2px;
    background: #e8001c;
}

/* ── 포스터 그리드 ── */
.poster-grid {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 20px;
}

.poster-card {
    background: #fff;
    border-radius: 6px;
    overflow: hidden;
    border: 1px solid #eee;
    cursor: pointer;
    transition: transform 0.2s, box-shadow 0.2s;
}
.poster-card:hover {
    transform: translateY(-5px);
    box-shadow: 0 10px 24px rgba(0,0,0,0.12);
}

.poster-card .thumb {
    width: 100%;
    aspect-ratio: 3/4;
    overflow: hidden;
    background: #eee;
    position: relative;
}
.poster-card .thumb img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    transition: transform 0.4s;
    display: block;
}
.poster-card:hover .thumb img { transform: scale(1.06); }

.poster-card .thumb .badge-wrap {
    position: absolute;
    top: 10px; right: 10px;
    display: flex; flex-direction: column; gap: 4px; align-items: flex-end;
}
.badge {
    font-size: 11px;
    font-weight: 700;
    padding: 3px 8px;
    border-radius: 12px;
    color: #fff;
}
.badge-pink   { background: #ff4d8d; }
.badge-purple { background: #9b3dc8; }
.badge-blue   { background: #1e90ff; }
.badge-red    { background: #e8001c; }

.poster-card .info { padding: 12px 12px 14px; }
.poster-card .info .name {
    font-size: 13px;
    color: #222;
    font-weight: 500;
    line-height: 1.5;
    margin-bottom: 6px;
    overflow: hidden;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
}
.poster-card .info .price {
    font-size: 15px;
    font-weight: 700;
    color: #e8001c;
}
.poster-card .info .sub {
    font-size: 11px;
    color: #aaa;
    margin-top: 3px;
}

/* ── 섹션 구분선 ── */
.section-divider {
    border: none;
    border-top: 6px solid #f0f0f0;
    margin: 0;
}

/* ── 빈 결과 ── */
.no-result {
    grid-column: 1 / -1;
    text-align: center;
    padding: 60px 0;
    color: #bbb;
    font-size: 14px;
}

/* ── 로딩 스켈레톤 ── */
.skeleton {
    background: #eee;
    border-radius: 6px;
    aspect-ratio: 3/4;
    animation: pulse 1.2s ease-in-out infinite;
}
@keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.5; }
}
</style>
</head>
<body>
<!-- 메인 슬라이더 -->
<div class="slider-wrap">
    <ul class="bxslider">
        <li><a href="#"><img src="/img/spot1.jpg" alt="배너1"></a></li>
        <li><a href="#"><img src="/img/spot2.jpg" alt="배너2"></a></li>
        <li><a href="#"><img src="/img/spot3.jpg" alt="배너3"></a></li>
    </ul>
</div>

<!-- WHAT'S HOT (NEW) -->
<div class="section">
    <h2 class="section-title">WHAT'S HOT</h2>
    <div class="poster-grid" id="newItemGrid">
        <!-- 스켈레톤 로딩 -->
        <div class="skeleton"></div>
        <div class="skeleton"></div>
        <div class="skeleton"></div>
        <div class="skeleton"></div>
    </div>
</div>

<hr class="section-divider">

<!-- BEST -->
<div class="section">
    <h2 class="section-title">BEST</h2>
    <div class="poster-grid" id="bestItemGrid">
        <div class="skeleton"></div>
        <div class="skeleton"></div>
        <div class="skeleton"></div>
        <div class="skeleton"></div>
    </div>
</div>

<form id="commonForm" name="commonForm"></form>


<script>
function numberWithCommas(x) {
    if (!x) return '0';
    return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

/* 배지 색상 */
var badgeColors = ['badge-pink', 'badge-purple', 'badge-blue', 'badge-red'];

function makeBadges(pickStr) {
    if (!pickStr) return '';
    var picks = pickStr.split(',');
    var html = "<div class='badge-wrap'>";
    for (var i = 0; i < picks.length && i < 4; i++) {
        var p = picks[i].trim();
        if (p) html += "<span class='badge " + badgeColors[i] + "'>" + p + "</span>";
    }
    return html + "</div>";
}

function makeCard(value) {
    var imgs = value.GOODS_IMAGE_STD ? value.GOODS_IMAGE_STD.split(',') : [];
    var img0 = imgs[0] ? imgs[0].trim() : '';
    var img1 = imgs[1] ? imgs[1].trim() : img0;
    var no   = value.GOODS_NO;
    var name = value.GOODS_NAME || '';
    var price = numberWithCommas(value.GOODS_SELL_PRICE);

    return "<div class='poster-card' onclick='goDetail(" + no + ")'>"
         +   "<div class='thumb'>"
         +     "<img src='/file/" + img0 + "'"
         +          " data-src0='/file/" + img0 + "'"
         +          " data-src1='/file/" + img1 + "'"
         +          " alt='" + name + "'"
         +          " onerror=\"this.src='/img/no_image.png'\">"
         +     makeBadges(value.GOODS_PICK)
         +   "</div>"
         +   "<div class='info'>"
         +     "<div class='name'>" + name + "</div>"
         +     "<div class='price'>" + price + "원</div>"
         +   "</div>"
         + "</div>";
}

function goDetail(no) {
    var comSubmit = new ComSubmit();
    comSubmit.setUrl("<c:url value='/shop/goodsDetail.do'/>");
    comSubmit.addParam("IDX", no);
    comSubmit.submit();
}

/* 이미지 호버 */
function bindHover(wrap) {
    $(wrap).find(".thumb img")
        .on("mouseenter", function() {
            $(this).attr("src", $(this).data("src1"));
        })
        .on("mouseleave", function() {
            $(this).attr("src", $(this).data("src0"));
        });
}

/* NEW */
function fn_selectNewItemList(pageNo) {
    var comAjax = new ComAjax();
    comAjax.setUrl("<c:url value='/mainList.do'/>");
    comAjax.setCallback("fn_newCallback");
    comAjax.addParam("PAGE_INDEX", pageNo);
    comAjax.addParam("PAGE_ROW", 8);
    comAjax.ajax();
}
function fn_newCallback(data) {
    var grid = $("#newItemGrid");
    grid.empty();
    if (!data.NewList || data.NewList.length === 0) {
        grid.append("<div class='no-result'>등록된 공연이 없습니다.</div>");
        return;
    }
    $.each(data.NewList, function(i, v) { grid.append(makeCard(v)); });
    bindHover(grid);
}

/* BEST */
function fn_selectBestItemList(pageNo) {
    var comAjax = new ComAjax();
    comAjax.setUrl("<c:url value='/mainList.do'/>");
    comAjax.setCallback("fn_bestCallback");
    comAjax.addParam("PAGE_INDEX", pageNo);
    comAjax.addParam("PAGE_ROW", 8);
    comAjax.ajax();
}
function fn_bestCallback(data) {
    var grid = $("#bestItemGrid");
    grid.empty();
    if (!data.BestList || data.BestList.length === 0) {
        grid.append("<div class='no-result'>등록된 공연이 없습니다.</div>");
        return;
    }
    $.each(data.BestList, function(i, v) { grid.append(makeCard(v)); });
    bindHover(grid);
}

$(document).ready(function () {
    fn_selectNewItemList(1);
    fn_selectBestItemList(1);

    $('.bxslider').bxSlider({
        auto: true,
        speed: 600,
        pause: 4000,
        mode: 'horizontal',
        pager: true,
        controls: true,
        responsive: true
    });
});
</script>
</body>
</html>