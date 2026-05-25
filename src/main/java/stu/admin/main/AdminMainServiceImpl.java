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
 *    2026.05.25 - 탬퍼 감지 로직 제거 (Splunk 측 처리)
 *    2026.05.25 - 스마트 공연 삭제 구현
 *                 · 예매 0건 -> Hard Delete (FK 역순으로 자식 삭제 후 본인 삭제)
 *                 · 예매 1건+ -> Soft Delete (status = 'CLOSED')
 *                 · @Transactional 로 트랜잭션 보장 (중간 실패 시 롤백)
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

	/**
	 * 공연 스마트 삭제.
	 *
	 *  1) 해당 공연의 예매 건수를 조회
	 *  2) 0건  : Hard Delete (자식 데이터 FK 역순 정리 후 공연 삭제)
	 *  3) 1건+ : Soft Delete (status='CLOSED')
	 *
	 *  여러 DELETE 가 묶이므로 트랜잭션으로 보호.
	 *  중간 실패 시 전체 롤백 -> 일부만 삭제되어 데이터 깨지는 사고 방지.
	 */
	@Override
	@Transactional(rollbackFor = Exception.class)
	public int deleteConcert(CommandMap commandMap) throws Exception {

		Map<String, Object> map = commandMap.getMap();
		Object concertId = map.get("concertId");

		int bookingCount = adminDao.countBookingsByConcert(map);

		if (bookingCount > 0) {
			// 예매 내역이 있으면 안전하게 Soft Delete
			log.info(AUDIT_TAG + " deleteConcert (SOFT) concertId=" + concertId
					+ ", bookingCount=" + bookingCount);
			adminDao.deleteConcert(map);
		} else {
			// 예매 내역이 없으면 Hard Delete (자식부터 정리)
			log.info(AUDIT_TAG + " deleteConcert (HARD) concertId=" + concertId);

			// FK 역순으로 삭제 (가장 깊은 자식부터)
			//   booking_items  →  payments  →  bookings  →  seats  →  concert_schedules  →  concerts
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

	// ---------- 예매 ----------

	@Override
	public List<Map<String, Object>> selectBookingList(Map<String, Object> map) throws Exception {
		return adminDao.selectBookingList(map);
	}

}
