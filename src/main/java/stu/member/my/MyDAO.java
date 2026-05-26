package stu.member.my;

/*
 * ============================================================
 * Project    : 관제 티켓 (Ticketing System)
 * Package    : stu.member.my
 * FileName   : MyDAO.java
 *
 * Developer  : 김희재 (feature/khj)
 * Created    : 2026.05.24
 * Modified   : 2026.05.24
 *
 * Description :
 *   - 마이페이지 DAO (DB 접근 계층)
 *   - AbstractDao 상속, MyBatis 매퍼 호출
 *   - 회원정보 조회/수정, 회원 탈퇴, 예매 내역 조회
 * ============================================================
 */

import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Repository;

import stu.common.dao.AbstractDao;

@Repository("myDAO")
public class MyDAO extends AbstractDao {

    /**
     * 회원정보 조회
     * @param map MEMBER_ID
     * @return 회원 1명의 정보 (MEMBER_ID, EMAIL, NAME, PHONE, BIRTH_DATE, ROLE)
     */
    @SuppressWarnings("unchecked")
    public Map<String, Object> selectMemberInfo(Map<String, Object> map) throws Exception {
        return (Map<String, Object>) selectOne("my.selectMemberInfo", map);
    }

    /**
     * 회원정보 수정 (이름, 휴대폰, 생년월일)
     * @param map MEMBER_ID, NAME, PHONE, BIRTH_DATE
     * @return 변경된 행 수
     */
    public int updateMemberInfo(Map<String, Object> map) throws Exception {
        Object result = update("my.updateMemberInfo", map);
        return result == null ? 0 : (Integer) result;
    }

    /**
     * 회원 탈퇴 (물리 삭제)
     * @param map MEMBER_ID
     * @return 삭제된 행 수
     */
    public int deleteMember(Map<String, Object> map) throws Exception {
        Object result = delete("my.deleteMember", map);
        return result == null ? 0 : (Integer) result;
    }
    
    /**
     * 활성 예매 건수 조회 (CANCELLED 제외)
     */
    public int countActiveBookings(Map<String, Object> param) throws Exception {
        return (Integer) selectOne("my.countActiveBookings", param);
    }

    /**
     * 예매 내역 조회 (회원 ID 기준 최신순)
     * @param map MEMBER_ID
     * @return 예매 목록
     */
    @SuppressWarnings("unchecked")
    public List<Map<String, Object>> selectBookingList(Map<String, Object> map) throws Exception {
        return (List<Map<String, Object>>) selectList("my.selectBookingList", map);
    }
}
