::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Grub4E.bat
::
:: Written by Grub4K (Grub4K#2417) with some techniques from DosTips.
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
if "%~1"==":engine" goto :engine
if "%~1"==":logging" goto :logging
if "%~1"==":controller" goto :controller

setlocal disableDelayedExpansion
:getSession
set "tempFileBase=%~dp0"
:: REMOVE
::if defined temp (set "tempFileBase=%temp%\") else if defined tmp set "tempFileBase=%tmp%\"
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "currDatetime=%%a"
set "currDatetime=%currDatetime:.=%"
set "currDatetime=%currDatetime:~0,-8%"
set "tempFileBase=%tempFileBase%sessions\%currDatetime%\"
set "keyFile=%tempFileBase%key.txt"
set "cmdFile=%tempFileBase%cmd.txt"
set "logFile=%tempFileBase%log.txt"
set "gameLock=%tempFileBase%lock.txt"
set "signal=%tempFileBase%signal.txt"
set "keyStream=9"
set "cmdStream=8"
set "logStream=7"
set "lockStream=6"
if not exist "%tempFileBase%" md "%tempFileBase%"
:: Lock this game session and launch.
:: Loop back and try a new session if failure.
:: Cleanup and exit when finished
call :launch %lockStream%>"%gameLock%" || goto :getSession
rd /s /q "%tempFileBase%"
exit /b

:launch
:: launch the game and the controller
copy nul "%keyFile%" >nul
copy nul "%cmdFile%" >nul
copy nul "%logFile%" >nul
start "Logging Console" /MIN cmd /c ^""%~f0" :logging %logStream%^<"%logFile%" 2^>nul ^"
start "" /b cmd /c ^""%~f0" :controller %keyStream%^>^>"%keyFile%" %cmdStream%^<"%cmdFile%" 2^>nul ^>nul^"
cmd /c ^""%~f0" :engine 2^>NUL  %keyStream%^<"%keyFile%" %cmdStream%^>^>"%cmdFile%" %logStream%^>^>"%logFile%" ^<nul^"
<NUL set /P "=Press any button to quit..."
:close
2>nul (>>"%keyFile%" call ) || goto :close
exit /b 0

:engine
call :init
setlocal EnableDelayedExpansion
call :init_delayed

:: TODO have first loader
title [%eID%] Loading... [ Keybinds ]
call :load_keybinds  saves\keybinds.txt

title [%eID%] Loading... [ Fonts    ]
call :load_fontset  data\sprites\font.txt

title [%eID%] Loading... [ Sprites  ]
call :load_character  data\sprites\charas.txt
call :load_spriteset  data\sprites\spriteset.txt

title [%eID%] Loading... [ Map      ]
call :load_map data\maps\map.txt

set /a "viewport_x=1, viewport_y=1"
set /a "viewport_x=viewport_x * 3, hRes=sHeight * 3, viewport_y_0=viewport_y, viewport_y_1=viewport_y + sWidth"

title [%eID%] !gametitle!
if defined DEBUG (
    set "debug_overlay[#]=1"
    set "debug_overlay_list="
    %@addDebugData% tDiff
    %@addDebugData% action_state
    %@addDebugData% fadeOverTime
    %@addDebugData% x_pos
    %@addDebugData% viewport_y_0
    set "debug_overlay[0]=浜様様様様様様様様様融"
    set "keybind[debug]=#"
    set "action_events=!action_events! transition debug "
    set "debug_overlay=1"
    set "keybind[transition]=x"
)

set "charstate=1"
set "action_state=fade01"
set "action_state_next=map"

%@sendCmd% go
for /f "tokens=1-4 delims=:.," %%a in ("!time: =0!") do set /a "t1=(((1%%a*60)+1%%b)*60+1%%c)*100+1%%d-36610100"
for /L %%. in ( infinite ) do (
    %= CALCULATE TIME DIFFERENCE AND FPS =%
    for /f "tokens=1-4 delims=:.," %%a in ("!time: =0!") do (
        set /a "t2=(((1%%a*60)+1%%b)*60+1%%c)*100+1%%d-36610100, tDiff=t2-t1, tDiff+=((~(tDiff&(1<<31))>>31)+1)*8640000, fps=100/tDiff, t1=t2"
    )
    %= DRAW THE SCREEN =%
    set "count=0"
    for /L %%a in ( !viewport_y_0! 1 !viewport_y_1! ) do (
        for %%b in ("!viewport_x!") do set "screen[!count!]=!map[%%a]:~%%~b,%HRES%!"
        set /a "count+=1"
    )
    for %%a in ( %sHeightIter% ) do (
        set "line[%%a]="
        for /F "tokens=1-16 delims=`" %%A in ("!screen[%%a]!") do (
            for %%b in ( %ssPosIter% ) do (
                set "line[%%a]=!line[%%a]!!LF! !spriteset[%%A]:~%%b,16!!spriteset[%%B]:~%%b,16!!spriteset[%%C]:~%%b,16!!spriteset[%%D]:~%%b,16!!spriteset[%%E]:~%%b,16!!spriteset[%%F]:~%%b,16!!spriteset[%%G]:~%%b,16!"
            )
        )
        set "line[%%a]=!line[%%a]:~1!"
    )
    %@drawOverAlpha% 48 48 char_sprite[!charstate!]

    %= EXECUTE FADING COMMAND =%
    if "!action_state:~0,4!" equ "fade" (
        if !fadeOverTime! equ 0 set /a "fadeOverCount=0, fadeOverTime=0, fadeOff=3+5*!action_state:~4,1!, fadeMul=(!action_state:~5,1!*2-1), fadeAdd=fadeOff+((~!action_state:~5,1!+1)*3)"
        for /L %%a in ( 0 1 3 ) do (
            set /a "fadeStateFrom=fadeOff+%%a, fadeStateTo=fadeMul*fadeOverCount+fadeAdd+%%a"
            for /F "tokens=1,2 delims=`" %%b in ("!fadeStateFrom!`!fadeStateTo!") do (
                for /F "tokens=1,2 delims=`" %%d in ("!fadeLookup:~%%~b,1!`!fadeLookup:~%%~c,1!") do (
                    for %%l in ( %sHeightIter% ) do (
                        set "line[%%l]=!line[%%l]:%%~d=%%~e!"
                    )
                )
            )
        )
        set /a "fadeOverTime+=tDiff, fadeOverCount=fadeOverTime/10"
        if !fadeOverCount! geq 4 (
            set "fadeOverTime=0"
            set "action_state=!action_state_next!"
        )
    )

    %= DEBUG OVERLAY =%
    if "!debug_overlay!"== "1" (
        set "debug_count=2"
        for %%a in ( !debug_overlay_list! ) do (
            set "debug_temp=                    !%%a!"
            set "debug_overlay[!debug_count!]=�!debug_temp:~-20!�"
            set /a "debug_count+=2"
        )
        set "debug_overlay[!debug_overlay[#]!]=藩様様様様様様様様様夕"
        %@drawOver% 2 2 22 !debug_overlay[#]! debug_overlay
    )

    %= FLIP =%
    %@cls%
    echo(
    for %%l in ( %sHeightIter% ) do (
        echo(!line[%%l]:.= !
    )

    %= PROCESS INPUT =%
    set "key_list="
    for /L %%: in ( 1 1 %MAXSIMULTKEYS% ) do (
        set "inKey="
        <&%keyStream% set /p "inKey="
        if defined inKey set "key_list=!key_list!!inKey:~0,-1!"
    )
    %= Clear action events =%
    for %%a in ( %action_events% ) do set "action_%%a="
    %= translate keypresses into action events =%
    if defined key_list (
        set "key_list=!key_list!"
        %= emergency quit button =%
        if "!key_list!" neq "!key_list:.=!" (
            %@sendCmd% quit
            %@log% :END
            exit
        )
        if not defined halt_action_translation for %%a in ( %action_events% ) do (
            for %%b in ("!keybind[%%a]!") do (
                if "!key_list!" neq "!key_list:%%~b=!" set "action_%%a=1"
            )
        )
    )

    if defined DEBUG (
        if defined action_debug set /a "debug_overlay^=1"
    )

    %= MAP TRANSITIONS =%
    if "!action_state:~0,10!" equ "transition" (
        set "action_state_next=_transition:!action_state:*:=!"
        set "action_state=fade00"
        set "halt_action_translation=1"
    ) else if "!action_state!" equ "_transition_end" (
        set "halt_action_translation="
        set "action_state=map"
    ) else if "!action_state:~0,11!" equ "_transition" (
        for /F "tokens=1-3 delims=`" %%W in ("!action_state:*:=!") do (
            call :load_map "data\maps\%%W"
            if "%%X" neq "" set /a "viewport_x=%%X * 3, hRes=sWidth * 3, viewport_y_0=%%Y, viewport_y_1=%%Y + sHeight"
        )
        set "action_state=fade01"
        set "action_state_next=_transition_end"
    )
    %= EXECUTE GAME LOGIC =%
    if "!action_state!"=="map" (
        set "col_check="
        if defined action_up (
            if !charstate! equ 4 (
                set "col_check=!screen[2]:~9,2!"
                set "viewShift=viewport_y_0-=1, viewport_y_1-=1"
            ) else set "charstate=4"
        )
        if defined action_down (
            if !charstate! equ 1 (
                set "col_check=!screen[4]:~9,2!"
                set "viewShift=viewport_y_0+=1, viewport_y_1+=1"
            ) else set "charstate=1"
        )
        if defined action_left (
            if !charstate! equ 6 (
                set "col_check=!screen[3]:~6,2!"
                set "viewShift=viewport_x-=3"
            ) else set "charstate=6"
        )
        if defined action_right (
            if !charstate! equ 8 (
                set "col_check=!screen[3]:~12,2!"
                set "viewShift=viewport_x+=3"
            ) else set "charstate=8"
        )
        if defined col_check (
            %= hard collision =%
            set "move=1"
            for %%a in ( FF !colmap_hard! ) do (
                if "!col_check!" equ "%%a" set "move="
            )
            %= soft collision =%
            set /a "_viewport_x=viewport_x, _viewport_y_1=viewport_y_1, _viewport_y_0=viewport_y_0, !viewShift!, x_pos=viewport_x / 3, y_pos=viewport_y_0, viewport_x=_viewport_x, viewport_y_0=_viewport_y_0, viewport_y_1=_viewport_y_1"
            set "viewport_y="
            for /F "tokens=1,2 delims=#" %%x in ("!x_pos!#!y_pos!") do (
                if "!colmap_soft: %%x#%%y#=!" neq "!colmap_soft!" (
                    for /F "tokens=1,2 delims=# " %%a in ("!colmap_soft:* %%x#%%y#=!") do (
                        %= TODO special soft collision for arrow showing =%
                        if "%%a"=="special" (
                            set "args=%%b"
                            set "args=!args:*`=!"
                            for /F "tokens=1 delims=`" %%A in ("%%b") do set "func=%%A"
                            if "!func!"=="transition" (
                                set "action_state=transition:!args!"
                            )
                        ) else (
                            set "args=%%b"
                            call :%%a !args:`= !
                        )
                    )
                )
            )
            if defined move set /a "!viewShift!"
        ) else if defined action_confirm (
            if !charstate! equ 4 (
                set "viewShift=viewport_y_0-=1, viewport_y_1-=1"
            ) else if !charstate! equ 1 (
                set "viewShift=viewport_y_0+=1, viewport_y_1+=1"
            ) else if !charstate! equ 6 (
                set "viewShift=viewport_x-=3"
            ) else if !charstate! equ 8 (
                set "viewShift=viewport_x+=3"
            )
            set /a "_viewport_x=viewport_x, _viewport_y_1=viewport_y_1, _viewport_y_0=viewport_y_0, !viewShift!, x_pos=viewport_x / 3, y_pos=viewport_y_0, viewport_x=_viewport_x, viewport_y_0=_viewport_y_0, viewport_y_1=_viewport_y_1"
            set "viewport_y="
            for %%a in ( !interactions! ) do (
                for /F "tokens=1-4 delims=#" %%b in ("%%a") do (
                    if "%%b#%%c"=="!x_pos!#!y_pos!" (
                        if "%%d"=="special" (
                            set "args=%%e"
                            set "args=!args:*`=!"
                            for /F "tokens=1 delims=`" %%A in ("%%e") do set "func=%%A"
                            if "!func!"=="dialog" (
                                %@log% INFO Entered dialog: "!args!"
                            ) else if "!func!"=="save" (
                                call :save_save "saves\test.sav"
                            )
                        ) else (
                            set "args=%%e"
                            call :%%d !args:`= !
                        )
                    )
                )
            )
        ) else if defined action_menu (
            set "action_state=menu"
        )
    ) else if "!action_state!"=="menu" (
        if defined action_menu set "action_state=map"
        if defined action_cancel set "action_state=map"
    )
)

:: TODO convert to macro
:load_spriteset  <spritefile> <offset>
:: loads a tilefile into the tilebuffer
if not exist "%~f1" (
    %@log% ERROR Error opening file "%~1"
    exit /B 1
)
set "__map=0123456789ABCDEF"
 <"%~f1" (
    set /P "__end="
    set /a "__start=(%~2+0),__end+=__start"
    for /L %%a in ( !__start! 1 !__end! ) do (
        set /a "dec=%%a"
        set "hex="
        for %%_ in ( 1 2 ) do (
            set /a "d=dec&15,dec>>=4"
            for %%d in (!d!) do set "hex=!__map:~%%d,1!!hex!"
        )
        for %%b in ("!hex!") do (
            set "spriteset[%%~b]="
            for %%_ in ( %tHeightIter% ) do (
                set /P "__inLine="
                set "spriteset[%%~b]=!spriteset[%%~b]!!__inLine!"
            )
        )
    )
)
for /F "tokens=1 delims==" %%v in ('set __ 2^>NUL') do set "%%v="
%@log% INFO Loaded spriteset from "%~1"
exit /B 0

:load_character  <spritefile>
call :load_spriteset  "%~1" && (
    set /a "count=0"
    for %%a in ( 00 01 02 03 04 05 06 07 08 09 0A ) do (
        call :texconvert_alpha %%a char_sprite[!count!]
        set /a "count+=1"
    )
)
exit /B

:load_keybinds  <keybindsfile>
if not exist "%~1" (
    set "action_events= up down left right menu confirm cancel "
    set "keybind[up]=w"
    set "keybind[down]=s"
    set "keybind[left]=a"
    set "keybind[right]=d"
    set "keybind[confirm]=e"
    set "keybind[cancel]=q"
    set "keybind[menu]={Enter}"
    call :save_keybinds  "%~1"
    %@log% WARNING File "%~1" does not exist, created defaults
    exit /B
)
%@log% DEBUG Trying to load from "%~1"
set "action_events= "
for /F "usebackq tokens=1,2 delims==" %%V in ("%~1") do (
    set "keybind[%%V]=%%W"
    set "action_events=!action_events!%%V "
)
%@log% INFO Loaded keybinds from "%~1"
exit /B

:save_keybinds  <keybindsfile>
>"%~1" (
    for /F "tokens=1,2 delims==" %%V in ('set keybind[') do (
        set "key=%%V"
        set "value=%%W"
        echo !key:~8,-1!=!value!
    )
)
%@log% INFO Saved keybinds to "%~1"
exit /B

:save_save  <savelocation:str>
>"%~1" (
    echo map=!map!
    set viewport_
    echo charstate=!charstate!
    for /F "delims=" %%F in ('set _gamedata_') do (
        set "value=%%F"
        echo !value:~10!
    )
)
set "value="
%@log% INFO Saved state to "%~1"
exit /B

:load_save
for /F "usebackq delims=" %%F in ("%~1") do (
    set "value=%%F"
    set "value=!value:*=!"
    for /F "tokens=1 delims==" %%A in ("%%F") do set "key=%%A"
    if "!key:~0,8!"=="viewport"(
        set "key=!value!"
    ) else if "!key!"=="map" (
        call :load_map  "!value!"
    ) else set "_gamedata_%%F"
)
set "key="
set "value="
%@log% INFO Loaded save from "%~1"
exit /B

:load_fontset  <fontset>
if not exist "%~f1" (
    %@log% ERROR Error opening file "%~1"
    exit /B
)
<"%~1" (
    set /p "__fontmap="
    %@strLen% __fontmap __fontcount
    set /a "__fontcount-=2"
    for /L %%a in ( 0 2 !__fontcount! ) do (
        set /a "__start=0x!__fontmap:~%%a,2! * fontwidth, __stop=__start+fontwidth"
        for /F "tokens=1,2 delims=`" %%b in ("!__start!`!__stop!") do (
            for /L %%d in ( 0 1 !fontheight! ) do (
                set /p "__current="
                set "fontset[%%d]=!fontset[%%d]:~0,%%b!!__current!!fontset[%%d]:~%%~c!"
            )
        )
    )
)
for /F "tokens=1 delims==" %%v in ('set __ 2^>NUL') do set "%%v="
%@log% INFO Loaded fontset from "%~1"
exit /B

:load_map  <mapfile>
if not exist "%~f1" (
    %@log% ERROR Error opening file "%~1"
    exit /B
)
<"%~f1" (
    set /p "colmap_hard="
    set "colmap_hard= !colmap_hard! "
    set /p "colmap_soft="
    set "colmap_soft= !colmap_soft! "
    set /p "interactions="
    set /p "__mapsize="
    set "__frame=FF`FF`FF"
    for /f "tokens=1,2 delims= " %%a in ("!__mapsize!") do (
        set "__mapsize_x=%%a"
        set "__mapsize_y=%%b"
    )
    set /a "__mapsize_x=__mapsize_x*2-2, __mapsize_y+=2"
    for /L %%a in ( 3 1 !__mapsize_y! ) do (
        set /p "__line="
        set "map[%%a]=!__frame!`"
        for /L %%b in ( 0 2 !__mapsize_x! ) do (
            set "map[%%a]=!map[%%a]!!__line:~%%b,2!`"
        )
        set "map[%%a]=!map[%%a]!!__frame!"
    )
)
set /a "__mapsize_y+=1, __count1=__mapsize_y+1, __count2=__mapsize_y+2"
set "__line=!__frame!`"
for /L %%_ in ( 0 2 !__mapsize_x! ) do set "__line=!__line!FF`"
set "__line=!__line!!__frame!"
for %%a in ( 0 1 2 !__mapsize_y! !__count1! !__count2! ) do set "map[%%a]=!__line!"
set "map=%~1"
for /F "tokens=1 delims==" %%v in ('set __ 2^>NUL') do set "%%v="
%@log% INFO Loaded map from "%~1"
exit /B

:texconvert_alpha  <spritePtr> <outputArray>
set "%~2="
for %%a in ( %tHeightIter% ) do (
    set /a "__mode=0"
    for %%b in ( %tWidthIter% ) do (
        set /a "__pos=%%a * 16 + %%b"
        for %%c in ("!__pos!") do (
            set "__current=!spriteset[%~1]:~%%~c,1!"
            if "!__current!" neq "." (
                if !__mode! equ 0 (
                    set "outlen=1"
                    set "outline=%%b`%%a`!__current!"
                    set "__mode=1"
                ) else (
                    set "outline=!outline!!__current!"
                    set /a "outlen+=1"
                )
            ) else (
                if !__mode! equ 1 (
                    set "%~2=!%~2!!outline!`!outlen!,"
                    set "__mode=0"
                )
            )
        )
    )
    if !__mode! equ 1 set "%~2=!%~2!!outline!`!outlen!,"
)
if defined %~2 (
    set "%~2=!%~2:~0,-1!"
    set "%~2=!%~2: =.!"
)
for /F "tokens=1 delims==" %%v in ('set __ 2^>NUL') do set "%%v="
%@log% INFO Alpha-converted sprite 0x%~1 to %~2
exit /B

:init
color F0
:: default values
for %%a in (
    "gameTitle=Game"
    "maxSimultKeys=10"
    "fontHeight=5"
    "fontWidth=3"
    "tWidth=16"
    "tHeight=16"
    "sWidth=7"
    "sHeight=7"
) do (
    for /F "tokens=1,2 delims==" %%b in ("%%~a") do (
        if not defined %%b set "%%b=%%c"
    )
)

set /a "dWidth=tWidth*sWidth+2, dHeight=tHeight*sHeight+2"
mode %dWidth%,%dHeight%

:: @log  loglevel message
:: @log  :END
:: @log  :setlevel level
:::  sends commands to the logging module
set "@log=>&%logStream% echo"

set "eID=Grub4E"
if defined DEBUG (
    %@log% :setlevel DEBUG
    set "eID=%eID%:DEBUG"
)

set "spriteset[FF]=                                                                                                                                                                                                                                                                "

set /a "fontheight-=1"

set "fadeOverTime=0"
set "fadeOverCount=0"
set "fadeLookup=    葦栩霸� "

set #charMap=#  20#!!21#^"^"22###23#$$24#%%%%25#^&^&26#''27#^(^(28#^)^)29#**2A#++2B#,,2C#--2D#..2E#//2F#0030#1131#2232#3333#4434#5535#6636#7737#8838#9939#::3A#;;3B#^<^<3C#==3D#^>^>3E#??3F#@@40#AA41#BB42#CC43#DD44#EE45#FF46#GG47#HH48#II49#JJ4A#KK4B#LL4C#MM4D#NN4E#OO4F#PP50#QQ51#RR52#SS53#TT54#UU55#VV56#WW57#XX58#YY59#ZZ5A#[[5B#\\5C#]]5D#^^^^5E#__5F#``60#aa61#bb62#cc63#dd64#ee65#ff66#gg67#hh68#ii69#jj6A#kk6B#ll6C#mm6D#nn6E#oo6F#pp70#qq71#rr72#ss73#tt74#uu75#vv76#ww77#xx78#yy79#zz7A#{{7B#^|^|7C#}}7D#~~7E

set "gameLoc=%~dp0"
:: REMOVE
::if defined appdata set "gameLoc=%AppData%\%gameTitle%\"
set "saveLoc=%gameLoc%saves\"
if not exist "%saveLoc%" md "%saveLoc%"

:: This is a strange way to get seed, but probably good enough for now
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "random_x32=%%a"
set "random_x32=%random_x32:.=%"
set /a "random_x32=0x%random_x32:~-12,-4%"

:: Define ESC as the escape character
for /f "delims=" %%E in ('forfiles /p "%~dp0." /m "%~nx0" /c "cmd /c echo(0x1B"') do (
    set "ESC=%%E"
    <NUL set /p "=%%E[?25l"
)

:: define LF as a Line Feed (newline) character
set ^"LF=^
%= These lines are required =%
^" do not remove

:: Define line continuation
set ^"\n=^^^%LF%%LF%^%LF%%LF%^^"

set "halt_action_translation="

:: @transition transition number
set @transition=for %%# in (1 2) do if %%#==2 (set "action_state=transition:!args!") else set /a args=

:: simple Xorshift
set @randomMoveNext=set /a "random_x32^=random_x32 << 13, random_x32^=random_x32 >> 17, random_x32^=random_x32 << 5"

:: @randomRange  [min] [max]
set @randomRange=for %%# in (1 2) do if %%#==2 (%\n%
for /f "tokens=1,2 delims=, " %%1 in ("!argv!") do ( %\n%
    if "%%2" equ "" ( %\n%
        set /a "rand=((random_x32>>32&1)*-2+1)*random_x32 + %%1 + 0" %\n%
    ) else set /a "rand=((random_x32>>32&1)*-2+1)*random_x32 %% (%%2 - min + 1) + %%1 + 0" %\n%
    %@randomMoveNext% %\n%
)) else set argv=,

::@strLen  <strVar> [RtnVar]
set @strLen=for %%# in (1 2) do if %%#==2 (%\n%
  for /f "tokens=1,2 delims=, " %%1 in ("!argv!") do (%\n%
    set "s=A!%%~1!"%\n%
    set "len=0"%\n%
    for %%P in (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) do (%\n%
      if "!s:~%%P,1!" neq "" (%\n%
        set /a "len+=%%P"%\n%
        set "s=!s:~%%P!"%\n%
      )%\n%
    )%\n%
    for %%V in (!len!) do set "%%~2=%%V" %\n%
  )%\n%
) else set argv=,

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
for /L %%e in ( 0 1 !len! ) do for %%a in ("!%%~1:~%%~e,1!") do ( %\n%
    set "__current=!#charMap:*#%%~a=!" %\n%
    if "!__current:~0,1!" neq "%%~a" set "__current=!__current:*#%%~a=!" %\n%
    set /a "__current=0x!__current:~1,2!*3" %\n%
    for %%c in ("!__current!") do for /L %%d in ( 0 1 !fontheight! ) do set "%%~2[%%d]=!%%~2[%%d]!!fontset[%%d]:~%%~c,3! " %\n%
) %\n%
for /L %%a in ( 0 1 !fontheight! ) do set "%%~2[%%a]=!%%~2[%%a]:~0,-1!" %\n%
)) else set argv=,

::@drawOver  <x> <y> <xlen> <ylen> <data>
::: draw data over a specified portion of the screen.
::: x and y start at 1
set @drawOver=for %%# in (1 2) do if %%#==2 ( %\n%
for /F "tokens=1-5 delims=, " %%1 in ("!args!") do ( %\n%
    for /L %%a in ( 0 1 %%~4 ) do ( %\n%
        set /a "y=%%2+%%a,linenum=y/16,linestart=(y%% 16)*(16*%sWidth%+2)+%%1,lineend=linestart+%%3" %\n%
        for /f "tokens=1-3" %%b in ("!linenum! !linestart! !lineend!") do ( %\n%
            set "line[%%b]=!line[%%~b]:~0,%%~c!!%%~5[%%a]:~0,%%3!!line[%%~b]:~%%~d!" %\n%
        ) %\n%
    ) %\n%
)) else set args=,

::@drawOverAlpha  <x> <y> <data>
::: draw data over a specified portion of the screen.
::: Input has to be a texture prepared using :texconvert_alpha
::: x and y start at 1
set @drawOverAlpha=for %%# in (1 2) do if %%#==2 ( %\n%
for /F "tokens=1-3 delims=, " %%1 in ("!args!") do ( %\n%
    for %%a in ( !%%~3! ) do ( %\n%
        for /F "tokens=1-4 delims=`" %%4 in ("%%a") do (%\n%
            set /a "y=%%2+%%5,linenum=y/16,linestart=(y%% 16)*(16*%sWidth%+2)+%%1+%%4+1,lineend=linestart+%%7" %\n%
            for /f "tokens=1-3" %%b in ("!linenum! !linestart! !lineend!") do ( %\n%
                set "line[%%b]=!line[%%~b]:~0,%%~c!%%6!line[%%~b]:~%%~d!" %\n%
            ) %\n%
        ) %\n%
    ) %\n%
)) else set args=,

:: @addDebugData  <dataVar>
::: adds a entry to the debug overlay for display
set @addDebugData=for %%# in (1 2) do if %%#==2 ( %\n%
for /F "tokens=1 delims=, " %%1 in ("!args!") do ( %\n%
    set "debug_temp= %%1                   "%\n%
    set "debug_overlay[!debug_overlay[#]!]=�!debug_temp:~0,20!�"%\n%
    set /a "debug_overlay[#]+=2"%\n%
    set "debug_overlay_list=!debug_overlay_list! %%1"%\n%
)) else set args=,

:: clear screen by setting cursor to 0:0
:: Can be switched out for `cls` on older systems
set "@cls=<NUL set /P =%ESC%[H"

:: @sendCmd  command
:::  sends a command to the controller
set "@sendCmd=>&%cmdStream% echo"

for /F "tokens=1 delims==" %%v in ('set __ 2^>NUL') do set "%%v="
%@log% INFO Finished normal setup
exit /B

:init_delayed
set /a "tHeight-=1, tWidth-=1, sHeight-=1, sWidth-=1, tHeightIter=tWidthIter=0, sHeightIter=sWidthIter=0"
for /L %%a in ( 1 1 %tHeight% ) do set "tHeightIter=!tHeightIter! %%a"
for /L %%a in ( 1 1 %tWidth% ) do set "tWidthIter=!tWidthIter! %%a"
for /L %%a in ( 1 1 %sHeight% ) do set "sHeightIter=!sHeightIter! %%a"
for /L %%a in ( 1 1 %sWidth% ) do set "sWidthIter=!sWidthIter! %%a"
set /a "tHeight+=1, tWidth+=1, sHeight+=1, sWidth+=1"

set /a "ssPosIter=accum=0"
for /L %%a in ( 2 1 %tHeight% ) do (
    set /a "accum+=tWidth"
    set "ssPosIter=!ssPosIter! !accum!"
)
%@log% DEBUG ssPosIter: !ssPosIter!
set "accum="

set "count=0"
set "lineset="
for %%a in ( A B C D E F G H I J K L M N O P Q R S T U V W X Y Z ) do (
    set /a "count+=1"
    if !count! leq %sWidth% set "lineset=!lineset!^!spriteset[%%%%a]_%%s^!"
)

set "empty="
set "fontset[0]="
for /L %%_ in ( 1 1 !fontwidth! ) do set "empty=!empty! "
for /L %%_ in ( 1 1 126 ) do set "fontset[0]=!fontset[0]!!empty!"
for /L %%a in ( 0 1 !fontheight! ) do set "fontset[%%a]=!fontset[0]!"
set "empty="

for /F "tokens=1 delims==" %%v in ('set __ 2^>NUL') do set "%%v="
%@log% INFO Finished delayed setup
exit /B

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:logging
:: Reads logging input and pretty prints these.
:: This routine respects the current loglevel and exists purely to not
:: slow down the tight main routine.
:: Accepted input is either ":END" ":setlevel <level>" or "<level> <message>"
setlocal DisableDelayedExpansion
:: define LF as a Line Feed (newline) character
set ^"LF=^
%= These lines are required =%
^" do not remove
:: Define line continuation
set ^"\n=^^^%LF%%LF%^%LF%%LF%^^"
:: Default loglevels
set "loglevels= ERROR WARNING "
:: TODO transition to use of %time% and %date%
set @perform_log=(%\n%
for /F "tokens=1 delims= " %%a in ("!message!") do (%\n%
    if "!loglevels:%%a=!" neq "!loglevels!" (%\n%
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
                %@perform_log%
                exit
            ) else if "!message:~1,8!"=="setlevel" (
                set "message=!message:* =!"
                set "loglevels="
                set "found="
                for %%a in (
                    "SILENT"
                    "ERROR"
                    "WARNING"
                    "INFO"
                    "DEBUG"
                ) do (
                    if not defined found set "loglevels=!loglevels!%%~a "
                    if "%%~a"=="!message:* =!" set "found=1"
                )
                set "loglevels= !loglevels:* =!"
                set "message=INFO Switched loglevel to !message:* =!"
                %@perform_log%
            )
        ) else %@perform_log%
    )
)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:controller
:: Detects keypresses and sends the information to the game via a key file.
:: Both <CR> and the Enter key are reported as {Enter}.
:: The Tab char gets reported as {Tab}.
:: An `.` is appended to preserve control chars when read by SET /P.
setlocal enableDelayedExpansion
for /f %%a in ('copy /Z "%~dpf0" nul') do set "CR=%%a"
((for /L %%P in (1,1,70) do pause>nul)&set /p "TAB=")<"!COMSPEC!"
set "TAB=!TAB:~0,1!"
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
        if !key! equ !CR! set "key={Enter}"
        if !key! equ !TAB! set "key={Tab}"
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
