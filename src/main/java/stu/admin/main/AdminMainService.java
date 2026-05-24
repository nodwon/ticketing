package stu.admin.main;

/**
 * ============================================================
 *  Project   : 관제 티켓 (Ticketing System)
 *  Package   : stu.admin.main
 *  FileName  : AdminMainService.java
 *
 *  Developer : 김태희 (feature/kth)
 *  Created   : 2026.05.24
 *  Modified  : 2026.05.24
 *
 *  Description :
 *    - 관리자 메인 Service 인터페이스
 *    - 대시보드 / 공연 / 회원 / 예매 4개 기능군의 메서드 선언
 * ============================================================
 */

import java.util.List;
import java.util.Map;

import stu.common.common.CommandMap;

public interface AdminMainService {

	// ---------- 대시보드 ----------

	/** 회원/공연/예매/탬퍼 카운트를 한 번에 조회. */
	Map<String, Object> selectDashboard(CommandMap commandMap) throws Exception;

	// ---------- 공연 ----------

	/** 공연 목록 (검색/페이징). */
	List<Map<String, Object>> selectConcertList(Map<String, Object> map) throws Exception;

	/** 공연 단건 조회 (수정 폼). */
	Map<String, Object> selectConcert(CommandMap commandMap) throws Exception;

	/** 공연 등록. */
	void insertConcert(CommandMap commandMap) throws Exception;

	/** 공연 수정. */
	void updateConcert(CommandMap commandMap) throws Exception;

	/** 공연 삭제 (soft delete : status='CLOSED'). */
	void deleteConcert(CommandMap commandMap) throws Exception;

	// ---------- 회원 ----------

	/** 회원 목록 (검색/페이징). */
	List<Map<String, Object>> selectMemberList(Map<String, Object> map) throws Exception;

	// ---------- 예매 ----------

	/** 예매 목록 (검색/페이징/탬퍼 필터). */
	List<Map<String, Object>> selectBookingList(Map<String, Object> map) throws Exception;

}