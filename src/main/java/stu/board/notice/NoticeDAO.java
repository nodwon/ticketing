/**
 * ============================================================
 * Project  : 관제 티켓 (Ticketing System)
 * Package  : stu.board.notice
 * FileName : NoticeDAO.java
 *
 * Developer : dw (feature/dw)
 * Created   : 2026.05.22
 * Modified  : 2026.05.22
 *
 * Description :
 *   - 공지사항 DAO
 *   - AbstractDao 상속
 * ============================================================
 */
package stu.board.notice;

import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Repository;

import stu.common.dao.AbstractDao;

@Repository("noticeDAO")
public class NoticeDAO extends AbstractDao {

    // 공지사항 목록 조회
    @SuppressWarnings("unchecked")
    public List<Map<String, Object>> selectNoticeList(Map<String, Object> map) throws Exception {
        return (List<Map<String, Object>>) selectPagingList("notice.selectNoticeList", map);
    }

    // 공지사항 등록
    public void insertNotice(Map<String, Object> map) throws Exception {
        insert("notice.insertNotice", map);
    }

    // 공지사항 상세 조회
    @SuppressWarnings("unchecked")
    public Map<String, Object> selectNoticeDetail(Map<String, Object> map) throws Exception {
        return (Map<String, Object>) selectOne("notice.selectNoticeDetail", map);
    }

    // 공지사항 수정
    public void updateNotice(Map<String, Object> map) throws Exception {
        update("notice.updateNotice", map);
    }

    // 공지사항 삭제
    public void deleteNotice(Map<String, Object> map) throws Exception {
        update("notice.deleteNotice", map);
    }
}