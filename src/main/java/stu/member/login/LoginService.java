/**
 * ============================================================
 * Project   : 관제 티켓 (Ticketing System)
 * Package   : stu.member.login
 * FileName  : LoginService.java
 *
 * Developer : 심재학 (feature/batman)
 * Created   : 2026.05.25
 * Modified  : 2026.05.25
 *
 * Description :
 *   - 로그인 처리 인터페이스
 *   - 이메일/비밀번호 검증
 *   - 아이디(이메일)/비밀번호 찾기
 *   - 마지막 로그인 시각 갱신
 * ============================================================
 */
package stu.member.login;

import java.util.Map;

import javax.servlet.http.HttpServletRequest;

public interface LoginService {
	
	Map<String, Object> selectName(Map<String, Object> map) throws Exception; // 이름 출력
	
	String selectFindPw(Map<String, Object> map) throws Exception; // 비밀번호 초기화
	
	void updatePw(Map<String, Object> map) throws Exception;
	
	Map<String, Object> logout(Map<String, Object> map) throws Exception; // 로그아웃
	
	Map<String, Object> loginAction(Map<String, Object> map) throws Exception; // 로그인
	
	Map<String, Object> selectFindPw2(Map<String, Object> map) throws Exception; // 이메일 비밀번호 찾기
	
	Map<String, Object> selectFindId(Map<String, Object> map) throws Exception; // 이메일 아이디 찾기
	
	public void lastLogin(Object x) throws Exception; // 마지막 로그인 날짜 갱신
	
}
