@echo off
set /a "dWidth=tWidth*sWidth+2, dHeight=tHeight*sHeight+2"
mode %dWidth%,%dHeight%
set "eID=Grub4E"
if defined DEBUG set "eID=%eID%:DEBUG"

set "spriteset[FF]=                                                                                                                                                                                                                                                                "

set /a "fontheight-=1"

set "fadeOverTime=0"
set "fadeOverCount=0"
set "fadeLookup=    ░▒███▒░ "

set #charMap=#  20#!!21#^"^"22###23#$$24#%%%%25#^&^&26#''27#^(^(28#^)^)29#**2A#++2B#,,2C#--2D#..2E#//2F#0030#1131#2232#3333#4434#5535#6636#7737#8838#9939#::3A#;;3B#^<^<3C#==3D#^>^>3E#??3F#@@40#AA41#BB42#CC43#DD44#EE45#FF46#GG47#HH48#II49#JJ4A#KK4B#LL4C#MM4D#NN4E#OO4F#PP50#QQ51#RR52#SS53#TT54#UU55#VV56#WW57#XX58#YY59#ZZ5A#[[5B#\\5C#]]5D#^^^^5E#__5F#``60#aa61#bb62#cc63#dd64#ee65#ff66#gg67#hh68#ii69#jj6A#kk6B#ll6C#mm6D#nn6E#oo6F#pp70#qq71#rr72#ss73#tt74#uu75#vv76#ww77#xx78#yy79#zz7A#{{7B#^|^|7C#}}7D#~~7E

set @log=call ^>^>"%gameLog%" echo %%time::=-%%:

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
    set "debug_overlay[!debug_overlay[#]!]=║!debug_temp:~0,20!║"%\n%
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
