<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<style>
.footer { background: #111; color: #999; margin-top: 40px; }
.footer-top { border-bottom: 1px solid #222; padding: 36px 0; }
.footer-top-inner { max-width: 1200px; margin: 0 auto; padding: 0 20px; display: grid; grid-template-columns: 1fr 1fr 1fr 1fr; gap: 32px; }
.footer-col h5 { color: #ddd; font-size: 13px; font-weight: bold; margin-bottom: 14px; padding-bottom: 8px; border-bottom: 1px solid #333; }
.footer-col ul { list-style: none; }
.footer-col ul li { margin-bottom: 8px; }
.footer-col ul li a { color: #888; font-size: 12px; }
.footer-col ul li a:hover { color: #ccc; }
.footer-team-name { font-size: 22px; font-weight: 700; color: #e8001c; letter-spacing: 4px; margin-bottom: 4px; }
.footer-team-sub { font-size: 11px; color: #555; letter-spacing: 2px; margin-bottom: 12px; }
.footer-git-btn { display: inline-flex; align-items: center; gap: 6px; background: #24292e; color: #ccc; font-size: 12px; padding: 7px 14px; border-radius: 4px; border: 1px solid #444; }
.footer-git-btn:hover { background: #333; color: #fff; }
.footer-cs-num { font-size: 24px; font-weight: 700; color: #fff; margin-bottom: 8px; }
.footer-cs-time { font-size: 12px; color: #777; line-height: 2; }
.footer-bottom { padding: 20px 0; }
.footer-bottom-inner { max-width: 1200px; margin: 0 auto; padding: 0 20px; }
.footer-bottom-links { display: flex; gap: 16px; margin-bottom: 14px; flex-wrap: wrap; }
.footer-bottom-links a { color: #777; font-size: 12px; }
.footer-bottom-links a:hover { color: #ccc; }
.footer-bottom-links a.strong { color: #aaa; font-weight: bold; }
.footer-bottom-info { font-size: 11px; color: #555; line-height: 2.2; }
.footer-bottom-info span { margin-right: 14px; }
.footer-copy { font-size: 11px; color: #444; margin-top: 10px; }
</style>

<footer class="footer">
  <div class="footer-top">
    <div class="footer-top-inner">

      <div class="footer-col">
        <div class="footer-team-name">JANUS</div>
        <div class="footer-team-sub">30기 최종 프로젝트</div>
        <a class="footer-git-btn" href="https://github.com/" target="_blank">🔗 GitHub 저장소</a>
      </div>

      <div class="footer-col">
        <h5>CS CENTER</h5>
        <div class="footer-cs-num">070-7111-2427</div>
        <div class="footer-cs-time">
          평일 10:00 ~ 17:00<br>
          토/일/공휴일 휴무<br>
          점심시간 13:00 ~ 14:00
        </div>
      </div>

      <div class="footer-col">
        <h5>고객지원</h5>
        <ul>
          <li><a href="/notice/openNoticeList.do">공지사항</a></li>
          <li><a href="/qna/openQnaList.do">Q&amp;N 문의게시판</a></li>
          <li><a href="/faq/openFaqList.do">FAQ</a></li>
          <li><a href="#">이용약관</a></li>
          <li><a href="#">개인정보처리방침</a></li>
        </ul>
      </div>

      <div class="footer-col">
        <h5>서비스</h5>
        <ul>
          <li><a href="/concert/list.do">콘서트</a></li>
          <li><a href="/musical/list.do">뮤지컬/연극</a></li>
          <li><a href="/exhibition/list.do">전시/스포츠</a></li>
          <li><a href="/event/list.do">이벤트</a></li>
          <li><a href="#">티켓판매안내</a></li>
        </ul>
      </div>

    </div>
  </div>

  <div class="footer-bottom">
    <div class="footer-bottom-inner">
      <div class="footer-bottom-links">
        <a href="#">회사소개</a>
        <a href="#">이용약관</a>
        <a href="#" class="strong">개인정보처리방침</a>
        <a href="#">청소년보호정책</a>
        <a href="#">이용안내</a>
        <a href="#">티켓판매안내</a>
      </div>
      <div class="footer-bottom-info">
        <span>팀명: TEAM JANUS</span>
        <span>대표: 박지명</span>
        <span>사업자등록번호: 111-81-01111</span>
        <span>주소: 서울 금천구 중구 동호로 256</span><br>
        <span>문의전화: 070-111-1111</span>
        <span>팩스: 02-1111-1111</span>
        <span>통신판매신고: 제2022-서울금천-0111호</span>
        <span>개인정보관리책임자: 전형준 (a@a.co.kr)</span>
      </div>
      <div class="footer-copy">© 2026 TEAM JANUS. ALL RIGHTS RESERVED.</div>
    </div>
  </div>
</footer>

</body>
</html>