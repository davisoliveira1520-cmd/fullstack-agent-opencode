"use strict";

/* ============================================================
   Jarvis Web — Assistente por voz
   - Chat com IA (OpenRouter / OpenAI / HuggingFace)
   - Comando de voz via Web Speech API (SpeechRecognition + TTS)
   - Criação de apps: o Jarvis gera um HTML único que pode ser
     baixado quando você pede algo como "crie um app de X"
   ============================================================ */

const DEFAULTS = {
  provider: "local",
  model: "openclaw",
  modelHelp: {
    local: "modo local: usa o OpenClaw/OpenCode da sua máquina (sem chave)",
    openrouter: "ex.: openai/gpt-4o-mini, anthropic/claude-3.5-sonnet, deepseek/deepseek-chat",
    openai: "ex.: gpt-4o-mini",
    huggingface: "ex.: Qwen/Qwen3-Coder-30B-A3B-Instruct (ou use OpenRouter)",
  },
  // Personalidade padrão do Jarvis (voz de assistente pessoal)
  persona:
    "Você é o Jarvis, um assistente pessoal de inteligência artificial. " +
    "Tenha uma personalidade elegante, inteligente, prestativa e um pouco sarcástica de vez em quando. " +
    "Responda de forma clara e direta. Quando o usuário pedir para 'criar um app', " +
    "gere um arquivo HTML único e completo (com CSS e JS embutidos) que funcione sozinho. " +
    "Embrulhe o código HTML em um bloco ```html ... ``` para que o usuário possa baixá-lo.",
};

const GATEWAY_LOCAL = "http://localhost:18789";

function localGatewayBase() {
  const h = location.hostname;
  if (h === "localhost" || h === "127.0.0.1" || h === "[::1]" || location.protocol === "https:") {
    return location.origin;
  }
  return GATEWAY_LOCAL;
}

const PROVIDERS = {
  local: {
    url: `${GATEWAY_LOCAL}/v1/chat/completions`,
    requiresKey: false,
    headers: () => ({ "Content-Type": "application/json" }),
    body: (model, messages) => ({ model, messages }),
  },
  openrouter: {
    url: "https://openrouter.ai/api/v1/chat/completions",
    requiresKey: true,
    headers: (key) => ({ Authorization: `Bearer ${key}`, "Content-Type": "application/json" }),
    body: (model, messages) => ({ model, messages }),
  },
  openai: {
    url: "https://api.openai.com/v1/chat/completions",
    requiresKey: true,
    headers: (key) => ({ Authorization: `Bearer ${key}`, "Content-Type": "application/json" }),
    body: (model, messages) => ({ model, messages }),
  },
  huggingface: {
    url: "https://router.huggingface.co/v1/chat/completions",
    requiresKey: true,
    headers: (key) => ({ Authorization: `Bearer ${key}`, "Content-Type": "application/json" }),
    body: (model, messages) => ({ model, messages }),
  },
};

/* ---------------- Estado ---------------- */
const state = {
  settings: loadSettings(),
  chats: loadChats(),
  activeChatId: null,
  listening: false,
  speechOn: true,
  busy: false,
};

function loadSettings() {
  try {
    return JSON.parse(localStorage.getItem("jarvis-settings") || "null") || {};
  } catch {
    return {};
  }
}

function saveSettings() {
  localStorage.setItem("jarvis-settings", JSON.stringify(state.settings));
}

function loadChats() {
  try {
    const c = JSON.parse(localStorage.getItem("jarvis-chats") || "[]");
    return Array.isArray(c) ? c : [];
  } catch {
    return [];
  }
}

function saveChats() {
  localStorage.setItem("jarvis-chats", JSON.stringify(state.chats));
}

/* ---------------- Eléments ---------------- */
const $ = (s) => document.querySelector(s);
const chatListEl = $("#chats");
const messagesEl = $("#messages");
const inputEl = $("#input");
const sendBtn = $("#send-btn");
const micBtn = $("#mic-btn");
const statusDot = $("#status-dot");
const statusText = $("#status-text");
const headerModel = $("#header-model");
const voiceToggle = $("#voice-toggle");
const darkToggle = $("#dark-toggle");
const iconDark = $("#icon-dark");
const iconMoon = $("#icon-moon");
const settingsModal = $("#settings-modal");
const settingsForm = $("#settings-form");

