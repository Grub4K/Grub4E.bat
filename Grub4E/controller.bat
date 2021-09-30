::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Grub4E/controller.bat
::
:: Written by Grub4K (Grub4K#2417) with some techniques from DosTips
:: and many ideas from the folks at server.bat (discord.gg/GSVrHag)
::
:: Reads keypresses and sends these to the engine via a key file.
:: Both <CR> and the Enter key are reported as {Enter}.
:: The Tab char gets reported as {Tab}.
:: An `.` is appended to preserve control chars when read by SET /P.
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
setlocal enableDelayedExpansion
for /f %%a in ('copy /Z "%~dpf0" nul') do set "\r=%%a"
<"!COMSPEC!" (
    for /L %%P in (1,1,70) do pause>nul
    set /p "\t="
)
set "\t=!\t:~0,1!"
set "^^=^!."
set "cmd=hold"
set "inCmd="
set "key="
for /l %%. in () do (
    if "!cmd!" neq "hold" (
        for /f "delims=" %%A in ('xcopy /w "%~f0" "%~f0" 2^>nul') do (
            if not defined key set "key=%%A^!"
        )
        if !key:~-1!==^^ (
            set "key=^"
        ) else set "key=!key:~-2,1!"
        if !key! equ !\r! set "key={Enter}"
        if !key! equ !\t! set "key={Tab}"
    )
    <&%cmdStream% set /p "inCmd="
    if defined inCmd (
        if !inCmd! equ quit exit
        set "cmd=!inCmd!"
        set "inCmd="
    )
    if defined key (
        >&%keyStream% (echo(!key!.)
        set "key="
    )
)
