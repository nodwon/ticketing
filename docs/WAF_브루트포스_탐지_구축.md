# 브루트포스 공격 탐지 구축 기록 (WAF → Splunk SIEM)

> 로그인 무차별 대입(Brute Force) 공격을 **WAF(ModSecurity)로 탐지**하고
> **Splunk SOC 대시보드에 표시**되게 만든 전체 과정 기록.
> (탐지만 수행 — 차단 안 함, 관제용)

---

## 0. 목표
- 같은 IP가 짧은 시간에 로그인을 여러 번 시도하면 **WAF가 탐지**
- 그 탐지 로그가 **Splunk 대시보드 HIGH 경보**에 뜨고, **공격자 IP**까지 식별

## 1. 환경 / 구성
| 구성 | 값 |
|---|---|
| WAF | nginx + ModSecurity v3 + OWASP CRS 4.25 (호스트 `waf`, IP `10.0.10.2`) |
| 타겟 앱 | `yanus.com` (WAF가 리버스 프록시로 백엔드 전달) |
| 공격자 | Kali (`10.44.44.44`) |
| SIEM | Splunk (WAF/IDS 로그 통합, `soc_base` 매크로로 정규화) |
| 핵심 설정 | `/etc/nginx/modsec/main.conf`, `/etc/nginx/modsec/modsecurity.conf` |

---

## 2. WAF 설정 구조 파악

WAF 콘솔(`waf@waf`)에서 어떤 설정 파일을 쓰는지 확인.

```bash
# nginx가 로드하는 modsec 룰 파일 위치
grep -rn "modsecurity_rules_file" /etc/nginx/ 2>/dev/null | grep -v "#"
# → /etc/nginx/modsec/main.conf 사용 확인

# modsec 디렉터리 구조 + Include 순서
ls -l /etc/nginx/modsec/
grep -rn "Include" /etc/nginx/modsec/*.conf
cat /etc/nginx/modsec/main.conf
```

`main.conf` 내용(예):
```
Include "/etc/nginx/modsec/modsecurity.conf"
SecRuleEngine DetectionOnly        # ← 탐지만 (차단 안 함)
Include "/etc/nginx/modsec/crs-setup.conf"
Include "/etc/nginx/modsec/rules/*.conf"
```

---

## 3. 핵심 설정 2가지 확인

```bash
grep -n "SecDataDir|SecRuleEngine" /etc/nginx/modsec/modsecurity.conf
# 또는
grep -nE "SecDataDir|SecRuleEngine" /etc/nginx/modsec/modsecurity.conf
```
확인 결과:
- `SecDataDir /tmp/`  → **IP별 카운터 저장소 있음** (브루트포스 카운트에 필수)
- `SecRuleEngine On`(modsecurity.conf) 이지만 `main.conf`에서 `DetectionOnly`로 덮어씀
  → **최종: DetectionOnly = 탐지만 함**

> 💡 **차단까지** 하려면 `main.conf`의 `SecRuleEngine DetectionOnly` → `SecRuleEngine On` 으로 변경.

---

## 4. 커스텀 브루트포스 룰 작성

CRS는 SQLi/XSS는 잡지만 **브루트포스 룰이 없어서** 직접 추가.

### 4-1. 룰 파일 생성

**방법 A — heredoc (붙여넣기 가능한 터미널에서)**
```bash
sudo tee /etc/nginx/modsec/custom-rules.conf > /dev/null << 'EOF'
SecAction "id:1000100,phase:1,nolog,pass,initcol:ip=%{REMOTE_ADDR}"
SecRule REQUEST_LINE "@rx ^POST /loginAction\.do" "id:1000101,phase:2,nolog,pass,setvar:ip.login_count=+1,expirevar:ip.login_count=30"
SecRule IP:LOGIN_COUNT "@gt 10" "id:1000102,phase:2,deny,status:429,log,msg:'Brute force detected'"
EOF
```

**방법 B — nano (붙여넣기 안 되는 콘솔에서 직접 입력)**
```bash
sudo nano /etc/nginx/modsec/custom-rules.conf
# 아래 3줄 입력 후  Ctrl+O → Enter → Ctrl+X
```
```
SecAction "id:1000100,phase:1,nolog,pass,initcol:ip=%{REMOTE_ADDR}"
SecRule REQUEST_LINE "@rx ^POST /loginAction\.do" "id:1000101,phase:2,nolog,pass,setvar:ip.login_count=+1,expirevar:ip.login_count=30"
SecRule IP:LOGIN_COUNT "@gt 10" "id:1000102,phase:2,deny,status:429,log,msg:'Brute force detected'"
```

