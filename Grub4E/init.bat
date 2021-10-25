::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Grub4E/init.bat
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
:init
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

set /a "dWidth=tWidth*sWidth, dHeight=tHeight*sHeight+1"
mode %dWidth%,%dHeight%

set /a "hRes=(sWidth+2) * 3"

:: @log  loglevel message
:: @log  `quit`
:: @log  `setlevel` level
:::  sends commands to the logging module
if not defined @log set "@log=>&%logStream% echo"

set "eID=Grub4E"
if defined DEBUG (
    %@log% setlevel DEBUG
    set "eID=%eID%:DEBUG"
)

set /a "fontHeight-=1"

set "shiftX=0"
set "shiftY=0"
set "fadeOverTime=0"
set "fadeOverCount=0"
set "fadeLookup=    ∞±€€€±∞ "

set "#charMap=#  20#!!21#""22###23#$$24#%%%%25#&&26#''27#((28#))29#**2A#++2B#,,2C#--2D#..2E#//2F#0030#1131#2232#3333#4434#5535#6636#7737#8838#9939#::3A#;;3B#<<3C#==3D#>>3E#??3F#@@40#AA41#BB42#CC43#DD44#EE45#FF46#GG47#HH48#II49#JJ4A#KK4B#LL4C#MM4D#NN4E#OO4F#PP50#QQ51#RR52#SS53#TT54#UU55#VV56#WW57#XX58#YY59#ZZ5A#[[5B#\\5C#]]5D#^^5E#__5F#``60#aa61#bb62#cc63#dd64#ee65#ff66#gg67#hh68#ii69#jj6A#kk6B#ll6C#mm6D#nn6E#oo6F#pp70#qq71#rr72#ss73#tt74#uu75#vv76#ww77#xx78#yy79#zz7A#{{7B#||7C#}}7D#~~7E"

:: REMOVE
::if defined appdata set "gameLoc=%AppData%\%gameTitle%\"
set "saveLoc=saves\"
if not exist "%saveLoc%" md "%saveLoc%"

:: This is a strange way to get seed, but probably good enough for now
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "random_x32=%%a"
set "random_x32=%random_x32:.=%"
set /a "random_x32=0x%random_x32:~-12,-4%"

:: Define optional VT100
if defined VT100 (
    for /f "delims=" %%E in (
        'forfiles /p "%~dp0." /m "%~nx0" /c "cmd /c echo(0x1B"'
    ) do (
        set "@cls=<NUL set /P =%%E[H"
        <NUL set /p "=%%E[?25l"
    )
)

:: define \n as a <LF> character
set ^"\n=^
%= These lines are required =%
^" do not remove

set #hasAction=not "!actions!"=="!actions: ? = !"
set "actions= "

set "haltActionTranslation="

set "@setTitle=title [!eID!]"

:: Fallback if no other cls has been defined
if not defined @cls set "@cls=cls"

:: @sendCmd  command
:::  sends a command to the controller
set "@sendCmd=>&%cmdStream% echo"

%@log% INFO Finished normal setup
exit /B
