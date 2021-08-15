::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Grub4E
::
:: Written by Grub4K (Grub4K#2417) with some techniques from DosTips
:: and many ideas from the folks at server.bat (discord.gg/GSVrHag)
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
::set "tempFileBase="
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
call :initDelayed

:: TODO have first loader
%@setTitle% Loading... [ Keybinds ]
call :loadKeybinds  saves\keybinds.txt

%@setTitle% Loading... [ Fonts    ]
call :loadFontset  data\sprites\font.txt

%@setTitle% Loading... [ Sprites  ]
call :loadCharacter  data\sprites\charas.txt
call :loadSpriteset  data\sprites\spriteset.txt

%@setTitle% Loading... [ Map      ]
call :loadMap data\maps\map.txt

set /a "viewportX=2, viewportY=2"
set /a "viewportX=(viewportX - 1) * 3, hRes=(sWidth+2) * 3, viewportY0=viewportY - 1, viewportY1=viewportY0 + sHeight + 2"

%@setTitle% !gameTitle!
if defined DEBUG (
    set "debugOverlay[#]=1"
    set "debugOverlayList="
    %@addDebugData% tDiff
    %@addDebugData% fps
    %@addDebugData% actionState
    %@addDebugData% shiftX
    %@addDebugData% shiftY
    %@addDebugData% viewportX
    %@addDebugData% viewportY0
    set "debugOverlay[0]=ษออออออออออออออออออออป"
    set "keybind[debug]=#"
    set "actionEvents=!actionEvents! transition debug "
    set "debugOverlay=1"
    set "keybind[transition]=x"
)

set "charstate=1"
set "actionState=fade01"
set "actionStateNext=map"

%@sendCmd% go
for /f "tokens=1-4 delims=:.," %%a in ("!time: =0!") do set /a "t1=(((1%%a*60)+1%%b)*60+1%%c)*100+1%%d-36610100"
for /L %%. in ( infinite ) do (
    %= CALCULATE TIME DIFFERENCE AND FPS =%
    for /f "tokens=1-4 delims=:.," %%a in ("!time: =0!") do (
        set /a "t2=(((1%%a*60)+1%%b)*60+1%%c)*100+1%%d-36610100, tDiff=t2-t1, tDiff+=((~(tDiff&(1<<31))>>31)+1)*8640000, fps=100/tDiff, t1=t2"
    )
    %= DRAW THE SCREEN =%
    set "count=-1"
    for %%b in ("!viewportX!") do (
        for /L %%a in ( !viewportY0! 1 !viewportY1! ) do (
            set "screen[!count!]=!map[%%a]:~%%~b,%hRes%!"
            set /a "count+=1"
        )
    )
    for %%a in ( -1 %sHeightIter% %sHeight% ) do (
        set "line[%%a]="
        for /F "tokens=1-26 delims=`" %%A in ("!screen[%%a]!") do (
            for %%b in ( %ssPosIter% ) do (
                set "line[%%a]=!line[%%a]!%#lineGenerator%"
            )
        )
    )
    %=TODO implement dynamic sprite drawing =%

    %= SCROLLING VIEWPORT SHIFT =%
    if not "!shiftX!"=="0" for %%x in ("!shiftX!") do (
        for %%a in ( -1 %sHeightIter%) do (
            set "line[%%a]=!line[%%a]:~%%~x!!line[%%a]:~0,%%~x!"
        )
    )
    %= WARNING - shiftY gives undefined behavior for negative values =%
    if not "!shiftY!"=="0" (
        set /a "__count=shiftY * ((%sWidth%+2)*%tWidth%)"
        for %%y in ("!__count!") do (
            set "__tempLine=!line[-1]:~%%~y!"
            for %%a in (-1 %sHeightIter% %sHeight%) do (
                set "__tempLine2=!line[%%a]:~-%%~y!"
                set "line[%%a]=!__tempLine!!line[%%a]:~0,-%%~y!"
                set "__tempLine=!__tempLine2!"
            )
        )
    )
    %@drawOverAlpha% 48 48 charSprite[!charstate!]

    %= EXECUTE FADING COMMAND =%
    if "!actionState:~0,4!" equ "fade" (
        if !fadeOverTime! equ 0 set /a "fadeOverCount=0, fadeOverTime=0, fadeOff=3+5*!actionState:~4,1!, fadeMul=(!actionState:~5,1!*2-1), fadeAdd=fadeOff+((~!actionState:~5,1!+1)*3)"
        for /L %%a in ( 0 1 3 ) do (
            set /a "fadeStateFrom=fadeOff+%%a, fadeStateTo=fadeMul*fadeOverCount+fadeAdd+%%a"
            for /F "tokens=1,2 delims=`" %%b in ("!fadeStateFrom!`!fadeStateTo!") do (
                for /F "tokens=1,2 delims=`" %%d in ("!fadeLookup:~%%~b,1!`!fadeLookup:~%%~c,1!") do (
                    for %%l in ( -1 %sHeightIter% %sHeight% ) do (
                        set "line[%%l]=!line[%%l]:%%~d=%%~e!"
                    )
                )
            )
        )
        set /a "fadeOverTime+=tDiff, fadeOverCount=fadeOverTime/10"
        if !fadeOverCount! geq 4 (
            set "fadeOverTime=0"
            set "actionState=!actionStateNext!"
        )
    )

    %= DEBUG OVERLAY =%
    if "!debugOverlay!"== "1" (
        set "debugCount=2"
        for %%a in ( !debugOverlayList! ) do (
            set "__debugTemp=                    !%%a!"
            set "debugOverlay[!debugCount!]=บ!__debugTemp:~-20!บ"
            set /a "debugCount+=2"
        )
        set "debugOverlay[!debugOverlay[#]!]=ศออออออออออออออออออออผ"
        %@drawOver% 2 2 22 !debugOverlay[#]! debugOverlay
        set "__debugTemp="
    )

    %= FLIP =%
    %@cls%
    for %%l in ( %sHeightIter% ) do (
        echo(%#clipLine%
    )

    %= PROCESS INPUT =%
    set "keyList="
    for /L %%: in ( 1 1 %MAXSIMULTKEYS% ) do (
        set "inKey="
        <&%keyStream% set /p "inKey="
        if defined inKey set "keyList=!keyList!!inKey:~0,-1!"
    )
    %= Clear action events =%
    %= TODO  rework action variable to be array not list =%
    for %%a in ( %actionEvents% ) do set "action[%%a]="
    %= translate keypresses into action events =%
    if defined keyList (
        %= emergency quit button =%
        if "!keyList!" neq "!keyList:.=!" (
            %@sendCmd% quit
            %@log% :END
            exit
        )
        %= TEMP small scroll =%
        if "!keyList!" neq "!keyList:j=!" set /a "shiftX-=1"
        if "!keyList!" neq "!keyList:l=!" set /a "shiftX+=1"
        if "!keyList!" neq "!keyList:k=!" set /a "shiftY-=1"
        if "!keyList!" neq "!keyList:i=!" set /a "shiftY+=1"
        if not defined haltActionTranslation for %%a in ( %actionEvents% ) do (
            for %%b in ("!keybind[%%a]!") do (
                if "!keyList!" neq "!keyList:%%~b=!" set "action[%%a]=1"
            )
        )
    )

    if defined DEBUG (
        if defined action[debug] set /a "debugOverlay^=1"
    )

    %= MAP TRANSITIONS =%
    %= TODO  use event system and queue to do this =%
    if "!actionState:~0,10!" equ "transition" (
        set "actionStateNext=_transition:!actionState:*:=!"
        set "actionState=fade00"
        set "haltActionTranslation=1"
    ) else if "!actionState!" equ "_transitionEnd" (
        set "haltActionTranslation="
        set "actionState=map"
    ) else if "!actionState:~0,11!" equ "_transition" (
        for /F "tokens=1-3 delims=`" %%W in ("!actionState:*:=!") do (
            call :loadMap "data\maps\%%W"
            if "%%X" neq "" set /a "viewportX=%%X * 3, hRes=sWidth * 3, viewportY0=%%Y, viewportY1=%%Y + sHeight"
        )
        set "actionState=fade01"
        set "actionStateNext=_transitionEnd"
    )
    if "!actionState:~0,2!" equ "sd" (
        for /F "tokens=1*" %%a in ("!actionState:~3!") do (
            set "actionState=%%a"
            set "actionStateNext=%%b"
        )
    )
    %= TODO fix issues here =%
    %= EXECUTE GAME LOGIC =%
    if "!actionState!"=="map" (
        set "colCheck="
        if defined action[up] (
            if !charstate! equ 4 (
                set "colCheck=!screen[2]:~12,2!"
                set "viewShift=viewportY0-=1, viewportY1-=1"
            ) else set "charstate=4"
        )
        if defined action[down] (
            if !charstate! equ 1 (
                set "colCheck=!screen[4]:~12,2!"
                set "viewShift=viewportY0+=1, viewportY1+=1"
            ) else set "charstate=1"
        )
        if defined action[left] (
            if !charstate! equ 6 (
                set "colCheck=!screen[3]:~9,2!"
                set "viewShift=viewportX-=3"
            ) else set "charstate=6"
        )
        if defined action[right] (
            if !charstate! equ 8 (
                set "colCheck=!screen[3]:~15,2!"
                set "viewShift=viewportX+=3"
            ) else set "charstate=8"
        )
        if defined colCheck (
            %= hard collision =%
            set "move=1"
            for %%a in ( FF !colmapHard! ) do (
                if "!colCheck!" equ "%%a" set "move="
            )
            %= soft collision =%
            set /a "_viewportX=viewportX, _viewportY1=viewportY1, _viewportY0=viewportY0, !viewShift!, xPos=viewportX / 3 + 1, yPos=viewportY0+1, viewportX=_viewportX, viewportY0=_viewportY0, viewportY1=_viewportY1"
            set "viewportY="
            for /F "tokens=1,2 delims=`" %%x in ("!xPos!`!yPos!") do (
                if "!colmapSoft: %%x#%%y#=!" neq "!colmapSoft!" (
                    for /F "tokens=1,2 delims=# " %%a in ("!colmapSoft:* %%x#%%y#=!") do (
                        %= TODO special soft collision for arrow showing =%
                        if "%%a"=="special" (
                            set "args=%%b"
                            set "args=!args:*`=!"
                            for /F "tokens=1 delims=`" %%A in ("%%b") do set "func=%%A"
                            if "!func!"=="transition" (
                                set "actionState=transition:!args!"
                            )
                        ) else (
                            set "args=%%b"
                            call :%%a !args:`= !
                        )
                    )
                )
            )
            if defined move set /a "!viewShift!"
        ) else if defined action[confirm] (
            if !charstate! equ 4 (
                set "viewShift=viewportY0-=1, viewportY1-=1"
            ) else if !charstate! equ 1 (
                set "viewShift=viewportY0+=1, viewportY1+=1"
            ) else if !charstate! equ 6 (
                set "viewShift=viewportX-=3"
            ) else if !charstate! equ 8 (
                set "viewShift=viewportX+=3"
            )
            set /a "_viewportX=viewportX, _viewportY1=viewportY1, _viewportY0=viewportY0, !viewShift!, xPos=viewportX / 3 + 1, yPos=viewportY0+1, viewportX=_viewportX, viewportY0=_viewportY0, viewportY1=_viewportY1"
            set "viewportY="
            for %%a in ( !interactions! ) do (
                for /F "tokens=1-4 delims=#" %%b in ("%%a") do (
                    if "%%b#%%c"=="!xPos!#!yPos!" (
                        if "%%d"=="special" (
                            set "args=%%e"
                            set "args=!args:*`=!"
                            for /F "tokens=1 delims=`" %%A in ("%%e") do set "func=%%A"
                            if "!func!"=="dialog" (
                                %@log% INFO Entered dialog: "!args!"
                            ) else if "!func!"=="save" (
                                call :saveSave "saves\test.sav"
                            )
                        ) else (
                            set "args=%%e"
                            call :%%d !args:`= !
                        )
                    )
                )
            )
        ) else if defined action[menu] (
            set "actionState=menu"
        )
    ) else if "!actionState!"=="menu" (
        if defined action[menu] set "actionState=map"
        if defined action[cancel] set "actionState=map"
    )
)

:: TODO convert to macro
:loadSpriteset  <sprite:file> <offset:int>
:: loads a tilefile into the tilebuffer
if not exist "%~f1" (
    %@log% ERROR Could not open file "%~1"
    exit /B 1
)
set "__map=0123456789ABCDEF"
 <"%~f1" (
    set /P "__end="
    set /a "__start=(%~2+0),__end+=__start"
    for /L %%a in ( !__start! 1 !__end! ) do (
        set /a "__dec=%%a"
        set "__hex="
        for %%_ in ( 1 2 ) do (
            set /a "__d=__dec&15,__dec>>=4"
            for %%d in (!__d!) do set "__hex=!__map:~%%d,1!!__hex!"
        )
        for %%b in ("!__hex!") do (
            set "spriteset[%%~b]="
            for %%_ in ( %tHeightIter% ) do (
                set /P "__inLine="
                set "spriteset[%%~b]=!spriteset[%%~b]!!__inLine!"
            )
        )
    )
)
set "__map="
set "__start="
set "__end="
set "__d="
set "__hex="
set "__dec="
set "__inLine="
%@log% INFO Loaded spriteset from "%~1"
exit /B 0

:loadCharacter  <sprite:file>
call :loadSpriteset  "%~1" && (
    set /a "__count=0"
    for %%a in ( 00 01 02 03 04 05 06 07 08 09 0A ) do (
        call :texconvertAlpha %%a charSprite[!__count!]
        set /a "__count+=1"
    )
)
set "__count="
exit /B

:loadKeybinds  <keybinds:file>
if not exist "%~1" (
    set "actionEvents= up down left right menu confirm cancel "
    set "keybind[up]=w"
    set "keybind[down]=s"
    set "keybind[left]=a"
    set "keybind[right]=d"
    set "keybind[confirm]=e"
    set "keybind[cancel]=q"
    set "keybind[menu]={Enter}"
    call :saveKeybinds  "%~1"
    %@log% WARNING File "%~1" does not exist, created defaults
    exit /B
)
%@log% DEBUG Trying to load from "%~1"
set "actionEvents= "
for /F "usebackq tokens=1,2 delims==" %%V in ("%~1") do (
    set "keybind[%%V]=%%W"
    set "actionEvents=!actionEvents!%%V "
)
%@log% INFO Loaded keybinds from "%~1"
exit /B

:saveKeybinds  <keybinds:file>
>"%~1" (
    for %%V in (%actionEvents%) do (
        echo %%V=!keybind[%%V]!
    )
)
%@log% INFO Saved keybinds to "%~1"
exit /B

:saveSave  <savelocation:str>
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

:: TODO fix this
:loadSave
for /F "usebackq delims=" %%F in ("%~1") do (
    set "__value=%%F"
    set "__value=!__value:*=!"
    for /F "tokens=1 delims==" %%A in ("%%F") do set "__key=%%A"
    if "!__key:~0,8!"=="viewport"(
        set "key=!value!"
    ) else if "!key!"=="map" (
        call :loadMap  "!value!"
    ) else set "_gamedata_%%F"
)
set "__key="
set "__value="
%@log% INFO Loaded save from "%~1"
exit /B

:loadFontset  <fontset>
if not exist "%~f1" (
    %@log% ERROR Could not open file "%~1"
    exit /B
)
<"%~1" (
    set /p "__fontmap="
    %@strLen% __fontmap __fontcount
    set /a "__fontcount-=2"
    for /L %%a in ( 0 2 !__fontcount! ) do (
        set /a "__start=0x!__fontmap:~%%a,2! * fontWidth, __stop=__start+fontWidth"
        for /F "tokens=1,2 delims=`" %%b in ("!__start!`!__stop!") do (
            for /L %%d in ( 0 1 !fontHeight! ) do (
                set /p "__current="
                set "fontset[%%d]=!fontset[%%d]:~0,%%b!!__current!!fontset[%%d]:~%%~c!"
            )
        )
    )
)
set "__fontmap="
set "__fontcount="
set "__start="
set "__stop="
set "__current="
%@log% INFO Loaded fontset from "%~1"
exit /B

:loadMap  <mapfile>
if not exist "%~f1" (
    %@log% ERROR Could not open file "%~1"
    exit /B 1
)
<"%~f1" (
    set /p "colmapHard="
    set "colmapHard= !colmapHard! "
    set /p "colmapSoft="
    set "colmapSoft= !colmapSoft! "
    set /p "interactions="
    set /p "__mapsize="
    set "__frame=FF`FF`FF`FF"
    for /f "tokens=1,2 delims= " %%a in ("!__mapsize!") do (
        set "__mapsizeX=%%a"
        set "__mapsizeY=%%b"
    )
    set /a "__mapsizeX=__mapsizeX*2-2, __mapsizeY+=2"
    for /L %%a in ( 3 1 !__mapsizeY! ) do (
        set /p "__line="
        set "map[%%a]=!__frame!`"
        for /L %%b in ( 0 2 !__mapsizeX! ) do (
            set "map[%%a]=!map[%%a]!!__line:~%%b,2!`"
        )
        set "map[%%a]=!map[%%a]!!__frame!"
    )
)
set /a "__mapsizeY+=1, __count1=__mapsizeY+1, __count2=__mapsizeY+2"
set "__line=!__frame!`"
for /L %%_ in ( 0 2 !__mapsizeX! ) do set "__line=!__line!FF`"
set "__line=!__line!!__frame!"
for %%a in ( 0 1 2 !__mapsizeY! !__count1! !__count2! ) do set "map[%%a]=!__line!"
set "map=%~1"
:: Reset temp variables
set "__mapsize="
set "__frame="
set "__mapsizeX="
set "__mapsizeY="
set "__line="
set "__count1="
set "__count2="
%@log% INFO Loaded map from "%~1"
exit /B

:texconvertAlpha  <sprite:ptr->spriteset> <output:array>
set "%~2="
for %%a in ( %tHeightIter% ) do (
    set /a "__mode=0"
    for %%b in ( %tWidthIter% ) do (
        set /a "__pos=%%a * 16 + %%b"
        for %%c in ("!__pos!") do (
            set "__current=!spriteset[%~1]:~%%~c,1!"
            if "!__current!" neq "." (
                if !__mode! equ 0 (
                    set "__outLen=1"
                    set "__outLine=%%b`%%a`!__current!"
                    set "__mode=1"
                ) else (
                    set "__outLine=!__outLine!!__current!"
                    set /a "__outLen+=1"
                )
            ) else (
                if !__mode! equ 1 (
                    set "%~2=!%~2!!__outLine!`!__outLen!,"
                    set "__mode=0"
                )
            )
        )
    )
    if !__mode! equ 1 set "%~2=!%~2!!__outLine!`!__outLen!,"
)
if defined %~2 (
    set "%~2=!%~2:~0,-1!"
    set "%~2=!%~2: =.!"
)
:: reset temp variables
set "__mode="
set "__pos="
set "__current="
set "__outLen="
set "__outLine="
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
if not defined @log set "@log=>&%logStream% echo"

set "eID=Grub4E"
if defined DEBUG (
    %@log% :setlevel DEBUG
    set "eID=%eID%:DEBUG"
)

set /a "fontHeight-=1"

set "shiftX=0"
set "shiftY=0"
set "fadeOverTime=0"
set "fadeOverCount=0"
set "fadeLookup=    ฐฑÛÛÛฑฐ "

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

:: Define \e as the escape character
:: TODO define VT100 switch
for /f "delims=" %%E in ('forfiles /p "%~dp0." /m "%~nx0" /c "cmd /c echo(0x1B"') do (
    set "\e=%%E"
    <NUL set /p "=%%E[?25l"
)

:: define LF as a Line Feed (newline) character
set ^"LF=^
%= These lines are required =%
^" do not remove

:: Define line continuation
set ^"\n=^^^%LF%%LF%^%LF%%LF%^^"

set "haltActionTranslation="

set "@setTitle=title [!eID!]"

:: TODO rework
:: @transition transition number
set @transition=for %%# in (1 2) do if %%#==2 (set "actionState=transition:!args!") else set /a args=

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

::@strLen  <str:var> <rtn:Var>
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

::@renderFont  <renderdata:var> <output>
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


:: TODO: make drawOver and drawOverAlpha able to use absolute position
::@drawOver  <x> <y> <xlen> <ylen> <data>
::: draw data over a specified portion of the screen.
::: x and y start at 1
set @drawOver=for %%# in (1 2) do if %%#==2 ( %\n%
for /F "tokens=1-5 delims=, " %%1 in ("!args!") do ( %\n%
    for /L %%a in ( 0 1 %%~4 ) do ( %\n%
        set /a "y=%%2+%%a,linenum=y/%tHeight%,linestart=(y%% %tHeight%)*(%tWidth%*(%sWidth%+2))+%tWidth%+%%1,lineend=linestart+%%3" %\n%
        for /f "tokens=1-3" %%b in ("!linenum! !linestart! !lineend!") do ( %\n%
            set "line[%%b]=!line[%%b]:~0,%%c!!%%~5[%%a]:~0,%%3!!line[%%b]:~%%d!" %\n%
        ) %\n%
    ) %\n%
)) else set args=,

::@drawOverAlpha  <x:int> <y:int> <data:array[alphaTexture]>
::: draw data over a specified portion of the screen.
::: Input has to be a texture prepared using :texconvertAlpha
::: x and y start at 1
set @drawOverAlpha=for %%# in (1 2) do if %%#==2 ( %\n%
for /F "tokens=1-3 delims=, " %%1 in ("!args!") do ( %\n%
    for %%a in ( !%%~3! ) do ( %\n%
        for /F "tokens=1-4 delims=`" %%4 in ("%%a") do (%\n%
            set "__temp=%%6"%\n%
            set /a "y=%%2+%%5,linenum=y/%tHeight%,linestart=(y%% %tHeight%)*(%tWidth%*(%sWidth%+2))+%tWidth%+%%1+%%4,lineend=linestart+%%7" %\n%
            for /f "tokens=1-3" %%b in ("!linenum! !linestart! !lineend!") do ( %\n%
                set "line[%%b]=!line[%%~b]:~0,%%~c!!__temp:.= !!line[%%~b]:~%%~d!" %\n%
            ) %\n%
        ) %\n%
    ) %\n%
)) else set args=,

:: @addDebugData  <dataVar>
::: adds a entry to the debug overlay for display
set @addDebugData=for %%# in (1 2) do if %%#==2 ( %\n%
for /F "tokens=1 delims=, " %%1 in ("!args!") do ( %\n%
    set "debugTemp= %%1                   "%\n%
    set "debugOverlay[!debugOverlay[#]!]=บ!debugTemp:~0,20!บ"%\n%
    set /a "debugOverlay[#]+=2"%\n%
    set "debugOverlayList=!debugOverlayList! %%1"%\n%
)) else set args=,

:: TODO have VT100 toggle
:: clear screen by setting cursor to 0:0
:: Can be switched out for `cls` on older systems
set "@cls=<NUL set /P =%\e%[H"

:: @sendCmd  command
:::  sends a command to the controller
set "@sendCmd=>&%cmdStream% echo"

:: TODO additional variable cleanup
for /F "delims=" %%a in ('set __') do (
    %@log% DEBUG %%a
)
%@log% INFO Finished normal setup
exit /B

:initDelayed
set /a "tHeight-=1, tWidth-=1, sHeight-=1, sWidth-=1, tHeightIter=tWidthIter=0, sHeightIter=sWidthIter=0, __tWidthXtHeight=tWidth*(tHeight+1), ssPosIter=0"
for /L %%a in ( 1 1 %tHeight% ) do set "tHeightIter=!tHeightIter! %%a"
for /L %%a in ( 1 1 %tWidth% ) do set "tWidthIter=!tWidthIter! %%a"
for /L %%a in ( 1 1 %sHeight% ) do set "sHeightIter=!sHeightIter! %%a"
for /L %%a in ( 1 1 %sWidth% ) do set "sWidthIter=!sWidthIter! %%a"
set /a "tHeight+=1, tWidth+=1, sHeight+=1, sWidth+=1"

for /L %%a in ( %tWidth% %tWidth% %__tWidthXtHeight% ) do set "ssPosIter=!ssPosIter! %%a"

set "__empty="
set "spriteset[FF]="
for /L %%. in ( 1 1 %tWidth% ) do set "__empty=!__empty! "
for /L %%. in ( 1 1 %tHeight% ) do set "spriteset[FF]=!spriteset[FF]!!__empty!"

set "__count=0"
set "lineset="
for %%a in ( A B C D E F G H I J K L M N O P Q R S T U V W X Y Z ) do (
    set /a "__count+=1"
    if !__count! leq %sWidth% set "lineset=!lineset!^!spriteset[%%%%a]_%%s^!"
)

set "__empty="
set "fontset[0]="
for /L %%_ in ( 1 1 !fontwidth! ) do set "empty=!empty! "
for /L %%_ in ( 1 1 126 ) do set "fontset[0]=!fontset[0]!!empty!"
for /L %%a in ( 0 1 !fontheight! ) do set "fontset[%%a]=!fontset[0]!"

set "__tempLookupIter=Z Y X W V U T S R Q P O N M L K J I H G F E D C B A"
set "__tempLookup=ABCDEFGHIJKLMNOPQRSTUVWXYZ"
set /a "__tempSWidth=sWidth+2"
for %%a in ("!__tempLookup:~%__tempSWidth%,1!") do (
    set "__tempLookupIter=!__tempLookupIter:*%%~a=!"
)
set "#lineGenerator="
for %%a in (!__tempLookupIter!) do (
    set "#lineGenerator=^!spriteset[%%~%%a]:~%%b,%tWidth%^!!#lineGenerator!"
)

set "#clipLine="
for %%a in (%tHeightIter%) do (
    set /a "__start=((%sWidth%+2) * %%a + 1) * %tWidth%, __end=(%sWidth%*%tWidth%)"
    set "#clipLine=!#clipLine!#^!line[%%l]:~!__start!,!__end!^!#^!LF^!"
)
set "#clipLine=!#clipLine:~0,-4!"

:: reset variables
set "__tWidthXtHeight="
set "__empty="
set "__count="
set "__tempLookupIter="
set "__tempLookup="
set "__tempSWidth="
set "__start="
set "__end="
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
set "logLevels= ERROR WARNING "
:: TODO transition to use of %time% and %date%
set @performLog=(%\n%
for /F "tokens=1 delims= " %%a in ("!message!") do (%\n%
    if "!logLevels:%%a=!" neq "!logLevels!" (%\n%
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
                %@performLog%
                exit
            ) else if "!message:~1,8!"=="setlevel" (
                set "message=!message:* =!"
                set "logLevels="
                set "found="
                for %%a in (
                    "SILENT"
                    "ERROR"
                    "WARNING"
                    "INFO"
                    "DEBUG"
                ) do (
                    if not defined found set "logLevels=!logLevels!%%~a "
                    if "%%~a"=="!message:* =!" set "found=1"
                )
                set "logLevels= !logLevels:* =!"
                set "message=INFO Switched loglevel to !message:* =!"
                %@performLog%
            )
        ) else %@performLog%
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
