package stu.payment;

import java.util.List;
import java.util.Map;

public interface PaymentService {
    void processPayment(Map<String, Object> map) throws Exception;
    Map<String, Object> getPaymentResult(String transactionId) throws Exception;
    List<Map<String, Object>> getPaymentHistory() throws Exception;
}