### 4-2. 룰 3줄의 의미

| 줄 | 역할 | 핵심 |
|---|---|---|
| ① `SecAction ... initcol:ip=%{REMOTE_ADDR}` | **출발지 IP별 카운터 준비** | phase1, 항상 실행 |
| ② `SecRule REQUEST_LINE "@rx ^POST /loginAction\.do" ... setvar:ip.login_count=+1, expirevar=30` | **로그인 POST마다 카운터 +1** (30초 창) | 슬라이딩 윈도우 |
| ③ `SecRule IP:LOGIN_COUNT "@gt 10" ... log, msg:'Brute force detected'` | **카운터 10 초과 시 탐지 로그** | 임계값=10 |

→ **"같은 IP가 30초 안에 `/loginAction.do` 로그인 11회↑ 시도하면 탐지"**

룰 ID를 왜 1개가 아닌 3개를 썼나?
브루트포스는 "여러 요청에 걸친" 공격이라서 1개 룰로는 안 되고, 상태(횟수)를 저장·누적·판단 하는 3단계가 각각 필요하기 때문

① id:1000100  → IP별 "카운터 장부" 준비 (initcol)
② id:1000101  → 로그인 POST 올 때마다 카운터 +1 (setvar)
③ id:1000102  → 카운터가 10 넘으면 → "브루트포스!" 탐지

### 4-3. 메인 설정에 등록
```bash
echo 'Include /etc/nginx/modsec/custom-rules.conf' | sudo tee -a /etc/nginx/modsec/main.conf
```

---

## 5. 문법 검사 & 적용

```bash
sudo nginx -t                    # "test is successful" 떠야 함
sudo systemctl reload nginx      # 적용
```

### ⚠️ 겪은 문제 — chain 문법 오류
- 처음엔 `chain` 으로 여러 줄 연결 → `nginx -t` 에서
  `Expecting an action, got: SecRule ...` 파싱 에러
- **해결**: 체인 제거 → `REQUEST_LINE` 하나로 **메서드+경로 동시 매칭**하는 위 3줄로 교체

---

## 6. 공격 재현 (테스트)

Kali(또는 터널 경유)에서 로그인 15회 시도 (11번째부터 룰 발동):

```bash
# Kali에서 직접 (포트 80, yanus.com)
for i in $(seq 1 15); do
  curl -s -o /dev/null -w "$i -> %{http_code}\n" -X POST \
    "http://yanus.com/loginAction.do" --data "MEMBER_ID=x&MEMBER_PASSWD=wrong$i"
done
```
- DetectionOnly라 응답은 계속 **200** (차단 안 함)

---

## 7. WAF 탐지 확인 (modsec_audit.log)