/* ---------------- Inicialização ---------------- */
function init() {
  applySettingsToUI();
  applyTheme();
  voiceToggle.classList.toggle("active", state.speechOn);
  renderChatList();
  if (state.chats.length === 0) {
    newChat();
  } else {
    setActiveChat(state.chats[0].id);
  }
  bindEvents();
  updateStatus("on", state.busy ? "processando" : "online");
  checkLocalGateway();
}

async function checkLocalGateway() {
  if ((state.settings.provider || "local") !== "local") return;
  const ok = await reachableLocalGateway();
  if (ok) {
    statusDot.className = "dot on";
    statusText.textContent = "Jarvis local conectado";
    headerModel.textContent = "◉ OpenCode/OpenClaw local conectado";
  } else {
    statusDot.className = "dot";
    statusText.textContent = "jarvis-server não está rodando";
  }
}

function bindEvents() {
  sendBtn.addEventListener("click", () => sendCurrentMessage());
  inputEl.addEventListener("keydown", (e) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      sendCurrentMessage();
    }
  });
  micBtn.addEventListener("click", toggleListening);
  voiceToggle.addEventListener("click", () => {
    state.speechOn = !state.speechOn;
    voiceToggle.classList.toggle("active", state.speechOn);
    if (!state.speechOn && window.speechSynthesis) speechSynthesis.cancel();
  });
  darkToggle.addEventListener("click", toggleTheme);
  $("#new-chat").addEventListener("click", () => newChat());
  $("#open-settings").addEventListener("click", () => openSettings());
  messagesEl.addEventListener("click", (e) => {
    const copyBtn = e.target.closest("[data-copy]");
    if (copyBtn) copyCode(copyBtn.dataset.copy);
    const dl = e.target.closest("[data-download-app]");
    if (dl) downloadApp(dl.dataset.downloadApp);
  });
  $("#chips").addEventListener("click", (e) => {
    const chip = e.target.closest(".chip");
    if (chip) {
      inputEl.value = chip.dataset.prompt;
      sendCurrentMessage();
    }
  });
  $("#provider").addEventListener("change", (e) => {
    const p = e.target.value;
    $("#model-help").textContent = DEFAULTS.modelHelp[p] || "";
    $("#model").placeholder = DEFAULTS.modelHelp[p] || "";
    toggleApiKeyField(p);
    updateLocalStatus(p);
  });
}

function toggleApiKeyField(provider) {
  const keyLabel = $("#api-key-label");
  if (!keyLabel) return;
  keyLabel.classList.toggle("hidden", provider === "local");
}

async function updateLocalStatus(provider) {
  const el = $("#local-status");
  if (!el) return;
  if (provider !== "local") {
    el.style.display = "none";
    return;
  }
  el.style.display = "block";
  el.className = "hint";
  el.textContent = "Verificando o servidor local…";
  const ok = await reachableLocalGateway();
  if (ok) {
    el.className = "hint ok";
    el.textContent = "✓ Jarvis local (OpenCode/OpenClaw) conectado em " + localGatewayBase();
  } else {
    el.className = "hint off";
    el.textContent = "✗ Servidor local não está rodando aqui. No seu PC, rode jarvis-server.bat (Windows) ou ./jarvis-server.sh e abra http://localhost:8080. Ou use um provedor de nuvem abaixo.";
  }
}

/* ---------------- Tema ---------------- */
function applyTheme() {
  const dark = localStorage.getItem("jarvis-theme") !== "light";
  document.body.dataset.theme = dark ? "dark" : "light";
  iconDark.style.display = dark ? "none" : "block";
  iconMoon.style.display = dark ? "block" : "none";
}

function toggleTheme() {
  localStorage.setItem("jarvis-theme", document.body.dataset.theme === "dark" ? "light" : "dark");
  applyTheme();
}

/* ---------------- Configurações ---------------- */
function openSettings() {
  const s = state.settings;
  $("#provider").value = s.provider || DEFAULTS.provider;
  $("#model").value = s.model || "";
  $("#api-key").value = s.apiKey || "";
  $("#persona").value = s.persona || DEFAULTS.persona;
  $("#model-help").textContent = DEFAULTS.modelHelp[$("#provider").value] || "";
  $("#model").placeholder = DEFAULTS.modelHelp[$("#provider").value] || "";
  toggleApiKeyField($("#provider").value);
  updateLocalStatus($("#provider").value);
  settingsModal.showModal();
}

