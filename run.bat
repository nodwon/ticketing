@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
REM ============================================================
REM 티켓팅 보안관제 - 환경 초기화 (Windows) + 폴더 리셋
REM
REM 동작:
REM   1) 기존 보안 로그 폴더가 있으면 통째 삭제 (확인 후)
REM   2) 종류별 하위 폴더 새로 생성
REM   3) 권한 설정
REM
REM 사용법:
REM   run.bat        ← 확인 메시지 표시 (안전 모드)
REM   run.bat /Y     ← 묻지 않고 바로 삭제 (자동 모드)
REM
REM ⚠ 주의: 기존 로그 파일이 모두 삭제됩니다.
REM    중요 로그는 미리 백업하세요.
REM ============================================================

set "BASE=C:\logs\ticketing\security"
set "AUTO=%~1"

echo ============================================
echo  티켓팅 보안관제 - 폴더 리셋
echo  대상: %BASE%
echo ============================================
echo.

REM ── [1/5] 기존 폴더 확인 + 삭제 ──────────────────────
if exist "%BASE%" (
    echo [1/5] 기존 폴더 발견: %BASE%
    echo.

    REM 자동 모드(/Y)가 아니면 확인 요청
    if /I not "%AUTO%"=="/Y" (
        echo ⚠ 이 폴더의 모든 로그 파일이 삭제됩니다.
        echo.
        set /p CONFIRM="정말 삭제하고 새로 만드시겠습니까? (Y/N): "
        if /I not "!CONFIRM!"=="Y" (
            echo.
            echo 취소되었습니다.
            pause
            exit /b 1
        )
    )

    echo   [삭제 중] %BASE% ...
    rmdir /S /Q "%BASE%" 2>nul

    REM 톰캣이 잠그고 있으면 삭제 실패할 수 있음
    if exist "%BASE%" (
        echo.
        echo [실패] 폴더 삭제 실패!
        echo    톰캣이 로그 파일을 잠그고 있을 가능성이 큽니다.
        echo    톰캣을 먼저 정지한 후 다시 실행하세요.
        echo.
        pause
        exit /b 1
    )
    echo   [OK] 기존 폴더 삭제 완료
) else (
    echo [1/5] 기존 폴더 없음 (새로 생성)
)

REM ── [2/5] 베이스 폴더 생성 ──────────────────────────
echo.
echo [2/5] 베이스 폴더 생성...
mkdir "%BASE%" 2>nul
echo   [OK] %BASE%

REM ── [3/5] 종류별 하위 폴더 생성 ─────────────────────
echo.
echo [3/5] 보안 로그 종류별 폴더 생성...
for %%D in (auth seat payment admin_access board behavior) do (
    mkdir "%BASE%\%%D" 2>nul
    echo   [생성] %BASE%\%%D
)

REM ── [4/5] 권한 설정 ─────────────────────────────────
echo.
echo [4/5] 권한 설정...
icacls "%BASE%" /grant Everyone:F /T >nul 2>&1
echo   [OK] %BASE% 및 하위 폴더 - Everyone:F 부여

REM ── [5/5] 결과 출력 ─────────────────────────────────
echo.
echo [5/5] 완료. 폴더 구조:
echo --------------------------------------------
dir /B /AD "%BASE%"
echo --------------------------------------------
echo.
echo   생성될 보안 로그 파일:
echo     %BASE%\auth\log_auth.json
echo     %BASE%\seat\log_seat.json
echo     %BASE%\payment\log_payment.json
echo     %BASE%\admin_access\log_admin_access.json
echo     %BASE%\board\log_board.json
echo     %BASE%\behavior\log_behavior_feature.json
echo.
echo   1시간 단위 롤링 백업 파일:
echo     log_xxx.YYYY-MM-DD_HH.json.gz
echo.
echo   ▶ 다음 작업:
echo     1. 톰캣 work 캐시 정리 (옛 클래스 제거)
echo        rmdir /S /Q %%CATALINA_HOME%%\work
echo     2. mvn clean package -DskipTests
echo     3. 톰캣 시작
echo     4. 좌석 페이지에서 구역 탭 (A/B/C/D/E) 클릭
echo     5. 로그 확인:
echo        type %BASE%\seat\log_seat.json
echo ============================================

pause
