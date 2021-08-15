::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Grub4E/engine.bat
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
call Grub4E\init.bat
setlocal enableDelayedExpansion
call Grub4E\lib\libmacro.bat "Grub4E\macroFunctions.bat"
call Grub4E\initDelayed.bat

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
            exit 0
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
