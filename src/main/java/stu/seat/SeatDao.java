/**
 * ============================================================
 * Project  : 관제 티켓 (Ticketing System)
 * Package  : stu.seat
 * FileName : SeatDao.java
 * 
 * Developer : 정희영 (feature/jhyjhy)
 * Created  : 2026.05.24
 * Modified  : 2026.05.24
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
}