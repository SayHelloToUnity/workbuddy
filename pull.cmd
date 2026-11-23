@echo off
setlocal
cd /d "%~dp0"
chcp 65001 >nul 2>nul
set "PYTHONIOENCODING=utf-8"
set "ERRLOG=%~dp0last-error.log"

echo ==================================================
echo  WorkBuddy PULL : remote --^> this PC
echo ==================================================
echo.

where python >nul 2>nul
if errorlevel 1 goto no_python
where git >nul 2>nul
if errorlevel 1 goto no_git

if not exist "%~dp0.git" goto no_repo
if not exist "%~dp0manifest.json" goto no_manifest
if not exist "%USERPROFILE%\.workbuddy" goto no_data
if not exist "%USERPROFILE%\.workbuddy\workbuddy.db" goto no_db

echo [1/3] Checking remote access...
git -C "%~dp0." ls-remote origin > "%ERRLOG%" 2>&1
if errorlevel 1 goto bad_remote
echo       ok

echo [2/3] Fetching and resetting to origin/main...
echo [3/3] Writing chats into this PC (overwrite + auto backup)...
echo       Close WorkBuddy now if it is running.
echo.
python "%~dp0wbmigrate.py" pull --repo "%~dp0." %*
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

:no_repo
echo [ERROR] This folder is not a git clone: %~dp0
echo         Run: git clone git@github.com:SayHelloToUnity/workbuddy.git wb-chat
goto fail

:no_manifest
echo [ERROR] manifest.json missing - clone incomplete or wrong branch.
echo         Run: git -C "%~dp0." fetch origin ^&^& git -C "%~dp0." reset --hard origin/main
goto fail

:no_data
echo [ERROR] %USERPROFILE%\.workbuddy not found.
echo         Start WorkBuddy once and sign in, then retry.
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
echo   Expected:  Hi SayHelloToUnity! ...
goto fail

:py_failed
echo.
echo [ERROR] pull failed. Look for lines starting with [ERROR] above.
goto fail

:fail
echo.
echo FAILED - see the message above.
echo A full copy is saved in: %~dp0last-run.log
goto fin

:fin
echo %cmdcmdline% | "%SystemRoot%\System32\find.exe" /i "%~nx0" >nul 2>nul && pause
endlocal
