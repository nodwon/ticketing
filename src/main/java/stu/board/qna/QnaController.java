package stu.board.qna;

import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
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
	public ModelAndView selectQnaList(CommandMap commandMap) throws Exception {
		ModelAndView mv = new ModelAndView("jsonView");
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
	
	@RequestMapping(value="/qna/insertQna.do", method = RequestMethod.POST )
	public ModelAndView insertQna(CommandMap commandMap, HttpServletRequest request) throws Exception{
		ModelAndView mv = new ModelAndView("redirect:/qna/openQnaList.do");
		
		// 💡 [추가] 로그인 세션에서 회원 식별 번호를 꺼내 명세서 규격(MEMBER_ID)에 맞게 주입
		javax.servlet.http.HttpSession session = request.getSession();
		if(session.getAttribute("MEMBER_NO") != null) {
			commandMap.put("MEMBER_ID", session.getAttribute("MEMBER_NO"));
		} else {
			commandMap.put("MEMBER_ID", null); // 로그인 안 된 경우 비회원 방어
		}
		
		// 기존 질문자님의 비밀글 처리 로직 (100% 그대로 유지)
		if(commandMap.containsKey("QNA_SECRET")==false) {
			commandMap.put("QNA_SECRET","0");
			commandMap.put("QNA_PASSWD","");
		}else{
			commandMap.put("QNA_SECRET","1");
		}
		
		// 화면단 오타(QNA_TITLE -> TITLE) 보정 방어막
		if(commandMap.containsKey("QNA_TITLE")) {
			commandMap.put("TITLE", commandMap.get("QNA_TITLE"));
		}
		if(commandMap.containsKey("QNA_CONTENT")) {
			commandMap.put("CONTENT", commandMap.get("QNA_CONTENT"));
		}
		
		qnaService.insertQna(commandMap.getMap(), request);
		
		return mv;
	}
	
	@RequestMapping(value="/qna/openQnaDetail.do")
	public ModelAndView openQnaDetail(CommandMap commandMap) throws Exception{
		ModelAndView mv = new ModelAndView("/board/qnaDetail");
		
		if(commandMap.containsKey("QNA_NO")) {
			commandMap.put("QNA_ID", commandMap.get("QNA_NO"));
		}
		
		Map<String,Object> map = qnaService.selectQnaDetail(commandMap.getMap());
		
		// 💡 상세 뷰 화면(JSP)이 깨지지 않고 옛날 데이터 명칭을 그대로 사용하도록 모델 맵 복사 주입
		if(map.get("map") != null) {
			Map<String, Object> detailMap = (Map<String, Object>) map.get("map");
			detailMap.put("QNA_TITLE", detailMap.get("QNA_TITLE"));
			detailMap.put("QNA_CONTENT", detailMap.get("QNA_CONTENT"));
			detailMap.put("QNA_DATE", detailMap.get("QNA_DATE"));
			detailMap.put("QNA_NO", detailMap.get("QNA_NO"));
			detailMap.put("QNA_NAME", detailMap.get("QNA_NAME"));
		}
		
		mv.addObject("map", map.get("map"));
		mv.addObject("list", map.get("list"));
		
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
	
}