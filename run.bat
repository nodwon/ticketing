@echo off
REM ============================================================
REM 티켓팅 보안관제 - 환경 초기화 (Windows)
REM 
REM 변경사항 (2026-05-29):
REM   - 보안 로그가 1시간 단위로 분리됨 (logback.xml 변경에 따라)
REM   - 파일명 예: log_auth.2026-05-29_14.json.gz
REM   - 디스크 공간이 더 많이 필요할 수 있음 (작은 파일 다수)
REM ============================================================

echo ============================================
echo  티켓팅 보안관제 환경 초기화 (Windows)
echo  로그 단위: 1시간별 분리
echo ============================================
echo.

REM [1/3] 보안 로그 디렉토리 생성
echo [1/3] 보안 로그 디렉토리 생성...
if not exist "C:\logs\ticketing\security" (
    mkdir "C:\logs\ticketing\security"
    echo   [OK] C:\logs\ticketing\security 생성 완료
) else (
    echo   [OK] 이미 존재: C:\logs\ticketing\security
)

REM [2/3] 권한 설정
echo.
echo [2/3] 권한 확인...
icacls "C:\logs\ticketing\security" /grant Everyone:F /T >nul 2>&1
echo   [OK] 권한 설정 완료

REM [3/3] 안내
echo.
echo [3/3] 완료.
echo.
echo   생성될 보안 로그 (1시간 단위 롤링):
echo     log_auth.json            -- 현재 1시간
echo     log_auth.YYYY-MM-DD_HH.json.gz  -- 이전 시간 (자동 압축)
echo     log_seat.json / log_payment.json / log_admin_access.json
echo     log_board.json / log_behavior_feature.json
echo.
echo   톰캣을 시작하세요.
echo ============================================

pause
