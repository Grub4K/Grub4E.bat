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

set ^"\n=^
%= these lines are required =%
^" do not remove

set __@strLen=for %%. in (1 2) do if %%.==2 (!\n!^
    for /f "tokens=1,2 delims=, " %%1 in ("^!argv^!") do (!\n!^
        set "__s=#^!%%~1^!"!\n!^
        set "%%~2=0"!\n!^
        for %%P in (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) do (!\n!^
            if "^!__s:~%%P,1^!" neq "" (!\n!^
                set /a "%%~2+=%%P"!\n!^
                set "__s=^!__s:~%%P^!"!\n!^
            )!\n!^
        )!\n!^
    )!\n!^
) else set argv=,

set "__filename=%~nx0"

set "__print_help="
set "__progress="
set "__generate_help="
set "__skip_flags="
set "__replace_vars="
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
    for %%a in ("-replace-variables" "v") do if defined __search_flag (
        if "%~1"=="-%%~a" (
            set "__replace_vars=1"
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
                        %__@strLen% __inline __inline_length
                        set "__inline_sub=!__inline:%%=!"
                        %__@strLen% __inline_sub __inline_sub_length
                        set /a "__iterations=(__inline_length - __inline_sub_length) / 2"
                        set "__line="
                        if defined __replace_vars (
                            for /L %%@ in ( 1 1 !__iterations! ) do (
                                if defined __inline (
                                    set "__process_line=!__inline:*%%=!"
                                    %__@strLen% __process_line __process_length
                                    set /a "__sublength=__inline_length - __process_length - 1, __inline_length-=__sublength+1"
                                    for %%a in ("!__sublength!") do set "__line=!__line!!__inline:~0,%%~a!"
                                    set "__inline=!__process_line!"
                                    if "!__inline:~0,1!"=="%%" (
                                        set "__line=!__line!%%"
                                        set "__inline=!__inline:~1!"
                                        set /a "__inline_length-=1"
                                    ) else (
                                        set "__process_line=!__inline:*%%=!"
                                        %__@strLen% __process_line __process_length
                                        set /a "__sublength=__inline_length - __process_length - 1, __inline_length-=__sublength+1"
                                        for %%a in ("!__sublength!") do (
                                            for %%b in ("!__inline:~0,%%~a!") do (
                                                set "__line=!__line!!%%~b!"
                                            )
                                        )
                                        set "__inline=!__process_line!"
                                    )
                                ) else (
                                    set "__line=!__line!!__inline!"
                                    set "__inline="
                                )
                            )
                        ) else (
                            set "__line=!__inline:%%%%=%%!"
                            set "__inline="
                        )
                        if defined __inline (
                            set "__line=!__line!!__inline!"
                        )
                        for %%a in ("!__macroname!") do (
                            set "%%~a=!%%~a!!\n!!__line!"
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
echo(  -# / --progress           show progress indicator, one `.` per processed input line
echo(  -v / --replace-variables  replace percent-variables with their corresponding value
echo(  -g / --generate-help      generate and print the help for each library file
echo(  -h / --help               print this help and exit
exit /B
