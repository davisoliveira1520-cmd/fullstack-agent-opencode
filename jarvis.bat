@echo off
rem Jarvis launcher (Windows): everything lives inside this repo.
rem OpenCode is bundled in bin\ and extracted on first run — nothing is
rem installed on this machine. Close the window (or Ctrl-C) to stop.
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

rem Run the Jarvis wizard from this repo (reads AGENTS.md + fullstack-agent.md).
echo   Jarvis: starting OpenCode...
"bin\opencode.exe" "set me up"

echo.
pause