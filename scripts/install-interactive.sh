#!/usr/bin/env bash
set -euo pipefail

# AI Workstation Bootstrap — Interactive Installer (macOS)
# Run: bash <(curl -fsSL https://raw.githubusercontent.com/subzone/ai-workstation-bootstrap/main/scripts/install-interactive.sh)

LOG_DIR="$HOME/.ai-bootstrap"
LOG_FILE="$LOG_DIR/install.log"
mkdir -p "$LOG_DIR"

# Resolve config source — clone repo if not running from local checkout
REPO_DIR="$LOG_DIR/repo"
SCRIPT_DIR="${REPO_DIR}/scripts"
CONFIG_SOURCE="${REPO_DIR}/configs"

if [ ! -d "$CONFIG_SOURCE" ]; then
    echo "📦 Downloading bootstrap repository..."
    rm -rf "$REPO_DIR"
    git clone --depth 1 https://github.com/subzone/ai-workstation-bootstrap.git "$REPO_DIR"
else
    echo "📦 Updating bootstrap repository..."
    git -C "$REPO_DIR" pull --ff-only 2>/dev/null || (rm -rf "$REPO_DIR" && git clone --depth 1 https://github.com/subzone/ai-workstation-bootstrap.git "$REPO_DIR")
fi

mkdir -p "$LOG_DIR"
log() { echo "$(date '+%Y-%m-%d %H:%M:%S')  $*" | tee -a "$LOG_FILE"; }

# ─── Colors ───
GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'

ask() {
    local prompt="$1" default="${2:-y}"
    if [[ "$default" == "y" ]]; then
        read -rp "$(echo -e "${BLUE}$prompt [Y/n]:${NC} ")" answer
        [[ "${answer:-y}" =~ ^[Yy]?$ ]]
    else
        read -rp "$(echo -e "${BLUE}$prompt [y/N]:${NC} ")" answer
        [[ "${answer:-n}" =~ ^[Yy]$ ]]
    fi
}

echo -e "${GREEN}"
echo "╔══════════════════════════════════════════════════╗"
echo "║   AI Workstation Bootstrap — Interactive Setup   ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

# ─── IDE Selection ───
echo -e "${YELLOW}── IDE & Editor ──${NC}"
INSTALL_VSCODE=false; INSTALL_INTELLIJ=false; INSTALL_VS=false

ask "VS Code (web/TypeScript/Python devs)" "y" && INSTALL_VSCODE=true
ask "IntelliJ IDEA (Java/Kotlin/Scala devs)" "n" && INSTALL_INTELLIJ=true
ask "Visual Studio (C#/.NET devs)" "n" && INSTALL_VS=true

# ─── Infrastructure Tools ───
echo ""
echo -e "${YELLOW}── Infrastructure & DevOps ──${NC}"
INSTALL_TF=false; INSTALL_K8S=false; INSTALL_ANSIBLE=false; INSTALL_JENKINS=false; INSTALL_AZDO=false

ask "Terraform (IaC)" "n" && INSTALL_TF=true
ask "Kubernetes tools (kubectl, helm, k9s)" "n" && INSTALL_K8S=true
ask "Ansible" "n" && INSTALL_ANSIBLE=true
ask "Jenkins MCP (CI/CD)" "n" && INSTALL_JENKINS=true
ask "Azure DevOps MCP" "n" && INSTALL_AZDO=true

# ─── Productivity Tools ───
echo ""
echo -e "${YELLOW}── AI Productivity ──${NC}"
INSTALL_STANDUP=false; INSTALL_MEETILY=false

ask "Automated Standups (git+jira→standup)" "y" && INSTALL_STANDUP=true
ask "Meeting Transcription (Meetily)" "n" && INSTALL_MEETILY=true

# ─── Model Selection ───
echo ""
echo -e "${YELLOW}── Model Selection ──${NC}"
echo "  Choose your primary chat/coding model:"
echo "    1) qwen3.5:4b      — 3.2GB, fast, good all-rounder (default)"
echo "    2) qwen3.5:9b      — 6.3GB, better reasoning"
echo "    3) glm4:9b         — 5.5GB, strong bilingual"
echo "    4) deepseek-v3:7b  — 4.2GB, strong code + reasoning"
echo "    5) mistral:7b      — 4.1GB, European language support"
echo "    6) granite3.1-dense:8b — 4.9GB, enterprise (IBM)"
echo "    7) llama3.2:3b     — 2.0GB, lightweight/low-RAM"
echo "    8) gemma3:4b       — 3.3GB, Google compact"
read -rp "$(echo -e "${BLUE}  Select [1-8, default 1]:${NC} ")" model_choice

case "${model_choice:-1}" in
    2) PRIMARY_MODEL="qwen3.5:9b" ;;
    3) PRIMARY_MODEL="glm4:9b" ;;
    4) PRIMARY_MODEL="deepseek-v3:7b" ;;
    5) PRIMARY_MODEL="mistral:7b" ;;
    6) PRIMARY_MODEL="granite3.1-dense:8b" ;;
    7) PRIMARY_MODEL="llama3.2:3b" ;;
    8) PRIMARY_MODEL="gemma3:4b" ;;
    *) PRIMARY_MODEL="qwen3.5:4b" ;;
