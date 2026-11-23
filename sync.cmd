@echo off
setlocal
rem WorkBuddy: push local chats to remote (remote is source of truth)
where python >nul 2>nul
if errorlevel 1 (
  echo Python not found. Install Python 3.8+ first.
  goto fail
)
python "%~dp0wbmigrate.py" sync --repo "%~dp0."
if errorlevel 1 goto fail
echo.
echo Done.
goto fin

:fail
echo.
echo FAILED. Read the output above.

:fin
echo %cmdcmdline% | find /i "%~nx0" >nul && pause
endlocal
