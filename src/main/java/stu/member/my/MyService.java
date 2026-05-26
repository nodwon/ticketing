package stu.member.my;

/*
 * ============================================================
 * Project    : 관제 티켓 (Ticketing System)
 * Package    : stu.member.my
 * FileName   : MyService.java
 *
 * Developer  : 김희재 (feature/khj)
 * Created    : 2026.05.24
 * Modified   : 2026.05.24
 *
 * Description :
 *   - 마이페이지 Service 인터페이스
 *   - 회원정보 조회/수정, 회원 탈퇴, 예매 내역 조회
 * ============================================================
 */

import java.util.List;
import java.util.Map;

public interface MyService {

    /** 회원정보 조회 */
    Map<String, Object> getMemberInfo(Map<String, Object> map) throws Exception;

    /** 회원정보 수정 (이름, 휴대폰, 생년월일) */
    int updateMemberInfo(Map<String, Object> map) throws Exception;

    /** 회원 탈퇴 (물리 삭제) */
    int deleteMember(Map<String, Object> map) throws Exception;

    /**
     * 활성 예매 건수 조회 (CANCELLED 제외)
     * - 회원 탈퇴 차단 여부 판단에 사용
     * @param param MEMBER_ID
     * @return PENDING + CONFIRMED 건수
     */
    int countActiveBookings(Map<String, Object> param) throws Exception;
    
    /** 예매 내역 조회 */
    List<Map<String, Object>> getBookingList(Map<String, Object> map) throws Exception;
}
