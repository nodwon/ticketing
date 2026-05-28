@echo off
REM ====================================
REM 티켓팅 보안관제 - 환경 초기화 스크립트
REM ====================================

echo [1/3] 보안 로그 디렉토리 생성...
if not exist "C:\logs\ticketing\security" (
    mkdir "C:\logs\ticketing\security"
    echo   ✅ C:\logs\ticketing\security 생성 완료
) else (
    echo   ✅ 이미 존재
)

echo [2/3] 권한 확인...
icacls "C:\logs\ticketing\security" /grant Everyone:F /T >nul
echo   ✅ 권한 설정 완료

echo [3/3] 완료. 톰캣을 시작하세요.
pause