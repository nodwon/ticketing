package stu.admin.main;

/**
 * ============================================================
 *  Project   : 관제 티켓 (Ticketing System)
 *  Package   : stu.admin.main
 *  FileName  : AdminMainServiceImpl.java
 *
 *  Developer : 김태희 (feature/kth)
 *  Created   : 2026.05.24
 *  Modified  : 2026.05.25
 *
 *  Description :
 *    - AdminMainService 구현체 (비즈니스 로직 + AUDIT 로그)
 *    - DAO 호출 + 관리자 활동 로그 기록
 *
 *  History :
 *    2026.05.25 - 탬퍼 감지 로직 제거 (보안 모니터링은 Splunk 측에서 처리)
 * ============================================================
 */

import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.apache.log4j.Logger;
import org.springframework.stereotype.Service;

import stu.common.common.CommandMap;

@Service("adminMainService")
public class AdminMainServiceImpl implements AdminMainService {

	private Logger log = Logger.getLogger(this.getClass());

	/** AUDIT 로그 prefix (관리자 활동 추적용). */
	private static final String AUDIT_TAG = "[AUDIT][admin]";

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
	public void deleteConcert(CommandMap commandMap) throws Exception {
		log.info(AUDIT_TAG + " deleteConcert (soft) concertId=" + commandMap.get("concertId"));
		adminDao.deleteConcert(commandMap.getMap());
	}

	// ---------- 회원 ----------

	@Override
	public List<Map<String, Object>> selectMemberList(Map<String, Object> map) throws Exception {
		return adminDao.selectMemberList(map);
	}

	// ---------- 예매 ----------

	@Override
	public List<Map<String, Object>> selectBookingList(Map<String, Object> map) throws Exception {
		return adminDao.selectBookingList(map);
	}

}