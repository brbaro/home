@echo off

:while
  if "%~1"=="" goto :eof
  taskkill /f /im "%~1.exe"
shift
goto while
