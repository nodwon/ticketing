<%--
    ============================================================
    Project  : 관제 티켓 (Ticketing System)
    Package  : views/seat
    FileName : seatSelect.jsp
    
    Developer : 정희영 (feature/jhyjhy)
    Created  : 2026.05.24
    Modified  : 2026.05.26
    
    Description :
    - 좌석 선택 화면
    - 좌석 현황을 시각적으로 표시
    - 좌석 클릭 시 임시 선점 처리
    - 좌석 구역(Zone) 탭으로 분할 표시 (10열씩 5구역)
    - 좌석 상태별 색상 구분
      * AVAILABLE : 회색 (선택 가능)
      * HELD      : 노랑  (선점됨, 클릭 불가)
      * RESERVED  : 빨강  (예매 완료, 클릭 불가)
      * SELECTED  : 파랑  (내가 선택한 좌석)
    ============================================================
--%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>좌석 선택 - 관제 티켓</title>
<style>
    body {
        font-family: 'Malgun Gothic', sans-serif;
        text-align: center;
        background: #f5f5f5;
        padding: 20px;
    }
    h1 { color: #333; }
    
    .stage {
        background: linear-gradient(90deg, #333, #555, #333);
        color: white;
        padding: 15px;
        margin: 20px auto;
        max-width: 600px;
        border-radius: 5px;
        font-weight: bold;
        letter-spacing: 5px;
    }
    
    /* ★ 추가: 구역 탭 스타일 */
    .zone-tabs {
        margin: 20px auto;
        max-width: 800px;
        display: flex;
        justify-content: center;
        gap: 5px;
        flex-wrap: wrap;
    }
    .zone-tab {
        padding: 10px 20px;
        background: #ddd;
        color: #555;
        border: none;
        border-radius: 5px 5px 0 0;
        cursor: pointer;
        font-weight: bold;
        font-size: 14px;
        transition: background 0.2s;
    }
    .zone-tab:hover { background: #aaa; color: white; }
    .zone-tab.active { background: #3498db; color: white; }
    .zone-tab .badge {
        display: inline-block;
        background: rgba(255,255,255,0.3);
        padding: 2px 6px;
        border-radius: 10px;
        font-size: 11px;
        margin-left: 5px;
    }
    
    .seat-map {
        display: inline-block;
        padding: 20px;
        background: white;
        border-radius: 10px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
    
    .seat-row {
        display: flex;
        justify-content: center;
        margin-bottom: 5px;
    }
    
    .seat {
        width: 30px;
        height: 30px;
        margin: 2px;
        border-radius: 5px;
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 10px;
        color: white;
        font-weight: bold;
        transition: transform 0.1s;
    }
    .seat:hover { transform: scale(1.1); }
    
    .seat.AVAILABLE { background: #888; }
    .seat.HELD      { background: #f5c842; cursor: not-allowed; }
    .seat.RESERVED  { background: #e74c3c; cursor: not-allowed; }
    .seat.SELECTED  { background: #3498db; }
    
    .legend {
        margin: 20px;
        display: flex;
        justify-content: center;
        gap: 20px;
    }
    .legend-item {
        display: flex;
        align-items: center;
        gap: 5px;
    }
    .legend-box {
        width: 20px;
        height: 20px;
        border-radius: 3px;
    }
    
    .info {
        margin-top: 20px;
        padding: 15px;
        background: #fff;
        border-radius: 5px;
        max-width: 500px;
        margin-left: auto;
        margin-right: auto;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
</style>
</head>
<body>

<h1>🎫 좌석 선택</h1>
<div class="stage">━━━ S T A G E ━━━</div>

<!-- ★ 추가: 구역 탭 -->
<div class="zone-tabs" id="zoneTabs">
    <p>구역 정보를 불러오는 중...</p>
</div>

<div class="seat-map" id="seatMap">
    <p>좌석 정보를 불러오는 중...</p>
</div>

<div class="legend">
    <div class="legend-item"><div class="legend-box" style="background:#888"></div>예매가능</div>
    <div class="legend-item"><div class="legend-box" style="background:#f5c842"></div>선점됨</div>
    <div class="legend-item"><div class="legend-box" style="background:#e74c3c"></div>예매완료</div>
    <div class="legend-item"><div class="legend-box" style="background:#3498db"></div>선택중</div>
</div>

<div class="info" id="info">
    좌석을 선택해 주세요
</div>


<div style="text-align:center; margin-top:20px;">
    <button onclick="goToBooking()" 
            style="padding:15px 50px; 
                   background:#3498db; 
                   color:white; 
                   border:none; 
                   border-radius:5px; 
                   font-size:16px; 
                   font-weight:bold;
                   cursor:pointer;">
        🎫 예매하기
    </button>
</div>

<script>
    // 페이지 진입 시 scheduleId 받기 (Controller에서 넘긴 값)
    var scheduleId = '${scheduleId}';
    
    // 테스트용 memberId (실제 운영 시 세션에서 가져와야 함)
    var memberId = '1';
    
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
            
            // 내가 선점한 좌석은 SELECTED(파란색)로 표시
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
    
    // 좌석 클릭 처리 (선점 / 해제 통합)
    function selectSeat(seatId, status, seatRow, seatCol) {
        var isMine = selectedSeats.some(function(s) {
            return s.seatId === seatId;
        });
        
        if (isMine) {
            releaseMySeat(seatId, seatRow, seatCol);
        } else if (status === 'HELD' || status === 'RESERVED') {
            alert('선택할 수 없는 좌석입니다.');
        } else {
            holdNewSeat(seatId, seatRow, seatCol);
        }
    }
    
    // 좌석 신규 점유 (hold.do 호출)
    function holdNewSeat(seatId, seatRow, seatCol) {
        var formData = 'seatId=' + seatId + '&memberId=' + memberId;
        
        var xhr = new XMLHttpRequest();
        xhr.open('POST', '/seat/hold.do', true);
        xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
        xhr.onload = function() {
            if (xhr.status === 200) {
                var res = JSON.parse(xhr.responseText);
                if (res.result === 'success') {
                    selectedSeats.push({
                        seatId: seatId,
                        seatRow: seatRow,
                        seatCol: seatCol
                    });
                    sessionStorage.setItem('selectedSeats_' + scheduleId, JSON.stringify(selectedSeats));
                    updateInfo();
                } else {
                    document.getElementById('info').innerHTML = '❌ ' + res.message;
                }
                loadSeats();
            }
        };
        xhr.send(formData);
    }
    
    // 좌석 선점 해제 (release.do 호출)
    function releaseMySeat(seatId, seatRow, seatCol) {
        var formData = 'seatId=' + seatId + '&memberId=' + memberId;
        
        var xhr = new XMLHttpRequest();
        xhr.open('POST', '/seat/release.do', true);
        xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
        xhr.onload = function() {
            if (xhr.status === 200) {
                var res = JSON.parse(xhr.responseText);
                if (res.result === 'success') {
                    selectedSeats = selectedSeats.filter(function(s) {
                        return s.seatId !== seatId;
                    });
                    sessionStorage.setItem('selectedSeats_' + scheduleId, JSON.stringify(selectedSeats));
                    updateInfo();
                } else {
                    document.getElementById('info').innerHTML = '❌ 해제 실패';
                }
                loadSeats();
            }
        };
        xhr.send(formData);
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
    
    // 예매 페이지로 이동
    function goToBooking() {
        if (selectedSeats.length === 0) {
            alert('좌석을 먼저 선택해주세요!');
            return;
        }
        
        if (!confirm(selectedSeats.length + '개 좌석을 예매하시겠습니까?')) {
            return;
        }
        
        var seatIds = selectedSeats.map(function(s) {
            return s.seatId;
        }).join(',');
        
        sessionStorage.removeItem('selectedSeats_' + scheduleId);
        
        location.href = '/booking/complete.do?scheduleId=' + scheduleId + '&seatIds=' + seatIds;
    }
    
    // 페이지 로드 시 좌석 불러오기
    window.onload = function() {
        loadSeats();
        updateInfo();
    };
</script>
</body>
</html>