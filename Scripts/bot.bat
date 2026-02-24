@echo off
setlocal enabledelayedexpansion

set "query=%*"
set "query=%query: =+%"
start "" "https://chat.openai.com?q=%query%"

exit /b
