package stu.board.qna;



import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.springframework.transaction.annotation.Transactional;


import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;

import org.apache.log4j.Logger;
import org.springframework.stereotype.Service;
//💡 프로젝트 내부에 존재하는 파일 유틸을 임포트하세요 (패키지 경로는 확인 필요)
import stu.common.util.FileUtils;

@Service("qnaService")
public class QnaServiceImpl implements QnaService{
	Logger log = Logger.getLogger(this.getClass());
	
	@Resource(name="qnaDAO")
	private QnaDAO qnaDAO;
	
	@Resource(name="fileUtils") // 💡 공통 파일 유틸 빈을 주입받습니다.
	private FileUtils fileUtils;
	
	@Override
	public List<Map<String, Object>> selectQnaList(Map<String, Object> map) throws Exception {
		return qnaDAO.selectQnaList(map);
	}

	// 🌟 [41번 API: Q&A 등록시 파일 업로드 로직 결합]
	@Override
	public void insertQna(Map<String, Object> map, HttpServletRequest request) throws Exception {
	    // 1. 본문 등록 (selectKey BEFORE로 map에 QNA_ID가 이미 채워진 상태)
	    qnaDAO.insertQna(map);
	    
	    // 2. QNA_ID 회수 및 검증
	    Object qnaIdObj = map.get("QNA_ID");
	    if (qnaIdObj == null || String.valueOf(qnaIdObj).trim().isEmpty()) {
	        log.error("[QNA INSERT FAIL] QNA_ID가 회수되지 않았습니다.");
	        throw new Exception("QNA_ID 생성 실패");
	    }
	    String confirmedPostId = String.valueOf(qnaIdObj).trim();
	    log.info("[QNA INSERT OK] 생성된 QNA_ID = " + confirmedPostId);
	    
	    // 3. 파일 파싱 및 INSERT
	    List<Map<String, Object>> fileList = fileUtils.parseInsertFileInfo(map, request);
	    if (fileList != null && !fileList.isEmpty()) {
	        for (Map<String, Object> fileMap : fileList) {
	            fileMap.put("POST_ID", confirmedPostId);
	            qnaDAO.insertFile(fileMap); 
	        }
	    }
	}

	// 🌟 [Q&A 상세조회시 첨부파일 목록 조회 로직 결합]
	@Override
	public Map<String, Object> selectQnaDetail(Map<String, Object> map) throws Exception {
		Map<String, Object> resultMap = new HashMap<String, Object>();
			
		// 1. 기존 기조 그대로 QNA_POSTS 본문 상세 내역을 가져옵니다.
		Map<String, Object> tempMap = qnaDAO.selectQnaDetail(map);
		if(tempMap != null) {
			tempMap.put("RNUM", map.get("RNUM"));
		}
		resultMap.put("map", tempMap);        
			
		// 2. 🌟 [핵심 추가] ATTACHMENTS 테이블에서 이 글 번호(POST_ID)에 묶인 파일 목록을 전부 가져옵니다.
		// qnaDetail.jsp 화면단에서 <c:forEach var="row" items="${list}"> 로 돌리는 타겟 주머니인 "list"에 채워줍니다.
		List<Map<String, Object>> fileList = qnaDAO.selectFileList(map);
		resultMap.put("list", fileList);       
			
		return resultMap;
	}
	
	@Override
	public Map<String, Object> selectFileInfo(Map<String, Object> map) throws Exception {
	    return qnaDAO.selectFileInfo(map);
	}

	@Override
	public void updateQna(Map<String, Object> map, HttpServletRequest request) throws Exception{
		qnaDAO.updateQna(map);
			}

	@Override
	public void deleteQna(Map<String, Object> map) throws Exception {
		qnaDAO.deleteQna(map);
	}
	
	@Override
	public Map<String, Object> selectQnaPassword(Map<String, Object> map) throws Exception {
		return qnaDAO.selectQnaPassword(map);
	}
	
}
