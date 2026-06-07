#!/usr/bin/env bash
set -euo pipefail

# AI Workstation Bootstrap — macOS

LOG_DIR="$HOME/.ai-bootstrap"
LOG_FILE="$LOG_DIR/install.log"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_SOURCE="$SCRIPT_DIR/../configs"

mkdir -p "$LOG_DIR"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S')  $*" | tee -a "$LOG_FILE"; }

log "=== AI Workstation Bootstrap (macOS) started ==="

# --- Pre-flight ---
RAM_GB=$(sysctl -n hw.memsize | awk '{print int($1/1073741824)}')
log "RAM: ${RAM_GB}GB"

# --- Step 1: Install toolchain ---
if ! command -v brew &>/dev/null; then
    log "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if ! command -v code &>/dev/null; then
    log "Installing VS Code..."
    brew install --cask visual-studio-code 2>/dev/null || true
else
    log "VS Code already installed."
fi

if ! command -v ollama &>/dev/null; then
    log "Installing Ollama..."
    brew install ollama
else
    log "Ollama already installed: $(ollama --version)"
fi

if ! command -v opencode &>/dev/null; then
    log "Installing OpenCode..."
    brew install opencode 2>/dev/null || curl -fsSL https://get.opencode.ai | sh
else
    log "OpenCode already installed."
fi

# --- Step 2: Ensure Ollama is running and pull models ---
log "Ensuring Ollama is running..."
pgrep -x ollama >/dev/null || (ollama serve &>/dev/null &)
sleep 3

MODELS=("qwen3.5:4b" "qwen2.5-coder:1.5b" "nomic-embed-text")
for model in "${MODELS[@]}"; do
    if ollama list 2>/dev/null | grep -q "^${model}"; then
        log "Model $model already present."
    else
        log "Pulling $model..."
        ollama pull "$model"
        log "Pulled $model"
    fi
done

# --- Step 3: Deploy configs ---
log "Deploying configurations..."

# VS Code
VSCODE_DIR="$HOME/Library/Application Support/Code/User"
mkdir -p "$VSCODE_DIR"
cp "$CONFIG_SOURCE/vscode/settings.json" "$VSCODE_DIR/settings.json"
log "VS Code config: $VSCODE_DIR/settings.json"

# OpenCode
OPENCODE_DIR="$HOME/.opencode"
mkdir -p "$OPENCODE_DIR"
cp "$CONFIG_SOURCE/opencode/.opencode.json" "$OPENCODE_DIR/.opencode.json"
cp "$CONFIG_SOURCE/opencode/mcp-servers.json" "$OPENCODE_DIR/mcp-servers.json"
log "OpenCode config: $OPENCODE_DIR/"

# Meetily
MEETILY_DIR="$HOME/.config/meetily"
mkdir -p "$MEETILY_DIR"
cp "$CONFIG_SOURCE/meetily/config.toml" "$MEETILY_DIR/config.toml"
log "Meetily config: $MEETILY_DIR/config.toml"

# --- Step 4: Install VS Code extensions ---
log "Installing VS Code extensions..."
code --install-extension Continue.continue 2>/dev/null && log "Installed: Continue" || log "Skip: Continue (code CLI not in PATH)"

# --- Verification ---
log ""
log "=== Verification ==="
log "Ollama: $(ollama --version 2>&1)"
log "Models:"
ollama list 2>/dev/null | tee -a "$LOG_FILE"
log ""
log "Configs deployed:"
ls -la "$VSCODE_DIR/settings.json" 2>/dev/null | tee -a "$LOG_FILE"
ls -la "$OPENCODE_DIR/.opencode.json" 2>/dev/null | tee -a "$LOG_FILE"
ls -la "$MEETILY_DIR/config.toml" 2>/dev/null | tee -a "$LOG_FILE"

touch "$LOG_DIR/.installed"
log ""
log "=== AI Workstation Bootstrap completed ==="
log "Test: opencode chat 'hello'"
