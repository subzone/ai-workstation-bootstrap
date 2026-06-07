#!/usr/bin/env bash
set -euo pipefail

# AI Workstation Bootstrap — Ubuntu/Linux (Intune or manual deployment)

LOG_DIR="/var/log/ai-bootstrap"
LOG_FILE="$LOG_DIR/install.log"
CONFIG_SOURCE="$(cd "$(dirname "$0")/../configs" && pwd)"

mkdir -p "$LOG_DIR"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S')  $*" | tee -a "$LOG_FILE"; }

log "=== AI Workstation Bootstrap started ==="
log "User: $(whoami) | Machine: $(hostname)"

# --- Pre-flight ---
RAM_GB=$(free -g | awk '/Mem:/{print $2}')
if [ "$RAM_GB" -lt 30 ]; then
    log "ERROR: Insufficient RAM (${RAM_GB}GB). Minimum 32GB required."
    exit 1
fi
log "Hardware OK: ${RAM_GB}GB RAM"

# --- Step 1: Install toolchain ---
log "Installing VS Code..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/ms.gpg
install -o root -g root -m 644 /tmp/ms.gpg /usr/share/keyrings/microsoft-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list
apt-get update -qq && apt-get install -y -qq code
log "VS Code installed."

log "Installing Ollama..."
curl -fsSL https://ollama.com/install.sh | sh
log "Ollama installed."

log "Installing OpenCode..."
curl -fsSL https://get.opencode.ai | sh
log "OpenCode installed."

# --- Step 2: Pull models ---
log "Starting Ollama..."
systemctl enable --now ollama 2>/dev/null || ollama serve &
sleep 5

log "Pulling qwen3.5:4b..."
ollama pull qwen3.5:4b
log "Pulled qwen3.5:4b"

log "Pulling qwen2.5-coder:1.5b..."
ollama pull qwen2.5-coder:1.5b
log "Pulled qwen2.5-coder:1.5b"

log "Pulling nomic-embed-text..."
ollama pull nomic-embed-text
log "Pulled nomic-embed-text"

# --- Step 3: Inject configs ---
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~$REAL_USER")

log "Deploying configurations for $REAL_USER..."

# VS Code
VSCODE_DIR="$REAL_HOME/.config/Code/User"
mkdir -p "$VSCODE_DIR"
cp "$CONFIG_SOURCE/vscode/settings.json" "$VSCODE_DIR/settings.json"
chown "$REAL_USER:$REAL_USER" "$VSCODE_DIR/settings.json"

# OpenCode
OPENCODE_DIR="$REAL_HOME/.opencode"
mkdir -p "$OPENCODE_DIR"
cp "$CONFIG_SOURCE/opencode/.opencode.json" "$OPENCODE_DIR/.opencode.json"
cp "$CONFIG_SOURCE/opencode/mcp-servers.json" "$OPENCODE_DIR/mcp-servers.json"
chown -R "$REAL_USER:$REAL_USER" "$OPENCODE_DIR"

# Meetily
MEETILY_DIR="$REAL_HOME/.config/meetily"
mkdir -p "$MEETILY_DIR"
cp "$CONFIG_SOURCE/meetily/config.toml" "$MEETILY_DIR/config.toml"
chown -R "$REAL_USER:$REAL_USER" "$MEETILY_DIR"

log "Configurations deployed."

touch "$LOG_DIR/.installed"
log "=== AI Workstation Bootstrap completed successfully ==="
