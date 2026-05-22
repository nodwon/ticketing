package stu.concert;

import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;

public interface GoodsService {

    // 최신 공연 리스트
    List<Map<String, Object>> newGoodsList(Map<String, Object> map) throws Exception;

    // 베스트 공연 리스트
    List<Map<String, Object>> bestGoodsList(Map<String, Object> map) throws Exception;

    // 카테고리별 공연 리스트
    List<Map<String, Object>> cateGoodsList(Map<String, Object> map, String keyword) throws Exception;

    // 메인 검색
    List<Map<String, Object>> mainSearch(Map<String, Object> map, String keyword) throws Exception;

    // 공연 상세
    Map<String, Object> selectGoodsDetail(Map<String, Object> map, HttpServletRequest request) throws Exception;

    // 공연 옵션 (좌석 등)
    Map<String, Object> selectGoodsAtt(Map<String, Object> map) throws Exception;

    // 공연 등록
    void insertGoods(Map<String, Object> map, HttpServletRequest request) throws Exception;

    // 공연 수정
    void updateGoods(Map<String, Object> map, HttpServletRequest request) throws Exception;

    // 공연 삭제
    void deleteGoods(Map<String, Object> map, HttpServletRequest request) throws Exception;

    // 좋아요 추가
    void insertGoodsLike(Map<String, Object> map) throws Exception;

    // 좋아요 삭제
    void deleteGoodsLike(Map<String, Object> map) throws Exception;

    // 장바구니 추가
    void insertBasket(Map<String, Object> map, HttpServletRequest request) throws Exception;

    // 옵션 PK 가져오기
    Map<String, Object> selectGoodsAttNum(Map<String, Object> map) throws Exception;

    // 장바구니 PK 가져오기
    List<Map<String, Object>> selectBasketNo(Map<String, Object> map) throws Exception;

    // QNA 리스트
    List<Map<String, Object>> selectGoodsQna(Map<String, Object> map) throws Exception;
    // QNA 등록
    void insertGoodsQna(Map<String, Object> map, HttpServletRequest request) throws Exception;

    // QNA 답변
    void updateGoodsQna(Map<String, Object> map, HttpServletRequest request) throws Exception;

    // 리뷰 리스트
    List<Map<String, Object>> selectReviewList(Map<String, Object> map) throws Exception;

    // 리뷰 등록
    void insertGoodsReview(Map<String, Object> map, HttpServletRequest request) throws Exception;

    // 리뷰 수정
    void updateReview(Map<String, Object> map, HttpServletRequest request) throws Exception;

    // 구매 리스트 삭제
    void gumeListDelete(Map<String, Object> map) throws Exception;

}