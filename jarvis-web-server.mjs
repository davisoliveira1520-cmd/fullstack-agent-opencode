#!/usr/bin/env node
import { createServer } from "node:http";
import { readFile, stat } from "node:fs/promises";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import path from "node:path";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const APP_DIR = path.join(__dirname, "docs", "app");
const GATEWAY_PORT = Number(process.env.JARVIS_GATEWAY_PORT || 18789);
const WEB_PORT = Number(process.env.JARVIS_WEB_PORT || 8080);
const GATEWAY_URL = `http://127.0.0.1:${GATEWAY_PORT}`;

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
    res.writeHead(403);
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
    res.writeHead(200, {
      "Content-Type": MIME[ext] || "application/octet-stream",
      "Cache-Control": "no-cache",
    });
    res.end(data);
  } catch {
    res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
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
        res.writeHead(up.status, {
          "Content-Type": up.headers.get("content-type") || "application/json",
        });
        const buf = Buffer.from(await up.arrayBuffer());
        res.end(buf);
      })
      .catch((err) => {
        log("Proxy error: " + err.message);
        res.writeHead(502, { "Content-Type": "application/json; charset=utf-8" });
        res.end(JSON.stringify({ error: { message: "gateway local indisponível" } }));
      });
  });
}

const server = createServer((req, res) => {
  const pathname = decodeURIComponent(new URL(req.url, `http://${req.headers.host}`).pathname);
  if (pathname.startsWith("/v1/")) {
    proxyGateway(req, res);
  } else {
    serveStatic(req, res, pathname);
  }
});

async function main() {
  startGateway();
  await waitForGateway();
  server.listen(WEB_PORT, "127.0.0.1", () => {
    log(`Jarvis Web rodando em http://localhost:${WEB_PORT}  (vá com o navegador!)`);
    log(`Gateway local (OpenClaw/OpenCode): ${GATEWAY_URL}`);
    log(`Pressione Ctrl+C para encerrar tudo.`);
  });
}

main();

process.on("SIGINT", () => {
  log("Encerrando...");
  server.close(() => process.exit(0));
});