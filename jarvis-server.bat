@echo off
setlocal enabledelayedexpansion
REM ============================================================
REM  Jarvis Server (Windows) — ponte local para o Jarvis Web
REM  Sobe o OpenClaw Gateway + servidor do Jarvis Web em localhost.
REM  Abra http://localhost:8080 no navegador e fale com o Jarvis
REM  via voz — usa as chaves/agentes da sua maquina, SEM chave.
REM ============================================================

echo.
echo  ============================================================
echo    JARVIS SERVER  -  modo local
echo  ============================================================
echo.

set "SCRIPT_DIR=%~dp0"

REM ---- pasta de config do openclaw ----
set "OCONF=%USERPROFILE%\.openclaw"
if not exist "%OCONF%" mkdir "%OCONF%"

REM ---- garante gateway.http.endpoints.chatCompletions.enabled=true ----
set "OCONF_FILE=%OCONF%\openclaw.json"
if not exist "%OCONF_FILE%" (
  echo { > "%OCONF_FILE%"
  echo   "gateway": { >> "%OCONF_FILE%"
  echo     "mode": "local", >> "%OCONF_FILE%"
  echo     "port": 18789, >> "%OCONF_FILE%"
  echo     "bind": "loopback", >> "%OCONF_FILE%"
  echo     "auth": { "mode": "none" }, >> "%OCONF_FILE%"
  echo     "http": { "endpoints": { "chatCompletions": { "enabled": true } } } >> "%OCONF_FILE%"
  echo   } >> "%OCONF_FILE%"
  echo } >> "%OCONF_FILE%"
  echo  [OK] Config criada: %OCONF_FILE%
) else (
  findstr /C:"chatCompletions" "%OCONF_FILE%" >nul 2>nul
  if errorlevel 1 (
    echo  [AVISO] Sua config %OCONF_FILE% nao habilita o endpoint HTTP.
    echo  A pagina de instalacao explica como ativar. O servidor mesmo assim
    echo  vai iniciar; se o Jarvis Web nao responder, adicione manualmente:
    echo    "gateway": { "http": { "endpoints": { "chatCompletions": { "enabled": true } } } }
    echo.
  ) else (
    echo  [OK] Endpoint HTTP ja habilitado na config.
  )
)

REM ---- localiza openclaw ----
set "OPENCLAW="
where openclaw >nul 2>nul && set "OPENCLAW=openclaw"

if not defined OPENCLAW (
  if exist "%APPDATA%\npm\openclaw.cmd" set "OPENCLAW=%APPDATA%\npm\openclaw.cmd"
)
if not defined OPENCLAW (
  if exist "%ProgramFiles%\nodejs\openclaw.cmd" set "OPENCLAW=%ProgramFiles%\nodejs\openclaw.cmd"
)
if not defined OPENCLAW (
  echo  [ERRO] OpenClaw (node) nao encontrado.
  echo  Instale primeiro o Node.js em https://nodejs.org e depois:
  echo      npm install -g openclaw@latest
  pause
  exit /b 1
)

echo  OpenClaw: %OPENCLAW%
echo.
echo  Iniciando servidor do Jarvis Web em http://localhost:8080
echo  Deixe esta janela aberta enquanto usar o Jarvis Web.
echo  (Feche esta janela para parar tudo.)
echo.

set "OPENCLAW_PATH=%OPENCLAW%"
where node >nul 2>nul
if errorlevel 1 (
  echo  [ERRO] Node.js nao encontrado no PATH.
  set "NODE_JS=%ProgramFiles%\nodejs\node.exe"
  if exist "%NODE_JS%" (
    "%NODE_JS%" "%SCRIPT_DIR%jarvis-web-server.mjs"
  ) else (
    echo  Instale o Node.js em https://nodejs.org
    pause
    exit /b 1
  )
) else (
  node "%SCRIPT_DIR%jarvis-web-server.mjs"
)

echo.
echo  Servidor encerrado.
pause
endlocal