esac
echo -e "  Selected: ${GREEN}$PRIMARY_MODEL${NC}"

echo ""
echo -e "${GREEN}Starting installation...${NC}"
log "=== AI Workstation Bootstrap started ==="
log "Selections: vscode=$INSTALL_VSCODE intellij=$INSTALL_INTELLIJ vs=$INSTALL_VS tf=$INSTALL_TF k8s=$INSTALL_K8S ansible=$INSTALL_ANSIBLE jenkins=$INSTALL_JENKINS azdo=$INSTALL_AZDO standup=$INSTALL_STANDUP meetily=$INSTALL_MEETILY"

# ─── Core: Ollama + Models ───
if ! command -v ollama &>/dev/null; then
    log "Installing Ollama..."
    brew install ollama 2>/dev/null || curl -fsSL https://ollama.com/install.sh | sh
fi
log "Ollama: $(ollama --version)"

pgrep -x ollama >/dev/null || (ollama serve &>/dev/null &); sleep 3

log "Pulling models..."
ollama pull "$PRIMARY_MODEL" 2>/dev/null
ollama pull qwen2.5-coder:1.5b 2>/dev/null
ollama pull nomic-embed-text 2>/dev/null
log "Models ready: $PRIMARY_MODEL + qwen2.5-coder:1.5b + nomic-embed-text"

# ─── IDE Installs ───
if $INSTALL_VSCODE; then
    brew install --cask visual-studio-code 2>/dev/null || true
    mkdir -p "$HOME/Library/Application Support/Code/User"
    # Inject config with selected model
    sed "s/qwen3.5:4b/$PRIMARY_MODEL/g" "$CONFIG_SOURCE/vscode/settings.json" \
        > "$HOME/Library/Application Support/Code/User/settings.json"
    code --install-extension Continue.continue 2>/dev/null || true
    code --install-extension christian-kohler.path-intellisense 2>/dev/null || true
    code --install-extension streetsidesoftware.code-spell-checker 2>/dev/null || true
    log "VS Code + extensions configured with $PRIMARY_MODEL."
fi

if $INSTALL_INTELLIJ; then
    brew install --cask intellij-idea 2>/dev/null || true
    # DevoxxGenie plugin — installed via IDE marketplace on first launch
    log "IntelliJ installed. Install DevoxxGenie plugin: Settings → Plugins → Search 'DevoxxGenie'"
    log "Configure: Settings → DevoxxGenie → Provider: Ollama, Model: qwen3.5:4b"
    cat > "$LOG_DIR/intellij-setup.txt" << 'EOF'
IntelliJ IDEA — AI Setup:
1. Open Settings → Plugins → Marketplace
2. Search "DevoxxGenie" → Install → Restart
3. Settings → Tools → DevoxxGenie:
   - LLM Provider: Ollama
   - Chat Model: qwen3.5:4b
   - Inline Completion Model: qwen2.5-coder:1.5b
   - URL: http://localhost:11434
4. For inline completion: Settings → Plugins → search "Ollama Completion" → Install
EOF
    echo -e "${YELLOW}ℹ️  See ~/.ai-bootstrap/intellij-setup.txt for plugin instructions${NC}"
fi

if $INSTALL_VS; then
    # Visual Studio (full) — LocalPilot extension
    log "Visual Studio: Install LocalPilot extension from VS Marketplace"
    cat > "$LOG_DIR/visualstudio-setup.txt" << 'EOF'
Visual Studio — AI Setup:
1. Extensions → Manage Extensions → Search "LocalPilot"
2. Install "LocalPilot - AI Coding Assistant (Ollama)"
3. Configure: Tools → Options → LocalPilot:
   - Ollama URL: http://localhost:11434
   - Model: qwen2.5-coder:7b
   - Enable Inline Completion: Yes
4. Trigger completion: Ctrl+Alt+C
EOF
    echo -e "${YELLOW}ℹ️  See ~/.ai-bootstrap/visualstudio-setup.txt for plugin instructions${NC}"
fi

# ─── Infrastructure Tools ───
if $INSTALL_TF; then
    brew install terraform 2>/dev/null || true
    log "Terraform installed: $(terraform version -json 2>/dev/null | python3 -c 'import json,sys;print(json.load(sys.stdin).get("terraform_version",""))' 2>/dev/null)"
fi

if $INSTALL_K8S; then
    brew install kubectl helm k9s 2>/dev/null || true
    log "K8s tools installed."
fi

