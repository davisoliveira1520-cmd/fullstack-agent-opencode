@echo off
setlocal enableextensions
REM ============================================================
REM  JARVIS (Windows) — abra e use. Nada de link extra.
REM  Um duplo-clique: instala Node/OpenClaw se faltar (1a vez),
REM  sobe o cerebro local e ABRE o Jarvis no navegador sozinho.
REM  Feche a janela (ou Ctrl+C) para encerrar tudo.
REM ============================================================

cd /d "%~dp0"

echo.
echo  ============================================================
echo    JARVIS  -  abrindo o seu assistente...
echo  ============================================================
echo.

REM ---- 1) Node.js (usado pelo cerebro e pelo servidor web) ----
where node >nul 2>nul
if errorlevel 1 (
  echo  Node.js nao encontrado. Vou instalar automaticamente (uma vez)...
  where winget >nul 2>nul
  if errorlevel 1 (
    echo  [ERRO] Nao achei o winget para instalar o Node.js.
    echo  Instale o Node.js em https://nodejs.org e rode o jarvis.bat de novo.
    goto cli
  )
  winget install --id OpenJS.NodeJS.LTS -e --silent --accept-package-agreements --accept-source-agreements
  if errorlevel 1 (
    echo  [ERRO] Falha ao instalar o Node.js pelo winget.
    echo  Instale o Node.js em https://nodejs.org e rode o jarvis.bat de novo.
    goto cli
  )
  set "PATH=%PATH%;%ProgramFiles%\nodejs;%APPDATA%\npm"
)

where node >nul 2>nul
if errorlevel 1 (
  echo  [ERRO] Node.js instalado mas nao entrou no PATH.
  echo  Feche e reabra o terminal e rode o jarvis.bat de novo.
  goto cli
)

REM ---- 2) OpenClaw (cerebro local, gateway HTTP) ----
where openclaw >nul 2>nul
if errorlevel 1 (
  if not exist "%APPDATA%\npm\openclaw.cmd" (
    echo  OpenClaw nao encontrado. Instalando automaticamente (uma vez)...
    call npm install -g openclaw@latest
  )
  set "PATH=%PATH%;%APPDATA%\npm"
)
where openclaw >nul 2>nul
if errorlevel 1 (
  if exist "%APPDATA%\npm\openclaw.cmd" (
    set "OPENCLAW_PATH=%APPDATA%\npm\openclaw.cmd"
  ) else (
    echo  [ERRO] Nao consegui instalar o OpenClaw.
    echo  Rode manualmente:  npm install -g openclaw@latest
    goto cli
  )
)

echo  Cerebro e servidor prontos. Abrindo o Jarvis no navegador...
echo  (Mantenha esta janela aberta enquanto usar. Ctrl+C fecha tudo.)
echo.
node jarvis-web-server.mjs

echo.
echo  Jarvis encerrado.
pause
exit /b 0

:cli
echo.
echo  Abrindo o Jarvis no terminal (modo CLI) ate instalar os requisitos...
if exist "bin\opencode.exe" (
  "bin\opencode.exe" "set me up"
) else (
  echo  bin\opencode.exe nao encontrado. Baixe o OpenCode do site oficial.
)
echo.
pause