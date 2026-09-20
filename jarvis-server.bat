@echo off
setlocal enabledelayedexpansion
REM ============================================================
REM  Jarvis Server (Windows) — ponte local para o Jarvis Web
REM  Sobe o OpenClaw Gateway + usa as chaves/agentes que voce
REM  ja tem na sua maquina (OpenCode / OpenClaw / Open-Lovable).
REM  O Jarvis Web conecta em http://localhost:18789 sem chave.
REM ============================================================

echo.
echo  ============================================================
echo    JARVIS SERVER  -  modo local (verde e amarelo)
echo  ============================================================
echo.

REM ---- localiza openclaw ----
set "OPENCLAW="
where openclaw >nul 2>nul && set "OPENCLAW=openclaw"

if not defined OPENCLAW (
  REM tenta via npm global
  if exist "%APPDATA%\npm\openclaw.cmd" set "OPENCLAW=%APPDATA%\npm\openclaw.cmd"
)
if not defined OPENCLAW (
  if exist "%ProgramFiles%\nodejs\openclaw.cmd" set "OPENCLAW=%ProgramFiles%\nodejs\openclaw.cmd"
)
if not defined OPENCLAW (
  echo  [ERRO] OpenClaw nao encontrado.
  echo  Instale primeiro:  npm install -g openclaw@latest
  echo  (ou rode a partir da pasta do Jarvis, que ja vem com tudo)
  pause
  exit /b 1
)

echo  OpenClaw: %OPENCLAW%
echo  Iniciando gateway em http://localhost:18789 ...
echo  Deixe esta janela aberta enquanto usar o Jarvis Web.
echo  (Feche esta janela para parar o servidor.)
echo.

call "%OPENCLAW%" gateway run --port 18789 --allow-unconfigured

echo.
echo  Servidor encerrado.
pause
endlocal