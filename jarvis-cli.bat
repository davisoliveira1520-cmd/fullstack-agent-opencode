@echo off
rem Jarvis CLI (Windows): abre o Jarvis no terminal (modo assistente OpenCode).
rem Sem servidor web — usa o binário de OpenCode embutido em bin\.
rem Copyright (C) 2026 Jared Rhodenizer
rem SPDX-License-Identifier: AGPL-3.0-or-later

setlocal
cd /d "%~dp0"

rem Extract the bundled OpenCode binary on first run.
if not exist "bin\opencode.exe" (
  echo   Jarvis: preparing OpenCode (one-time, inside this repo)...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Force -LiteralPath 'bin\opencode-windows-x64.zip' -DestinationPath 'bin'" >nul
  if errorlevel 1 (
    echo   Could not unpack bin\opencode-windows-x64.zip. Is the file still there?
    pause
    exit /b 1
  )
)

echo   Jarvis: starting OpenCode (CLI)...
"bin\opencode.exe" "set me up"

echo.
pause