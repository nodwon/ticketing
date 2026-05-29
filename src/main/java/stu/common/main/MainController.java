package stu.common.main;

import javax.servlet.http.HttpServletRequest;

import org.apache.log4j.Logger;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.servlet.ModelAndView;

import stu.common.common.CommandMap;

@Controller
public class MainController {

	Logger log = Logger.getLogger(this.getClass()); //로그

	@RequestMapping(value = "main.do")
	public ModelAndView openMainList(CommandMap commandMap, HttpServletRequest request)  // 메인
			throws Exception {
		ModelAndView mv = new ModelAndView("main");

		mv.addObject("IDX", commandMap.getMap().get("IDX"));

		String filePath_temp = request.getContextPath() + "/file/";
		mv.addObject("path", filePath_temp);
		request.setAttribute("path", filePath_temp);


		return mv;
	}
}
