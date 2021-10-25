@echo off
setlocal enableDelayedExpansion
set "returnValue=0"

for /F "tokens=2 delims==." %%a in (
    'wmic os get LocalDateTime /value'
) do set "datef.Date=%%a"
set "datef.Year=!datef.Date:~0,4!"
set "datef.Month=!datef.Date:~4,2!"
set "datef.Day=!datef.Date:~6,2!"
set "datef.Date="

set "datef.Once="
if "!datef.Month!"=="!datef.Day!" (
    set "datef.Once=1"
    set "returnValue=1"
)

set "datef.Lookup= "
for /F "tokens=1-5 delims=:.,-\_/ " %%e in ("!date!") do (
    for %%b in ("%%e e" "%%f f" "%%g g" "%%h h" "%%k k") do (
        for /F "tokens=1,2" %%c in ("%%~b") do (
            for %%a in (Year Day Month) do (
                if "%%c"=="!datef.%%a!" (
                    if "!datef.Lookup:%%d=!"=="!datef.Lookup!" (
                        set "datef.%%a=%%d"
                        set "datef.Lookup=!datef.Lookup!%%d"
                    )
                )
            )
        )
    )
)

for %%a in (Year Month Day) do (
    if not defined datef.%%a set "returnValue=2"
)

if !returnValue! equ 2 (
    set @datef.parseDateTime=for /F "tokens=2 delims==+" %%a in ^('wmic os get LocalDateTime /value'^) do set "datef.Date=%%a"^^^&
    set "datef.Year=^!datef.Date:~0,-17^!"
    set "datef.Month=^!datef.Date:~-17,2^!"
    set "datef.Day=^!datef.Date:~-15,2^!"
    set "datef.Hours=^!datef.Date:~-13,2^!"
    set "datef.Minutes=^!datef.Date:~-11,2^!"
    set "datef.Seconds=^!datef.Date:~-9,2^!"
    set "datef.CentiSeconds=^!datef.Date:~-6,2^!"
) else (
    for %%a in (Year Month Day) do set "datef.%%a=%%!datef.%%a!"
    set @datef.parseDateTime=for /F "tokens=1-9 delims=:.,-\_/ " %%a in ^("^!time: =0^! ^!date^!"^) do
    if defined datef.Once (
        set @datef.parseDateTime=!@datef.parseDateTime! ^(if defined datef.Once ^(if 1!datef.Month! GTR 1!datef.Day! ^(^
                set "datef.Swap=1" ^^^&^
                set "datef.Once=" ^
            ^)^)^)^^^&^(^
                if defined datef.Swap ^(set "datef.Format=!datef.Day! !datef.Month!"^) else set "datef.Format=!datef.Month! !datef.Day!"^
            ^)^^^&^
            for /F "tokens=1-2" %%l in ^("^^^!datef.Format^^^!"^) do
        set "datef.Month=%%l"
        set "datef.Day=%%m"
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
    set "datef.Format=%datef.Format%"
    set "@datef.parseDateTime=%@datef.parseDateTime%"
    set "datef.Once=%datef.Once%"
    set "datef.Swap="
    exit /B %returnValue%
)
