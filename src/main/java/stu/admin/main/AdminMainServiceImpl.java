package stu.admin.main;

/**
 * ============================================================
 *  Project   : 관제 티켓 (Ticketing System)
 *  Package   : stu.admin.main
 *  FileName  : AdminMainServiceImpl.java
 *
 *  Developer : 김태희 (feature/kth)
 *  Created   : 2026.05.24
 *  Modified  : 2026.05.27
 *
 *  Description :
 *    - AdminMainService 구현체 (비즈니스 로직 + AUDIT 로그)
 *    - DAO 호출 + 관리자 활동 로그 기록
 *
 *  History :
 *    2026.05.25 - 스마트 공연 삭제 구현
 *                 · 예매 0건 -> Hard Delete (FK 역순 자식 정리 후 본인 삭제)
 *                 · 예매 1건+ -> Soft Delete (status='CLOSED')
 *                 · @Transactional 적용
 *    2026.05.27 - 회원 권한 변경 4개 메서드 구현
 *                 · banMember / unbanMember / promoteMember / demoteMember
 *                 · 보호 장치 적용:
 *                   - 잘못된 현재 role 이면 MemberRoleChangeException
 *                   - 마지막 ADMIN 강등 시도 시 차단
 *                 · 권한 변경은 [AUDIT][admin][CRITICAL] 태그로 로그 강화
 * ============================================================
 */

import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.apache.log4j.Logger;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import stu.common.common.CommandMap;

@Service("adminMainService")
public class AdminMainServiceImpl implements AdminMainService {

	private Logger log = Logger.getLogger(this.getClass());

	/** 일반 AUDIT 로그 prefix (관리자 활동 추적용). */
	private static final String AUDIT_TAG = "[AUDIT][admin]";

	/** 권한 변경 등 민감 작업용 강화 prefix (Splunk Alert 매칭용). */
	private static final String AUDIT_TAG_CRITICAL = "[AUDIT][admin][CRITICAL]";

	/** role 상수. */
	private static final String ROLE_USER        = "USER";
	private static final String ROLE_USER_BANNED = "USER_BANNED";
	private static final String ROLE_ADMIN       = "ADMIN";

	@Resource(name = "adminDao")
	private AdminDao adminDao;

	// ---------- 대시보드 ----------

	@Override
	public Map<String, Object> selectDashboard(CommandMap commandMap) throws Exception {
		return adminDao.selectDashboard(commandMap.getMap());
	}

	// ---------- 공연 ----------

	@Override
	public List<Map<String, Object>> selectConcertList(Map<String, Object> map) throws Exception {
		return adminDao.selectConcertList(map);
	}

	@Override
	public Map<String, Object> selectConcert(CommandMap commandMap) throws Exception {
		return adminDao.selectConcert(commandMap.getMap());
	}

	@Override
	public void insertConcert(CommandMap commandMap) throws Exception {
		log.info(AUDIT_TAG + " insertConcert title=" + commandMap.get("title")
				+ ", artist=" + commandMap.get("artist"));
		adminDao.insertConcert(commandMap.getMap());
	}

	@Override
	public void updateConcert(CommandMap commandMap) throws Exception {
		log.info(AUDIT_TAG + " updateConcert concertId=" + commandMap.get("concertId"));
		adminDao.updateConcert(commandMap.getMap());
	}

	@Override
	@Transactional(rollbackFor = Exception.class)
	public int deleteConcert(CommandMap commandMap) throws Exception {

		Map<String, Object> map = commandMap.getMap();
		Object concertId = map.get("concertId");

		int bookingCount = adminDao.countBookingsByConcert(map);

		if (bookingCount > 0) {
			log.info(AUDIT_TAG + " deleteConcert (SOFT) concertId=" + concertId
					+ ", bookingCount=" + bookingCount);
			adminDao.deleteConcert(map);
		} else {
			log.info(AUDIT_TAG + " deleteConcert (HARD) concertId=" + concertId);
			adminDao.deleteBookingItemsByConcert(map);
			adminDao.deletePaymentsByConcert(map);
			adminDao.deleteBookingsByConcert(map);
			adminDao.deleteSeatsByConcert(map);
			adminDao.deleteSchedulesByConcert(map);
			adminDao.deleteConcertHard(map);
		}

		return bookingCount;
	}

	// ---------- 회원 ----------

	@Override
	public List<Map<String, Object>> selectMemberList(Map<String, Object> map) throws Exception {
		return adminDao.selectMemberList(map);
	}

