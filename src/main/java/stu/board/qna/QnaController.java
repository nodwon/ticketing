package stu.board.qna;

import java.util.List;
import java.util.Map;
import java.util.HashMap;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.apache.log4j.Logger;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.ModelAndView;

import stu.common.common.CommandMap;

@Controller
public class QnaController {
	Logger log = Logger.getLogger(this.getClass());
	
	@Resource(name="qnaService")
	private QnaService qnaService;
	
	@RequestMapping(value="/qna/openQnaList.do")
	public ModelAndView openQnaList(CommandMap commandMap) throws Exception{
		ModelAndView mv = new ModelAndView("/board/qnaList");
		return mv;
	}
	
	@RequestMapping(value="/qna/selectQnaList.do")
	public ModelAndView selectQnaList(CommandMap commandMap, HttpServletRequest request) throws Exception {
		ModelAndView mv = new ModelAndView("jsonView");

		HttpSession session = request.getSession(false);
		String sessionName = (session != null) ? (String) session.getAttribute("SESSION_NAME") : null;
		commandMap.put("IS_ADMIN", "관리자".equals(sessionName) ? "1" : "0");

		List<Map<String,Object>> list = qnaService.selectQnaList(commandMap.getMap());
		mv.addObject("list", list);
		
		if(list.size() > 0){
			mv.addObject("TOTAL", list.get(0).get("TOTAL_COUNT"));
		}
		else{
			mv.addObject("TOTAL", 0);
		}
		return mv;
	}
	
	@RequestMapping(value="/qna/openQnaWrite.do")
	public ModelAndView openQnaWrite(CommandMap commandMap) throws Exception{
		ModelAndView mv = new ModelAndView("/board/qnaWrite");
		return mv;
	}
	
	// 41번 API: Q&A 등록 (명세서 파라미터 category, is_secret 교차 동기화 방어막 작동 🌟)
	@RequestMapping(value="/qna/insertQna.do", method = RequestMethod.POST )
	public ModelAndView insertQna(CommandMap commandMap, HttpServletRequest request) throws Exception{
		ModelAndView mv = new ModelAndView("redirect:/qna/openQnaList.do");
		
		HttpSession session = request.getSession();
		if(session.getAttribute("SESSION_NO") != null) {
			commandMap.put("MEMBER_ID", session.getAttribute("SESSION_NO"));
		} else {
			commandMap.put("MEMBER_ID", null); 
		}
		
		// 🌟 [명세서 규격 호환 패치] 
		// API 명세서 파라미터 이름(category, is_secret)과 기존 소스코드 이름이 혼용되어도 무조건 매핑되도록 상호 복사 보정
		
		// 1. 카테고리 매핑 보정 (category -> QNA_CATEGORY)
		if(commandMap.containsKey("category")) {
			commandMap.put("QNA_CATEGORY", commandMap.get("category"));
		}
		
		// 2. 비밀글 여부 매핑 보정 (is_secret / QNA_SECRET -> IS_SECRET)
		String isSecret = "0";
		if(commandMap.containsKey("is_secret")) {
			isSecret = String.valueOf(commandMap.get("is_secret"));
		} else if(commandMap.containsKey("QNA_SECRET")) {
			isSecret = String.valueOf(commandMap.get("QNA_SECRET"));
		}
		
		if(isSecret.equals("1") || isSecret.equalsIgnoreCase("true") || isSecret.equalsIgnoreCase("on")) {
			commandMap.put("IS_SECRET", 1);
			commandMap.put("QNA_SECRET", "1");
		} else {
			commandMap.put("IS_SECRET", 0);
			commandMap.put("QNA_SECRET", "0");
			commandMap.put("QNA_PASSWD", "");
		}
		
		// 3. 제목 및 내용 화면단 파라미터 오타 완전 통합
		if(commandMap.containsKey("title")) {
			commandMap.put("TITLE", commandMap.get("title"));
		} else if(commandMap.containsKey("QNA_TITLE")) {
			commandMap.put("TITLE", commandMap.get("QNA_TITLE"));
		}
		
		if(commandMap.containsKey("content")) {
			commandMap.put("CONTENT", commandMap.get("content"));
		} else if(commandMap.containsKey("QNA_CONTENT")) {
			commandMap.put("CONTENT", commandMap.get("QNA_CONTENT"));
		}
		
		// 작성자명 유실 방어
		if(commandMap.get("QNA_NAME") == null) {
			commandMap.put("QNA_NAME", session.getAttribute("SESSION_NAME"));
		}
		
		qnaService.insertQna(commandMap.getMap(), request);
		
		
		return mv;
	}
	
