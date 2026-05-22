package stu.payment;

import org.springframework.stereotype.Repository;

import stu.common.dao.AbstractDao;

import java.util.List;
import java.util.Map;

@Repository("paymentDao")
public class PaymentDao extends AbstractDao {

    // 1. 결제 내역 최초 등록
    public void insertPayment(Map<String, Object> map) throws Exception {
        insert("payment.insertPayment", map);
    }

    // 2. 결제 단건 조회 (결과창 출력용)
    @SuppressWarnings("unchecked")
    public Map<String, Object> selectPaymentById(String transactionId) throws Exception {
        return (Map<String, Object>) selectOne("payment.selectPaymentById", transactionId);
    }

    // 3. 전체 결제 내역 조회 (관제용 리스트)
    @SuppressWarnings("unchecked")
    public List<Map<String, Object>> selectPaymentList() throws Exception {
        return (List<Map<String, Object>>) selectList("payment.selectPaymentList");
    }
}