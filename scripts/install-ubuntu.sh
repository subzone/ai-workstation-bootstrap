#!/usr/bin/env bash
set -euo pipefail

# AI Workstation Bootstrap — Linux (Ubuntu/Debian/Fedora)
# Run: bash <(curl -fsSL https://raw.githubusercontent.com/subzone/ai-workstation-bootstrap/main/scripts/install-ubuntu.sh)
# Or:  git clone ... && bash scripts/install-ubuntu.sh

LOG_DIR="${HOME}/.ai-bootstrap"
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
fi

mkdir -p "$LOG_DIR"
log() { echo "$(date '+%Y-%m-%d %H:%M:%S')  $*" | tee -a "$LOG_FILE"; }

# ─── Colors ───
GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

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
echo "║   AI Workstation Bootstrap — Linux Setup         ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

# ─── Pre-flight ───
RAM_GB=$(free -g 2>/dev/null | awk '/Mem:/{print $2}' || echo "8")
log "=== AI Workstation Bootstrap started ==="
log "RAM: ${RAM_GB}GB | User: $(whoami) | Machine: $(hostname)"

if [ "$RAM_GB" -lt 4 ]; then
    echo -e "${RED}ERROR: Need at least 4GB RAM. You have ${RAM_GB}GB.${NC}"
    exit 1
elif [ "$RAM_GB" -lt 16 ]; then
    echo -e "${YELLOW}⚠️  ${RAM_GB}GB RAM detected. Will use lightweight models.${NC}"
fi

# Detect package manager
if command -v apt-get &>/dev/null; then
    PKG="apt"
elif command -v dnf &>/dev/null; then
    PKG="dnf"
elif command -v pacman &>/dev/null; then
    PKG="pacman"
else
    echo -e "${RED}Unsupported package manager. Install manually.${NC}"; exit 1
fi
log "Package manager: $PKG"

# ─── IDE Selection ───
echo -e "${YELLOW}── IDE & Editor ──${NC}"
INSTALL_VSCODE=false; INSTALL_INTELLIJ=false

ask "VS Code" "y" && INSTALL_VSCODE=true
ask "IntelliJ IDEA (JetBrains Toolbox)" "n" && INSTALL_INTELLIJ=true

# ─── Infrastructure Tools ───
echo ""
echo -e "${YELLOW}── Infrastructure & DevOps ──${NC}"
INSTALL_TF=false; INSTALL_K8S=false; INSTALL_ANSIBLE=false

ask "Terraform" "n" && INSTALL_TF=true
ask "Kubernetes tools (kubectl, helm, k9s)" "n" && INSTALL_K8S=true
ask "Ansible" "n" && INSTALL_ANSIBLE=true

# ─── Productivity ───
echo ""
echo -e "${YELLOW}── AI Productivity ──${NC}"
INSTALL_STANDUP=false
ask "Automated Standups" "y" && INSTALL_STANDUP=true

# ─── Model Selection ───
echo ""
echo -e "${YELLOW}── Model Selection ──${NC}"
echo "  Choose your primary model:"
echo "    1) qwen3.5:4b      — 3.2GB (default)"
echo "    2) qwen3.5:9b      — 6.3GB, better reasoning"
echo "    3) glm4:9b         — 5.5GB, bilingual"
echo "    4) deepseek-v3:7b  — 4.2GB, code + reasoning"
echo "    5) mistral:7b      — 4.1GB, European languages"
echo "    6) granite3.1-dense:8b — 4.9GB, enterprise (IBM)"
echo "    7) llama3.2:3b     — 2.0GB, lightweight"
echo "    8) gemma3:4b       — 3.3GB, Google"
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
log "Selections: vscode=$INSTALL_VSCODE intellij=$INSTALL_INTELLIJ tf=$INSTALL_TF k8s=$INSTALL_K8S ansible=$INSTALL_ANSIBLE standup=$INSTALL_STANDUP model=$PRIMARY_MODEL"

# ─── Core: Ollama ───
if ! command -v ollama &>/dev/null; then
    log "Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
fi
log "Ollama: $(ollama --version 2>&1)"

# Start Ollama
if command -v systemctl &>/dev/null && systemctl is-active ollama &>/dev/null; then
    log "Ollama already running via systemd."
elif pgrep -x ollama &>/dev/null; then
    log "Ollama already running."
else
    log "Starting Ollama..."
    nohup ollama serve &>/dev/null &
    sleep 5
fi

# Pull models
log "Pulling $PRIMARY_MODEL..."
ollama pull "$PRIMARY_MODEL"
log "Pulling qwen2.5-coder:1.5b (autocomplete)..."
ollama pull qwen2.5-coder:1.5b
log "Pulling nomic-embed-text (embeddings)..."
ollama pull nomic-embed-text
log "Models ready."

# ─── IDE Install ───
if $INSTALL_VSCODE; then
    if ! command -v code &>/dev/null; then
        log "Installing VS Code..."
        case $PKG in
            apt)
                wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/ms.gpg
                sudo install -o root -g root -m 644 /tmp/ms.gpg /usr/share/keyrings/microsoft-archive-keyring.gpg
                echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
                sudo apt-get update -qq && sudo apt-get install -y -qq code ;;
            dnf) sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
                 sudo dnf install -y code ;;
            pacman) sudo pacman -S --noconfirm code ;;
        esac
    fi
    # Config
    VSCODE_DIR="$HOME/.config/Code/User"
    mkdir -p "$VSCODE_DIR"
    sed "s/qwen3.5:4b/$PRIMARY_MODEL/g" "$CONFIG_SOURCE/vscode/settings.json" > "$VSCODE_DIR/settings.json"
    code --install-extension Continue.continue 2>/dev/null || true
    code --install-extension christian-kohler.path-intellisense 2>/dev/null || true
    code --install-extension streetsidesoftware.code-spell-checker 2>/dev/null || true
    log "VS Code configured with $PRIMARY_MODEL."