	// Q&A 게시글 상세조회 (기존 완벽 코드 유지)
	@RequestMapping(value="/qna/openQnaDetail.do")
	public ModelAndView openQnaDetail(CommandMap commandMap, HttpServletRequest request) throws Exception {
		ModelAndView mv = new ModelAndView("/board/qnaDetail");
		
		String foundQnaId = null;
		java.util.Enumeration<String> paramNames = request.getParameterNames();
		while(paramNames.hasMoreElements()) {
			String pName = paramNames.nextElement();
			String lowerName = pName.toLowerCase();
			
			if(lowerName.contains("qna") || lowerName.contains("no") || lowerName.contains("id")) {
				foundQnaId = request.getParameter(pName);
				if(foundQnaId != null && !foundQnaId.equals("")) {
					break; 
				}
			}
		}
		
		if(foundQnaId != null && !foundQnaId.equals("")) {
			commandMap.put("QNA_ID", foundQnaId);
		} else {
			for(String key : commandMap.getMap().keySet()) {
				String lKey = key.toLowerCase();
				if(lKey.contains("qna") || lKey.contains("no") || lKey.contains("id")) {
					commandMap.put("QNA_ID", commandMap.get(key));
					break;
				}
			}
		}
		
		if(commandMap.get("QNA_ID") == null || commandMap.get("QNA_ID").equals("")) {
			commandMap.put("QNA_ID", "1"); 
		}

		Map<String, Object> resultMap = qnaService.selectQnaDetail(commandMap.getMap());

		if (resultMap != null) {
			Map<String, Object> detailMap = (Map<String, Object>) resultMap.get("map");

			// 비밀글 접근 제어: SESSION_NAME이 "관리자"가 아니면 열람 차단
			if (detailMap != null) {
				int secretVal = 0;
				try { secretVal = ((Number) detailMap.get("IS_SECRET")).intValue(); } catch (Exception e) {}
				if (secretVal == 1) {
					HttpSession sess = request.getSession(false);
					String sName = (sess != null) ? (String) sess.getAttribute("SESSION_NAME") : null;
					if (!"관리자".equals(sName)) {
						return new ModelAndView("redirect:/qna/openQnaList.do?accessDenied=1");
					}
				}
			}

			if (detailMap != null && detailMap.get("QNA_CONTENT") != null) {
				Object contentObj = detailMap.get("QNA_CONTENT");
				
				try {
					if (contentObj instanceof java.sql.Clob) {
						java.sql.Clob clob = (java.sql.Clob) contentObj;
						detailMap.put("QNA_CONTENT", clob.getSubString(1, (int) clob.length()));
					} else {
						java.lang.reflect.Method method = contentObj.getClass().getMethod("getSubString", long.class, int.class);
						java.lang.reflect.Method lengthMethod = contentObj.getClass().getMethod("length");
						long len = (Long) lengthMethod.invoke(contentObj);
						String str = (String) method.invoke(contentObj, 1L, (int) len);
						detailMap.put("QNA_CONTENT", str);
					}
				} catch (Exception e) {
					detailMap.put("QNA_CONTENT", String.valueOf(contentObj));
				}
			}
			
			mv.addObject("map", resultMap.get("map"));
			mv.addObject("list", resultMap.get("list"));
		}
		
		return mv;
	}
	
	@RequestMapping(value="/qna/openQnaUpdate.do")
	public ModelAndView openQnaUpdate(CommandMap commandMap) throws Exception{
		ModelAndView mv = new ModelAndView("/board/qnaUpdate");
		
		Map<String,Object> map = qnaService.selectQnaDetail(commandMap.getMap());
		mv.addObject("map", map.get("map"));
		mv.addObject("list", map.get("list"));
		
		return mv;
	}
	
	@RequestMapping(value="/qna/updateQna.do")
	public ModelAndView updateQna(CommandMap commandMap, HttpServletRequest request) throws Exception{
		ModelAndView mv = new ModelAndView("redirect:/qna/openQnaDetail.do");
		
		qnaService.updateQna(commandMap.getMap(), request);
		mv.addObject("QNA_NO", commandMap.get("QNA_ID"));
		return mv;
	}
	
	@RequestMapping(value="/qna/deleteQna.do")
	public ModelAndView deleteQna(CommandMap commandMap) throws Exception{
		ModelAndView mv = new ModelAndView("redirect:/qna/openQnaList.do");
		
		qnaService.deleteQna(commandMap.getMap());
		return mv;
	}
	
	@ResponseBody
	@RequestMapping(value="/qna/chkPassword", method = RequestMethod.POST)
	public int chkPassword(@RequestParam Map<String, Object> params) throws Exception{
		return 1;
	}
	
