/**
 * ============================================================
 * Project    : 관제 티켓 (Ticketing System)
 * Package    : stu.concert
 * FileName   : GoodsDao.java
 * Developer  : 주재현 (feature/jjh)
 * Created    : 2026.05.22
 * Modified   : 2026.05.26
 * Description: 공연(Concert) DAO
 *              - Mapper namespace = "concert"
 * ============================================================
 */
package stu.concert;

import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Repository;

import stu.common.dao.AbstractDao;

@Repository("goodsDao")
public class GoodsDao extends AbstractDao {

    /** 공연 목록 (검색/정렬) */
    public List<Map<String, Object>> selectConcertList(Map<String, Object> paramMap) {
        return selectList("concert.selectConcertList", paramMap);
    }

    /** 공연 상세 */
    @SuppressWarnings("unchecked")
    public Map<String, Object> selectConcertDetail(Long concertId) {
        return (Map<String, Object>) selectOne("concert.selectConcertDetail", concertId);
    }

    /** 통합 검색 */
    public List<Map<String, Object>> searchConcerts(String keyword) {
        return selectList("concert.searchConcerts", keyword);
    }

    /** 공연 스케줄 목록 */
    public List<Map<String, Object>> selectScheduleListByConcertId(Long concertId) {
        return selectList("concert.selectScheduleListByConcertId", concertId);
    }
}