if $INSTALL_ANSIBLE; then
    brew install ansible 2>/dev/null || true
    log "Ansible installed: $(ansible --version 2>/dev/null | head -1)"
fi

# ─── MCP Servers Config ───
OPENCODE_DIR="$HOME/.config/opencode"
mkdir -p "$OPENCODE_DIR"
sed "s/qwen3.5:4b/$PRIMARY_MODEL/g" "$CONFIG_SOURCE/opencode/config.json" > "$OPENCODE_DIR/config.json"

# Build MCP config dynamically based on selections
python3 - "$OPENCODE_DIR/mcp-servers.json" "$INSTALL_K8S" "$INSTALL_TF" "$INSTALL_JENKINS" "$INSTALL_AZDO" << 'PYEOF'
import json, sys
out_path, k8s, tf, jenkins, azdo = sys.argv[1], sys.argv[2]=="true", sys.argv[3]=="true", sys.argv[4]=="true", sys.argv[5]=="true"

servers = {
    "github": {"command": "npx", "args": ["-y", "@modelcontextprotocol/server-github"], "env": {"GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"}},
    "microsoft365": {"command": "npx", "args": ["-y", "@subzone81/ms-365-mcp"], "env": {"MS365_TENANT_ID": "${MS365_TENANT_ID}", "MS365_CLIENT_ID": "${MS365_CLIENT_ID}", "MS365_CLIENT_SECRET": "${MS365_CLIENT_SECRET}"}},
    "jira": {"command": "npx", "args": ["-y", "mcp-server-atlassian"], "env": {"ATLASSIAN_SITE_URL": "${JIRA_URL}", "ATLASSIAN_USER_EMAIL": "${JIRA_EMAIL}", "ATLASSIAN_API_TOKEN": "${JIRA_API_TOKEN}"}},
}
if k8s: servers["kubernetes"] = {"command": "npx", "args": ["-y", "mcp-server-kubernetes"], "env": {"KUBECONFIG": "~/.kube/config"}}
if tf: servers["terraform"] = {"command": "npx", "args": ["-y", "@hashicorp/terraform-mcp-server"], "env": {}}
if jenkins: servers["jenkins"] = {"command": "npx", "args": ["-y", "mcp-jenkins"], "env": {"JENKINS_URL": "${JENKINS_URL}", "JENKINS_USER": "${JENKINS_USER}", "JENKINS_TOKEN": "${JENKINS_TOKEN}"}}
if azdo: servers["azure-devops"] = {"command": "npx", "args": ["-y", "@microsoft/azure-devops-mcp"], "env": {"AZURE_DEVOPS_ORG": "${AZURE_DEVOPS_ORG}", "AZURE_DEVOPS_PAT": "${AZURE_DEVOPS_PAT}"}}

json.dump({"mcpServers": servers}, open(out_path, "w"), indent=2)
print(f"MCP config: {len(servers)} servers", file=sys.stderr)
PYEOF
log "MCP config written."

# ─── Standup + code-rag + switch-model utilities ───
TOOLS_BIN="$HOME/.local/bin"
mkdir -p "$TOOLS_BIN"

# code-rag CLI
cat > "$TOOLS_BIN/code-rag" << WRAPPER
#!/bin/bash
exec uv run --directory ~/.ai-bootstrap/repo/tools/code-rag python3 code_rag.py "\$@"
WRAPPER
chmod +x "$TOOLS_BIN/code-rag"
log "code-rag CLI installed."
if $INSTALL_STANDUP; then
    STANDUP_DIR="$HOME/.local/bin"
    mkdir -p "$STANDUP_DIR"
    cp "$SCRIPT_DIR/../tools/standup/standup.py" "$STANDUP_DIR/standup.py"
    cat > "$STANDUP_DIR/standup" << WRAPPER
#!/bin/bash
exec python3 "$STANDUP_DIR/standup.py" "\$@"
WRAPPER
    chmod +x "$STANDUP_DIR/standup"
    log "Standup tool installed: run 'standup' from any directory"
    echo -e "${GREEN}✅ Run 'standup' to generate your daily update${NC}"
fi

# ─── Meetily ───
if $INSTALL_MEETILY; then
    mkdir -p "$HOME/.config/meetily"
    cp "$CONFIG_SOURCE/meetily/config.toml" "$HOME/.config/meetily/config.toml"
    log "Meetily config deployed."
fi

# ─── Done ───
touch "$LOG_DIR/.installed"
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ AI Workstation Bootstrap complete!       ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo "Next steps:"
echo "  1. Set up MCP tokens: see docs/MCP_SETUP.md"
$INSTALL_INTELLIJ && echo "  2. Configure IntelliJ: see ~/.ai-bootstrap/intellij-setup.txt"
$INSTALL_VS && echo "  2. Configure Visual Studio: see ~/.ai-bootstrap/visualstudio-setup.txt"
echo "  3. Test: opencode chat 'hello'"
echo ""
log "=== Bootstrap completed ==="
