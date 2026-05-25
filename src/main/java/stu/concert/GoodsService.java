/**
 * ============================================================
 * Project    : 관제 티켓 (Ticketing System)
 * Package    : stu.concert
 * FileName   : GoodsService.java
 * Developer  : 주재현 (feature/jjh)
 * Created    : 2026.05.22
 * Modified   : 2026.05.25
 * Description: 공연(Concert) 비즈니스 서비스 인터페이스
 *              - 공연 목록 조회 (검색/정렬)
 *              - 공연 상세 조회
 *              - 게시판 후기(post_type=REVIEW) 조회
 *              - Q&A (qna_posts) 조회
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

    /** 후기 목록 (post_type='REVIEW') */
    List<Map<String, Object>> selectReviewPosts() throws Exception;

    /** Q&A 목록 */
    List<Map<String, Object>> selectQnaPosts() throws Exception;
}
