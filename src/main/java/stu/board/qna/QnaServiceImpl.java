package stu.board.qna;



import java.util.HashMap;
import java.util.List;
import java.util.Map;

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
		// 1. 먼저 QNA_POSTS 테이블에 게시글 본문을 인서트합니다.
		// (이때 오라클 시퀀스에 의해 QNA_ID 번호가 생성됩니다.)
		qnaDAO.insertQna(map);
			
		// 2. 공통 파일 유틸리티를 호출하여 D:\sts4File\ 폴더에 실제 파일을 저장하고,
		// 파싱된 파일 정보 리스트(ORIGINAL_NAME, SAVED_NAME 등)를 받아옵니다.
		// ※ 팀 공통 유틸 메서드명이 parseInsertFileInfo 인지 확인해 보세요!
		List<Map<String, Object>> fileList = fileUtils.parseInsertFileInfo(map, request);
			
		// 3. 첨부된 파일이 존재한다면, 파일 개수만큼 반복문을 돌며 ATTACHMENTS 테이블에 차례대로 인서트합니다.
		if(fileList != null) {
			for(int i=0, size=fileList.size(); i<size; i++) {
				Map<String, Object> fileMap = fileList.get(i);
					
				// 🚨 [중요] 첨부파일 테이블의 POST_ID 컬럼에 현재 등록된 Q&A 글 번호를 매핑해야 합니다.
				// (insertQna 실행 후 맵에 QNA_ID가 자동으로 담겨 나오도록 MyBatis 세팅이 필요합니다.)
				fileMap.put("POST_ID", map.get("QNA_ID"));
					
				// DAO를 통해 ATTACHMENTS 테이블에 한 행씩 삽입
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
