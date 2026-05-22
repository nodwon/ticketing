package stu.payment;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import javax.annotation.Resource;
import java.util.List;
import java.util.Map;

@Controller
@RequestMapping("/payment")
public class PaymentController {

    @Resource(name="paymentService")
    private PaymentService paymentService;

    // 1. 결제 정보 입력 폼 조회 및 내역 연동
    @RequestMapping("/form.do")
    public String paymentForm(Model model) throws Exception {
        List<Map<String, Object>> history = paymentService.getPaymentHistory();
        model.addAttribute("paymentList", history);
        return "paymentForm";
    }

    // 2. 가상 결제 패킷 처리 및 완료 페이지 이동
    @RequestMapping(value = "/result.do", method = RequestMethod.POST)
    public String paymentProcess(@RequestParam Map<String, Object> commandMap, Model model) throws Exception {
        
        // 폼에서 넘어온 컬럼 데이터를 가지고 서비스 호출
        paymentService.processPayment(commandMap);
        
        // 영수증 조회를 위해 발급된 transaction_id를 꺼내서 단건 조회
        String txId = (String) commandMap.get("transaction_id");
        Map<String, Object> result = paymentService.getPaymentResult(txId);
        
        model.addAttribute("payResult", result);
        return "paymentResult";
    }
}