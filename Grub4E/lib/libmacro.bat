::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: libmacro.bat
::
:: Written by Grub4K (Grub4K#2417)
::
:: Convert functions within a file to macros, optionally with arguments
::
:: Version History:
::  v1.0    Initial release
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

if not "!"=="" (
    >&2 echo ERROR: This script requires delayed expansion to be enabled at startup
    exit /B 3
)

set ^"__LF=^
%= these lines are required =%
^" do not remove

set "__filename=%~nx0"

set "__print_help="
set "__progress="
set "__generate_help="
set "__skip_flags="
set "__files="

:read_flags
if "%~1"=="" goto :_skip_flags
set "__search_flag=1"
if not defined __parse_flags (
    if "%~1"=="--" (
        set "__parse_flags=1"
        set "__search_flag="
    )
    for %%a in ("-generate-help" "g") do if defined __search_flag (
        if "%~1"=="-%%~a" (
            set "__generate_help=1"
            set "__search_flag="
        )
    )
    for %%a in ("-help" "h") do if defined __search_flag (
        if "%~1"=="-%%~a" (
            call :__print_help
            for /F "tokens=1 delims==" %%a in ('set __') do set "%%a="
            exit /B 0
        )
    )
    for %%a in ("-progress" "#") do if defined __search_flag (
        if "%~1"=="-%%~a" (
            set "__progress=."
            set "__search_flag="
        )
    )
)

if defined __search_flag (
    set __files=!__files! "%~1"
)
shift
goto :read_flags

:_skip_flags

if not defined __files (
    call :__print_help
    for /F "tokens=1 delims==" %%a in ('set __') do set "%%a="
    if not defined __print_help (exit /B 1) else exit /B 0
)

if defined __print_help (
    exit /B 0
)

for %%A in (!__files!) do (
    set "__file=%%~A"
    if not exist "!__file!" (
        >&2 echo ERROR: File "!__file!" does not exist
        for /F "tokens=1 delims==" %%a in ('set __') do set "%%a="
        exit /B 2
    )
)

for %%A in (!__files!) do (
    set "__file=%%~A"

    for /F "delims=" %%a in ('type "!__file!" ^| find /V /c ""') do set "__file_len=%%a"

    set "__macroname="
    <"!__file!" (
        for /L %%. in ( 1 1 !__file_len! ) do (
            set "__inline="
            set /p "__inline=!__progress!"
            if defined __inline (
                if "!__inline:~0,1!"==":" (
                    if not "!__inline:~1,1!"==":" (
                        for /F "tokens=1,2 delims= " %%a in ("!__inline:~1!") do (
                            set "__macroname=@%%a"
                            if not "%%b"=="" (
                                set "!__macroname!=for %%# in (1 2) do if %%#==2 for /F "tokens=1-9" %%1 in ("^^^!args^^^!") do ( endlocal!__LF!"
                                set "__macros_write_end=!__macros_write_end! !__macroname!
                            )
                        )
                    )
                ) else (
                    if defined __macroname (
                        for %%a in ("!__macroname!") do (
                            set "%%~a=!%%~a!!__inline:%%%%=%%!!__LF!"
                        )
                    )
                )
            )
        )
    )
)
for %%a in (!__macros_write_end!) do (
    set "%%a=!%%a!!__LF!) else setlocal EnableDelayedExpansion&set args="
)
if defined __progress echo:

for /F "tokens=1 delims==" %%a in ('set __') do set "%%a="
exit /B 0

:__print_help
echo(!__filename!  [options] ^<filename^> [filename [...]]
echo(
echo(  This script requires delayed expansion enabled at startup
echo(
echo(  -g / --generate-help      generate and print the help for each library file
echo(  -# / --progress           show progress indicator, one `.` per processed input line
echo(  -h / --help               print this help and exit
exit /B
