::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Grub4E.bat
::
:: Written by Grub4K (Grub4K#2417) with some techniques from DosTips.
::
::
:: Changelog
::
:: 0.3
::   - implement fading
::   - move keybind loading
::   - Check hard collision map before movement
::   - renderFont macro
::   - changed naming of session folder
::   - move action event setup to keybind loading
::   - added additional info for debug mode
::   - Use @ convention for macros
::
:: 0.2
::   - Create debug mode
::   - Implement map loading
::   - Implement limited fontset loading
::   - Implement fontset rendering
::   - Implement action events
::   - Move macro definition to subroutine
::
:: 0.1
::   - Initial
::
:: This Source Code Form is subject to the terms of the Mozilla Public
:: License, v. 2.0. If a copy of the MPL was not distributed with this
:: file, You can obtain one at http://mozilla.org/MPL/2.0/.
:: This Source Code Form is "Incompatible With Secondary Licenses", as
:: defined by the Mozilla Public License, v. 2.0.
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@echo off
cls
if "%~1" == "startGame" goto :game
if "%~1" == "startController" goto :controller
setlocal disableDelayedExpansion
set "DEBUG="
if "%~1" == "-DEBUG" set "DEBUG=1"
pause
color F0
mode 114,114
goto :getSession

:game
set "VERTICAL_RES=8"
set "HORIZONTAL_RES=8"
set "MAXSIMULTKEYS=10"

:: TODO make this exportable ie read data\gameinfo.txt
set "GAMETITLE=Demo game"


set /a "VERTICAL_RES-=1, HORIZONTAL_RES-=1"
:: TODO: dynamic creation of for in content counters
set "UPPER=A B C D E F G H I J K L M N O P Q R S T U V W X Y Z"

set "current_key="

set "HEX=0 1 2 3 4 5 6 7 8 9 A B C D E F "

::call :setup_macros
:: define LF as a Line Feed (newline) character
set ^"LF=^
%= These lines are required =%
^" do not remove

:: Define ESC as the escape character
for /f "delims=" %%E in ('forfiles /p "%~dp0." /m "%~nx0" /c "cmd /c echo(0x1B"') do (
    set "ESC=%%E"
    <NUL set /p "_=%%E[?25l"
)

call :setup_macros

setlocal EnableDelayedExpansion

set "count=0"
set "lineset="
for %%a in ( %UPPER% ) do (
    set /a "count+=1"
    if !count! leq %HORIZONTAL_RES% set "lineset=!lineset!^!spriteset[%%%%a]_%%s^!"
)
:: Fill the spriteset with an empty tile
for %%s in ( %HEX% ) do (
    set "spriteset[FF]_%%s=                "
)

:: DONE SETTING UP ENGINE

:: TODO load keybinds from file
title [Grub4E] Loading... [ Keybinds ]
call :load_keybinds save\keybinds.txt

title [Grub4E] Loading... [ Fonts    ]
call :load_fontset data\font.txt

title [Grub4E] Loading... [ Sprites  ]
call :load_spriteset data\spriteset.txt

title [Grub4E] Loading... [ Map      ]
call :load_map data\map.txt

set /a "viewport_x=1, viewport_y=1"
set /a "viewport_x=viewport_x * 3, HRES= HORIZONTAL_RES *3, viewport_y_0=viewport_y, viewport_y_1=viewport_y + VERTICAL_RES"

title [Grub4E] !gametitle!
if defined DEBUG (
    set "temp=DEBUG"
    %@renderFont% temp debug_line
    set "temp="
    set "debug_overlay[0]=###########"
    set "debug_overlay[1]=#CS/f:    #"
    set "debug_overlay[3]=#FPS:     #"
    set "debug_overlay[5]=#State:   #"
    set "debug_overlay[7]=###########"
    set "keybind[debug]=#"
    set "action_events=!action_events! transition debug "
    set "debug_overlay=0"
    set "keybind[transition]=x"
    title [Grub4E] DEBUG:!gametitle!
)

set "overCount=0"
set "action_state=fadein"
set "action_state_next=map"

%@sendCmd% go
for /L %%. in ( infinite ) do (
    %= CALCULATE TIME DIFFERENCE AND FPS =%
    for /f "tokens=1-4 delims=:.," %%a in ("!time: =0!") do (
        set /a "t2=(((1%%a*60)+1%%b)*60+1%%c)*100+1%%d-36610100, tDiff=t2-t1, tDiff+=((~(tDiff&(1<<31))>>31)+1)*8640000, fps=100/tDiff, t1=t2"
    )
    %= DRAW THE SCREEN =%
    %=TODO    implement partial redraws %
    %=         - skip background recalculation %
    %=         - calculate substring position for line, then for loop over and insert %
    %=TODO    implement automatic dynamic sprites draw %
    %=TODO    implement text draw %
    set "count=0"
    for /L %%a in ( !viewport_y_0! 1 !viewport_y_1! ) do (
        for %%b in ("!viewport_x!") do for %%c in ("!HRES!") do set "screen[!count!]=!map[%%a]:~%%~b,%%~c!"
        set /a "count+=1"
    )

    %=TODO    manage drawing of character differntly %
    set "screen[3]=!screen[3]:~0,9!08!screen[3]:~11!"
    %=TODO    generate below counter dynamically %
    for %%l in ( 0 1 2 3 4 5 6 ) do (
        for /F "tokens=1-16 delims=`" %%A in ("!screen[%%l]!") do (
            set "line[%%l]="
            for %%s in ( %HEX% ) do (
                set "line[%%l]=!line[%%l]!!LF! %lineset%"
            )
        )
    )

    %= EXECUTE FADING COMMAND =%
    if "!action_state:~0,4!" equ "fade" (
        if "!action_state!" equ "fadein" (
            if !overCount! geq 13 (
                if !overCount! geq 16 (
                    if !overCount! geq 19 (
                        set "action_state=!action_state_next!"
                        set "overCount=0"
                    )
                    for %%l in ( 0 1 2 3 4 5 6 ) do (
                        set "line[%%l]=!line[%%l]:°= !"
                        set "line[%%l]=!line[%%l]:±=°!"
                        set "line[%%l]=!line[%%l]:Û=±!"
                    )
                ) else for %%l in ( 0 1 2 3 4 5 6 ) do (
                    set "line[%%l]=!line[%%l]:°= !"
                    set "line[%%l]=!line[%%l]:±= !"
                    set "line[%%l]=!line[%%l]:Û=°!"
                )
            ) else for %%l in ( 0 1 2 3 4 5 6 ) do (
                set "line[%%l]=!line[%%l]:°= !"
                set "line[%%l]=!line[%%l]:±= !"
                set "line[%%l]=!line[%%l]:Û= !"
            )
        ) else (
            if !overCount! geq 3 (
                if !overCount! geq 6 (
                    if !overCount! geq 19 (
                        set "action_state=!action_state_next!"
                        set "overCount=0"
                    )
                    for %%l in ( 0 1 2 3 4 5 6 ) do (
                        set "line[%%l]=!line[%%l]:°= !"
                        set "line[%%l]=!line[%%l]:±= !"
                        set "line[%%l]=!line[%%l]:Û= !"
                    )
                ) else for %%l in ( 0 1 2 3 4 5 6 ) do (
                    set "line[%%l]=!line[%%l]:°= !"
                    set "line[%%l]=!line[%%l]:±= !"
                    set "line[%%l]=!line[%%l]:Û=°!"
                )
            ) else for %%l in ( 0 1 2 3 4 5 6 ) do (
                set "line[%%l]=!line[%%l]:°= !"
                set "line[%%l]=!line[%%l]:±=°!"
                set "line[%%l]=!line[%%l]:Û=±!"
            )
        )
        set /a "overCount+=1"
    )

    if defined DEBUG %@drawOver% 93 106 19 5 debug_line
    if "!debug_overlay!"== "1" (
        set "debug_overlay[2]=         !tDiff!"
        set "debug_overlay[2]=#!debug_overlay[2]:~-9!#"
        set "debug_overlay[4]=         !fps!"
        set "debug_overlay[4]=#!debug_overlay[4]:~-9!#"
        set "debug_overlay[6]=         !action_state!"
        set "debug_overlay[6]=#!debug_overlay[6]:~-9!#"
        %@drawOver% 14 14 11 8 debug_overlay
    )

    %@cls%
    echo(
    for %%l in ( 0 1 2 3 4 5 6 ) do (
        echo(!line[%%l]:~1!
    )

    %= PROCESS INPUT =%
    set "key_list="
    for /L %%: in ( 1 1 %MAXSIMULTKEYS% ) do (
        <&%keyStream% set /p "inKey="
        if not "!current_key!" == "!inKey!" (
            set "key=!inKey:*#=!"
            set "key_list=!key_list!#!key:~0,-1!"
            set "current_key=!inKey!"
        )
    )
    %= Clear action events =%
    for %%a in ( %action_events% ) do set "action_%%a="
    %= translate keypresses into action events =%
    if defined key_list (
        set "key_list=!key_list!#"
        %= emergency quit button =%
        if "!key_list!" neq "!key_list:#+#=!" (
            %@sendCmd% quit
            exit
        )
        for %%a in ( %action_events% ) do (
            for %%b in ("!keybind[%%a]!") do (
                if "!key_list!" neq "!key_list:%%~b#=!" set "action_%%a=1"
            )
        )
    )

    if defined DEBUG (
        if defined action_debug set /a "debug_overlay^=1"
        if defined action_transition (
            set "action_state=fadeout"
            set "action_state_next=debug_t"
        )
        if "!action_state!" equ "debug_t" (
            set "action_state=fadein"
            set "action_state_next=map"
            call :load_map data\map2.txt
            set /a "viewport_x=4, viewport_y=0"
            set /a "viewport_x=viewport_x * 3, HRES= HORIZONTAL_RES *3, viewport_y_0=viewport_y, viewport_y_1=viewport_y + VERTICAL_RES"
        )
    )

    %= EXECUTE GAME LOGIC =%
    %=TODO    action resolver for cursor stuff in menus %
    %=TODO    calculate player position based of viewpoint =%
    %=TODO    SOFT collision - check if position is in specials, if so execute specials with parameters %
    if "!action_state!"=="map" (
        if defined action_up (
            set "move=1"
            for %%a in ( FF !colmap_hard! ) do (
                if "!screen[2]:~9,2!" equ "%%a" set "move="
            )
            if defined move set /a "viewport_y_0-=1, viewport_y_1-=1"
        )
        if defined action_down (
            set "move=1"
            for %%a in ( FF !colmap_hard! ) do (
                if "!screen[4]:~9,2!" equ "%%a" set "move="
            )
            if defined move set /a "viewport_y_0+=1, viewport_y_1+=1"
        )
        if defined action_left (
            set "move=1"
            for %%a in ( FF !colmap_hard! ) do (
                if "!screen[3]:~6,2!" equ "%%a" set "move="
            )
            if defined move set /a "viewport_x-=3"

        )
        if defined action_right (
            set "move=1"
            for %%a in ( FF !colmap_hard! ) do (
                if "!screen[3]:~12,2!" equ "%%a" set "move="
            )
            if defined move set /a "viewport_x+=3"
        )
        if defined action_menu set "action_state=menu"
    ) else if "!action_state!"=="menu" (
        if defined action_menu set "action_state=map"
        if defined action_cancel set "action_state=map"
    )
)

:: REVIEW: Use hex for numbers or not? change to normal
:load_spriteset  <spritefile> <offset>
:: loads a tilefile into the tilebuffer
set "__map=0123456789ABCDEF"
(
    set /P "__spritecount="
    set /a "__off=%~2+0,__spritecount+=off"
    for /L %%# in ( !__off! 1 !__spritecount! ) do (
        set "__hex="
        set "__dec=%%#"
        for %%n in ( 0 1 ) do (
            set /a "__d=__dec&15,__dec>>=4"
            for %%d in (!__d!) do set "__hex=!__map:~%%d,1!!__hex!"
        )
        for %%s in ( %HEX% ) do (
            set /P "spriteset[!__hex!]_%%s="
        )
    )
) < "%~1"
for /F "tokens=1 delims==" %%v in ('set __') do set "%%v="
exit /B

:: TODO: load from a file
:load_keybinds  <keybindsfile>
set "action_events= up down left right menu confirm cancel "
set "keybind[up]=w"
set "keybind[down]=s"
set "keybind[left]=a"
set "keybind[right]=d"
set "keybind[confirm]=e"
set "keybind[cancel]=q"
set "keybind[menu]={Enter}"
exit /B

:: TODO: convert every char in fontmap to ascii, use that
:load_fontset  <fontset>
set /a "fontheight=5 - 1"
set /a "__fontcount=16"
(
    set /p "__fontmap="
    %@strLen% fontmap fontcount
    set /a "__fontcount-=1"
    for /L %%a in ( 0 1 !__fontcount! ) do (
        set "__current=!__fontmap:~%%a,1!"
        for /L %%b in ( 0 1 !fontheight! ) do (
            set /p "font[!__current!][%%b]="
        )
    )
) <"%~1"
for /F "tokens=1 delims==" %%v in ('set __') do set "%%v="
exit /B

:: TODO: make this more advanced
::        - automatic spriteset loading
::        - starting position (?)
::        - tile events
:load_map  <mapfile>
:: TODO: load collision map from map file
set "colmap_hard= 02 03 04 06 05 "
set "__frame=FF`FF`FF"
set /a "__count=3"
for /F "usebackq delims=" %%a in ("%~f1") do (
    set "__line=%%a"
    if not defined mapsize (
        %@strLen% __line mapsize
        set /a "mapsize-=1"
    )
    set "map[!__count!]=!__frame!`"
    for %%b in ("map[!__count!]") do (
        for /L %%c in ( 0 2 !mapsize! ) do (
            set "%%~b=!%%~b!!__line:~%%c,2!`"
        )
        set "%%~b=!%%~b!!__frame!"
    )
    set /a "__count+=1"
)
set /a "__count1=__count+1, __count2=__count+2"
set "__line=!__frame!`"
for /L %%. in ( 0 2 !mapsize! ) do set "__line=!__line!FF`"
set "__line=!__line!!__frame!"
for %%a in ( 0 1 2 !__count! !__count1! !__count2! ) do set "map[%%a]=!__line!"
for /F "tokens=1 delims==" %%v in ('set __') do set "%%v="
exit /B

:setup_macros
:: Define line continuation
set ^"\n=^^^%LF%%LF%^%LF%%LF%^^"

::@strLen  <strVar> [RtnVar]
set @strLen=for %%# in (1 2) do if %%#==2 (%\n%
  for /f "tokens=1,2 delims=, " %%1 in ("!argv!") do ( endlocal%\n%
    set "s=A!%%~1!"%\n%
    set "len=0"%\n%
    for %%P in (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) do (%\n%
      if "!s:~%%P,1!" neq "" (%\n%
        set /a "len+=%%P"%\n%
        set "s=!s:~%%P!"%\n%
      )%\n%
    )%\n%
    for %%V in (!len!) do endlocal^&if "%%~2" neq "" (set "%%~2=%%V") else echo %%V%\n%
  )%\n%
) else setlocal enableDelayedExpansion^&setlocal^&set argv=,

::@renderFont  <renderdata> <output>
:: render characters into an array to be displayed with @drawOver
set @renderFont=for %%# in (1 2) do if %%#==2 ( for /f "tokens=1,2 delims=, " %%1 in ("!argv!") do ( %\n%
for /L %%a in ( 0 1 !fontheight! ) do set "%%~2[%%a]=" %\n%
set "s=!%%~1!" %\n%
set "len=0" %\n%
for %%a in ( 4096 2048 1024 512 256 128 64 32 16 8 4 2 1 ) do if "!s:~%%a,1!" neq "" (%\n%
    set /a "len+=%%a" %\n%
    set "s=!s:~%%a!" %\n%
) %\n%
for /L %%b in ( 0 1 !len! ) do for %%c in ("!%%~1:~%%~b,1!") do for /L %%a in ( 0 1 !fontheight! ) do set "%%~2[%%a]=!%%~2[%%a]!!font[%%~c][%%a]! " %\n%
for /L %%a in ( 0 1 !fontheight! ) do set "%%~2[%%a]=!%%~2[%%a]:~0,-1!" %\n%
)) else set argv=,

