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
setlocal disableDelayedExpansion
:: Default loglevels
set "logLevels= ERROR WARNING "

call Grub4E\lib\libdatef.bat
if errorlevel 2 (
    set "message=WARNING Could not determine date format, falling back to wmic"
) else if errorlevel 1 (
    set "message=WARNING Date format ambiguous, added a one day safety fallback"
) else set "message="

set "timeFormat=%datef.Year%-%datef.Month%-%datef.Day% %datef.Hours%:%datef.Minutes%:%datef.Seconds%,%datef.CentiSeconds%"
:: TODO transition to use of %time% and %date%
set @performLog=^
for /F "tokens=1 delims= " %%a in ("!message!") do ^
    if "!logLevels:%%a=!" neq "!logLevels!" (^
        set "level=%%a   " ^&^
        set "message=!message:* =!" ^&^
        %@datef.parseDateTime% (echo  %timeFormat% ^^^| !level:~0,7! ^^^| !message!)^
    )

setlocal EnableDelayedExpansion
if defined message (
    %@performLog%
)

for /L %%. in () do (
    set "message="
    <&%logStream% set /p "message="

    if defined message (
        if "!message:~0,1!" equ ":" (
            if "!message!"==":END" (
                set "message=INFO Terminated logging module"
                %@performLog%
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
