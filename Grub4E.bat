::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Grub4E.bat
::
:: Written by Grub4K (Grub4K#2417) with some techniques from DosTips.
::
::
:: Changelog
::
:: 0.1.0
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
if "%~1" == "startGame" goto :game
if "%~1" == "startController" goto :controller
color F0
mode 114,114
cls
setlocal disableDelayedExpansion
::goto :DEBUG
goto :getSession

:game
set "VERTICAL_RES=8"
set "HORIZONTAL_RES=8"
set "MAXSIMULTKEYS=10"

set "GAMETITLE=Demo game"

set "DEBUG_OVERLAY=1"

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

:: Define line continuation
set ^"\n=^^^%LF%%LF%^%LF%%LF%^^"

:: Define ESC as the escape character
for /f "delims=" %%E in ('forfiles /p "%~dp0." /m "%~nx0" /c "cmd /c echo(0x1B"') do (
    set "ESC=%%E"
)


::drawover  <x> <y> <xlen> <ylen> <data>
::: draw data over a specified portion of the screen.
set drawover=for %%# in (1 2) do if %%#==2 ( %\n%
for /F "tokens=1-5 delims=, " %%1 in ("!args!") do ( %\n%
    set /a "yless=%%~4-1" %\n%
    for /L %%a in ( 0 1 !yless! ) do ( %\n%
        set /a "y=%%~2+%%a,linenum=y/16,linestart=(y %% 16)*(16*7+2)+%%~1,lineend=linestart+%%~3" %\n%
        for /f "tokens=1-3" %%b in ("!linenum! !linestart! !lineend!") do ( %\n%
            set "line[%%b]=!line[%%~b]:~0,%%~c!!%%~5[%%a]:~0,%%~3!!line[%%~b]:~%%~d!" %\n%
        ) %\n%
    ) %\n%
)) else set args=,

:: Define 'clear screen' macro
set "cls=<NUL set /P =%ESC%[H"





<NUL set /p "_=%ESC%[?25l"
setlocal EnableDelayedExpansion
title [Grub4E] !gametitle!


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

:: sendCmd  command
:::  sends a command to the controller
set "sendCmd=>&%cmdStream% echo"


:: DONE SETTING UP ENGINE

call :load_spriteset data\spriteset.txt


:: TODO: implement map loading
set "line=-1"
for %%a in (
    "FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF"
    "FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF"
    "FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF"
    "FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF"
    "FF`FF`FF`FF`04`04`04`04`07`04`04`04`04`FF`FF`FF`FF"
    "FF`FF`FF`FF`02`01`01`01`01`06`01`06`02`FF`FF`FF`FF"
    "FF`FF`FF`FF`03`01`01`01`01`05`01`05`03`FF`FF`FF`FF"
    "FF`FF`FF`FF`02`01`01`01`01`01`01`01`02`FF`FF`FF`FF"
    "FF`FF`FF`FF`03`01`01`01`01`06`01`06`03`FF`FF`FF`FF"
    "FF`FF`FF`FF`02`01`01`01`01`05`01`05`02`FF`FF`FF`FF"
    "FF`FF`FF`FF`03`01`01`01`01`01`01`01`03`FF`FF`FF`FF"
    "FF`FF`FF`FF`01`01`01`00`00`01`01`01`01`FF`FF`FF`FF"
    "FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF"
    "FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF"
    "FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF"
    "FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF`FF"
) do (
    set /a "line+=1"
    set "map[!line!]=%%~a"
)
set "action_state=map"
set "action_events= up down left right menu confirm cancel "
:: TODO load keybinds from file
set "keybind[up]=w"
set "keybind[down]=s"
set "keybind[left]=a"
set "keybind[right]=d"
set "keybind[confirm]=e"
set "keybind[cancel]=q"
set "keybind[menu]={Enter}"

if defined debug_overlay (
    set debug_overlay[0]=########
    set debug_overlay[1]=#CS/f: #
    set debug_overlay[3]=#FPS:  #
    set debug_overlay[5]=#State:#
    set debug_overlay[7]=########
)

set /a "viewport_x=0, viewport_y=0"
set /a "viewport_x=viewport_x * 3, HRES= HORIZONTAL_RES *3, viewport_y_0=viewport_y, viewport_y_1=viewport_y + VERTICAL_RES"


%sendCmd% go
for /L %%. in ( infinite ) do (
    %= CALCULATE FPS AND DISPLAY IN TITLE =%

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
    set "screen[3]=!screen[3]:~0,9!08!screen[3]:~-10!"
    %=TODO    generate below counter dynamically %
    for %%l in ( 0 1 2 3 4 5 6 ) do (
        for /F "tokens=1-16 delims=`" %%A in ("!screen[%%l]!") do (
            set "line[%%l]="
            for %%s in ( %HEX% ) do (
                set "line[%%l]=!line[%%l]!!LF! %lineset%"
            )
        )
    )


    if defined debug_overlay (
        for /f "tokens=1-4 delims=:.," %%a in ("!time: =0!") do (
            set /a "t2=(((1%%a*60)+1%%b)*60+1%%c)*100+1%%d-36610100, tDiff=t2-t1, tDiff+=((~(tDiff&(1<<31))>>31)+1)*8640000, fps=100/tDiff, t1=t2"
        )
        set "debug_overlay[2]=      !tDiff!"
        set "debug_overlay[2]=#!debug_overlay[2]:~-6!#"
        set "debug_overlay[4]=      !fps!"
        set "debug_overlay[4]=#!debug_overlay[4]:~-6!#"
        set "debug_overlay[6]=      !action_state!"
        set "debug_overlay[6]=#!debug_overlay[6]:~-6!#"
        %drawover% 14 14 8 8 debug_overlay
    )

    %cls%
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
            %sendcmd% quit
            exit
        )
        for %%a in ( %action_events% ) do (
            for %%b in ("!keybind[%%a]!") do (
                if "!key_list!" neq "!key_list:#%%~b#=!" set "action_%%a=1"
            )
        )
    )

    %= EXECUTE GAME LOGIC =%
    %=TODO    action resolver for cursor stuff in menus %
    %=TODO    move player only if not hit wall %
    if "!action_state!"=="map" (
        if defined action_up (
            set /a "viewport_y_0-=1, viewport_y_1-=1"
        )
        if defined action_down (
            set /a "viewport_y_0+=1, viewport_y_1+=1"
        )
        if defined action_left (
            set /a "viewport_x-=3"
        )
        if defined action_right (
            set /a "viewport_x+=3"
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

:setup_macros
:: TODO

for /F "tokens=1 delims==" %%v in ('set __') do set "%%v="
exit /B

:getSession
::if defined temp (set "tempFileBase=%temp%\") else if defined tmp set "tempFileBase=%tmp%\"
set "tempFileBase=%tempFileBase%Grub4E\%time::=-%\"
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

:DEBUG

exit /B


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
