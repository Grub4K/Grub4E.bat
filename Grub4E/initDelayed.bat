::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Grub4E/initDelayed.bat
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

set /a "tHeight-=1, tWidth-=1, sHeight-=1, sWidth-=1, tHeightIter=tWidthIter=0, sHeightIter=sWidthIter=0"
for /L %%a in ( 1 1 %tHeight% ) do set "tHeightIter=!tHeightIter! %%a"
for /L %%a in ( 1 1 %tWidth% ) do set "tWidthIter=!tWidthIter! %%a"
for /L %%a in ( 1 1 %sHeight% ) do set "sHeightIter=!sHeightIter! %%a"
for /L %%a in ( 1 1 %sWidth% ) do set "sWidthIter=!sWidthIter! %%a"
set /a "tHeight+=1, tWidth+=1, sHeight+=1, sWidth+=1, __tWidthXtHeight=tWidth*tHeight, ssPosIter=0"

for /L %%a in ( %tWidth% %tWidth% %__tWidthXtHeight% ) do set "ssPosIter=!ssPosIter! %%a"

set "__empty="
set "spriteset[FF]="
for /L %%. in ( 1 1 %tWidth% ) do set "__empty=!__empty! "
for /L %%. in ( 1 1 %tHeight% ) do set "spriteset[FF]=!spriteset[FF]!!__empty!"

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
    set "#clipLine=!#clipLine!^!line[%%l]:~!__start!,!__end!^!^!\n^!"
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
