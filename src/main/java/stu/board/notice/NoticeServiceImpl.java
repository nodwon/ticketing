/**
 * ============================================================
 * Project  : 관제 티켓 (Ticketing System)
 * Package  : stu.board.notice
 * FileName : NoticeServiceImpl.java
 *
 * Developer : dw (feature/dw)
 * Created   : 2026.05.22
 * Modified  : 2026.05.22
 *
 * Description :
 *   - 공지사항 서비스 구현체
 *   - NoticeService 인터페이스 구현
 * ============================================================
 */
package stu.board.notice;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;

import org.apache.log4j.Logger;
import org.springframework.stereotype.Service;

@Service("noticeService")
public class NoticeServiceImpl implements NoticeService {

    Logger log = Logger.getLogger(this.getClass());

    @Resource(name = "noticeDAO")
    private NoticeDAO noticeDAO;

    // 공지사항 목록 조회
    @Override
    public List<Map<String, Object>> selectNoticeList(Map<String, Object> map) throws Exception {
        return noticeDAO.selectNoticeList(map);
    }

    // 공지사항 등록
    @Override
    public void insertNotice(Map<String, Object> map, HttpServletRequest request) throws Exception {
        noticeDAO.insertNotice(map);
    }

    // 공지사항 상세 조회
    @Override
    public Map<String, Object> selectNoticeDetail(Map<String, Object> map) throws Exception {
        Map<String, Object> resultMap = new HashMap<String, Object>();
        Map<String, Object> tempMap = noticeDAO.selectNoticeDetail(map);
        resultMap.put("map", tempMap);
        return resultMap;
    }

    // 공지사항 수정
    @Override
    public void updateNotice(Map<String, Object> map, HttpServletRequest request) throws Exception {
        noticeDAO.updateNotice(map);
    }

    // 공지사항 삭제
    @Override
    public void deleteNotice(Map<String, Object> map) throws Exception {
        noticeDAO.deleteNotice(map);
    }
}