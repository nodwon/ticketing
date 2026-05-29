package stu.member.join;

import java.io.PrintWriter;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.log4j.Logger;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.ModelAndView;

import stu.common.common.CommandMap;


@Controller
public class JoinController {

	Logger log = Logger.getLogger(this.getClass());

	@Resource(name="joinService")
	private JoinService joinService;

	// 회원가입 폼
	@RequestMapping(value="/joinForm.do")
	public ModelAndView joinForm(CommandMap commandMap) throws Exception {
		ModelAndView mv = new ModelAndView("login/joinForm");


		return mv;
	}

	// 회원가입 처리
	@RequestMapping(value="/joinAction.do", method=RequestMethod.POST)
	public ModelAndView insertMember(CommandMap commandMap, HttpServletRequest request) throws Exception {
		ModelAndView mv = new ModelAndView("login/joinAction");
		// 이메일, SMS 수신 여부
		String email_agree = (String)commandMap.get("EMAIL_AGREE");
		String sms_agree = (String)commandMap.get("SMS_AGREE");
		// 체크를 하지 않으면 '0' 으로 set 후 넘김
		if(email_agree == null) {
			email_agree = "0";
			commandMap.put("EMAIL_AGREE", email_agree);
			mv.addObject("EMAIL_AGREE",email_agree);
		}
		if(sms_agree == null) {
			sms_agree = "0";
			commandMap.put("SMS_AGREE", sms_agree);
			mv.addObject("SMS_AGREE",sms_agree);
		}
		// 이메일
		String email = request.getParameter("MEMBER_EMAIL") + "@" + request.getParameter("MEMBER_EMAIL2");
		System.out.println("이메일 : "+email);
		// 직접입력일 경우
		if(request.getParameter("MEMBER_EMAIL2") == "") {
			email = request.getParameter("MEMBER_EMAIL");
		}
		commandMap.remove("MEMBER_EMAIL");
		commandMap.put("MEMBER_EMAIL", email);
		mv.addObject("MEMBER_EMAIL",email);

		String birth = request.getParameter("MEMBER_BIRTH")
					 + request.getParameter("MEMBER_BIRTH2")
					 + request.getParameter("MEMBER_BIRTH3");
		commandMap.remove("MEMBER_BIRTH");
		commandMap.put("MEMBER_BIRTH", birth);
		mv.addObject("MEMBER_BIRTH",birth);

		try {
	        joinService.insertMember(commandMap.getMap());
	    } catch (org.springframework.dao.DuplicateKeyException e) {
	        // 이메일 중복
	        mv.setViewName("login/joinForm");
	        mv.addObject("message", "이미 가입된 이메일입니다.");
	        return mv;
	    }

        mv.addObject("MEMBER_NAME", commandMap.get("MEMBER_NAME"));
        mv.addObject("MEMBER_ID", commandMap.get("MEMBER_ID"));
        mv.addObject("MEMBER_PW", commandMap.get("MEMBER_PW"));
        mv.addObject("MEMBER_PHONE", commandMap.get("MEMBER_PHONE"));
        mv.addObject("MEMBER_ZIPCODE", commandMap.get("MEMBER_ZIPCODE"));
        mv.addObject("MEMBER_ADDR1", commandMap.get("MEMBER_ADDR1"));
        mv.addObject("MEMBER_ADDR2", commandMap.get("MEMBER_ADDR2"));

		return mv;
	}

	//아이디 중복 체크
	@RequestMapping(value="/selectIdCheck.do", method=RequestMethod.GET)
	@ResponseBody
	public int selectIdCheck(@RequestParam("mem_userid") String mem_userid) throws Exception{

		int cnt = joinService.selectIdCheck(mem_userid);

		return cnt;
	}

	//이메일 중복 체크 - KMK 추가
	@RequestMapping(value="/selectEmailCheck.do", method=RequestMethod.GET)
	@ResponseBody
	public int selectEmailCheck(@RequestParam("user_email") String user_email) throws Exception{
		System.out.println("이메일 체크"+user_email);
		int cnt = joinService.selectEmailCheck(user_email);

		return cnt;
	}
}
