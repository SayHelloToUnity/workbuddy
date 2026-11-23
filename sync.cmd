@echo off
setlocal
cd /d "%~dp0"
chcp 65001 >nul 2>nul
set "PYTHONIOENCODING=utf-8"
set "ERRLOG=%~dp0last-error.log"

echo ==================================================
echo  WorkBuddy SYNC : this PC --^> remote
echo ==================================================
echo.

where python >nul 2>nul
if errorlevel 1 goto no_python
where git >nul 2>nul
if errorlevel 1 goto no_git

set "REPO=%~dp0."
if not exist "%~dp0manifest.json" set "REPO=C:\Users\56583\WorkBuddy\_wb-sync\snapshot"
if not exist "%REPO%\manifest.json" goto no_snapshot
if not exist "%USERPROFILE%\.workbuddy\workbuddy.db" goto no_db

echo   repo: %REPO%
echo.
echo [1/2] Checking remote access...
git -C "%REPO%" ls-remote origin > "%ERRLOG%" 2>&1
if errorlevel 1 goto bad_remote
echo       ok

echo [2/2] Exporting and pushing...
echo.
python "%~dp0wbmigrate.py" sync --repo "%REPO%" %*
if errorlevel 1 goto py_failed

echo.
echo Done.
goto fin

:no_python
echo [ERROR] python not found in PATH.
echo         Install Python 3.8+ and tick "Add python.exe to PATH".
goto fail

:no_git
echo [ERROR] git not found in PATH. Install Git for Windows.
goto fail

:no_snapshot
echo [ERROR] No snapshot folder found.
echo         Looked in: %~dp0
echo         Looked in: C:\Users\56583\WorkBuddy\_wb-sync\snapshot
goto fail

:no_db
echo [ERROR] workbuddy.db missing in %USERPROFILE%\.workbuddy
echo         Start WorkBuddy once and sign in, then retry.
goto fail

:bad_remote
echo [ERROR] Cannot reach the git remote. git said:
echo.
type "%ERRLOG%"
echo.
echo   Test SSH:  ssh -T git@github.com
goto fail

:py_failed
echo.
echo [ERROR] sync failed. Look for lines starting with [ERROR] above.
goto fail

:fail
echo.
echo FAILED - see the message above.
echo A full copy is saved in: %~dp0last-run.log
goto fin

:fin
echo %cmdcmdline% | "%SystemRoot%\System32\find.exe" /i "%~nx0" >nul 2>nul && pause
endlocal
