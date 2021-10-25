::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Grub4E
::
:: Written by Grub4K (Grub4K#2417) with some techniques from DosTips
:: and many ideas from the folks at server.bat (discord.gg/GSVrHag)
::
::
:: This Source Code Form is subject to the terms of the Mozilla Public
:: License, v. 2.0. If a copy of the MPL was not distributed with this
:: file, You can obtain one at http://mozilla.org/MPL/2.0/.
:: This Source Code Form is "Incompatible With Secondary Licenses", as
:: defined by the Mozilla Public License, v. 2.0.
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@echo off
setlocal disableDelayedExpansion

:getSession
set "tempFileBase=%~dp0"
:: REMOVE
::set "tempFileBase="
::if defined temp (set "tempFileBase=%temp%\") else if defined tmp set "tempFileBase=%tmp%\"
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "currDatetime=%%a"
set "currDatetime=%currDatetime:.=%"
set "currDatetime=%currDatetime:~0,-8%"
set "tempFileBase=%tempFileBase%sessions\%currDatetime%\"
set "keyFile=%tempFileBase%key.txt"
set "cmdFile=%tempFileBase%cmd.txt"
set "logFile=%tempFileBase%log.txt"
set "lockFile=%tempFileBase%lock.txt"
set "signal=%tempFileBase%signal.txt"
set "keyStream=9"
set "cmdStream=8"
set "logStream=7"
set "lockStream=6"
if not exist "%tempFileBase%" md "%tempFileBase%"
:: Lock this game session and launch.
:: Loop back and try a new session if failure.
:: Cleanup and exit when finished
call :launch %lockStream%>"%lockFile%" || goto :getSession
rd /s /q "%tempFileBase%"
exit /b

:launch
:: launch the game and the controller
copy nul "%keyFile%" >nul
copy nul "%cmdFile%" >nul
copy nul "%logFile%" >nul
set "fail="
:: TODO unify interface for controller and logging
if defined loggingWindow start "Logging Console" cmd /c ^"Grub4E\logging.bat %logStream%^<"%logFile%" 2^>nul ^"
start "" /b cmd /c ^"Grub4E\controller.bat %keyStream%^>^>"%keyFile%" %cmdStream%^<"%cmdFile%" 2^>nul ^>nul^"
cmd /c ^"Grub4E\engine.bat 2^>NUL  %keyStream%^<"%keyFile%" %cmdStream%^>^>"%cmdFile%" %logStream%^>^>"%logFile%" ^<nul^"

if errorlevel 1 (
    echo:
    if errorlevel 255 (
        echo Engine has crashed on a syntax error
    ) else echo Engine did not shutdown correctly
    if defined loggingWindow echo Check the logging window
    set "fail=1"
) else if defined loggingWindow (
    >>"%logFile%" echo quit
)

>>"%cmdFile%" echo quit
<nul set /P "=Press any button to quit..."
ping -n 1 localhost >NUL
2>nul (>>"%keyFile%" call ) && >nul pause
:close
2>nul (>>"%keyFile%" call ) || (
    ping -n 1 localhost >NUL
    goto :close
)

if defined fail if defined loggingWindow (
    >>"%logFile%" echo quit
    ping -n 2 localhost >NUL
    %= TODO delete the logFile ?=%
)
exit /b 0