	/**
	 * 일반 회원 정지 (USER → USER_BANNED).
	 * 대상이 USER 가 아닐 경우 차단.
	 */
	@Override
	@Transactional(rollbackFor = Exception.class)
	public Map<String, Object> banMember(CommandMap commandMap) throws Exception {

		Map<String, Object> member = loadMemberOrThrow(commandMap);
		String currentRole = (String) member.get("ROLE");

		if (!ROLE_USER.equals(currentRole)) {
			throw new MemberRoleChangeException(
				"정지할 수 있는 대상은 일반 회원(USER) 뿐입니다. (현재 상태: " + currentRole + ")");
		}

		changeRole(member, ROLE_USER_BANNED, "BAN");
		return member;
	}

	/**
	 * 정지된 일반 회원 활성화 (USER_BANNED → USER).
	 * 대상이 USER_BANNED 가 아닐 경우 차단.
	 */
	@Override
	@Transactional(rollbackFor = Exception.class)
	public Map<String, Object> unbanMember(CommandMap commandMap) throws Exception {

		Map<String, Object> member = loadMemberOrThrow(commandMap);
		String currentRole = (String) member.get("ROLE");

		if (!ROLE_USER_BANNED.equals(currentRole)) {
			throw new MemberRoleChangeException(
				"활성화할 수 있는 대상은 정지된 회원(USER_BANNED) 뿐입니다. (현재 상태: " + currentRole + ")");
		}

		changeRole(member, ROLE_USER, "UNBAN");
		return member;
	}

	/**
	 * 관리자 승격 (USER 또는 USER_BANNED → ADMIN).
	 * 이미 ADMIN 이면 차단.
	 */
	@Override
	@Transactional(rollbackFor = Exception.class)
	public Map<String, Object> promoteMember(CommandMap commandMap) throws Exception {

		Map<String, Object> member = loadMemberOrThrow(commandMap);
		String currentRole = (String) member.get("ROLE");

		if (ROLE_ADMIN.equals(currentRole)) {
			throw new MemberRoleChangeException("이미 관리자(ADMIN) 인 회원입니다.");
		}

		changeRole(member, ROLE_ADMIN, "PROMOTE");
		return member;
	}

	/**
	 * 관리자 강등 (ADMIN → USER).
	 * 대상이 ADMIN 이 아니거나, ADMIN 이 1명 이하면 차단 (마지막 관리자 보호).
	 */
	@Override
	@Transactional(rollbackFor = Exception.class)
	public Map<String, Object> demoteMember(CommandMap commandMap) throws Exception {

		Map<String, Object> member = loadMemberOrThrow(commandMap);
		String currentRole = (String) member.get("ROLE");

		if (!ROLE_ADMIN.equals(currentRole)) {
			throw new MemberRoleChangeException(
				"강등할 수 있는 대상은 관리자(ADMIN) 뿐입니다. (현재 상태: " + currentRole + ")");
		}

		// 마지막 관리자 보호 - ADMIN 이 1명 이하이면 강등 차단
		int adminCount = adminDao.countAdmin();
		if (adminCount <= 1) {
			log.warn(AUDIT_TAG_CRITICAL + " demoteMember BLOCKED (last admin protection) "
					+ "memberId=" + member.get("MEMBER_ID") + ", adminCount=" + adminCount);
			throw new MemberRoleChangeException(
				"관리자(ADMIN) 는 최소 1명 이상 유지되어야 합니다. (현재 관리자 수: " + adminCount + ")");
		}

		changeRole(member, ROLE_USER, "DEMOTE");
		return member;
	}

	// ---------- 예매 ----------

	@Override
	public List<Map<String, Object>> selectBookingList(Map<String, Object> map) throws Exception {
		return adminDao.selectBookingList(map);
	}

	// ---------- 내부 helper ----------

	/**
	 * memberId 로 회원 조회. 없으면 예외.
	 */
	private Map<String, Object> loadMemberOrThrow(CommandMap commandMap) throws Exception {
		Map<String, Object> member = adminDao.selectMember(commandMap.getMap());
		if (member == null) {
			throw new MemberRoleChangeException(
				"존재하지 않는 회원입니다. (memberId=" + commandMap.get("memberId") + ")");
		}
		return member;
	}

	/**
	 * 실제 DB UPDATE 수행 + CRITICAL AUDIT 로그.
	 */
	private void changeRole(Map<String, Object> member, String newRole, String action)
			throws Exception {

		String before = (String) member.get("ROLE");

		java.util.HashMap<String, Object> param = new java.util.HashMap<String, Object>();
		param.put("memberId", member.get("MEMBER_ID"));
		param.put("newRole",  newRole);

		adminDao.updateMemberRole(param);

		log.info(AUDIT_TAG_CRITICAL + " " + action + " "
				+ "memberId=" + member.get("MEMBER_ID")
				+ ", email=" + member.get("EMAIL")
				+ ", before=" + before
				+ ", after=" + newRole);

		// 호출자가 메시지 만들 때 사용하도록 새 role 도 채워줌
		member.put("BEFORE_ROLE", before);
		member.put("AFTER_ROLE",  newRole);
	}

}