::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Detects keypresses and sends the information to the game via a key file.
:: This routine incorrectly reports `!` as something else. Both <CR> and the
:: Enter key are reported as {Enter}. An extra character is appended to the
:: output to preserve any control chars when read by SET /P.
@echo off
setlocal enableDelayedExpansion
for /f %%a in ('copy /Z "%~dpf0" nul') do set "CR=%%a"
set "cmd=hold"
set "inCmd="
set "key="
for /l %%. in () do (
    if "!cmd!" neq "hold" (
        for /f "delims=" %%A in ('xcopy /w "%~f0" "%~f0" 2^>nul') do (
            if not defined key set "key=%%A"
        )
        set "key=!key:~-1!"
        if !key! equ !CR! set "key={Enter}"
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
