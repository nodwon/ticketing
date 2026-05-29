<%--
 * ============================================================
 * Project  : 관제 티켓 (Ticketing System)
 * FileName : seatSelect.jsp
 * Modified  : 2026.05.28 (UI 공통 테마 통일 - theme.css 적용)
 * Modified  : 2026.05.29 - 김희재 (봇 탐지용 개편)
 *   - 구역 클릭 시 AJAX /seat/zone.do 호출 (서버 로그 적재)
 *   - 좌석 번호 숨김 (클릭 시 하단 정보창에만 표시)
 *   - HELD/RESERVED → UI에서 "예매불가" 로 통합 (회색)
 *   - 색상 재정의 : 예매가능=빨강 / 예매불가=회색 / 선택됨=노랑
 *   - HELD 클릭 시 "이미 결제 중인 좌석입니다" 안내
 *   - 최대 선택 가능 좌석 4석 → 2석
 *   - 우측 사이드바 레이아웃 (STAGE / 구역 A~E / 선택정보 / 예매하기)
 *   - 색상 설명은 좌석맵 아래 중앙
 *
 * Description :
 *   - 좌석 클릭 시 로컬 selectedSeats 에만 저장 (서버 hold 없음)
 *   - 좌석 구역(Zone) 탭 클릭 시마다 서버 요청 → log_api 기록
 *   - 좌석 상태별 색상 구분 (UI 단순화)
 *     * 예매가능 (AVAILABLE)         : 빨강
 *     * 예매불가 (HELD + RESERVED)   : 회색
 *     * 선택됨   (본인이 클릭)        : 노랑 (개인 화면 전용)
 * ============================================================
