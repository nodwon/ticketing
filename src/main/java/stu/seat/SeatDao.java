/**
 * ============================================================
 * Project  : 관제 티켓 (Ticketing System)
 * Package  : stu.seat
 * FileName : SeatDao.java
 * 
 * Developer : 정희영 (feature/jhyjhy)
 * Created  : 2026.05.24
 * Modified  : 2026.05.24
 * Modified  : 2026.05.29 - 김희재 (구역별 좌석 조회 추가, 봇 탐지용)
 * 
 * Description :
 * - 좌석 DB 접근 계층 (DAO)
 * - AbstractDao 상속하여 MyBatis SqlSession 사용
 * - Seat_SQL.xml의 SQL 호출
 *   namespace : "seat"
 * ============================================================
 */
package stu.seat;

import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Repository;

import stu.common.dao.AbstractDao;

@Repository("seatDao")
public class SeatDao extends AbstractDao {
    
    // 1. 좌석 현황 조회 (특정 스케줄의 모든 좌석)
    @SuppressWarnings("unchecked")
    public List<Map<String, Object>> selectSeatList(Map<String, Object> map) throws Exception {
        return (List<Map<String, Object>>) selectList("seat.selectSeatList", map);
    }
    
    // 2. 좌석 임시 선점 (AVAILABLE → HELD)
    //    조건부 UPDATE이므로 affected rows로 성공/실패 판단
    public int holdSeat(Map<String, Object> map) throws Exception {
        return (int) update("seat.holdSeat", map);
    }
    
    // 3. 좌석 선점 해제 (HELD → AVAILABLE)
    public int releaseSeat(Map<String, Object> map) throws Exception {
        return (int) update("seat.releaseSeat", map);
    }
    
    // 4. 좌석 단건 조회
    @SuppressWarnings("unchecked")
    public Map<String, Object> selectSeat(Map<String, Object> map) throws Exception {
        return (Map<String, Object>) selectOne("seat.selectSeat", map);
    }
    
    // 5. 구역별 좌석 조회 (봇 탐지용)
    //    [2026.05.29 김희재 추가]
    //    - 구역(A~E) 클릭 시 호출, seat_row 범위로 필터링
    //    - 정상 사용자는 여러 구역을 둘러보고, 봇은 구역 조회를 건너뛰는 패턴
    @SuppressWarnings("unchecked")
    public List<Map<String, Object>> selectSeatListByZone(Map<String, Object> map) throws Exception {
        return (List<Map<String, Object>>) selectList("seat.selectSeatListByZone", map);
    }
}
