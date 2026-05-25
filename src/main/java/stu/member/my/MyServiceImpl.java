package stu.member.my;

/*
 * ============================================================
 * Project    : 관제 티켓 (Ticketing System)
 * Package    : stu.member.my
 * FileName   : MyServiceImpl.java
 *
 * Developer  : 김희재 (feature/khj)
 * Created    : 2026.05.24
 * Modified   : 2026.05.24
 *
 * Description :
 *   - MyService 구현체
 *   - DAO 호출 위임 (비즈니스 로직은 Controller / DAO 에 분산)
 * ============================================================
 */

import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.apache.log4j.Logger;
import org.springframework.stereotype.Service;

@Service("myService")
public class MyServiceImpl implements MyService {

    private static final Logger log = Logger.getLogger(MyServiceImpl.class);

    @Resource(name = "myDAO")
    private MyDAO myDAO;

    @Override
    public Map<String, Object> getMemberInfo(Map<String, Object> map) throws Exception {
        return myDAO.selectMemberInfo(map);
    }

    @Override
    public int updateMemberInfo(Map<String, Object> map) throws Exception {
        return myDAO.updateMemberInfo(map);
    }

    @Override
    public int deleteMember(Map<String, Object> map) throws Exception {
        return myDAO.deleteMember(map);
    }

    @Override
    public List<Map<String, Object>> getBookingList(Map<String, Object> map) throws Exception {
        return myDAO.selectBookingList(map);
    }
}
