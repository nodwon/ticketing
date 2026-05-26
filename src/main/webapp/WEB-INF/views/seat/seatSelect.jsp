<%--
    ============================================================
    Project  : 관제 티켓 (Ticketing System)
    Package  : views/seat
    FileName : seatSelect.jsp
    
    Developer : 정희영 (feature/jhyjhy)
    Created  : 2026.05.24
    Modified  : 2026.05.24
    
    Description :
    - 좌석 선택 화면
    - 좌석 현황을 시각적으로 표시
    - 좌석 클릭 시 임시 선점 처리
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
    
    // 좌석 목록 로드
    function loadSeats() {
        var xhr = new XMLHttpRequest();
        xhr.open('GET', '/seat/list.do?scheduleId=' + scheduleId, true);
        xhr.onload = function() {
            if (xhr.status === 200) {
                var seats = JSON.parse(xhr.responseText);
                renderSeats(seats);
            }
        };
        xhr.send();
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
        
        // ★ 추가: 내가 선점한 좌석은 SELECTED(파란색)로 표시
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
    
 	// sessionStorage에서 복원 (새로고침해도 유지)
    var selectedSeats = JSON.parse(sessionStorage.getItem('selectedSeats_' + scheduleId) || '[]');
    
    // 좌석 클릭 처리 (선점 / 해제 통합)
    function selectSeat(seatId, status, seatRow, seatCol) {
        // 내가 이미 선택한 좌석인지 확인 (3번: 두번 클릭 = 취소)
        var isMine = selectedSeats.some(function(s) {
            return s.seatId === seatId;
        });
        
        if (isMine) {
            // 내가 선택한 좌석을 다시 클릭 → 해제
            releaseMySeat(seatId, seatRow, seatCol);
        } else if (status === 'HELD' || status === 'RESERVED') {
            // 남의 점유 또는 예매완료 좌석
            alert('선택할 수 없는 좌석입니다.');
        } else {
            // 신규 점유
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
                    // 선택 목록에서 제거
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
        
        // 좌석 라벨 만들기: "1열 5번", "1열 6번" ...
        var seatLabels = selectedSeats.map(function(s) {
            return s.seatRow + '열 ' + s.seatCol + '번';
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
    
    // 명세 15번: POST /api/bookings
    var requestBody = {
        schedule_id: parseInt(scheduleId),
        seat_ids: selectedSeats.map(function(s) { return s.seatId; }),
        payment_method: 'CARD'   // 명세에 있는 필드 (값은 임시)
    };
    
    fetch('/api/bookings', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(requestBody)
    })
    .then(function(res) {
        if (!res.ok) {
            throw new Error('예매 요청 실패: HTTP ' + res.status);
        }
        return res.json();
    })
    .then(function(data) {
        // 명세 15번 Response: 201 Created / booking_id
        if (data.booking_id) {
            // sessionStorage 정리 (예매 완료했으니까)
            sessionStorage.removeItem('selectedSeats_' + scheduleId);
            
            // 완료 페이지로 이동
            location.href = '/bookingComplete.do?bookingId=' + data.booking_id;
        } else {
            alert('예매 처리 중 오류가 발생했습니다.');
        }
    })
    .catch(function(err) {
        console.error('예매 오류:', err);
        alert('예매 실패: ' + err.message);
    });
	}
    
    
    // 페이지 로드 시 좌석 불러오기
    window.onload = function() {
    loadSeats();
    updateInfo();  // 새로고침 시 복원된 좌석 표시
	};
</script>
</body>
</html>