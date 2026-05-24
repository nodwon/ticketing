package stu.admin.main;

/**
 * ============================================================
 *  Project   : 관제 티켓 (Ticketing System)
 *  Package   : stu.admin.main
 *  FileName  : AdminDao.java
 *
 *  Developer : 김태희 (feature/kth)
 *  Created   : 2026.05.24
 *  Modified  : 2026.05.24
 *
 *  Description :
 *    - 관리자 화면 데이터 접근 객체 (DAO)
 *    - AbstractDao 상속하여 SqlSessionTemplate 자동 주입
 *    - MyBatis namespace : "admin"  (Admin_SQL.xml)
 * ============================================================
 */

import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Repository;

import stu.common.dao.AbstractDao;

@Repository("adminDao")
public class AdminDao extends AbstractDao {

	// ---------- 대시보드 ----------

	/** 회원/공연/예매/탬퍼 카운트 단건 조회. */
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

	/** 공연 삭제 (soft delete : status='CLOSED'). */
	public void deleteConcert(Map<String, Object> map) throws Exception {
		update("admin.deleteConcert", map);
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