/**
 * ============================================================
 * Project    : 관제 티켓 (Ticketing System)
 * Package    : stu.concert
 * FileName   : GoodsService.java
 * Developer  : 주재현 (feature/jjh)
 * Created    : 2026.05.22
 * Modified   : 2026.05.27
 * ============================================================
 */
package stu.concert;

import java.util.List;
import java.util.Map;

public interface GoodsService {

    /** 공연 목록 (status 필터) - 안전 */
    List<Map<String, Object>> selectConcertList(Map<String, Object> paramMap) throws Exception;

    /** 공연 상세 - 안전 */
    Map<String, Object> selectConcertDetail(Long concertId) throws Exception;

    /** 공연 스케줄 - 안전 */
    List<Map<String, Object>> selectScheduleListByConcertId(Long concertId) throws Exception;

    /** ⚠️ 키워드 검색 - 의도적 취약 (SQL Injection 학습용) */
    List<Map<String, Object>> searchConcertsByKeyword(Map<String, Object> paramMap) throws Exception;
}
