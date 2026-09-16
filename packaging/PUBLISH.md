# Publicação oficial do Jarvis

O que já está pronto neste repo:

- `packaging/winget/manifests/...` — manifests para o Windows Package Manager (winget)
- `brew/jarvis.rb` — formula Homebrew (tap)
- `packaging/jarvis.zip` — pacote de instalação (não vai pro git; é o asset do Release)

SHA256 do pacote atual: `a84ea08d15b5d87a7ce4b3c4a8a731359b41a0a487351e565b1e1ccfc1657977`
URL esperada pelos manifests: https://github.com/davisoliveira1520-cmd/fullstack-agent-opencode/releases/download/v1.0.0/jarvis.zip

## 1. Criar o GitHub Release (versão 1.0.0)

1. Entre em https://github.com/davisoliveira1520-cmd/fullstack-agent-opencode/releases/new
2. Tag: `v1.0.0` (já existe e foi enviada)
3. Título: `v1.0.0`
4. Nos **Assets**, faça upload de `packaging/jarvis.zip` (56 MB — o mesmo arquivo local, não regerere; só funciona se for byte a byte igual ao SHA256 acima)
5. Publica o Release

O URL do zip vira exatamente: `https://github.com/davisoliveira1520-cmd/fullstack-agent-opencode/releases/download/v1.0.0/jarvis.zip`

## 2. Testar localmente

```powershell
# winget
winget validate "packaging\winget\manifests\d\davisoliveira1520-cmd\Jarvis\1.0.0"
winget install --manifest "packaging\winget\manifests\d\davisoliveira1520-cmd\Jarvis\1.0.0"

# Homebrew (após o tap existir)
brew install --build-from-source jarvis
```

## 3. Publicar no winget (Windows)

1. Faça fork de `https://github.com/microsoft/winget-pkgs`
2. Copie a pasta `manifests/` para o fork:
   ```
   manifests/d/davisoliveira1520-cmd/Jarvis/1.0.0/
   ```
3. Abra um PR para `microsoft/winget-pkgs` (bot valida automaticamente)
4. Aprovado → `winget install davisoliveira1520-cmd.Jarvis`

## 4. Publicar no Homebrew (macOS / Linux)

Opção A — tap pessoal (rápido, não precisa de aprovação):

1. Crie um repo novo `homebrew-jarvis` em `https://github.com/new` (nome: `homebrew-jarvis`)
2. Nele, adicione a pasta `Formula/` com o conteúdo de `brew/jarvis.rb` (dentro de `Formula/jarvis.rb`)
3. Para instalar:
   ```
   brew tap davisoliveira1520-cmd/jarvis
   brew install jarvis
   ```

Opção B — fórmula oficial `brew install jarvis` (precisa de review da comunidade):

> A Homebrew removeu o formula stub. O caminho oficial é o **tap pessoal** (A). Para inclusão no núcleo, consulte https://docs.brew.sh/Adding-Software-to-Homebrew

## Notas

- **Non-interactive**: o `jarvis.bat`/`jarvis.sh` baixa o binário do OpenCode para `bin/` na primeira execução somente se o SO não for Windows, ou o zip não estiver disponível — veja `jarvis.sh`/`jarvis.bat`.
- Ao gerar uma versão nova (1.1.0 etc.): repita o passo 1 com a nova tag, mantenha o `jarvis.zip` imutável, atualize `PackageVersion` nos três arquivos do manifesto e crie a branch de manifest `1.1.0`.