package stu.payment;

import org.springframework.stereotype.Service;
import javax.annotation.Resource;
import java.util.List;
import java.util.Map;

@Service("paymentService")
public class PaymentServiceImpl implements PaymentService {

    @Resource(name="paymentDao")
    private PaymentDao paymentDao;

    @Override
    public void processPayment(Map<String, Object> map) throws Exception {
        // Map 방식을 쓰면 여기서 패킷 추적용 ID나 상태값을 맵에 바로 찔러 넣으면 됩니다.
        if (!map.containsKey("transaction_id") || map.get("transaction_id") == null) {
            map.put("transaction_id", "TX_" + System.currentTimeMillis() / 1000);
        }
        if (!map.containsKey("status")) {
            map.put("status", "SUCCESS"); // 기본값 셋팅
        }
        paymentDao.insertPayment(map);
    }

    @Override
    public Map<String, Object> getPaymentResult(String transactionId) throws Exception {
        return paymentDao.selectPaymentById(transactionId);
    }

    @Override
    public List<Map<String, Object>> getPaymentHistory() throws Exception {
        return paymentDao.selectPaymentList();
    }
}