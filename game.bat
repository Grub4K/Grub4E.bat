@echo off
setlocal
set "DEBUG=1"
color F0
for /F "usebackq delims=" %%a in ("data\game.txt") do set "%%a"

engine\load
