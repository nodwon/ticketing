/**
 * ============================================================
 * Project    : 관제 티켓 (Ticketing System)
 * Package    : stu.concert
 * FileName   : GoodsServiceImpl.java
 * Developer  : 주재현 (feature/jjh)
 * Created    : 2026.05.22
 * Modified   : 2026.05.26
 * Description: GoodsService 구현체
 * ============================================================
 */
package stu.concert;

import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

@Service("goodsService")
public class GoodsServiceImpl implements GoodsService {

    private static final Logger logger = LoggerFactory.getLogger(GoodsServiceImpl.class);

    @Resource(name = "goodsDao")
    private GoodsDao goodsDao;

    @Override
    public List<Map<String, Object>> selectConcertList(Map<String, Object> paramMap) throws Exception {
        logger.info("[SERVICE] selectConcertList param={}", paramMap);
        return goodsDao.selectConcertList(paramMap);
    }

    @Override
    public Map<String, Object> selectConcertDetail(Long concertId) throws Exception {
        logger.info("[SERVICE] selectConcertDetail id={}", concertId);
        return goodsDao.selectConcertDetail(concertId);
    }

    @Override
    public List<Map<String, Object>> searchConcerts(String keyword) throws Exception {
        logger.info("[SERVICE] searchConcerts keyword={}", keyword);
        return goodsDao.searchConcerts(keyword);
    }

    @Override
    public List<Map<String, Object>> selectScheduleListByConcertId(Long concertId) throws Exception {
        logger.info("[SERVICE] selectScheduleListByConcertId id={}", concertId);
        return goodsDao.selectScheduleListByConcertId(concertId);
    }
}
