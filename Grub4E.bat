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
cls
if "%~1" == "startGame" goto :game
if "%~1" == "startController" goto :controller
setlocal disableDelayedExpansion
set "DEBUG="
if /i "%~1" == "-DEBUG" set "DEBUG=1"
color F0
mode 114,114
:getSession
::if defined temp (set "tempFileBase=%temp%\") else if defined tmp set "tempFileBase=%tmp%\"
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "tempFileBase=%%a"
set "tempFileBase=%tempFileBase:.=%"
set "tempFileBase=%tempFileBase:~0,-7%"
set "tempFileBase=%~dp0sessions\%tempFileBase%\"
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

:launch
:: launch the game and the controller
copy nul "%keyFile%" >nul
copy nul "%cmdFile%" >nul
copy nul "%gameLog%" >nul
start "" /b cmd /c ^""%~f0" startController %keyStream%^>^>"%keyFile%" %cmdStream%^<"%cmdFile%" 2^>nul ^>nul^"
cmd /c ^""%~f0" startGame  2^>NUL  %keyStream%^<"%keyFile%" %cmdStream%^>^>"%cmdFile%" ^<nul^"
<NUL set /P "=Press any button to quit..."
:close
2>nul (>>"%keyFile%" call ) || goto :close
exit /b 0

:game
for /F "usebackq delims=" %%a in ("data\game.txt") do set "%%a"

call :setup
setlocal EnableDelayedExpansion
call :setupDelayed

:: DONE SETTING UP ENGINE

title [%eID%] Loading... [ Keybinds ]
call :load_keybinds  save\keybinds.txt

title [%eID%] Loading... [ Fonts    ]
call :load_fontset  data\font.txt

title [%eID%] Loading... [ Sprites  ]



call :load_spriteset  data\charas.txt
set /a "count=0"
for %%a in ( 00 01 02 03 04 05 06 07 08 09 0A ) do (
    call :texconvert_alpha %%a char_sprite[!count!]
    set /a "count+=1"
)

call :load_spriteset  data\spriteset.txt

title [%eID%] Loading... [ Map      ]
call :load_map data\map.txt

set /a "viewport_x=1, viewport_y=1"
set /a "viewport_x=viewport_x * 3, hRes=sHeight * 3, viewport_y_0=viewport_y, viewport_y_1=viewport_y + sWidth"

title [%eID%] !gametitle!
if defined DEBUG (
    set "templine=DEBUG"
    %@renderFont% templine debug_line
    set "templine="
    set "debug_overlay[#]=1"
    set "debug_overlay_list="
    %@addDebugData% tDiff
    %@addDebugData% action_state
    %@addDebugData% fadeOverTime
    set "debug_overlay[0]=ษออออออออออออออออออออป"
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
        for %%b in ("!viewport_x!") do for %%c in ("!HRES!") do set "screen[!count!]=!map[%%a]:~%%~b,%%~c!"
        set /a "count+=1"
    )
    :: TODO fix this to be dynamic
    for %%a in ( %sHeightIter% ) do (
        set "line[%%a]="
        for /F "tokens=1-16 delims=`" %%A in ("!screen[%%a]!") do (
            for %%b in ( 0 16 32 48 64 80 96 112 128 144 160 176 192 208 224 240 ) do (
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
                    for %%l in ( 0 1 2 3 4 5 6 ) do (
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
            set "debug_overlay[!debug_count!]=บ!debug_temp:~-20!บ"
            set /a "debug_count+=2"
        )
        set "debug_overlay[!debug_overlay[#]!]=ศออออออออออออออออออออผ"
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
        if "!key_list!" neq "!key_list:+=!" (
            %@sendCmd% quit
            exit
        )
        for %%a in ( %action_events% ) do (
            for %%b in ("!keybind[%%a]!") do (
                if "!key_list!" neq "!key_list:%%~b=!" set "action_%%a=1"
            )
        )
    )

    if defined DEBUG (
        if defined action_debug set /a "debug_overlay^=1"
        if defined action_transition (
            set "action_state=fade00"
            set "action_state_next=debug_t"
        )
        if "!action_state!" equ "debug_t" (
            set "action_state=fade01"
            set "action_state_next=map"
            call :load_map data\map2.txt
            set /a "viewport_x=4, viewport_y=0"
            set /a "viewport_x=viewport_x * 3, HRES= sWidth *3, viewport_y_0=viewport_y, viewport_y_1=viewport_y + sHeight"
        )
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
            set "move=1"
            for %%a in ( FF !colmap_hard! ) do (
                if "!col_check!" equ "%%a" set "move="
            )
            if defined move set /a "!viewShift!"
        )
        if defined action_menu set "action_state=menu"
    ) else if "!action_state!"=="menu" (
        if defined action_menu set "action_state=map"
        if defined action_cancel set "action_state=map"
    )
)

:: TODO convert to macro
:load_spriteset  <spritefile> <offset>
:: loads a tilefile into the tilebuffer
if not exist "%~f1" (
    %@log% Error opening file "%~1"
    exit /B
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
            %@log% Created: spriteset[%%~b]: !spriteset[%%~b]!
        )
    )
)
for /F "tokens=1 delims==" %%v in ('set __') do set "%%v="
%@log% Loaded spriteset from "%~1"
exit /B

