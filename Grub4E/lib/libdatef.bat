@echo off
setlocal enableDelayedExpansion

for /F "tokens=2 delims==." %%a in (
    'wmic os get LocalDateTime /value'
) do set "datef.Date=%%a"
set "datef.Year=!datef.Date:~0,4!"
set "datef.Month=!datef.Date:~4,2!"
set "datef.Day=!datef.Date:~6,2!"
set "datef.Date="

:: TODO make this produce unique tokens
for /F "tokens=1-5 delims=:.,-\_/ " %%e in ("!date!") do (
    for %%a in (Year Month Day) do (
        if "%%e"=="!datef.%%a!" set "datef.%%a=e"
        if "%%f"=="!datef.%%a!" set "datef.%%a=f"
        if "%%g"=="!datef.%%a!" set "datef.%%a=g"
        if "%%h"=="!datef.%%a!" set "datef.%%a=h"
        if "%%i"=="!datef.%%a!" set "datef.%%a=i"
    )
)

set @datef.parseDateTime=for /F "tokens=1-9 delims=:.,-\_/ " %%a in ("^!time: =0^! ^!date^!") do

set "returnValue=0"
for %%a in (Year Month Day) do (
    if not defined datef.%%a set "returnValue=2"
)
if !returnValue! equ 2 (
    set @datef.parseDateTime=for /F "tokens=2 delims==+" %%a in ^('wmic os get LocalDateTime /value'^) do set "datef.Date=%%a"^^^&
    %"
    set "datef.Year=^!datef.Date:~0,-17^!"
    set "dtf.Month=^!datef.Date:~-17,2^!"
    set "datef.Day=^!datef.Date:~-15,2^!"
    set "datef.Hours=^!datef.Date:~-13,2^!"
    set "datef.Minutes=^!datef.Date:~-11,2^!"
    set "datef.Seconds=^!datef.Date:~-9,2^!"
    set "datef.CentiSeconds=^!datef.Date:~-6,2^!"
) else (
    if "!datef.Month!"=="!datef.Day!" (
        set @datef.parseDateTime=!@parseDateTime! if "!datef.Month!"=="!datef.Day!"
        set "returnValue=1"
    )
    for %%a in (Year Month Day) do (
        set "datef.%%a=%%!datef.%%a!"
    )
    set "datef.Hours=%%a"
    set "datef.Minutes=%%b"
    set "datef.Seconds=%%c"
    set "datef.CentiSeconds=%%d"
)

(
    endlocal
    set "datef.Year=%datef.Year%"
    set "datef.Month=%datef.Month%"
    set "datef.Day=%datef.Day%"
    set "datef.Hours=%datef.Hours%"
    set "datef.Minutes=%datef.Minutes%"
    set "datef.Seconds=%datef.Seconds%"
    set "datef.CentiSeconds=%datef.CentiSeconds%"
    set "@datef.parseDateTime=%@datef.parseDateTime%"
    exit /B %returnValue%
)