--%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>좌석 선택 | GWANJE TICKET</title>
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/theme.css">
<style>
    body { background: var(--gray); }

    /* ===== [2026.05.29 김희재] 사이드바 레이아웃 ===== */
    .ss-layout {
        display: flex;
        gap: 20px;
        max-width: 1100px;
        margin: 24px auto;
        padding: 0 20px;
        align-items: stretch;
    }
    .ss-center {
        flex: 1;
        min-width: 0;
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 14px;
    }
    .ss-side {
        width: 260px;
        flex-shrink: 0;
        display: flex;
        flex-direction: column;
        gap: 14px;
    }

    /* STAGE (사이드바 상단) */
    .ss-stage {
        background: var(--dark);
        color: var(--white);
        padding: 12px;
        border-radius: var(--radius);
        font-weight: 700; letter-spacing: 4px; text-align: center;
        font-family: var(--font-en);
        border-bottom: 3px solid var(--red);
        font-size: 13px;
    }

    /* 구역 탭 — 가로 5칸 그리드 (A|B|C|D|E) */
    .zone-tabs {
        display: grid;
        grid-template-columns: repeat(5, 1fr);
        gap: 4px;
    }
    .zone-tab {
        padding: 22px 0;
        background: var(--white); color: var(--muted);
        border: 1px solid var(--border);
        border-radius: var(--radius);
        cursor: pointer; font-weight: 600; font-size: 14px;
        transition: all .2s;
        text-align: center;
        position: relative;
    }
    .zone-tab:hover { background: var(--gray); color: var(--text); }
    .zone-tab.active { background: var(--dark); color: var(--white); border-color: var(--dark); }
    .zone-tab .badge {
        position: absolute;
        top: -5px; right: -5px;
        background: var(--red);
        padding: 0 6px; border-radius: 10px;
        font-size: 11px; color: var(--white);
        min-width: 16px; height: 16px; line-height: 16px;
    }

    /* 좌석맵 */
    .seat-map {
        display: inline-block; padding: 18px;
        background: var(--white);
        border: 1px solid var(--border);
        border-radius: var(--radius-lg);
        box-shadow: var(--shadow);
    }

    .seat-row { display: flex; justify-content: center; align-items: center; margin-bottom: 4px; }
    .row-label {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        width: 22px; height: 26px;
        margin: 2px 8px 2px 2px;
        font-size: 12px;
        color: var(--muted);
        font-weight: 600;
    }
    .seat {
        width: 26px; height: 26px; margin: 2px;
        border-radius: var(--radius); cursor: pointer;
        display: flex; align-items: center; justify-content: center;
        font-size: 10px; color: var(--white); font-weight: 700;
        transition: transform .1s;
    }
    .seat:hover { transform: scale(1.12); }
    /* [2026.05.29 김희재] 좌석 상태별 색상 (단순화)
       예매가능=빨강 / 예매불가=회색 / 선택됨=노랑 */
    .seat.AVAILABLE   { background: #e8001c; }
    .seat.UNAVAILABLE { background: #bdbdbd; cursor: not-allowed; }
    .seat.SELECTED    {
        background: #f5c842;
        color: #000;
        border: 2px solid #000;
        box-sizing: border-box;
    }
    .seat.SELECTED::after {
        content: '✓';
        font-size: 14px;
        font-weight: 900;
        line-height: 1;
    }

    /* 범례 (좌석맵 아래, 중앙) */
    .legend {
        display: flex;
        gap: 22px; flex-wrap: wrap;
        justify-content: center;
        padding: 10px 18px;
        background: var(--white);
        border: 1px solid var(--border);
        border-radius: var(--radius);
        font-size: 13px; color: var(--text);
    }
    .legend-item { display: flex; align-items: center; gap: 6px; }
    .legend-box { width: 16px; height: 16px; border-radius: 3px; }

    /* 선택 정보 박스 (사이드바) */
    .info {
        padding: 14px 16px;
        background: var(--white);
        border: 1px solid var(--border);
        border-radius: var(--radius-lg);
        box-shadow: var(--shadow);
        font-size: 14px; color: var(--text);
        flex: 1;
        min-height: 76px;
    }
    .info .label {
        font-size: 11px; color: var(--muted);
        font-weight: 600; margin-bottom: 6px;
        letter-spacing: 1px;
    }
    .info b { color: var(--red); }

    /* 예매하기 버튼 — 사이드바 맨 아래 (범례와 같은 라인) */
    .ss-actions { margin-top: 0; }
    .ss-actions .tk-btn { width: 100%; }
</style>
</head>
<body>

<!-- 페이지 헤더 (공통 톤) -->
<div class="tk-page-head">
    <div class="tk-page-head-inner">
        <div class="brand">SEAT SELECTION</div>
        <h1>좌석 선택</h1>
        <p>원하는 좌석을 선택하세요. 최대 2석까지 선택 가능합니다.</p>
        <div class="tk-steps">
            <span class="tk-step"><span class="num">1</span>공연 선택</span>
            <span class="tk-step-sep">›</span>
            <span class="tk-step active"><span class="num">2</span>좌석 선택</span>
            <span class="tk-step-sep">›</span>
            <span class="tk-step"><span class="num">3</span>결제</span>
            <span class="tk-step-sep">›</span>
            <span class="tk-step"><span class="num">4</span>완료</span>
        </div>
    </div>
</div>

<!-- [2026.05.29 김희재] 우측 사이드바 레이아웃 -->
<div class="ss-layout">

    <!-- 중앙: 좌석맵 + 범례 -->
    <main class="ss-center">
        <div class="seat-map" id="seatMap">
            <p class="tk-text-muted">좌석 정보를 불러오는 중...</p>
        </div>
        <div class="legend">
            <div class="legend-item"><div class="legend-box" style="background:#e8001c"></div>예매가능</div>
            <div class="legend-item"><div class="legend-box" style="background:#bdbdbd"></div>예매불가</div>
            <div class="legend-item"><div class="legend-box" style="background:#f5c842"></div>선택됨</div>
        </div>
    </main>

    <!-- 우측 사이드바: STAGE / 구역 / 선택정보 / 예매하기 -->
    <aside class="ss-side">
        <div class="ss-stage">━ S T A G E ━</div>
        <div class="zone-tabs" id="zoneTabs">
            <p class="tk-text-muted" style="grid-column: 1 / -1;">구역 정보를 불러오는 중...</p>
        </div>
        <div class="info" id="info">
            <div class="label">선택한 좌석</div>
            좌석을 선택해 주세요
        </div>
        <div class="ss-actions">
            <button onclick="goToBooking()" class="tk-btn tk-btn-primary tk-btn-lg">🎫 예매하기</button>
        </div>
    </aside>

</div>

<script>
    // 페이지 진입 시 scheduleId 받기 (Controller에서 넘긴 값)
    var scheduleId = '${scheduleId}';

    // 세션에서 로그인 회원 ID 가져옴
    var memberId = '<c:out value="${sessionScope.SESSION_NO}"/>';
    if (!memberId) {
        alert('로그인이 필요합니다.');
        location.href = '/loginForm.do';
    }

    // 현재 구역 + 구역별 좌석 캐시
    var currentZone = 'A';
    var currentZoneSeats = [];
    var ROWS_PER_ZONE = 10;
    var ZONE_COUNT = 5;

    var selectedSeats = JSON.parse(sessionStorage.getItem('selectedSeats_' + scheduleId) || '[]');

    // ─────────────────────────────────────────────
    // [2026.05.29 김희재] 구역 탭 렌더링
    //   - [사이드바 레이아웃] 가로 5칸 그리드 — A~E 한 글자만 표시
    //   - tooltip(title)로 "X구역 (N~M열)" 표기
    // ─────────────────────────────────────────────
    function renderZoneTabs() {
        var html = '';
        for (var i = 0; i < ZONE_COUNT; i++) {
            var zoneName = String.fromCharCode(65 + i);
            var startRow = i * ROWS_PER_ZONE + 1;
            var endRow   = (i + 1) * ROWS_PER_ZONE;

            var mineInZone = selectedSeats.filter(function(s) {
                return s.seatRow >= startRow && s.seatRow <= endRow;
            }).length;

            var activeClass = (zoneName === currentZone) ? 'active' : '';
            var badge = mineInZone > 0
                ? '<span class="badge">' + mineInZone + '</span>'
                : '';
            var title = zoneName + '구역 (' + startRow + '~' + endRow + '열)';

            html += '<button class="zone-tab ' + activeClass + '"';
            html += ' onclick="switchZone(\'' + zoneName + '\')"';
            html += ' title="' + title + '">';
            html += zoneName + badge;
            html += '</button>';
        }
        document.getElementById('zoneTabs').innerHTML = html;
    }

    // ─────────────────────────────────────────────
    // [2026.05.29 김희재] 구역 전환 (★ 핵심 변경)
    //   기존: 로컬 allSeats 필터링만 함 (서버 요청 없음)
    //   변경: 구역 클릭마다 AJAX /seat/zone.do 호출 → log_api 기록
    // ─────────────────────────────────────────────
    function switchZone(zone) {
        currentZone = zone;
        renderZoneTabs();
        loadZoneSeats(zone);
    }

    // ─────────────────────────────────────────────
    // [2026.05.29 김희재] 구역별 좌석 로드 (서버 요청)
    // ─────────────────────────────────────────────
    function loadZoneSeats(zone) {
        document.getElementById('seatMap').innerHTML =
            '<p class="tk-text-muted">' + zone + '구역 좌석을 불러오는 중...</p>';

        var xhr = new XMLHttpRequest();
        xhr.open('GET', '/seat/zone.do?scheduleId=' + scheduleId + '&zone=' + zone, true);
        xhr.onload = function() {
            if (xhr.status === 200) {
                currentZoneSeats = JSON.parse(xhr.responseText);
                renderSeats(currentZoneSeats);
            } else {
                document.getElementById('seatMap').innerHTML =
                    '<p class="tk-text-muted">좌석을 불러올 수 없습니다.</p>';
            }
        };
        xhr.onerror = function() {
            document.getElementById('seatMap').innerHTML =
                '<p class="tk-text-muted">네트워크 오류가 발생했습니다.</p>';
        };
        xhr.send();
    }

    // ─────────────────────────────────────────────
    // [2026.05.29 김희재] 좌석 그리기 — 번호 숨김 + 상태 통합
    // ─────────────────────────────────────────────
    function renderSeats(seats) {
        var html = '';
        var currentRow = null;
        var rowIndex = 0;   // [2026.05.29 김희재] 행 라벨용 (구역 무관 1부터)

        seats.forEach(function(seat) {
            if (currentRow !== seat.seatRow) {
                if (currentRow !== null) html += '</div>';
                rowIndex++;
                html += '<div class="seat-row">';
                html += '<span class="row-label">' + rowIndex + '</span>';
                currentRow = seat.seatRow;
            }

            var isMine = selectedSeats.some(function(s) {
                return s.seatId === seat.seatId;
            });

            var displayStatus;
            if (isMine) {
                displayStatus = 'SELECTED';
            } else if (seat.status === 'AVAILABLE') {
                displayStatus = 'AVAILABLE';
            } else {
                displayStatus = 'UNAVAILABLE';
            }

            html += '<div class="seat ' + displayStatus + '"';
            html += ' data-seat-id="' + seat.seatId + '"';
            html += ' onclick="selectSeat(' + seat.seatId + ', \'' + seat.status + '\', ' + seat.seatRow + ', ' + seat.seatCol + ')"';
            html += ' title="' + seat.seatRow + '열 ' + seat.seatCol + '번 / ' + seat.price + '원">';
            html += '</div>';
        });
        if (currentRow !== null) html += '</div>';

        document.getElementById('seatMap').innerHTML = html;
    }

    // ─────────────────────────────────────────────
    // 좌석 클릭 처리
    //   [2026.05.29 김희재]
    //     - HELD  → "이미 결제 중인 좌석입니다" 안내
    //     - RESERVED 등 그 외 → "선택할 수 없는 좌석입니다"
    //     - 최대 선택 좌석 2석으로 변경
    // ─────────────────────────────────────────────
    function selectSeat(seatId, status, seatRow, seatCol) {
        var isMine = selectedSeats.some(function(s) {
            return s.seatId === seatId;
        });

        if (isMine) {
            selectedSeats = selectedSeats.filter(function(s) {
                return s.seatId !== seatId;
            });
        } else if (status === 'HELD') {
            alert('이미 결제 중인 좌석입니다.');
            return;
        } else if (status !== 'AVAILABLE') {
            alert('선택할 수 없는 좌석입니다.');
            return;
        } else {
            if (selectedSeats.length >= 2) {
                alert('최대 2석까지 선택 가능합니다.');
                return;
            }
            selectedSeats.push({
                seatId: seatId,
                seatRow: seatRow,
                seatCol: seatCol
            });
        }

        sessionStorage.setItem('selectedSeats_' + scheduleId, JSON.stringify(selectedSeats));
        updateInfo();
        renderZoneTabs();
        renderSeats(currentZoneSeats);
    }

    // ─────────────────────────────────────────────
    // 선택 좌석 정보 화면 업데이트 (사이드바용)
    //   [2026.05.29 김희재] label 헤더 + 세로 나열
    // ─────────────────────────────────────────────
    function updateInfo() {
        if (selectedSeats.length === 0) {
            document.getElementById('info').innerHTML =
                '<div class="label">선택한 좌석</div>좌석을 선택해 주세요';
            return;
        }

        var seatLabels = selectedSeats.map(function(s) {
            var zoneIndex = Math.floor((s.seatRow - 1) / ROWS_PER_ZONE);
            var zoneName = String.fromCharCode(65 + zoneIndex);
            return zoneName + '구역 ' + s.seatRow + '열 ' + s.seatCol + '번';
        }).join('<br>');

        var msg = '<div class="label">선택한 좌석</div>';
        msg += '✅ <b>' + selectedSeats.length + '개</b> 선택<br>';
        msg += '<span style="font-size:13px; color:#555;">' + seatLabels + '</span>';

        document.getElementById('info').innerHTML = msg;
    }

    // 예매 페이지로 이동 → 결제 폼까지 자동 redirect
    function goToBooking() {
        if (selectedSeats.length === 0) {
            alert('좌석을 먼저 선택해주세요!');
            return;
        }

        if (!confirm(selectedSeats.length + '개 좌석을 결제하시겠습니까?')) {
            return;
        }

        var seatIds = selectedSeats.map(function(s) {
            return s.seatId;
        }).join(',');

        sessionStorage.removeItem('selectedSeats_' + scheduleId);

        var form = document.createElement('form');
        form.method = 'POST';
        form.action = '/bookingCreate.do';

        var fields = {
            memberId  : memberId,
            scheduleId: scheduleId,
            seatIds   : seatIds
        };
        for (var key in fields) {
            var input = document.createElement('input');
            input.type  = 'hidden';
            input.name  = key;
            input.value = fields[key];
            form.appendChild(input);
        }
        document.body.appendChild(form);
        form.submit();
    }

    window.onload = function() {
        renderZoneTabs();
        loadZoneSeats('A');
        updateInfo();
    };
</script>
</body>
</html>