:load_keybinds  <keybindsfile>
set "action_events= up down left right menu confirm cancel "
set "keybind[up]=w"
set "keybind[down]=s"
set "keybind[left]=a"
set "keybind[right]=d"
set "keybind[confirm]=e"
set "keybind[cancel]=q"
set "keybind[menu]={Enter}"
%@log% Loaded keybinds from "%~1":dummy
exit /B

:load_fontset  <fontset>
if not exist "%~f1" (
    %@log% Error opening file "%~1"
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
for /F "tokens=1 delims==" %%v in ('set __') do set "%%v="
%@log% Loaded fontset from "%~1"
exit /B

:load_map  <mapfile>
if not exist "%~f1" (
    %@log% Error opening file "%~1"
    exit /B
)
<"%~f1" (
    set /p "colmap_hard="
    set "colmap_hard= !colmap_hard! "
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
for /L %%. in ( 0 2 !__mapsize_x! ) do set "__line=!__line!FF`"
set "__line=!__line!!__frame!"
for %%a in ( 0 1 2 !__mapsize_y! !__count1! !__count2! ) do set "map[%%a]=!__line!"
for /F "tokens=1 delims==" %%v in ('set __') do set "%%v="
%@log% Loaded map from "%~1"
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
for /F "tokens=1 delims==" %%v in ('set __') do set "%%v="
%@log% Converted 0x%~1 to %~2: !%~2!
exit /B

:setup
set "eID=Grub4E"
if defined DEBUG set "eID=%eID%:DEBUG"

set "spriteset[FF]=                                                                                                                                                                                                                                                                "

set /a "fontheight-=1"

set "fadeOverTime=0"
set "fadeOverCount=0"
set "fadeLookup=    ฐฑÛÛÛฑฐ "

set #charMap=#  20#!!21#^"^"22###23#$$24#%%%%25#^&^&26#''27#^(^(28#^)^)29#**2A#++2B#,,2C#--2D#..2E#//2F#0030#1131#2232#3333#4434#5535#6636#7737#8838#9939#::3A#;;3B#^<^<3C#==3D#^>^>3E#??3F#@@40#AA41#BB42#CC43#DD44#EE45#FF46#GG47#HH48#II49#JJ4A#KK4B#LL4C#MM4D#NN4E#OO4F#PP50#QQ51#RR52#SS53#TT54#UU55#VV56#WW57#XX58#YY59#ZZ5A#[[5B#\\5C#]]5D#^^^^5E#__5F#``60#aa61#bb62#cc63#dd64#ee65#ff66#gg67#hh68#ii69#jj6A#kk6B#ll6C#mm6D#nn6E#oo6F#pp70#qq71#rr72#ss73#tt74#uu75#vv76#ww77#xx78#yy79#zz7A#{{7B#^|^|7C#}}7D#~~7E

set @log=^>^>"%gameLog%" echo !time::=-!:

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

:: TODO: adjust this
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
    set "debug_overlay[!debug_overlay[#]!]=บ!debug_temp:~0,20!บ"%\n%
    set /a "debug_overlay[#]+=2"%\n%
    set "debug_overlay_list=!debug_overlay_list! %%1"%\n%
)) else set args=,

:: clear screen by setting cursor to 0:0
:: Can be switched out for `cls`
set "@cls=<NUL set /P =%ESC%[H"

:: @sendCmd  command
:::  sends a command to the controller
set "@sendCmd=>&%cmdStream% echo"


for /F "tokens=1 delims==" %%v in ('set __') do set "%%v="
%@log% Finished normal setup
exit /B

:: SETUP PART, DELAYED EXPANDED

:setupDelayed
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

for /F "tokens=1 delims==" %%v in ('set __') do set "%%v="
%@log% Finished delayed setup
exit /B

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:controller
:: Detects keypresses and sends the information to the game via a key file.
:: This routine incorrectly reports `!` as something else. Both <CR> and the
:: Enter key are reported as {Enter}. An extra character is appended to the
:: output to preserve any control chars when read by SET /P.
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
