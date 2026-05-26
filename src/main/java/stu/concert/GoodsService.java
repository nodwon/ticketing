/**
 * ============================================================
 * Project    : 관제 티켓 (Ticketing System)
 * Package    : stu.concert
 * FileName   : GoodsService.java
 * Developer  : 주재현 (feature/jjh)
 * Created    : 2026.05.22
 * Modified   : 2026.05.26
 * Description: 공연(Concert) 비즈니스 서비스 인터페이스
 *              - 공연 목록 / 상세 / 검색
 *              - 공연 스케줄(concert_schedules) 조회
 * ============================================================
 */
package stu.concert;

import java.util.List;
import java.util.Map;

public interface GoodsService {

    /** 공연 목록 조회 (대소문자 무관 검색, 정렬) */
    List<Map<String, Object>> selectConcertList(Map<String, Object> paramMap) throws Exception;

    /** 공연 상세 조회 */
    Map<String, Object> selectConcertDetail(Long concertId) throws Exception;

    /** 검색 (제목/아티스트/공연장) */
    List<Map<String, Object>> searchConcerts(String keyword) throws Exception;

    /** 공연 스케줄 목록 (concert_schedules) */
    List<Map<String, Object>> selectScheduleListByConcertId(Long concertId) throws Exception;
}
