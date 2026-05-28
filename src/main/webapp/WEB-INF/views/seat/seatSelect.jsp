<%--
 * ============================================================
 * Project  : 관제 티켓 (Ticketing System)
 * FileName : seatSelect.jsp
 * Modified  : 2026.05.28 (UI 공통 테마 통일 - theme.css 적용)
 *
 * Description :
 *   - 좌석 클릭 시 임시 선점 처리
 *   - 좌석 구역(Zone) 탭으로 분할 표시 (10열씩 5구역)
 *   - 좌석 상태별 색상 구분
 *     * AVAILABLE : 회색 (선택 가능)
 *     * HELD      : 노랑  (선점됨, 클릭 불가)
 *     * RESERVED  : 빨강  (예매 완료, 클릭 불가)
 *     * SELECTED  : 메인레드 (내가 선택한 좌석)
 *   ※ JS 로직/클래스명은 기능에 직결되므로 변경 없음, 스타일 값만 통일
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

    .ss-stage {
        background: var(--dark);
        color: var(--white);
        padding: 16px; margin: 24px auto 20px;
        max-width: 640px; border-radius: var(--radius);
        font-weight: 700; letter-spacing: 6px; text-align: center;
        font-family: var(--font-en);
        border-bottom: 3px solid var(--red);
    }

    .zone-tabs {
        margin: 0 auto 0; max-width: 860px;
        display: flex; justify-content: center; gap: 4px; flex-wrap: wrap;
    }
    .zone-tab {
        padding: 11px 20px;
        background: var(--white); color: var(--muted);
        border: 1px solid var(--border); border-bottom: none;
        border-radius: var(--radius) var(--radius) 0 0;
        cursor: pointer; font-weight: 600; font-size: 14px;
        transition: all .2s;
    }
    .zone-tab:hover { background: var(--gray); color: var(--text); }
    .zone-tab.active { background: var(--dark); color: var(--white); border-color: var(--dark); }
    .zone-tab .badge {
        display: inline-block; background: var(--red);
        padding: 1px 7px; border-radius: 10px;
        font-size: 11px; margin-left: 6px; color: var(--white);
    }

    .seat-map {
        display: inline-block; padding: 24px;
        background: var(--white);
        border: 1px solid var(--border);
        border-radius: var(--radius-lg);
        box-shadow: var(--shadow);
    }
    .seat-map-wrap { text-align: center; }

    .seat-row { display: flex; justify-content: center; margin-bottom: 5px; }
    .seat {
        width: 30px; height: 30px; margin: 2px;
        border-radius: var(--radius); cursor: pointer;
        display: flex; align-items: center; justify-content: center;
        font-size: 10px; color: var(--white); font-weight: 700;
        transition: transform .1s;
    }
    .seat:hover { transform: scale(1.12); }
    /* 좌석 상태색 - 기능 구분 유지, 톤만 정리 */
    .seat.AVAILABLE { background: #bdbdbd; }
    .seat.HELD      { background: #f5c842; cursor: not-allowed; }
    .seat.RESERVED  { background: #777; cursor: not-allowed; }
    .seat.SELECTED  { background: var(--red); }

    .legend {
        margin: 22px auto; display: flex;
        justify-content: center; gap: 22px; flex-wrap: wrap;
        font-size: 13px; color: var(--text);
    }
    .legend-item { display: flex; align-items: center; gap: 6px; }
    .legend-box { width: 18px; height: 18px; border-radius: 3px; }

    .info {
        margin: 0 auto; padding: 18px 22px;
        background: var(--white);
        border: 1px solid var(--border);
        border-radius: var(--radius-lg);
        max-width: 560px; text-align: center;
        box-shadow: var(--shadow); font-size: 15px; color: var(--text);
    }
    .info b { color: var(--red); }

    .ss-actions { text-align: center; margin-top: 24px; padding-bottom: 60px; }
</style>
</head>
<body>

<!-- 페이지 헤더 (공통 톤) -->
<div class="tk-page-head">
    <div class="tk-page-head-inner">
        <div class="brand">SEAT SELECTION</div>
        <h1>좌석 선택</h1>
        <p>원하는 좌석을 선택하세요. 최대 4석까지 선택 가능합니다.</p>
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

<div class="ss-stage">━━━ S T A G E ━━━</div>

<!-- 구역 탭 -->
<div class="zone-tabs" id="zoneTabs">
    <p class="tk-text-muted">구역 정보를 불러오는 중...</p>
</div>

<div class="seat-map-wrap">
    <div class="seat-map" id="seatMap">
        <p class="tk-text-muted">좌석 정보를 불러오는 중...</p>
    </div>
</div>

<div class="legend">
    <div class="legend-item"><div class="legend-box" style="background:#bdbdbd"></div>예매가능</div>
    <div class="legend-item"><div class="legend-box" style="background:#f5c842"></div>선점됨</div>
    <div class="legend-item"><div class="legend-box" style="background:#777"></div>예매완료</div>
    <div class="legend-item"><div class="legend-box" style="background:#e8001c"></div>선택중</div>
</div>

<div class="info" id="info">
    좌석을 선택해 주세요
</div>

<div class="ss-actions">
    <button onclick="goToBooking()" class="tk-btn tk-btn-primary tk-btn-lg">🎫 예매하기</button>
</div>

<script>
    // 페이지 진입 시 scheduleId 받기 (Controller에서 넘긴 값)
    var scheduleId = '${scheduleId}';

    // 세션에서 로그인 회원 ID 가져옴 (하드코딩 제거)
    // 서버 측 BookingController 가 다시 한번 SESSION_NO 로 덮어쓰므로
    // 클라이언트 변조는 차단됨. 여기서는 좌석 hold/release 호출에만 사용.
    var memberId = '<c:out value="${sessionScope.SESSION_NO}"/>';
    if (!memberId) {
        alert('로그인이 필요합니다.');
        location.href = '/loginForm.do';
    }

    // ★ 추가: 전체 좌석 데이터 + 현재 구역
    var allSeats = [];
    var currentZone = 'A';
    var ROWS_PER_ZONE = 10;  // 한 구역당 10열 (100석)

    // sessionStorage에서 복원 (새로고침해도 유지)
    var selectedSeats = JSON.parse(sessionStorage.getItem('selectedSeats_' + scheduleId) || '[]');

    // 좌석 목록 로드 (★ 변경: 전체 받고 필터링)
    function loadSeats() {
        var xhr = new XMLHttpRequest();
        xhr.open('GET', '/seat/list.do?scheduleId=' + scheduleId, true);
        xhr.onload = function() {
            if (xhr.status === 200) {
                allSeats = JSON.parse(xhr.responseText);
                renderZoneTabs();
                renderSeats(getCurrentZoneSeats());
            }
        };
        xhr.send();
    }

    // ★ 추가: 구역 탭 그리기
    function renderZoneTabs() {
        var maxRow = Math.max.apply(null, allSeats.map(function(s) { return s.seatRow; }));
        var zoneCount = Math.ceil(maxRow / ROWS_PER_ZONE);

        var html = '';
        for (var i = 0; i < zoneCount; i++) {
            var zoneName = String.fromCharCode(65 + i);  // A, B, C, D...
            var startRow = i * ROWS_PER_ZONE + 1;
            var endRow = Math.min((i + 1) * ROWS_PER_ZONE, maxRow);

            // 해당 구역에 내가 선택한 좌석 수 카운트
            var mineInZone = selectedSeats.filter(function(s) {
                return s.seatRow >= startRow && s.seatRow <= endRow;
            }).length;

            var activeClass = (zoneName === currentZone) ? 'active' : '';
            var badge = mineInZone > 0
                ? '<span class="badge">' + mineInZone + '</span>'
                : '';

            html += '<button class="zone-tab ' + activeClass + '"';
            html += ' onclick="switchZone(\'' + zoneName + '\')">';
            html += zoneName + '구역 (' + startRow + '~' + endRow + '열)' + badge;
            html += '</button>';
        }

        document.getElementById('zoneTabs').innerHTML = html;
    }

    // ★ 추가: 현재 구역의 좌석만 필터링
    function getCurrentZoneSeats() {
        var zoneIndex = currentZone.charCodeAt(0) - 65;  // A=0, B=1, ...
        var startRow = zoneIndex * ROWS_PER_ZONE + 1;
        var endRow = (zoneIndex + 1) * ROWS_PER_ZONE;

        return allSeats.filter(function(seat) {
            return seat.seatRow >= startRow && seat.seatRow <= endRow;
        });
    }

    // ★ 추가: 구역 전환
    function switchZone(zone) {
        currentZone = zone;
        renderZoneTabs();
        renderSeats(getCurrentZoneSeats());
    }

    // 좌석 그리기
    function renderSeats(seats) {
        var html = '';
        var currentRow = null;

        seats.forEach(function(seat) {
            if (currentRow !== seat.seatRow) {
                if (currentRow !== null) html += '</div>';
                html += '<div class="seat-row">';
                currentRow = seat.seatRow;
            }

            // 내가 선점한 좌석은 SELECTED(메인레드)로 표시
            var isMine = selectedSeats.some(function(s) {
                return s.seatId === seat.seatId;
            });
            var displayStatus = isMine ? 'SELECTED' : seat.status;

            html += '<div class="seat ' + displayStatus + '"';
            html += ' data-seat-id="' + seat.seatId + '"';
            html += ' onclick="selectSeat(' + seat.seatId + ', \'' + seat.status + '\', ' + seat.seatRow + ', ' + seat.seatCol + ')"';
            html += ' title="' + seat.seatRow + '열 ' + seat.seatCol + '번 / ' + seat.price + '원">';
            html += seat.seatCol;
            html += '</div>';
        });
        if (currentRow !== null) html += '</div>';

        document.getElementById('seatMap').innerHTML = html;
    }

    // 좌석 클릭 처리 (선택 / 해제 - 모두 로컬 배열만 조작)
    // [2026-05-26 정책 변경]
    //   이전: 클릭 즉시 /seat/hold.do 호출 → seats.status=HELD
    //   현재: 클릭은 로컬 selectedSeats 에만 저장.
    //         "다음 단계" 버튼으로 /bookingCreate.do 호출 시
    //         BookingService 가 트랜잭션 안에서 일괄 HELD + PENDING 생성.
    //   효과: 결제 페이지 진입 전에는 다른 사용자에게 좌석이 계속 보이고
    //         클릭만으로는 점유되지 않음.
    function selectSeat(seatId, status, seatRow, seatCol) {
        var isMine = selectedSeats.some(function(s) {
            return s.seatId === seatId;
        });

        if (isMine) {
            // 선택 취소
            selectedSeats = selectedSeats.filter(function(s) {
                return s.seatId !== seatId;
            });
        } else if (status === 'HELD' || status === 'RESERVED') {
            alert('선택할 수 없는 좌석입니다.');
            return;
        } else {
            // 최대 4석 제한 (서버측 BookingService 와 일치)
            if (selectedSeats.length >= 4) {
                alert('최대 4석까지 선택 가능합니다.');
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
        // 화면만 다시 그리기 (서버 호출 없음)
        renderSeats(getCurrentZoneSeats());
    }

    // 선택 좌석 정보 화면 업데이트
    function updateInfo() {
    if (selectedSeats.length === 0) {
        document.getElementById('info').innerHTML = '좌석을 선택해 주세요';
        return;
    }

    // ★ 구역 정보 포함해서 라벨 만들기
    var seatLabels = selectedSeats.map(function(s) {
        // seatRow를 기반으로 구역 계산
        var zoneIndex = Math.floor((s.seatRow - 1) / ROWS_PER_ZONE);
        var zoneName = String.fromCharCode(65 + zoneIndex);  // A, B, C...
        return zoneName + '구역 ' + s.seatRow + '열 ' + s.seatCol + '번';
    }).join(', ');

    var msg = '✅ 선택한 좌석: <b>' + selectedSeats.length + '개</b>';
    msg += '<br>';
    msg += '<span style="font-size:14px; color:#555;">' + seatLabels + '</span>';

    document.getElementById('info').innerHTML = msg;
	}

    // 예매 페이지로 이동 → 결제 폼까지 자동 redirect
    // [2026.05.26 결제 모듈(king) 통합]
    //   기존 : GET /booking/complete.do?... → 404 (해당 매핑 없음)
    //   변경 : POST /bookingCreate.do (예매 생성, PENDING)
    //             → BookingController 가 /payment/form.do?bookingId=N 으로 redirect
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

        // 동적으로 form 생성 후 POST 전송
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

    // 페이지 로드 시 좌석 불러오기
    window.onload = function() {
        loadSeats();
        updateInfo();
    };
</script>
</body>
</html>
