package stu.admin.main;

/**
 * ============================================================
 *  Project   : 관제 티켓 (Ticketing System)
 *  Package   : stu.admin.main
 *  FileName  : AdminDao.java
 *
 *  Developer : 김태희 (feature/kth)
 *  Created   : 2026.05.24
 *  Modified  : 2026.05.25
 *
 *  Description :
 *    - 관리자 화면 데이터 접근 객체 (DAO)
 *    - AbstractDao 상속하여 SqlSessionTemplate 자동 주입
 *    - MyBatis namespace : "admin"  (Admin_SQL.xml)
 *
 *  History :
 *    2026.05.25 - 스마트 공연 삭제용 메서드 추가
 *                 · countBookingsByConcert : 예매 건수 조회
 *                 · deleteConcertHard      : 공연 row 자체 삭제
 *                 · deleteSchedulesByConcert / deleteSeatsByConcert
 *                   / deleteBookingsByConcert / deleteBookingItemsByConcert
 *                   / deletePaymentsByConcert : 자식 데이터 삭제 (FK 역순)
 * ============================================================
 */

import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Repository;

import stu.common.dao.AbstractDao;

@Repository("adminDao")
public class AdminDao extends AbstractDao {

	// ---------- 대시보드 ----------

	/** 회원/공연/예매 카운트 단건 조회. */
	@SuppressWarnings("unchecked")
	public Map<String, Object> selectDashboard(Map<String, Object> map) throws Exception {
		return (Map<String, Object>) selectOne("admin.selectDashboard", map);
	}

	// ---------- 공연 ----------

	/** 공연 목록 (검색/페이징). */
	@SuppressWarnings("unchecked")
	public List<Map<String, Object>> selectConcertList(Map<String, Object> map) throws Exception {
		return (List<Map<String, Object>>) selectPagingList("admin.selectConcertList", map);
	}

	/** 공연 단건 조회. */
	@SuppressWarnings("unchecked")
	public Map<String, Object> selectConcert(Map<String, Object> map) throws Exception {
		return (Map<String, Object>) selectOne("admin.selectConcert", map);
	}

	/** 공연 등록. */
	public void insertConcert(Map<String, Object> map) throws Exception {
		insert("admin.insertConcert", map);
	}

	/** 공연 수정. */
	public void updateConcert(Map<String, Object> map) throws Exception {
		update("admin.updateConcert", map);
	}

	// ---------- 공연 삭제 (스마트) ----------

	/** 공연 ID 로 예매 건수 조회 (스마트 삭제 판정용). */
	public int countBookingsByConcert(Map<String, Object> map) throws Exception {
		Object result = selectOne("admin.countBookingsByConcert", map);
		return result == null ? 0 : Integer.parseInt(result.toString());
	}

	/** [Soft] 공연 상태만 'CLOSED' 로 변경 (기존 deleteConcert). */
	public void deleteConcert(Map<String, Object> map) throws Exception {
		update("admin.deleteConcert", map);
	}

	/** [Hard] 공연 row 자체 삭제. */
	public void deleteConcertHard(Map<String, Object> map) throws Exception {
		delete("admin.deleteConcertHard", map);
	}

	/** [Hard] 공연 산하의 booking_items 삭제 (가장 깊은 자식부터). */
	public void deleteBookingItemsByConcert(Map<String, Object> map) throws Exception {
		delete("admin.deleteBookingItemsByConcert", map);
	}

	/** [Hard] 공연 산하의 payments 삭제. */
	public void deletePaymentsByConcert(Map<String, Object> map) throws Exception {
		delete("admin.deletePaymentsByConcert", map);
	}

	/** [Hard] 공연 산하의 bookings 삭제. */
	public void deleteBookingsByConcert(Map<String, Object> map) throws Exception {
		delete("admin.deleteBookingsByConcert", map);
	}

	/** [Hard] 공연 산하의 seats 삭제. */
	public void deleteSeatsByConcert(Map<String, Object> map) throws Exception {
		delete("admin.deleteSeatsByConcert", map);
	}

	/** [Hard] 공연 산하의 concert_schedules 삭제. */
	public void deleteSchedulesByConcert(Map<String, Object> map) throws Exception {
		delete("admin.deleteSchedulesByConcert", map);
	}

	// ---------- 회원 ----------

	/** 회원 목록 (검색/페이징). */
	@SuppressWarnings("unchecked")
	public List<Map<String, Object>> selectMemberList(Map<String, Object> map) throws Exception {
		return (List<Map<String, Object>>) selectPagingList("admin.selectMemberList", map);
	}

	// ---------- 예매 ----------

	/** 예매 목록 (검색/페이징/탬퍼 필터). */
	@SuppressWarnings("unchecked")
	public List<Map<String, Object>> selectBookingList(Map<String, Object> map) throws Exception {
		return (List<Map<String, Object>>) selectPagingList("admin.selectBookingList", map);
	}

}
