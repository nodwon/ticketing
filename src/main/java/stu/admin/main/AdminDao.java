package stu.admin.main;

/**
 * ============================================================
 *  Project   : 관제 티켓 (Ticketing System)
 *  Package   : stu.admin.main
 *  FileName  : AdminDao.java
 *
 *  Developer : 김태희 (feature/kth)
 *  Created   : 2026.05.24
 *  Modified  : 2026.05.27
 *
 *  Description :
 *    - 관리자 화면 데이터 접근 객체 (DAO)
 *    - AbstractDao 상속하여 SqlSessionTemplate 자동 주입
 *    - MyBatis namespace : "admin"  (Admin_SQL.xml)
 *
 *  History :
 *    2026.05.25 - 스마트 공연 삭제용 메서드 추가
 *                 · countBookingsByConcert / deleteConcertHard
 *                 · deleteSchedulesByConcert / deleteSeatsByConcert
 *                 · deleteBookingsByConcert / deleteBookingItemsByConcert
 *                 · deletePaymentsByConcert
 *    2026.05.27 - 회원 권한 관리 메서드 추가
 *                 · selectMember         : 회원 단건 조회
 *                 · countAdmin           : ADMIN 카운트 (마지막 관리자 보호)
 *                 · updateMemberRole     : 회원 role 변경 (정지/활성화/승격/강등 공용)
 * ============================================================
 */

import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Repository;

import stu.common.dao.AbstractDao;

@Repository("adminDao")
public class AdminDao extends AbstractDao {

	// ---------- 대시보드 ----------

	@SuppressWarnings("unchecked")
	public Map<String, Object> selectDashboard(Map<String, Object> map) throws Exception {
		return (Map<String, Object>) selectOne("admin.selectDashboard", map);
	}

	// ---------- 공연 ----------

	@SuppressWarnings("unchecked")
	public List<Map<String, Object>> selectConcertList(Map<String, Object> map) throws Exception {
		return (List<Map<String, Object>>) selectPagingList("admin.selectConcertList", map);
	}

	@SuppressWarnings("unchecked")
	public Map<String, Object> selectConcert(Map<String, Object> map) throws Exception {
		return (Map<String, Object>) selectOne("admin.selectConcert", map);
	}

	public void insertConcert(Map<String, Object> map) throws Exception {
		insert("admin.insertConcert", map);
	}

	public void updateConcert(Map<String, Object> map) throws Exception {
		update("admin.updateConcert", map);
	}

	// ---------- 공연 삭제 (스마트) ----------

	public int countBookingsByConcert(Map<String, Object> map) throws Exception {
		Object result = selectOne("admin.countBookingsByConcert", map);
		return result == null ? 0 : Integer.parseInt(result.toString());
	}

	public void deleteConcert(Map<String, Object> map) throws Exception {
		update("admin.deleteConcert", map);
	}

	public void deleteConcertHard(Map<String, Object> map) throws Exception {
		delete("admin.deleteConcertHard", map);
	}

	public void deleteBookingItemsByConcert(Map<String, Object> map) throws Exception {
		delete("admin.deleteBookingItemsByConcert", map);
	}

	public void deletePaymentsByConcert(Map<String, Object> map) throws Exception {
		delete("admin.deletePaymentsByConcert", map);
	}

	public void deleteBookingsByConcert(Map<String, Object> map) throws Exception {
		delete("admin.deleteBookingsByConcert", map);
	}

	public void deleteSeatsByConcert(Map<String, Object> map) throws Exception {
		delete("admin.deleteSeatsByConcert", map);
	}

	public void deleteSchedulesByConcert(Map<String, Object> map) throws Exception {
		delete("admin.deleteSchedulesByConcert", map);
	}

	// ---------- 회원 ----------

	@SuppressWarnings("unchecked")
	public List<Map<String, Object>> selectMemberList(Map<String, Object> map) throws Exception {
		return (List<Map<String, Object>>) selectPagingList("admin.selectMemberList", map);
	}

	/** 회원 단건 조회 (권한 변경 전 현재 role 확인용). */
	@SuppressWarnings("unchecked")
	public Map<String, Object> selectMember(Map<String, Object> map) throws Exception {
		return (Map<String, Object>) selectOne("admin.selectMember", map);
	}

	/** ADMIN 카운트 (마지막 관리자 보호용). */
	public int countAdmin() throws Exception {
		Object result = selectOne("admin.countAdmin", null);
		return result == null ? 0 : Integer.parseInt(result.toString());
	}

	/**
	 * 회원 role 변경 (정지/활성화/승격/강등 공용).
	 * @param map memberId(필수), newRole(USER / USER_BANNED / ADMIN)
	 */
	public void updateMemberRole(Map<String, Object> map) throws Exception {
		update("admin.updateMemberRole", map);
	}

	// ---------- 예매 ----------

	@SuppressWarnings("unchecked")
	public List<Map<String, Object>> selectBookingList(Map<String, Object> map) throws Exception {
		return (List<Map<String, Object>>) selectPagingList("admin.selectBookingList", map);
	}

}