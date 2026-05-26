package stu.admin.main;

/**
 * ============================================================
 *  Project   : 관제 티켓 (Ticketing System)
 *  Package   : stu.admin.main
 *  FileName  : AdminMainService.java
 *
 *  Developer : 김태희 (feature/kth)
 *  Created   : 2026.05.24
 *  Modified  : 2026.05.25
 *
 *  Description :
 *    - 관리자 메인 Service 인터페이스
 *    - 대시보드 / 공연 / 회원 / 예매 4개 기능군의 메서드 선언
 *
 *  History :
 *    2026.05.25 - deleteConcert 반환 타입 변경 (void -> int)
 *                 · 예매 건수를 반환해서 Controller 에서 메시지 분기
 *                 · 0 이면 Hard Delete 수행됨, 1 이상이면 Soft Delete 수행됨
 * ============================================================
 */

import java.util.List;
import java.util.Map;

import stu.common.common.CommandMap;

public interface AdminMainService {

	// ---------- 대시보드 ----------

	/** 회원/공연/예매 카운트를 한 번에 조회. */
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

	/**
	 * 공연 스마트 삭제.
	 *
	 * <pre>
	 *  - 예매 0건  : Hard Delete (자식 데이터 다 정리 후 공연 row 삭제)
	 *  - 예매 1건+ : Soft Delete (status = 'CLOSED' 만 변경)
	 * </pre>
	 *
	 * @return 삭제 시점의 예매 건수
	 *         (Controller 에서 0/N 으로 메시지 분기용)
	 */
	int deleteConcert(CommandMap commandMap) throws Exception;

	// ---------- 회원 ----------

	/** 회원 목록 (검색/페이징). */
	List<Map<String, Object>> selectMemberList(Map<String, Object> map) throws Exception;

	// ---------- 예매 ----------

	/** 예매 목록 (검색/페이징/탬퍼 필터). */
	List<Map<String, Object>> selectBookingList(Map<String, Object> map) throws Exception;


}
