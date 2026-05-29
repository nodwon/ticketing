/**
 * ============================================================
 * Project  : 관제 티켓 (Ticketing System)
 * Package  : stu.seat
 * FileName : SeatService.java
 * 
 * Developer : 정희영 (feature/jhyjhy)
 * Created  : 2026.05.24
 * Modified  : 2026.05.24
 * Modified  : 2026.05.29 - 김희재 (구역별 좌석 조회 추가, 봇 탐지용)
 * 
 * Description :
 * - 좌석 현황 조회 (스케줄별 전체 좌석)
 * - 좌석 임시 선점 (AVAILABLE → HELD)
 * - 좌석 선점 해제 (HELD → AVAILABLE)
 * - 좌석 단건 조회 (가격, 상태 확인용)
 * - 구역별 좌석 조회 (봇 탐지용) [김희재 추가]
 * ============================================================
 */
package stu.seat;

import java.util.List;
import java.util.Map;

public interface SeatService {
    
    // 1. 좌석 현황 조회 (특정 스케줄의 모든 좌석)
    List<Map<String, Object>> selectSeatList(Map<String, Object> map) throws Exception;
    
    // 2. 좌석 임시 선점 (AVAILABLE → HELD)
    int holdSeat(Map<String, Object> map) throws Exception;
    
    // 3. 좌석 선점 해제 (HELD → AVAILABLE)
    int releaseSeat(Map<String, Object> map) throws Exception;
    
    // 4. 좌석 단건 조회 (가격, 상태 확인용)
    Map<String, Object> selectSeat(Map<String, Object> map) throws Exception;
    
    // 5. 구역별 좌석 조회 (봇 탐지용)
    //    [2026.05.29 김희재 추가]
    List<Map<String, Object>> selectSeatListByZone(Map<String, Object> map) throws Exception;
}
