@echo off
setlocal enabledelayedexpansion

if "%~1"=="" (
  echo Usage: remap [orig:new] [orig2:new2] ...
  echo Example: remap 3a:1d (Caps Lock to L-Ctrl) ^| remap 5b:00 (Disable Win Key)
  echo.
  echo --- MODIFIERS ^& SYSTEM ---          --- NAVIGATION ---
  echo 01: Esc          1c: Enter           48: Up          47: Home
  echo 3a: CapsLock     0e: Backspace       50: Down        4f: End
  echo 0f: Tab          39: Space           4b: Left        49: PgUp
  echo 2a: L-Shift      36: R-Shift         4d: Right       51: PgDn
  echo 1d: L-Ctrl       e01d: R-Ctrl        52: Insert      53: Delete
  echo 38: L-Alt        e038: R-Alt         5b: L-Win       5c: R-Win
  echo.
  echo --- FUNCTION KEYS ---               --- NUMPAD ---
  echo 3b-44: F1-F10    57: F11    58: F12  52: 0/Ins       4f: 1/End
  echo 45: NumLock      46: ScrollLock      50: 2/Down      51: 3/PgDn
  echo e037: PrtSc      e046: Break         4b: 4/Left      4c: 5/Clear
  echo.                                     4d: 6/Right     47: 7/Home
  echo --- MEDIA (Extended) ---             48: 8/Up        49: 9/PgUp
  echo e020: Mute       e02e: VolDown       37: * 4a: -
  echo e030: VolUp      e022: Play/Pause    4e: +           e01c: Enter
  echo.
  echo --- ALPHA-NUMERIC ---
  echo 1e:A  1f:S  20:D  21:F  22:G  23:H  24:J  25:K  26:L
  echo 10:Q  11:W  12:E  13:R  14:T  15:Y  16:U  17:I  18:O  19:P
  echo 2c:Z  2d:X  2e:C  2f:V  30:B  31:N  32:M  33:,  34:.  35:/
  echo 02:1  03:2  04:3  05:4  06:5  07:6  08:7  09:8  0a:9  0b:0
  echo 29: `  2b: \  1a: [  1b: ]  27: ;  28: '  0c: -  0d: =
  exit /b 0
)

if /i "%~1"=="reset" (
  echo [!] Resetting ScanCode Map...
  wudo reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layout" /v "Scancode Map" /f
  exit /b %errorlevel%
)

:: Build Binary Map
set "header=0000000000000000"
set /a count=1
set "mappings="

for %%a in (%*) do (
  for /f "tokens=1,2 delims=:" %%b in ("%%a") do (
    set "o=%%b" & set "n=%%c"
    :: Handle 1-byte vs 2-byte (Extended e0xx) scancodes by ensuring 4 bytes total (Little-Endian)
    if "!n:~0,2!"=="e0" (set "new=!n:~2,2!e0") else (set "new=!n!00")
    if "!o:~0,2!"=="e0" (set "orig=!o:~2,2!e0") else (set "orig=!o!00")
    set "mappings=!mappings!!new!0000!orig!0000"
    set /a count+=1
  )
)

set /a count+=1
set "hexCount="
powershell -NoProfile -Command "$c = [int]%count%; '{0:x2}000000' -f $c" > %temp%\hcount.txt
set /p hexCount=<%temp%\hcount.txt

set "finalMap=%header%%hexCount%%mappings%00000000"
wudo reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layout" /v "Scancode Map" /t REG_BINARY /d %finalMap% /f

echo [!] Applied. Restart required.
endlocal