fi

if $INSTALL_INTELLIJ; then
    if ! command -v jetbrains-toolbox &>/dev/null; then
        log "Installing JetBrains Toolbox..."
        wget -qO /tmp/jetbrains-toolbox.tar.gz "https://data.services.jetbrains.com/products/download?platform=linux&code=TBA"
        tar -xzf /tmp/jetbrains-toolbox.tar.gz -C /tmp/
        /tmp/jetbrains-toolbox-*/jetbrains-toolbox 2>/dev/null &
        log "JetBrains Toolbox launched. Install IntelliJ from the UI."
    fi
    cat > "$LOG_DIR/intellij-setup.txt" << 'EOF'
IntelliJ IDEA — AI Setup:
1. Settings → Plugins → Marketplace → Search "DevoxxGenie" → Install
2. Settings → Tools → DevoxxGenie:
   - LLM Provider: Ollama
   - Chat Model: (your selected model)
   - URL: http://localhost:11434
3. For inline completion: Plugins → "Ollama Completion" → Install
EOF
    echo -e "${YELLOW}ℹ️  See ~/.ai-bootstrap/intellij-setup.txt${NC}"
fi

# ─── Infrastructure ───
if $INSTALL_TF; then
    if ! command -v terraform &>/dev/null; then
        case $PKG in
            apt) wget -qO- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp.gpg
                 echo "deb [signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
                 sudo apt-get update -qq && sudo apt-get install -y -qq terraform ;;
            dnf) sudo dnf install -y terraform ;;
            pacman) sudo pacman -S --noconfirm terraform ;;
        esac
    fi
    log "Terraform: $(terraform version -json 2>/dev/null | python3 -c 'import json,sys;print(json.load(sys.stdin).get("terraform_version","installed"))' 2>/dev/null || echo 'installed')"
fi

if $INSTALL_K8S; then
    command -v kubectl &>/dev/null || {
        curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && rm kubectl
    }
    command -v helm &>/dev/null || {
        curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    }
    command -v k9s &>/dev/null || {
        curl -fsSL https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz | sudo tar -xz -C /usr/local/bin k9s
    }
    log "K8s tools installed."
fi

if $INSTALL_ANSIBLE; then
    command -v ansible &>/dev/null || {
        case $PKG in
            apt) sudo apt-get install -y -qq ansible ;;
            dnf) sudo dnf install -y ansible ;;
            pacman) sudo pacman -S --noconfirm ansible ;;
        esac
    }
    log "Ansible: $(ansible --version 2>/dev/null | head -1)"
fi

# ─── OpenCode + MCP Config ───
OPENCODE_DIR="$HOME/.config/opencode"
mkdir -p "$OPENCODE_DIR"
sed "s/qwen3.5:4b/$PRIMARY_MODEL/g" "$CONFIG_SOURCE/opencode/config.json" > "$OPENCODE_DIR/config.json"
cp "$CONFIG_SOURCE/opencode/mcp-servers.json" "$OPENCODE_DIR/mcp-servers.json"
log "OpenCode configured."

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
    cp "$SCRIPT_DIR/../tools/standup/standup.py" "$TOOLS_BIN/standup.py"
    cat > "$TOOLS_BIN/standup" << WRAPPER
#!/bin/bash
exec python3 "$TOOLS_BIN/standup.py" "\$@"
WRAPPER
    chmod +x "$TOOLS_BIN/standup"
    log "Standup tool installed."
fi

# switch-model utility
cp "$SCRIPT_DIR/../tools/switch-model" "$TOOLS_BIN/switch-model"
chmod +x "$TOOLS_BIN/switch-model"
# Fix macOS sed syntax for Linux
sed -i "s/sed -i ''/sed -i/g" "$TOOLS_BIN/switch-model"
# Fix VS Code config path for Linux
sed -i 's|Library/Application Support/Code/User|.config/Code/User|g' "$TOOLS_BIN/switch-model"
log "switch-model utility installed."

# Ensure ~/.local/bin is in PATH
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    SHELL_RC="$HOME/.bashrc"
    [ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
    log "Added ~/.local/bin to PATH in $SHELL_RC"
fi

# ─── Done ───
touch "$LOG_DIR/.installed"
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ AI Workstation Bootstrap complete!       ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo "Installed:"
echo "  • Ollama + $PRIMARY_MODEL + qwen2.5-coder:1.5b + nomic-embed-text"
$INSTALL_VSCODE && echo "  • VS Code + Continue extension"
$INSTALL_INTELLIJ && echo "  • JetBrains Toolbox (see ~/.ai-bootstrap/intellij-setup.txt)"
$INSTALL_TF && echo "  • Terraform"
$INSTALL_K8S && echo "  • kubectl, helm, k9s"
$INSTALL_ANSIBLE && echo "  • Ansible"
$INSTALL_STANDUP && echo "  • standup (run: standup)"
echo "  • switch-model (run: switch-model mistral:7b)"
echo ""
echo "Next steps:"
echo "  1. Restart terminal (or: source ~/.bashrc)"
echo "  2. Set up MCP tokens: see docs/MCP_SETUP.md"
echo "  3. Test: opencode chat 'hello'"
echo ""
log "=== Bootstrap completed ==="