::@drawOver  <x> <y> <xlen> <ylen> <data>
::: draw data over a specified portion of the screen.
set @drawOver=for %%# in (1 2) do if %%#==2 ( %\n%
for /F "tokens=1-5 delims=, " %%1 in ("!args!") do ( %\n%
    set /a "yless=%%~4-1" %\n%
    for /L %%a in ( 0 1 !yless! ) do ( %\n%
        set /a "y=%%~2+%%a,linenum=y/16,linestart=(y %% 16)*(16*7+2)+%%~1,lineend=linestart+%%~3" %\n%
        for /f "tokens=1-3" %%b in ("!linenum! !linestart! !lineend!") do ( %\n%
            set "line[%%b]=!line[%%~b]:~0,%%~c!!%%~5[%%a]:~0,%%~3!!line[%%~b]:~%%~d!" %\n%
        ) %\n%
    ) %\n%
)) else set args=,

:: clear screen by setting cursor to 0:0
set "@cls=<NUL set /P =%ESC%[H"

:: @sendCmd  command
:::  sends a command to the controller
set "@sendCmd=>&%cmdStream% echo"

for /F "tokens=1 delims==" %%v in ('set __') do set "%%v="
exit /B

:getSession
::if defined temp (set "tempFileBase=%temp%\") else if defined tmp set "tempFileBase=%tmp%\"
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "tempFileBase=%%a"
set "tempFileBase=%tempFileBase:.=%"
set "tempFileBase=%tempFileBase:~0,-7%"
set "tempFileBase=%~dp0Grub4E\%tempFileBase%\"
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

::------------------------------------------
:launch
:: launch the game and the controller
copy nul "%keyFile%" >nul
copy nul "%cmdFile%" >nul
start "" /b cmd /c ^""%~f0" startController %keyStream%^>^>"%keyFile%" %cmdStream%^<"%cmdFile%" 2^>nul ^>nul^"
cmd /c ^""%~f0" startGame  2^>NUL  %keyStream%^<"%keyFile%" %cmdStream%^>^>"%cmdFile%" ^<nul^"
<NUL set /P "=Press any button to quit..."
:close
2>nul (>>"%keyFile%" call ) || goto :close
exit /b 0

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:controller
:: Detects keypresses and sends the information to the game via a key file.
::
:: As written, this routine incorrectly reports ! as ), but that doesn't matter
:: since we don't need that key. Both <CR> and Enter key are reported as {Enter}.
:: An extra character is appended to the output to preserve any control chars
:: when read by SET /P.
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
        >&%keyStream% (echo(!time!#!key!.)
        set "key="
    )
)
