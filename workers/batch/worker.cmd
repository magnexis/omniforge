@echo off
setlocal EnableDelayedExpansion

set "input=%~1"
set "length=0"

:count
if defined input (
  set "input=!input:~1!"
  set /a length+=1
  goto count
)

echo {"length":%length%}
