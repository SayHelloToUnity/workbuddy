@echo off
setlocal
cd /d "%~dp0"
set "ERRLOG=%~dp0last-error.log"

echo ==================================================
echo  WorkBuddy SYNC : this PC --^> remote
echo ==================================================
echo.

rem ---- locate a real python (skip the Microsoft Store stub) ----
set "PY="
for /f "delims=" %%p in ('where python 2^>nul') do (
  echo %%p | "%SystemRoot%\System32\find.exe" /i "WindowsApps" >nul || set "PY=%%p"
)
if not defined PY for /f "delims=" %%p in ('where py 2^>nul') do if not defined PY set "PY=%%p"
if not defined PY for /d %%d in ("%USERPROFILE%\.workbuddy\binaries\python\versions\*") do if not defined PY if exist "%%~fd\python.exe" set "PY=%%~fd\python.exe"
if not defined PY goto no_python

echo   python: %PY%
"%PY%" -c "import sys;print('   version:',sys.version.split()[0])"
if errorlevel 1 goto bad_python
echo.

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
"%PY%" "%~dp0wbmigrate.py" sync --repo "%REPO%" %*
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" goto py_failed

echo.
echo Done.
goto fin

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
echo [ERROR] sync failed, exit code %RC%.
echo         Full log: %~dp0last-run.log
goto fail

:no_python
echo [ERROR] No usable Python found.
echo         Checked: where python (excluding WindowsApps), where py,
echo                  %USERPROFILE%\.workbuddy\binaries\python\versions
echo         Fix: install Python 3.8+ from python.org and tick
echo              "Add python.exe to PATH", then reopen this window.
goto fail

:bad_python
echo [ERROR] That python cannot run: %PY%
echo         If the path contains WindowsApps it is a Microsoft Store stub.
echo         Install real Python 3.8+ from python.org and retry.
goto fail

:fail
echo.
echo FAILED - see the message above.
echo If nothing is shown, open: %~dp0last-run.log
goto fin

:fin
echo %cmdcmdline% | "%SystemRoot%\System32\find.exe" /i "%~nx0" >nul 2>nul && pause
endlocal
