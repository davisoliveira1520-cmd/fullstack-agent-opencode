#!/usr/bin/env node
import { createServer } from "node:http";
import { readFile, stat } from "node:fs/promises";
import { spawn, exec } from "node:child_process";
import { fileURLToPath } from "node:url";
import path from "node:path";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const APP_DIR = path.join(__dirname, "docs", "app");
const GATEWAY_PORT = Number(process.env.JARVIS_GATEWAY_PORT || 18789);
const WEB_PORT = Number(process.env.JARVIS_WEB_PORT || 8080);
const WEB_BIND = process.env.JARVIS_BIND || "127.0.0.1";
const API_TOKEN = process.env.JARVIS_API_TOKEN || "";
const CORS_ORIGIN = process.env.JARVIS_CORS_ORIGIN || "*";
const GATEWAY_URL = `http://127.0.0.1:${GATEWAY_PORT}`;

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": CORS_ORIGIN,
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

function withCORS(head) {
  return { ...CORS_HEADERS, ...head };
}

function authOk(req) {
  if (!API_TOKEN) return true;
  const auth = req.headers.authorization || "";
  return auth === `Bearer ${API_TOKEN}`;
}

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".mjs": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon",
  ".txt": "text/plain; charset=utf-8",
  ".md": "text/markdown; charset=utf-8",
  ".woff2": "font/woff2",
};

function log(...args) {
  console.log(`[jarvis-web]`, ...args);
}

async function fetchModels() {
  const res = await fetch(`${GATEWAY_URL}/v1/models`);
  return res.ok;
}

function startGateway() {
  const cmd = process.env.OPENCLAW_PATH && process.env.OPENCLAW_PATH !== "openclaw"
    ? process.env.OPENCLAW_PATH
    : "openclaw";
  log("Iniciando OpenClaw Gateway: " + cmd);
  const child = spawn(cmd, ["gateway", "run", "--port", String(GATEWAY_PORT), "--allow-unconfigured"], {
    stdio: "inherit",
    env: process.env,
  });
  child.on("exit", (code) => {
    log(`Gateway encerrado (exit ${code}).`);
    process.exit(code ?? 0);
  });
  child.on("error", (err) => {
    log("ERRO ao iniciar o gateway: " + err.message);
    log("Verifique se o OpenClaw está instalado:  npm install -g openclaw@latest");
    process.exit(1);
  });
  return child;
}

async function waitForGateway(timeoutMs = 60000) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    try {
      if (await fetchModels()) {
        log("Gateway pronto em " + GATEWAY_URL);
        return true;
      }
    } catch {
      /* ainda subindo */
    }
    await new Promise((r) => setTimeout(r, 800));
  }
  log(`Aviso: gateway não respondeu em ${GATEWAY_URL} dentro de ${timeoutMs}ms.`);
  return false;
}

async function serveStatic(req, res, pathname) {
  let filePath;
  if (pathname === "/" || pathname === "") {
    filePath = path.join(APP_DIR, "index.html");
  } else {
    filePath = path.join(APP_DIR, pathname.replace(/^\/+/, ""));
  }

  if (!filePath.startsWith(APP_DIR)) {
    res.writeHead(403, withCORS({ "Content-Type": "text/plain; charset=utf-8" }));
    res.end("Forbidden");
    return;
  }

  try {
    const st = await stat(filePath);
    if (st.isDirectory()) {
      filePath = path.join(filePath, "index.html");
    }
    const data = await readFile(filePath);
    const ext = path.extname(filePath).toLowerCase();
    res.writeHead(200, withCORS({
      "Content-Type": MIME[ext] || "application/octet-stream",
      "Cache-Control": "no-cache",
    }));
    res.end(data);
  } catch {
    res.writeHead(404, withCORS({ "Content-Type": "text/plain; charset=utf-8" }));
    res.end("404 Not Found");
  }
}

function proxyGateway(req, res) {
  const target = new URL(req.url, GATEWAY_URL);
  const bodyChunks = [];
  req.on("data", (c) => bodyChunks.push(c));
  req.on("end", () => {
    const headers = { ...req.headers };
    delete headers.host;
    headers["content-type"] = headers["content-type"] || "application/json";
    fetch(target, {
      method: req.method,
      headers,
      body: bodyChunks.length ? Buffer.concat(bodyChunks) : undefined,
    })
      .then(async (up) => {
        res.writeHead(up.status, withCORS({
          "Content-Type": up.headers.get("content-type") || "application/json",
        }));
        const buf = Buffer.from(await up.arrayBuffer());
        res.end(buf);
      })
      .catch((err) => {
        log("Proxy error: " + err.message);
        res.writeHead(502, withCORS({ "Content-Type": "application/json; charset=utf-8" }));
        res.end(JSON.stringify({ error: { message: "gateway local indisponível" } }));
      });
  });
}

const server = createServer((req, res) => {
  const pathname = decodeURIComponent(new URL(req.url, `http://${req.headers.host}`).pathname);
  if (req.method === "OPTIONS") {
    res.writeHead(204, CORS_HEADERS);
    res.end();
    return;
  }
  if (pathname.startsWith("/v1/")) {
    if (!authOk(req)) {
      res.writeHead(401, withCORS({ "Content-Type": "application/json; charset=utf-8" }));
      res.end(JSON.stringify({ error: { message: "token inválido ou ausente" } }));
      return;
    }
    proxyGateway(req, res);
  } else {
    serveStatic(req, res, pathname);
  }
});

function openBrowser(url) {
  const p = process.platform;
  let cmd;
  if (p === "win32") cmd = `cmd /c start "" "${url}"`;
  else if (p === "darwin") cmd = `open "${url}"`;
  else cmd = `xdg-open "${url}" >/dev/null 2>&1`;
  exec(cmd, (err) => {
    if (err) log("Não consegui abrir o navegador automaticamente. Abra manualmente: " + url);
  });
}

async function main() {
  startGateway();
  server.listen(WEB_PORT, WEB_BIND, () => {
    log(`Jarvis Web rodando em http://${WEB_BIND}:${WEB_PORT}`);
    log(`Gateway local (OpenClaw/OpenCode): ${GATEWAY_URL}`);
    log(API_TOKEN ? "Auth habilitada (Bearer token)." : "AVISO: sem JARVIS_API_TOKEN, API aberta.");
    if (WEB_BIND === "127.0.0.1") {
      log(`Abrindo o navegador... (a janela desta etapa fica aberta; Ctrl+C encerra).`);
      setTimeout(() => openBrowser(`http://localhost:${WEB_PORT}`), 1000);
    }
  });
  waitForGateway();
}

main();

process.on("SIGINT", () => {
  log("Encerrando...");
  server.close(() => process.exit(0));
});