/**
 * ============================================================
 * Project  : 관제 티켓 (Ticketing System)
 * Package  : stu.board.notice
 * FileName : NoticeService.java
 *
 * Developer : dw (feature/dw)
 * Created   : 2026.05.22
 * Modified  : 2026.05.22
 *
 * Description :
 *   - 공지사항 서비스 인터페이스
 * ============================================================
 */
package stu.board.notice;

import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;

public interface NoticeService {

    List<Map<String, Object>> selectNoticeList(Map<String, Object> map) throws Exception;

    void insertNotice(Map<String, Object> map, HttpServletRequest request) throws Exception;

    Map<String, Object> selectNoticeDetail(Map<String, Object> map) throws Exception;

    void updateNotice(Map<String, Object> map, HttpServletRequest request) throws Exception;

    void deleteNotice(Map<String, Object> map) throws Exception;
}