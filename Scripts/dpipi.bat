@echo off
setlocal enabledelayedexpansion

set "game=%~1"
set "engine_sens="

for %%a in (source apex cs cs2 gmod hl2 l4d l4d2 portal portal2 tf2) do if /i "%game%"=="%%a" set "engine_sens=2"
for %%a in (fortnite fn siege rss) do if /i "%game%"=="%%a" set "engine_sens=8"
if /i "%game%"=="mwf" set "engine_sens=7"
for %%a in (overwatch ow) do if /i "%game%"=="%%a" set "engine_sens=6.77"
if /i "%game%"=="realm" set "engine_sens=5.4"
for %%a in (quake3 q3a) do if /i "%game%"=="%%a" set "engine_sens=2.2"
for %%a in (sg splitgate) do if /i "%game%"=="%%a" set "engine_sens=4.7"
for %%a in (val valorant) do if /i "%game%"=="%%a" set "engine_sens=0.635"

if not defined engine_sens goto :help

set "LABEL=Sensitivity: "
set "INVERT=0"

if /i "%~2"=="-i" (
  set "LABEL=Inches per pi: "
  set "INVERT=1"
  set "VAL_PROMPT=Sensitivity [%engine_sens%]"
  set "VAL_DEFAULT=%engine_sens%"
  set "TARGET_VAL=%~3"
  set "TARGET_DPI=%~4"
) else (
  set "VAL_PROMPT=Inches per pi [10]"
  set "VAL_DEFAULT=10"
  set "TARGET_VAL=%~2"
  set "TARGET_DPI=%~3"
)

if "%TARGET_VAL%"=="" (
  set /p "USER_VAL=%VAL_PROMPT%: "
  if "!USER_VAL!"=="" set "USER_VAL=%VAL_DEFAULT%"
) else (
  set "USER_VAL=%TARGET_VAL%"
)

if "%TARGET_DPI%"=="" (
  set /p "USER_DPI=Dots per inch [800]: "
  if "!USER_DPI!"=="" set "USER_DPI=800"
) else (
  set "USER_DPI=%TARGET_DPI%"
)

for /f "usebackq" %%R in (`powershell -NoProfile -Command ^
  "$dpiMult = 400 / %USER_DPI%;" ^
  "$valMult = (10 * %engine_sens%) / %USER_VAL%;" ^
  "$result = $valMult * $dpiMult;" ^
  "[math]::Round($result, 4)"`) do set "RESULT=%%R"

echo %LABEL%%RESULT%
exit /b

:help
echo.
echo Usage: sens [game] [-i] [val] [dpi]
echo.
echo Games: source, fortnite, mwf, overwatch, quake3, realm, siege, splitgate, valorant
echo.
exit /b
