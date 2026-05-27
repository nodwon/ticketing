package stu.admin.main;

/**
 * ============================================================
 *  Project   : 관제 티켓 (Ticketing System)
 *  Package   : stu.admin.main
 *  FileName  : AdminMainService.java
 *
 *  Developer : 김태희 (feature/kth)
 *  Created   : 2026.05.24
 *  Modified  : 2026.05.27
 *
 *  Description :
 *    - 관리자 메인 Service 인터페이스
 *    - 대시보드 / 공연 / 회원 / 예매 4개 기능군의 메서드 선언
 *
 *  History :
 *    2026.05.25 - deleteConcert 반환 타입 변경 (void -> int)
 *                 · 예매 건수를 반환해서 Controller 에서 메시지 분기
 *    2026.05.27 - 회원 권한 변경 메서드 4개 추가
 *                 · banMember     : USER -> USER_BANNED (정지)
 *                 · unbanMember   : USER_BANNED -> USER (활성화)
 *                 · promoteMember : USER / USER_BANNED -> ADMIN (승격)
 *                 · demoteMember  : ADMIN -> USER (강등, 마지막 관리자 보호)
 *                 · MemberRoleChangeException : 보호 장치 위반 시 발생
 * ============================================================
 */

import java.util.List;
import java.util.Map;

import stu.common.common.CommandMap;

public interface AdminMainService {

	// ---------- 대시보드 ----------

	Map<String, Object> selectDashboard(CommandMap commandMap) throws Exception;

	// ---------- 공연 ----------

	List<Map<String, Object>> selectConcertList(Map<String, Object> map) throws Exception;

	Map<String, Object> selectConcert(CommandMap commandMap) throws Exception;

	void insertConcert(CommandMap commandMap) throws Exception;

	void updateConcert(CommandMap commandMap) throws Exception;

	/**
	 * 공연 스마트 삭제.
	 * @return 삭제 시점의 예매 건수 (0=Hard Delete 수행됨, 1+=Soft Delete 수행됨)
	 */
	int deleteConcert(CommandMap commandMap) throws Exception;

	// ---------- 회원 ----------

	List<Map<String, Object>> selectMemberList(Map<String, Object> map) throws Exception;

	/**
	 * 일반 회원 정지 (USER → USER_BANNED).
	 *
	 * <pre>
	 *  - 대상이 USER 가 아닐 경우 MemberRoleChangeException 발생
	 *    (ADMIN 은 정지 불가, USER_BANNED 는 이미 정지 상태)
	 * </pre>
	 *
	 * @return 변경된 회원의 정보 (email, name 등)
	 */
	Map<String, Object> banMember(CommandMap commandMap) throws Exception;

	/**
	 * 정지된 일반 회원 활성화 (USER_BANNED → USER).
	 *
	 * <pre>
	 *  - 대상이 USER_BANNED 가 아닐 경우 MemberRoleChangeException 발생
	 * </pre>
	 *
	 * @return 변경된 회원의 정보
	 */
	Map<String, Object> unbanMember(CommandMap commandMap) throws Exception;

	/**
	 * 관리자 승격 (USER / USER_BANNED → ADMIN).
	 *
	 * <pre>
	 *  - 대상이 이미 ADMIN 이면 MemberRoleChangeException 발생
	 *  - USER_BANNED 인 회원도 승격 시 정지가 풀리면서 ADMIN 으로 변경됨
	 * </pre>
	 *
	 * @return 변경된 회원의 정보
	 */
	Map<String, Object> promoteMember(CommandMap commandMap) throws Exception;

	/**
	 * 관리자 강등 (ADMIN → USER).
	 *
	 * <pre>
	 *  - 대상이 ADMIN 이 아닐 경우 MemberRoleChangeException 발생
	 *  - ADMIN 이 1명만 남았을 때 강등 시도 시 MemberRoleChangeException 발생
	 *    (마지막 관리자 보호)
	 * </pre>
	 *
	 * @return 변경된 회원의 정보
	 */
	Map<String, Object> demoteMember(CommandMap commandMap) throws Exception;

	// ---------- 예매 ----------

	List<Map<String, Object>> selectBookingList(Map<String, Object> map) throws Exception;

	// ---------- 예외 ----------

	/**
	 * 회원 권한 변경 보호 장치 위반 시 발생하는 예외.
	 * (예: 마지막 관리자 강등 시도, ADMIN 정지 시도, 이미 같은 상태로 변경 시도 등)
	 */
	public static class MemberRoleChangeException extends Exception {
		private static final long serialVersionUID = 1L;
		public MemberRoleChangeException(String message) { super(message); }
	}

}