```bash
sudo grep -iE "Brute force|1000102" /var/log/modsec_audit.log | tail -10
```
정상 출력 예:
```
ModSecurity: Warning. Matched "Operator `Gt' with parameter `10' against
variable `IP:LOGIN_COUNT' (Value: `13') ... [id "1000102"]
[msg "Brute force detected"] ... [hostname "yanus.com"] [uri "/loginAction.do"]  IP:10.44.44.44
```
→ `id 1000102`, `Brute force detected`, `Value 11~15`, `IP:10.44.44.44` 확인 = **WAF 탐지 성공** ✅

---

## 8. Splunk 인덱싱 확인

Splunk **Search & Reporting** 에서:
```spl
index=* ("Brute force detected" OR "1000102") earliest=-30m
| table _time, src_ip, uri, severity, message
```
→ 브루트포스 이벤트 **들어옴 확인**(전송·인덱싱 정상)
→ 단, **대시보드엔 안 뜸**, `src_ip`/`uri` 비어 보임 → 9단계로

---

## 9. 대시보드 미표시 원인 진단

### 9-1. HIGH 경보 패널 SPL 확인
(대시보드 → 변경/편집 → 해당 패널 → Search)
```spl
`soc_base` | where severity=3 | ... | table Time, ..., signature, src_ip, dest_ip, uri, status
```
→ **`where severity=3`** : severity 3 이벤트만 표시

### 9-2. `soc_base` 매크로 확인
(설정 → 고급 검색 → 검색 매크로 → `soc_base`)

매크로의 WAF 섹션이 공격을 **태그로만 분류**:
```spl
| eval atk=mvfilter(match(atag,"^(sqli|xss|rce|lfi|injection-php)$"))   # ← 이 5개만 인식
| eval signature=case(maxc==0,"WAF Anomaly", ...)                       # 브루트포스 → "WAF Anomaly"
| eval severity=case(signature=="SQL Injection",3, ... ,true(),1)       # WAF Anomaly → severity 1
```

**결론(원인):**
- 매크로가 **bruteforce를 모름** → `signature="WAF Anomaly"`, `severity=1`
- 패널의 `where severity=3` 에서 **제외됨** → 대시보드에 안 뜸

---

## 10. soc_base 매크로 수정 (해결)

설정 → 고급 검색 → 검색 매크로 → **`soc_base`** 의 Definition 편집, WAF 섹션에 **2곳 추가**:

**수정 ① — 브루트포스 signature 인식** (signature case 줄 바로 뒤에 한 줄 추가)
```spl
| eval signature=if(match(_raw,"Brute force detected"),"Brute Force",signature)
```

**수정 ② — severity에 "Brute Force" = 3 추가** (severity case 줄에 삽입)
```spl
| eval severity=case(signature=="SQL Injection",3,signature=="RCE",3,signature=="PHP Injection",3,signature=="Brute Force",3,signature=="XSS",2,signature=="Path Traversal/LFI",2,true(),1)
```
→ **저장(Save)**

> 매크로는 **검색 시점**에 분류하므로 **이미 인덱싱된 이벤트도 자동 재분류**됨.

---

## 11. 최종 검증

1. 공격 15회 재현(6단계)
2. 대시보드 시간범위 **15분** → **HIGH 경보** 확인
3. 검색으로도 확인:
```spl
`soc_base` | where signature="Brute Force" earliest=-15m
| table _time, source_type, signature, severity, src_ip, uri
```

대시보드 결과:
| Source | Signature | 위험도 | Src IP | Dest IP | URI |
|---|---|---|---|---|---|
| WAF Web | **Brute Force** | **HIGH** | 10.44.44.44 | 10.0.10.2 | /loginAction.do |

→ **공격 → WAF 탐지 → Splunk 대시보드 표시까지 완성** ✅🎉

---

## ✅ 완성된 탐지 체인
```
공격자(Kali, curl)
 → WAF(nginx + ModSecurity 룰 id 1000102)
 → "Brute force detected" 탐지
 → /var/log/modsec_audit.log
 → Splunk forwarder
 → soc_base 매크로 (Brute Force / severity 3 분류)
 → SOC 대시보드 HIGH 경보 + 공격자 IP(10.44.44.44) 식별
```

---

## 📎 부록

### A. 자주 막히는 곳
| 증상 | 원인 | 해결 |
|---|---|---|
| `nginx -t` fail | chain 문법 | 체인 없는 3줄 버전 |
| 카운터 안 올라감 | SecDataDir 없음/권한 | `SecDataDir` 설정, `/tmp` 권한 |
| 차단 안 됨 | DetectionOnly | `SecRuleEngine On` |
| modsec_audit.log엔 있는데 Splunk엔 없음 | forwarder 미수집 | inputs.conf 경로 확인 |
| Splunk엔 있는데 대시보드엔 없음 | severity/분류 누락 | **soc_base 매크로 수정** |

### B. 임계값 조정
- 허용 횟수: 룰 ③의 `@gt 10` 숫자
- 시간 창: 룰 ②의 `expirevar:ip.login_count=30` (초)
- 예) "60초에 20회" → `@gt 20`, `expirevar:...=60`

### C. 탐지 → 차단으로 전환
```bash
sudo sed -i 's/^SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsec/main.conf
sudo nginx -t && sudo systemctl reload nginx
```
→ 이후 11번째 시도부터 **HTTP 429로 실제 차단**

### D. 참고 — 카운터가 빠른 버스트에서 일부 누락
ModSecurity 파일 기반 컬렉션은 초고속 연속 요청 시 read-modify-write 지연으로
탐지 알럿 수가 줄 수 있음(예: 5회 예상 → 2회). **탐지 자체엔 문제 없음.**
정확한 카운트가 필요하면 요청 사이 `sleep 0.3` 추가.