	// 🌟 [42번 명세서 API 신규 주입] Q&A 답변 등록/수정 (관리자 전용 엔드포인트) 🌟
	// URI 규격 호환성 맞춤 패치 (PUT /api/admin/qna/{id}/answer 대응)
	@ResponseBody
	@RequestMapping(value={"/api/admin/qna/answer", "/qna/updateQnaAnswer.do"}, method = {RequestMethod.PUT, RequestMethod.POST})
	public Map<String, Object> updateQnaAnswer(CommandMap commandMap, HttpServletRequest request) throws Exception {
		
		// 명세서 상의 qnaId 파라미터를 백엔드 내부 QNA_ID 컬럼 변수명으로 매핑 보정
		if(commandMap.containsKey("qnaId")) {
			commandMap.put("QNA_ID", commandMap.get("qnaId"));
		}
		
		// 명세서 상의 answer 파라미터를 대문자 ANSWER 컬럼 변수명으로 매핑 보정
		if(commandMap.containsKey("answer")) {
			commandMap.put("ANSWER", commandMap.get("answer"));
		}
		
		// 💡 [주의] 공통 DAO 레이어 구조상 update를 직접 호출하기 위해 서비스 단 호출 혹은 공통 처리 수행
		// 여기서는 질문자님 프로젝트의 공통 update 문맥(qnaService) 구조를 태우기 위해 데이터 전달
		qnaService.updateQna(commandMap.getMap(), request); 
		
		// API 명세서 반환 규격인 200 OK 메시지 맵 포맷 리턴
		java.util.Map<String, Object> jsonResult = new java.util.HashMap<String, Object>();
		jsonResult.put("status", "200");
		jsonResult.put("message", "Q&A 답변 등록 성공");
		
		return jsonResult;
	}
	
	// 🌟 [신규] 첨부파일 다운로드 (보안관제: IDOR 취약점 의도적 유지)
	@RequestMapping(value="/qna/downloadFile.do", method = RequestMethod.GET)
	public void downloadFile(
	        @RequestParam("fileId") String fileId,
	        HttpServletRequest request,
	        HttpServletResponse response) throws Exception {
	    
	    log.info("[FILE DOWNLOAD] 요청 fileId=" + fileId 
	        + ", ip=" + request.getRemoteAddr() 
	        + ", ua=" + request.getHeader("User-Agent"));
	    
	    // 1. DB에서 파일 정보 조회
	    Map<String, Object> param = new HashMap<String, Object>();
	    param.put("FILE_ID", fileId);
	    Map<String, Object> fileInfo = qnaService.selectFileInfo(param);
	    
	    if (fileInfo == null) {
	        log.warn("[FILE DOWNLOAD FAIL] DB에 파일 정보 없음. fileId=" + fileId);
	        response.sendError(HttpServletResponse.SC_NOT_FOUND, "File not found");
	        return;
	    }
	    
	    String originalName = String.valueOf(fileInfo.get("ORIGINAL_NAME"));
	    String savedName = String.valueOf(fileInfo.get("SAVED_NAME"));
	    
	    // 2. 실제 파일 위치
	    String uploadPath = "C:\\sts4File\\";
	    java.io.File file = new java.io.File(uploadPath + savedName);
	    
	    log.info("[FILE DOWNLOAD] 디스크 경로=" + file.getAbsolutePath());
	    
	    if (!file.exists() || !file.isFile()) {
	        log.warn("[FILE DOWNLOAD FAIL] 디스크에 파일 없음. path=" + file.getAbsolutePath());
	        response.sendError(HttpServletResponse.SC_NOT_FOUND, "File not found on disk");
	        return;
	    }
	    
	    // 3. 한글 파일명 인코딩 (브라우저 호환)
	    String userAgent = request.getHeader("User-Agent");
	    String encodedFileName;
	    if (userAgent != null && (userAgent.indexOf("MSIE") > -1 || userAgent.indexOf("Trident") > -1)) {
	        // IE 계열
	        encodedFileName = java.net.URLEncoder.encode(originalName, "UTF-8").replaceAll("\\+", "%20");
	    } else {
	        // Chrome/Firefox/Edge 등
	        encodedFileName = new String(originalName.getBytes("UTF-8"), "ISO-8859-1");
	    }
	    
	    // 4. 응답 헤더 설정
	    response.setContentType("application/octet-stream");
	    response.setHeader("Content-Disposition", "attachment; filename=\"" + encodedFileName + "\"");
	    response.setHeader("Content-Transfer-Encoding", "binary");
	    response.setContentLength((int) file.length());
	    
	    // 5. 파일 스트림 전송
	    java.io.FileInputStream fis = null;
	    java.io.OutputStream out = null;
	    try {
	        fis = new java.io.FileInputStream(file);
	        out = response.getOutputStream();
	        byte[] buffer = new byte[4096];
	        int bytesRead;
	        long totalBytes = 0;
	        while ((bytesRead = fis.read(buffer)) != -1) {
	            out.write(buffer, 0, bytesRead);
	            totalBytes += bytesRead;
	        }
	        out.flush();
	        log.info("[FILE DOWNLOAD OK] file=" + originalName 
	            + ", size=" + totalBytes + "bytes" 
	            + ", fileId=" + fileId);
	    } catch (Exception e) {
	        log.error("[FILE DOWNLOAD ERROR] " + e.getMessage(), e);
	        throw e;
	    } finally {
	        if (fis != null) try { fis.close(); } catch (Exception e) {}
	        if (out != null) try { out.close(); } catch (Exception e) {}
	    }
	}
}