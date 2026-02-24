@echo off

if "%~1"=="" (
  start mstsc
) else (
  start mstsc /v:%~1
)
