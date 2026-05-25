<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>좌석 선택 - ${scheduleInfo.TITLE}</title>
<style>
    body { font-family: 'Malgun Gothic', sans-serif; background: #f5f5f5; margin: 0; padding: 20px; }
    .container { max-width: 900px; margin: 0 auto; background: #fff; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    h1 { color: #333; border-bottom: 2px solid #ff6b6b; padding-bottom: 10px; }
    .info-box {
        background: #fff8f8;
        border-left: 4px solid #ff6b6b;
        padding: 15px 20px;
        margin: 20px 0;
        border-radius: 4px;
    }
    .info-box p { margin: 5px 0; color: #555; }
    .stage {
        background: #333;
        color: #fff;
        text-align: center;
        padding: 15px;
        margin: 30px 0 20px 0;
        border-radius: 6px;
        letter-spacing: 8px;
        font-weight: bold;
    }
    .legend {
        display: flex;
        justify-content: center;
        gap: 20px;
        margin: 15px 0 25px 0;
        font-size: 13px;
        color: #666;
    }
    .legend-item { display: flex; align-items: center; gap: 6px; }
    .legend-box { width: 18px; height: 18px; border-radius: 3px; }
    .seat-map {
        display: grid;
        grid-template-columns: repeat(4, 80px);
        gap: 10px;
        justify-content: center;
        margin: 20px 0;
    }
    .seat {
        width: 80px; height: 80px;
        border-radius: 8px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 14px;
        font-weight: bold;
        cursor: pointer;
        transition: all 0.15s;
        user-select: none;
    }
    .seat.available { background: #e0e0e0; color: #333; }
    .seat.available:hover { background: #ffd2d2; }
    .seat.held { background: #ffd54f; color: #333; cursor: not-allowed; }
    .seat.reserved { background: #888; color: #fff; cursor: not-allowed; }
    .seat.selected { background: #ff6b6b; color: #fff; }
    .summary {
        background: #fafafa;
        padding: 20px;
        border-radius: 8px;
        margin-top: 25px;
        text-align: center;
    }
    .summary .total {
        font-size: 24px;
        font-weight: bold;
        color: #ff6b6b;
        margin: 10px 0;
    }
    .btn-book {
        background: #ff6b6b;
        color: #fff;
        border: none;
        padding: 14px 50px;
        font-size: 16px;
        font-weight: bold;
        border-radius: 6px;
        cursor: pointer;
        margin-top: 15px;
    }
    .btn-book:hover { background: #e85c5c; }
    .btn-book:disabled { background: #ccc; cursor: not-allowed; }
    .selected-list { color: #666; font-size: 14px; margin: 5px 0; }
</style>
</head>
<body>

<div class="container">

    <h1>${scheduleInfo.TITLE}</h1>

    <!-- 공연 정보 -->
    <div class="info-box">
        <p><strong>아티스트:</strong> ${scheduleInfo.ARTIST}</p>
        <p><strong>장소:</strong> ${scheduleInfo.VENUE}</p>
        <p><strong>공연일시:</strong> ${scheduleInfo.PERFORMANCEDATE}</p>
        <p><strong>잔여 좌석:</strong> ${scheduleInfo.AVAILABLESEATS} / ${scheduleInfo.TOTALSEATS}석</p>
    </div>

    <!-- 무대 -->
    <div class="stage">S T A G E</div>

    <!-- 범례 -->
    <div class="legend">
        <div class="legend-item"><span class="legend-box" style="background:#e0e0e0;"></span>예매가능</div>
        <div class="legend-item"><span class="legend-box" style="background:#ffd54f;"></span>선점중</div>
        <div class="legend-item"><span class="legend-box" style="background:#888;"></span>예매완료</div>
        <div class="legend-item"><span class="legend-box" style="background:#ff6b6b;"></span>선택</div>
    </div>

    <!-- 좌석맵 -->
    <div class="seat-map">
        <c:forEach var="seat" items="${seatList}">
            <div class="seat 
                <c:choose>
                    <c:when test="${seat.STATUS == 'AVAILABLE'}">available</c:when>
                    <c:when test="${seat.STATUS == 'HELD'}">held</c:when>
                    <c:when test="${seat.STATUS == 'RESERVED'}">reserved</c:when>
                </c:choose>"
                data-seat-id="${seat.SEATID}"
                data-price="${seat.PRICE}"
                data-row="${seat.SEATROW}"
                data-col="${seat.SEATCOL}">
                ${seat.SEATROW}-${seat.SEATCOL}
            </div>
        </c:forEach>
    </div>

    <!-- 선택 정보 + 예매하기 -->
    <div class="summary">
        <div class="selected-list" id="selectedList">선택된 좌석이 없습니다</div>
        <div>합계</div>
        <div class="total" id="totalPrice">0원</div>
        
        <!-- 실제 POST 요청을 보낼 form -->
        <form id="bookingForm" action="<c:url value='/bookingCreate.do'/>" method="post">
            <input type="hidden" name="memberId" value="1" />
            <input type="hidden" name="scheduleId" value="${scheduleInfo.SCHEDULEID}" />
            <input type="hidden" name="seatIds" id="seatIdsInput" value="" />
            <button type="submit" class="btn-book" id="btnBook" disabled>예매하기</button>
        </form>
    </div>

</div>

<script>
    var selectedSeats = [];  // {seatId, price, row, col} 객체 배열

    document.querySelectorAll('.seat.available').forEach(function(seat) {
        seat.addEventListener('click', function() {
            var seatId = this.dataset.seatId;
            var price = parseInt(this.dataset.price);
            var row = this.dataset.row;
            var col = this.dataset.col;

            var index = selectedSeats.findIndex(function(s) { return s.seatId === seatId; });

            if (index >= 0) {
                // 이미 선택된 좌석 → 해제
                selectedSeats.splice(index, 1);
                this.classList.remove('selected');
            } else {
                // 최대 4석 제한
                if (selectedSeats.length >= 4) {
                    alert('최대 4석까지 선택 가능합니다');
                    return;
                }
                selectedSeats.push({
                    seatId: seatId,
                    price: price,
                    row: row,
                    col: col
                });
                this.classList.add('selected');
            }

            updateSummary();
        });
    });

    function updateSummary() {
        var total = 0;
        var labels = [];

        selectedSeats.forEach(function(s) {
            total += s.price;
            labels.push(s.row + '열 ' + s.col + '번');
        });

        // 선택된 좌석 표시
        if (selectedSeats.length === 0) {
            document.getElementById('selectedList').textContent = '선택된 좌석이 없습니다';
        } else {
            document.getElementById('selectedList').textContent = '선택: ' + labels.join(', ');
        }

        // 합계
        document.getElementById('totalPrice').textContent = total.toLocaleString() + '원';

        // hidden input에 좌석 ID들 콤마로 연결
        var seatIdsStr = selectedSeats.map(function(s) { return s.seatId; }).join(',');
        document.getElementById('seatIdsInput').value = seatIdsStr;

        // 버튼 활성화/비활성화
        document.getElementById('btnBook').disabled = (selectedSeats.length === 0);
    }

    // form 제출 전 최종 확인
    document.getElementById('bookingForm').addEventListener('submit', function(e) {
        if (selectedSeats.length === 0) {
            alert('좌석을 선택해주세요');
            e.preventDefault();
            return;
        }
        if (!confirm(selectedSeats.length + '석을 예매하시겠습니까?\n합계: ' 
                + document.getElementById('totalPrice').textContent)) {
            e.preventDefault();
        }
    });
</script>

</body>
</html>