::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Grub4E/logging.bat
::
:: Written by Grub4K (Grub4K#2417) with some techniques from DosTips
:: and many ideas from the folks at server.bat (discord.gg/GSVrHag)
::
:: Reads logging input stream and pretty prints these.
:: It respects the current loglevel and exists to have 2 outputs and
:: as to not slow down the tight main loop.
:: Accepted input is either ":END" ":setlevel <level>" or "<level> <message>"
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
setlocal DisableDelayedExpansion
:: define LF as a Line Feed (newline) character
set ^"LF=^
%= These lines are required =%
^" do not remove
:: Define line continuation
set ^"\n=^^^%LF%%LF%^%LF%%LF%^^"
:: Default loglevels
set "logLevels= ERROR WARNING "
:: TODO transition to use of %time% and %date%
set @performLog=(%\n%
for /F "tokens=1 delims= " %%a in ("!message!") do (%\n%
    if "!logLevels:%%a=!" neq "!logLevels!" (%\n%
        set "level=%%a   "%\n%
        set "message=!message:* =!"%\n%
        for /F "tokens=2 delims==" %%T in ('wmic OS Get localdatetime /value') do set "t=%%T"%\n%
        echo  !t:~0,4!-!t:~4,2!-!t:~6,2! !t:~8,2!:!t:~10,2!:!t:~12,2! ^^^| !level:~0,7! ^^^| !message!%\n%
    )%\n%
))
setlocal EnableDelayedExpansion
for /L %%. in () do (
    set "message="
    <&%logStream% set /p "message="

    if defined message (
        if "!message:~0,1!" equ ":" (
            if "!message!"==":END" (
                set "message=INFO Terminated logging module"
                %@performLog%
                <nul set /P "=Press any button to quit..."
                >nul pause
                exit
            ) else if "!message:~1,8!"=="setlevel" (
                set "message=!message:* =!"
                set "logLevels="
                set "found="
                for %%a in (
                    "SILENT"
                    "ERROR"
                    "WARNING"
                    "INFO"
                    "DEBUG"
                ) do (
                    if not defined found set "logLevels=!logLevels!%%~a "
                    if "%%~a"=="!message:* =!" set "found=1"
                )
                set "logLevels= !logLevels:* =!"
                set "message=INFO Switched loglevel to !message:* =!"
                %@performLog%
            )
        ) else %@performLog%
    )
)
