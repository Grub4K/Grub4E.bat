@echo off
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