settingsForm.addEventListener("close", () => {
  if (settingsForm.returnValue === "default") {
    state.settings.provider = $("#provider").value;
    state.settings.model = $("#model").value.trim();
    state.settings.apiKey = $("#api-key").value.trim();
    state.settings.persona = $("#persona").value.trim();
    saveSettings();
    applySettingsToUI();
    toast("Configurações salvas");
    checkLocalGateway();
  }
});

function applySettingsToUI() {
  const p = state.settings.provider || "local";
  const m = state.settings.model;
  if (p === "local") {
    headerModel.textContent = "◉ OpenCode/OpenClaw local";
  } else if (m && p) {
    headerModel.textContent = `${p} · ${m}`;
  } else {
    headerModel.textContent = "modelo não configurado";
  }
}

/* ---------------- Chat ---------------- */
function newChat() {
  const chat = { id: uid(), title: "Nova conversa", messages: [], createdAt: Date.now() };
  state.chats.unshift(chat);
  saveChats();
  setActiveChat(chat.id);
  renderChatList();
  messagesEl.innerHTML = "";
  showWelcome();
}

function getActiveChat() {
  return state.chats.find((c) => c.id === state.activeChatId) || null;
}

function setActiveChat(id) {
  state.activeChatId = id;
  const chat = getActiveChat();
  renderChatList();
  messagesEl.innerHTML = "";
  if (!chat) return;
  const initial = chat.messages || [];
  if (initial.length === 0) {
    showWelcome();
    return;
  }
  for (const m of initial) {
    appendMessageEl(m.role, m.content, { skipSave: true, fromHistory: true });
  }
  scrollBottom();
}

function renderChatList() {
  chatListEl.innerHTML = "";
  for (const c of state.chats) {
    const item = document.createElement("button");
    item.className = "chat-item" + (c.id === state.activeChatId ? " active" : "");
    const titleEl = document.createElement("span");
    titleEl.textContent = c.title;
    const del = document.createElement("button");
    del.className = "del";
    del.textContent = "✕";
    del.addEventListener("click", (e) => {
      e.stopPropagation();
      deleteChat(c.id);
    });
    item.appendChild(titleEl);
    item.appendChild(del);
    item.addEventListener("click", () => setActiveChat(c.id));
    chatListEl.appendChild(item);
  }
}

function deleteChat(id) {
  if (state.chats.length === 1) {
    state.chats = [];
    saveChats();
    newChat();
    return;
  }
  state.chats = state.chats.filter((c) => c.id !== id);
  saveChats();
  const next = state.chats[0];
  setActiveChat(next.id);
}

function showWelcome() {
  messagesEl.innerHTML = `
    <div class="msg bot">
      <div class="avatar">J</div>
      <div class="bubble">
        <div class="typearea">
          <p>Olá, sou o <strong>Jarvis</strong>. Posso conversar, programar e <strong>criar apps</strong> por texto ou por voz.</p>
          <p>Experimente: <em>"crie um app de lista de tarefas"</em> — eu gero um app HTML pronto para baixar.</p>
        </div>
      </div>
    </div>`;
  const ta = messagesEl.querySelector(".typearea");
  typeWriter(ta, "Olá, sou o Jarvis. Posso conversar, programar e criar apps por texto ou por voz. Pode me pedir por voz: 'crie um app de lista de tarefas' — eu gero um app pronto.");
}

/* ---------------- Mensagens ---------------- */
function addMessage(role, content) {
  const chat = getActiveChat();
  if (!chat) return;
  chat.messages.push({ role, content });
  if (chat.title === "Nova conversa") {
    chat.title = makeTitle(content);
  }
  saveChats();
  renderChatList();
}

function makeTitle(content) {
  const clean = content.replace(/```[\s\S]*?```/g, "").trim();
  const first = clean.split("\n")[0] || "";
  return first.length > 42 ? first.slice(0, 42) + "…" : first || "Nova conversa";
}

function appendMessageEl(role, content, opts = {}) {
  const wrap = document.createElement("div");
  wrap.className = `msg ${role === "user" ? "user" : "bot"}`;
  const avatar = document.createElement("div");
  avatar.className = "avatar";
  avatar.textContent = role === "user" ? "EU" : "J";
  const bubble = document.createElement("div");
  bubble.className = "bubble";
  bubble.innerHTML = renderContent(content);
  wrap.appendChild(avatar);
  wrap.appendChild(bubble);
  messagesEl.appendChild(wrap);
  scrollBottom();
  return bubble;
}

