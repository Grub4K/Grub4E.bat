::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Grub4E/macroFunctions.bat
::
:: Written by Grub4K (Grub4K#2417) with some techniques from DosTips
:: and many ideas from the folks at server.bat (discord.gg/GSVrHag)
::
::
:: This file contains some functions that are suppose to be converted
:: to macros using `libmacro.bat`
::
:: This Source Code Form is subject to the terms of the Mozilla Public
:: License, v. 2.0. If a copy of the MPL was not distributed with this
:: file, You can obtain one at http://mozilla.org/MPL/2.0/.
:: This Source Code Form is "Incompatible With Secondary Licenses", as
:: defined by the Mozilla Public License, v. 2.0.
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: TODO: make drawOver and drawOverAlpha able to use absolute position
:drawOver  <x:int> <y:int> <xLen:int> <yLen:int> <data:array[texture]>
:: draw data over a specified portion of the screen.
:: x and y start at 1
for /L %%a in ( 0 1 %%~4 ) do (
    set /a "y=%2+%%a,linenum=y/!tHeight!,linestart=(y%% !tHeight!)*(!tWidth!*(!sWidth!+2))+!tWidth!+%1,lineend=linestart+%3"
    for /f "tokens=1-3" %%b in ("!linenum! !linestart! !lineend!") do (
        set "line[%%b]=!line[%%b]:~0,%%c!!%~5[%%a]:~0,%3!!line[%%b]:~%%d!"
    )
)

:drawSprite  <x:int> <y:int> <sprite:int>
:: draws a sprite over a specified portion of the screen
:: uses the currently loaded sprite index
set /a "%%4Render=0, y=%2-posY+tHeight, yLimit=tHeight*(sHeight+2), x=%1-posX+tWidth, xLimit=tWidth*(sWidth+2)"
if !y! geq 0 if !y! leq !yLimit! if !x! geq 0 if !x! leq !xLimit! (
    for %%a in (!tHeightIter!) do (
        set /a "y=%2+%%a-posY, linenum=y/tHeight, linestart=(y%%tHeight)*(tWidth*(sWidth+2))+tWidth+%1-posX, lineend=linestart+tWidth, texstart=%%a*tWidth"
        for /f "tokens=1-5" %%b in ("!linenum! !linestart! !lineend! !texstart! !tWidth!") do (
            set "line[%%b]=!line[%%b]:~0,%%c!!spriteset[%%3]:~%%e,%%f!!line[%%b]:~%%d!"
        )
    )
    set "%%4Render=1"
)


:drawOverAlpha  <x:int> <y:int> <data:array[textureAlpha]>
:: draw data over a specified portion of the screen.
:: Input has to be a texture prepared using :texconvertAlpha
:: x and y start at 1
for %%a in ( !%%~3! ) do (
    for /F "tokens=1-4 delims=`" %%4 in ("%%a") do (
        set "__temp=%%6"
        set /a "y=%%2+%%5,linenum=y/!tHeight!,linestart=(y%% !tHeight!)*(!tWidth!*(!sWidth!+2))+!tWidth!+%%1+%%4,lineend=linestart+%%7"
        for /f "tokens=1-3" %%b in ("!linenum! !linestart! !lineend!") do (
            set "line[%%b]=!line[%%~b]:~0,%%~c!!__temp:.= !!line[%%~b]:~%%~d!"
        )
    )
)
set "__temp="


:randomRange  [min:int] [max:int]
:: TODO rework this shit capping alg
if "%2" equ "" (
    set /a "?=(random_x32 & 0x7FFFFFFF) + (%1+0)"
) else set /a "?=(random_x32 & 0x7FFFFFFF) %% (%2 + 1 - (%1+0)) + (%1+0)"
set /a "random_x32^=random_x32 << 13, random_x32^=((random_x32&0x7FFFFFFF)>>17) | ((random_x32>>17)&0x4000), random_x32^=random_x32 << 5"

:strLen  <str:var> <rtn:Var>
set "__s=A!%%~1!"
set "%%~2=0"
for %%P in (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) do (
    if "!__s:~%%P,1!" neq "" (
        set /a "%%~2+=%%P"
        set "__s=!__s:~%%P!"
    )
)
set "__s="

:addDebugData  <data:var>
::: adds a entry to the debug overlay for display
set "debugOverlay[!debugOverLay[#]!]=봬컴컴컴컴컴컴컴컵컴컴컴컴컴컴컴컴컴컴캤"
set /a "debugOverlay[#]+=2"
set "debugOverlayList=!debugOverlayList! %%1"

:renderFont  <data:var> <output:array[texture]>
:: render characters into an array to be displayed with @drawOver
for /L %%a in ( 0 1 !fontheight! ) do set "%%~2[%%a]="
set "s=!%%~1!"
set "len=0"
for %%a in ( 4096 2048 1024 512 256 128 64 32 16 8 4 2 1 ) do (
    if "!s:~%%a,1!" neq "" (
        set /a "len+=%%a"
        set "s=!s:~%%a!"
    )
)
for /L %%a in ( 0 1 !len! ) do (
    for %%b in ("!%%~1:~%%~a,1!") do (
        set "__current=!#charMap:*#%%~b=!"
        if "!__current:~0,1!" neq "%%~b" (
            set "__current=!__current:*#%%~b=!"
        )
        set /a "__current=0x!__current:~1,2!*!fontwidth!"
        for /F "tokens=1,2" %%c in ("!__current! !fontwidth!") do (
            for /L %%e in ( 0 1 !fontheight! ) do (
                set "%%~2[%%e]=!%%~2[%%e]!!fontset[%%e]:~%%c,%%d! "
            )
        )
    )
)
for /L %%a in ( 0 1 !fontheight! ) do (
    set "%%~2[%%a]=!%%~2[%%a]:~0,-1!"
)

:addCoroutine  <coroutine> [argument1] [argument2] [argument3] [argument4]
set "coroutines=!coroutines!coro_%%~1`%%~2`%%~3`%%~4`%%~5 "

:removeCoroutine  <coroutine> [argument1] [argument2] [argument3] [argument4]
set "coroutines=!coroutines: coro_%%~1`%%~2`%%~3`%%~4`%%~5 = !"
