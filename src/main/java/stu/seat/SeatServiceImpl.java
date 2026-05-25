/**
 * ============================================================
 * Project  : 관제 티켓 (Ticketing System)
 * Package  : stu.seat
 * FileName : SeatServiceImpl.java
 * 
 * Developer : 정희영 (feature/jhyjhy)
 * Created  : 2026.05.24
 * Modified  : 2026.05.24
 * 
 * Description :
 * - SeatService 인터페이스 구현체
 * - 좌석 비즈니스 로직 처리
 * - 좌석 점유/해제 시 @Transactional 적용
 *   (Race Condition 방지 - 동시 점유 차단)
 * ============================================================
 */
package stu.seat;

import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service("seatService")
public class SeatServiceImpl implements SeatService {
    
    @Resource(name="seatDao")
    private SeatDao seatDao;
    
    // 1. 좌석 현황 조회
    @Override
    public List<Map<String, Object>> selectSeatList(Map<String, Object> map) throws Exception {
        return seatDao.selectSeatList(map);
    }
    
    // 2. 좌석 임시 선점 (트랜잭션 적용 - Race Condition 방지)
    @Override
    @Transactional
    public int holdSeat(Map<String, Object> map) throws Exception {
        // 조건부 UPDATE: status가 AVAILABLE일 때만 HELD로 변경
        // 반환값 0 = 이미 다른 사람이 잡았거나 RESERVED 상태 (실패)
        // 반환값 1 = 성공
        return seatDao.holdSeat(map);
    }
    
    // 3. 좌석 선점 해제
    @Override
    @Transactional
    public int releaseSeat(Map<String, Object> map) throws Exception {
        return seatDao.releaseSeat(map);
    }
    
    // 4. 좌석 단건 조회
    @Override
    public Map<String, Object> selectSeat(Map<String, Object> map) throws Exception {
        return seatDao.selectSeat(map);
    }
}
