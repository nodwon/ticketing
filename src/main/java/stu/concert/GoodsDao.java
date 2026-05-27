/**
 * ============================================================
 * Project    : 관제 티켓 (Ticketing System)
 * Package    : stu.concert
 * FileName   : GoodsDao.java
 * Developer  : 주재현 (feature/jjh)
 * Created    : 2026.05.22
 * Modified   : 2026.05.27
 * ============================================================
 */
package stu.concert;

import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Repository;

import stu.common.dao.AbstractDao;

@Repository("goodsDao")
public class GoodsDao extends AbstractDao {

    /** 공연 목록 (안전) */
    public List<Map<String, Object>> selectConcertList(Map<String, Object> paramMap) {
        return selectList("concert.selectConcertList", paramMap);
    }

    /** 공연 상세 (안전) */
    @SuppressWarnings("unchecked")
    public Map<String, Object> selectConcertDetail(Long concertId) {
        return (Map<String, Object>) selectOne("concert.selectConcertDetail", concertId);
    }

    /** 공연 스케줄 (안전) */
    public List<Map<String, Object>> selectScheduleListByConcertId(Long concertId) {
        return selectList("concert.selectScheduleListByConcertId", concertId);
    }

    /** ⚠️ 키워드 검색 (취약) */
    public List<Map<String, Object>> searchConcertsByKeyword(Map<String, Object> paramMap) {
        return selectList("concert.searchConcertsByKeyword", paramMap);
    }
}
