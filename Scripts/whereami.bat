@echo off

if "%whereami%"=="" (
  echo windows
) else (
  echo %whereami%
)
