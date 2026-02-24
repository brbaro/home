@echo off
setlocal enabledelayedexpansion

set "query=%*"
set "query=%query: =+%"
start "" "https://www.google.com/search?q=%query%"

exit /b
