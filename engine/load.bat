@echo off
setlocal disableDelayedExpansion
:getSession
::if defined temp (set "tempFileBase=%temp%\") else if defined tmp set "tempFileBase=%tmp%\"
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "tempFileBase=%%a"
set "tempFileBase=%tempFileBase:.=%"
set "tempFileBase=%tempFileBase:~0,-7%"
set "tempFileBase=%~dp0sessions\%tempFileBase%\"
set "keyFile=%tempFileBase%key.txt"
set "cmdFile=%tempFileBase%cmd.txt"
set "gameLock=%tempFileBase%lock.txt"
set "gameLog=%tempFileBase%gamelog.txt"
set "signal=%tempFileBase%signal.txt"
set "keyStream=9"
set "cmdStream=8"
set "lockStream=7"
if not exist "%tempFileBase%" md "%tempFileBase%"
:: Lock this game session and launch.
:: Loop back and try a new session if failure.
:: Cleanup and exit when finished
call :launch %lockStream%>"%gameLock%" || goto :getSession
rd /s /q "%tempFileBase%"
exit /b

:launch
:: launch the game and the controller
copy nul "%keyFile%" >nul
copy nul "%cmdFile%" >nul
copy nul "%gameLog%" >nul
start "" /b cmd /c ^""%~dp0controller.bat" %keyStream%^>^>"%keyFile%" %cmdStream%^<"%cmdFile%" 2^>nul ^>nul^"
cmd /c ^""%~dp0engine.bat" 2^>NUL  %keyStream%^<"%keyFile%" %cmdStream%^>^>"%cmdFile%" ^<nul^"
<NUL set /P "=Press any button to quit..."
:close
2>nul (>>"%keyFile%" call ) || goto :close
exit /b 0
