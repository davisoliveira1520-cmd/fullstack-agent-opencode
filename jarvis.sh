#!/bin/bash
# Jarvis launcher (macOS / Linux): everything lives inside this repo.
# OpenCode is fetched into bin\ on first run (one binary per OS/arch, kept
# inside this repo, not installed on the machine). Nothing else needed.
# Copyright (C) 2026 Jared Rhodenizer
# SPDX-License-Identifier: AGPL-3.0-or-later

set -euo pipefail
cd "$(dirname "$0")"

BIN="bin/opencode"

if [ ! -x "$BIN" ]; then
  echo "  Jarvis: preparing OpenCode (one-time, inside this repo)..."
  mkdir -p bin tmp

  OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
  ARCH="$(uname -m)"
  case "$ARCH" in
    aarch64|arm64) ARCH="arm64" ;;
    x86_64|amd64)  ARCH="x64" ;;
  esac

  case "$OS:$ARCH" in
    darwin:arm64) FILE="opencode-darwin-arm64.zip" ;;
    darwin:x64)   FILE="opencode-darwin-x64.zip" ;;
    linux:x64)   FILE="opencode-linux-x64.tar.gz" ;;
    linux:arm64) FILE="opencode-linux-arm64.tar.gz" ;;
    *) echo "  Unsupported OS/arch: $OS/$ARCH"; exit 1 ;;
  esac

  URL="https://github.com/anomalyco/opencode/releases/latest/download/$FILE"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL -o "tmp/$FILE" "$URL"
  else
    wget -O "tmp/$FILE" "$URL"
  fi

  case "$FILE" in
    *.zip) unzip -oq "tmp/$FILE" -d tmp ;;
    *.tar.gz) tar -xzf "tmp/$FILE" -C tmp ;;
  esac
  mv -f tmp/opencode "$BIN"
  chmod +x "$BIN"
  rm -rf tmp
fi

echo "  Jarvis: starting OpenCode..."
"$BIN" "set me up"