/* Renderiza markdown leve + blocos ```html → botão de copiar */
function renderContent(content) {
  let out = escapeHtml(content);
  // extrai apps (```html ... ```)
  const codeBlocks = [];
  out = out.replace(/```html\s*([\s\S]*?)```/g, (m, code) => {
    const idx = codeBlocks.length;
    codeBlocks.push(code.trim());
    return `{{{CODE_BLOCK_${idx}}}}`;
  });
  out = out.replace(/```(\w+)?\s*([\s\S]*?)```/g, (m, lang, code) => {
    const idx = codeBlocks.length;
    codeBlocks.push({ lang: lang || "", code: code.trim() });
    return `{{{CODE_BLOCK_${idx}}}}`;
  });

  out = out
    .replace(/^### (.*)$/gm, "<h3>$1</h3>")
    .replace(/^## (.*)$/gm, "<h2>$1</h2>")
    .replace(/^# (.*)$/gm, "<h1>$1</h1>")
    .replace(/\*\*(.*?)\*\*/g, "<strong>$1</strong>")
    .replace(/(^|\s)\*([^*\n]+)\*/g, "$1<em>$2</em>")
    .replace(/\n/g, "<br/>");

  for (let i = 0; i < codeBlocks.length; i++) {
    const b = codeBlocks[i];
    const codeHtml = escapeHtml(b.code || b);
    const isApp = typeof b === "object" ? false : true;

    let card = "";
    if (typeof b === "object" && b.code) {
      card = `
      <div class="code-block-head">
        <span>${b.lang || "código"}</span>
        <button data-copy="${i}">Copiar</button>
      </div>`;
    }
    const appCard = isApp ? `
      <div class="app-card">
        <span class="app-title">App gerado pelo Jarvis</span>
        <span class="app-desc">HTML único, pronto para usar</span>
        <span class="app-actions">
          <button class="btn primary" data-download-app="${i}">⬇ Baixar app</button>
          <button class="btn" data-copy="${i}">Copiar código</button>
        </span>
      </div>` : "";

    out = out.replace(`{{{CODE_BLOCK_${i}}}}`,
      `${card}<pre><code>${codeHtml}</code></pre>${appCard}`);
  }
  return out;
}

function copyCode(i) {
  const chat = getActiveChat();
  const block = extractBlock(chat.messages, i);
  if (!block) return;
  navigator.clipboard.writeText(block).then(() => toast("Código copiado!"));
}

function downloadApp(i) {
  const chat = getActiveChat();
  const block = extractBlock(chat.messages, i);
  if (!block) return;
  const blob = new Blob([block], { type: "text/html" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `jarvis-app-${Date.now().toString(36)}.html`;
  a.click();
  URL.revokeObjectURL(url);
  toast("App baixado! Abra o .html em qualquer navegador.");
}

function extractBlock(messages, i) {
  const blocks = [];
  for (const m of messages) {
    if (m.role !== "assistant") continue;
    const re = /```(?:html)?\s*([\s\S]*?)```/g;
    let x;
    while ((x = re.exec(m.content))) blocks.push(x[1].trim());
  }
  return blocks[i] || null;
}

/* ---------------- Envio ---------------- */
async function sendCurrentMessage() {
  const text = inputEl.value.trim();
  if (!text || state.busy) return;
  inputEl.value = "";
  autoResize();
  await sendMessage(text);
}

async function sendMessage(text) {
  if (state.busy) return;
  const chat = getActiveChat();
  if (!chat) return;

  // remove welcome
  const welcome = messagesEl.querySelector(".welcome");
  if (welcome) welcome.remove();

  appendMessageEl("user", text, {});
  addMessage("user", text);
  state.busy = true;
  updateStatus("busy", "processando…");

  const typing = showTyping();

  try {
    const reply = await callAI(chat.messages);
    typing.remove();
    appendMessageEl("assistant", reply, {});
    addMessage("assistant", reply);
    if (state.speechOn) speak(reply);
  } catch (err) {
    typing.remove();
    appendMessageEl("assistant", `⚠️ ${err.message}`);
  } finally {
    state.busy = false;
    updateStatus("on", "online");
  }
}

function showTyping() {
  const wrap = document.createElement("div");
  wrap.className = "msg bot";
  wrap.innerHTML = `
    <div class="avatar">J</div>
    <div class="bubble typing">Jarvis está pensando<span class="td"><i></i><i></i><i></i></span></div>`;
  messagesEl.appendChild(wrap);
  scrollBottom();
  return wrap;
}

/* ---------------- IA ---------------- */
async function callAI(messages) {
  const s = state.settings;
  let provider = PROVIDERS[s.provider] || PROVIDERS.local;
  const model = s.model || DEFAULTS.model;
  const sys = s.persona || DEFAULTS.persona;

  // Habilita "criar app": o Jarvis responde com HTML puro quando o pedido é um app
  const lastUser = [...messages].reverse().find((m) => m.role === "user");
  const systemText = sys + (lastUser && /(cri(ar|e|ei)|faz|faça|ger(ar|a|e)) .*(app|site|calculadora|lista)/i.test(lastUser.content)
    ? " Se o pedido for criar um app, responda APENAS com um bloco ```html contendo o app completo (CSS e JS embutidos), sem texto fora do bloco."
    : "");

  const payload = {
    messages: [{ role: "system", content: systemText }, ...messages.map((m) => ({ role: m.role, content: m.content }))],
    max_tokens: 4000,
    stream: false,
  };

  // Passo 1: tenta o gateway local (OpenClaw/OpenCode) — sem chave
  if (provider.requiresKey === false || !s.apiKey || !PROVIDERS[s.provider]) {
    try {
      return await chatCompletions(PROVIDERS.local, "local", model, payload);
    } catch (err) {
      // gateway local fora do ar
    }
    // Passo 2 (fallback): nuvem, se o usuário tiver chave configurada
    if (s.apiKey && PROVIDERS[s.provider] && PROVIDERS[s.provider].requiresKey) {
      provider = PROVIDERS[s.provider];
      try {
        return await chatCompletions(provider, s.provider, model, payload);
      } catch (err) {
        throw err;
      }
    }
    throw new Error(
      "O Jarvis local (OpenCode/OpenClaw) não está rodando aqui.\n" +
      "No seu PC, rode jarvis-server.bat (Windows) ou ./jarvis-server.sh e abra http://localhost:8080.\n" +
      "Dica: para usar sem precisar do servidor, escolha um provedor (ex.: OpenRouter) nas Configurações e cole a chave."
    );
  }

  // provedor de nuvem escolhido com chave
  if (!s.apiKey) {
    throw new Error("Configure a chave da API nas Configurações.");
  }
  return await chatCompletions(provider, s.provider, model, payload);
}

async function chatCompletions(provider, name, model, payload) {
  if (name === "local" && !(await reachableLocalGateway())) {
    throw new Error("jarvis-server não está rodando. Abra http://localhost:8080 no navegador (ou rode jarvis-server.bat/.sh) e tente de novo.");
  }
  const url = name === "local" ? `${localGatewayBase()}/v1/chat/completions` : provider.url;
  const res = await fetch(url, {
    method: "POST",
    headers: provider.headers(name === "local" ? "" : state.settings.apiKey),
    body: JSON.stringify(provider.body(model, payload.messages)),
  });

  if (!res.ok) {
    let msg = `HTTP ${res.status}`;
    try {
      const j = await res.json();
      msg = (j.error && (j.error.message || j.error)) || j.message || msg;
    } catch {}
    throw new Error(`Erro da API (${res.status}): ${msg}`);
  }
  const data = await res.json();
  const content = data.choices && data.choices[0] && data.choices[0].message && data.choices[0].message.content;
  if (!content) throw new Error("Resposta vazia da API.");
  return content;
}

async function reachableLocalGateway() {
  const bases = [localGatewayBase(), GATEWAY_LOCAL];
  for (const base of bases) {
    try {
      const ctrl = new AbortController();
      const t = setTimeout(() => ctrl.abort(), 1500);
      const r = await fetch(`${base}/v1/models`, { signal: ctrl.signal });
      clearTimeout(t);
      if (r.ok) return true;
    } catch {
      clearTimeout(t);
    }
  }
  return false;
}

/* ---------------- Voz ---------------- */
let recognition = null;
let recognitionRunning = false;
let finalTranscript = "";

function toggleListening() {
  if (recognitionRunning) {
    stopListening();
    return;
  }
  startListening();
}

function startListening() {
  const SR = window.SpeechRecognition || window.webkitSpeechRecognition;
  if (!SR) {
    toast("Seu navegador não suporta comando de voz (use Chrome/Edge).");
    return;
  }
  if (!recognition) {
    recognition = new SR();
    recognition.lang = "pt-BR";
    recognition.continuous = true;
    recognition.interimResults = true;

    recognition.onresult = (e) => {
      let interim = "";
      for (let i = e.resultIndex; i < e.results.length; i++) {
        const t = e.results[i][0].transcript;
        if (e.results[i].isFinal) finalTranscript += t;
        else interim += t;
      }
      inputEl.value = (finalTranscript + interim).trim();
      autoResize();
      listenForCommand(finalTranscript + interim);
    };

    recognition.onerror = (e) => {
      if (e.error === "not-allowed") {
        toast("Permissão de microfone negada. Autorize no navegador.");
      }
      stopListening(true);
    };

    recognition.onend = () => {
      if (recognitionRunning) {
        if (finalTranscript.trim().length > 0 && !state.busy) {
          sendMessage(finalTranscript.trim());
        }
        finalTranscript = "";
      }
    };
  }
  finalTranscript = "";
  inputEl.value = "";
  recognitionRunning = true;
  micBtn.classList.add("active");
  toast("🎙 Ouvindo… fale ou digite o comando");
  updateStatus("busy", "ouvindo…");
  try {
    recognition.start();
  } catch {}
}

function stopListening(reset) {
  recognitionRunning = false;
  micBtn.classList.remove("active");
  if (recognition) {
    try { recognition.stop(); } catch {}
  }
  if (reset) return;
  if (finalTranscript.trim().length > 0 && !state.busy) {
    sendMessage(finalTranscript.trim());
  }
  finalTranscript = "";
}

/* Comandos de voz especiais */
function listenForCommand(text) {
  const t = text.trim().toLowerCase();
  // "limpe" → limpar conversa
  if (/\blimpa\b/.test(t) && /\b(conversa|tudo|chat)\b/.test(t)) {
    stopListening();
    inputEl.value = "";
    getActiveChat().messages = [];
    saveChats();
    messagesEl.innerHTML = "";
    showWelcome();
    toast("Conversa limpa");
  }
  // "configurações" → abre menu
  if (/\bconfigura[cç][õo]es\b/.test(t)) {
    stopListening();
    openSettings();
  }
}

/* Leitura em voz */
function speak(text) {
  if (!("speechSynthesis" in window) || !state.speechOn) return;
  speechSynthesis.cancel();
  // remove código e markdown grosseiro antes de falar
  const clean = text
    .replace(/```[\s\S]*?```/g, "bloco de código gerado.")
    .replace(/[`*_#>]/g, "")
    .replace(/\n+/g, " ")
    .slice(0, 2200);
  const u = new SpeechSynthesisUtterance(clean);
  u.lang = "pt-BR";
  u.rate = 1.02;
  u.pitch = 0.95;
  const voices = speechSynthesis.getVoices();
  const br = voices.find((v) => v.lang === "pt-BR");
  if (br) u.voice = br;
  speechSynthesis.speak(u);
}

/* ---------------- Utilitários ---------------- */
function uid() {
  return Date.now().toString(36) + Math.random().toString(36).slice(2, 8);
}

function escapeHtml(s) {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function scrollBottom() {
  messagesEl.scrollTop = messagesEl.scrollHeight;
}

function autoResize() {
  inputEl.style.height = "auto";
  inputEl.style.height = Math.min(inputEl.scrollHeight, 180) + "px";
}

function updateStatus(state_, text) {
  statusDot.className = "dot " + (state_ === "on" ? "on" : state_ === "busy" ? "busy" : "");
  statusText.textContent = text;
}

let toastTimer = null;
function toast(msg) {
  const el = $("#toast");
  el.textContent = msg;
  el.classList.add("show");
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => el.classList.remove("show"), 3200);
}

function typeWriter(el, text) {
  if (!el) return;
  const speed = 12;
  let i = 0;
  const f = () => {
    if (i > text.length) { el.innerHTML = el.innerHTML.replace(/\u200B$/, ""); return; }
    if (i < text.length) {
      el.textContent = text.slice(0, i) + "\u200B";
      i += 3;
      setTimeout(f, speed);
    }
  };
  f();
}

/* ---------------- Boot ---------------- */
init();