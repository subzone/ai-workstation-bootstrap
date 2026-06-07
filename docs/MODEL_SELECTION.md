# Model Selection Guide

Choose the local model that best fits your hardware and workload. All models run via Ollama on your machine.

## Recommended Models

### Chat / Code Assistant (primary model)

| Model | Size | RAM Needed | Speed | Best For |
|---|---|---|---|---|
| **qwen3.5:4b** | 3.2 GB | 6 GB | ⚡ Fast | Default. Good all-rounder |
| **qwen3.5:9b** | 6.3 GB | 10 GB | 🔵 Medium | Better reasoning, 32GB machines |
| **glm4:9b** | 5.5 GB | 9 GB | 🔵 Medium | Strong Chinese/English bilingual |
| **minimax-m1:4b** | 3.0 GB | 6 GB | ⚡ Fast | Creative tasks, conversation |
| **deepseek-v3:7b** | 4.2 GB | 7 GB | 🔵 Medium | Strong code + reasoning |
| **mistral:7b** | 4.1 GB | 7 GB | 🔵 Medium | European language support |
| **mistral-small:22b** | 13 GB | 20 GB | 🔴 Slow | Best quality, needs 32GB RAM |
| **llama3.2:3b** | 2.0 GB | 4 GB | ⚡⚡ Fastest | Lightweight, low-RAM machines |
| **granite3.1-dense:8b** | 4.9 GB | 8 GB | 🔵 Medium | Enterprise-friendly (IBM) |
| **gemma3:4b** | 3.3 GB | 6 GB | ⚡ Fast | Google's compact model |

### Code Autocomplete (inline suggestions)

| Model | Size | Latency | Notes |
|---|---|---|---|
| **qwen2.5-coder:1.5b** ★ | 1.0 GB | ~200ms | Best speed/quality for FIM |
| **qwen2.5-coder:7b** | 4.7 GB | ~500ms | Better quality, slightly slower |
| **deepseek-coder-v2:16b** | 9.0 GB | ~800ms | Best code quality, needs RAM |
| **starcoder2:3b** | 1.7 GB | ~250ms | Multi-language, lightweight |
| **codellama:7b** | 3.8 GB | ~400ms | Python/C++/Java focused |

### Embeddings (for code-rag)

| Model | Size | Dimensions | Notes |
|---|---|---|---|
| **nomic-embed-text** ★ | 274 MB | 768 | Default. Fast, good quality |
| **mxbai-embed-large** | 670 MB | 1024 | Better accuracy, heavier |
| **snowflake-arctic-embed:33m** | 67 MB | 384 | Ultra-light, mobile/CI |

★ = Default in bootstrap

---

## How to Switch Models

### Step 1: Pull the new model

```bash
ollama pull glm4:9b
# or
ollama pull deepseek-v3:7b
# or
ollama pull mistral:7b
```

### Step 2: Update your config

Edit `~/.opencode/.opencode.json`:
```json
{
  "model": "glm4:9b"
}
```

### Step 3: Update VS Code (Continue)

Edit VS Code Settings (`Cmd+,` → search "continue"):
```json
{
  "continue.models": [
    {
      "title": "GLM-4 9B (Local)",
      "provider": "ollama",
      "model": "glm4:9b",
      "apiBase": "http://localhost:11434"
    }
  ]
}
```

### Step 4: Update IntelliJ (DevoxxGenie)

Settings → Tools → DevoxxGenie → Chat Model: type the new model name.

### Step 5: Update all tools

Set environment variable (affects standup, code-review, test-gen, etc.):
```bash
# Add to ~/.zshrc or ~/.bashrc
export STANDUP_MODEL="glm4:9b"
export CODE_REVIEW_MODEL="glm4:9b"
```

Or use the one-liner to reconfigure everything:
```bash
code-rag-configure --model glm4:9b
```

---

## Quick Switch Script

Save as `~/.local/bin/switch-model`:

```bash
#!/bin/bash
# Usage: switch-model glm4:9b

MODEL="${1:?Usage: switch-model <model-name>}"

echo "Switching all tools to: $MODEL"

# Pull if not present
ollama pull "$MODEL" 2>/dev/null

# OpenCode
python3 -c "
import json; p='$HOME/.opencode/.opencode.json'
d=json.load(open(p)); d['model']='$MODEL'
json.dump(d, open(p,'w'), indent=2)
" && echo "✅ OpenCode"

# VS Code Continue
python3 -c "
import json; p='$HOME/Library/Application Support/Code/User/settings.json'
d=json.load(open(p))
if 'continue.models' in d and d['continue.models']:
    d['continue.models'][0]['model']='$MODEL'
json.dump(d, open(p,'w'), indent=2)
" && echo "✅ VS Code"

# Shell exports
grep -q "CODE_REVIEW_MODEL" ~/.zshrc 2>/dev/null && \
  sed -i '' "s/CODE_REVIEW_MODEL=.*/CODE_REVIEW_MODEL=\"$MODEL\"/" ~/.zshrc || \
  echo "export CODE_REVIEW_MODEL=\"$MODEL\"" >> ~/.zshrc

grep -q "STANDUP_MODEL" ~/.zshrc 2>/dev/null && \
  sed -i '' "s/STANDUP_MODEL=.*/STANDUP_MODEL=\"$MODEL\"/" ~/.zshrc || \
  echo "export STANDUP_MODEL=\"$MODEL\"" >> ~/.zshrc

echo "✅ Environment variables"
echo ""
echo "Done. Restart your terminal or run: source ~/.zshrc"
```

---

## Choosing the Right Model

### By hardware

| Your RAM | Recommended |
|---|---|
| 8 GB | `llama3.2:3b` + `starcoder2:3b` (autocomplete) |
| 16 GB | `qwen3.5:4b` + `qwen2.5-coder:1.5b` (default) |
| 32 GB | `qwen3.5:9b` or `deepseek-v3:7b` + `qwen2.5-coder:7b` |
| 64 GB | `mistral-small:22b` + `deepseek-coder-v2:16b` |

### By use case

| Need | Best model |
|---|---|
| Fastest possible responses | `llama3.2:3b` or `qwen3.5:4b` |
| Best code quality | `deepseek-v3:7b` or `qwen2.5-coder:7b` |
| Best reasoning (architecture decisions) | `qwen3.5:9b` or `mistral-small:22b` |
| Non-English (German, French, etc.) | `mistral:7b` |
| Chinese + English | `glm4:9b` or `qwen3.5:9b` |
| Enterprise compliance (non-Chinese origin) | `granite3.1-dense:8b` or `mistral:7b` |
| Smallest footprint | `llama3.2:3b` (2GB) |

### By trust/origin preference

| Origin | Models |
|---|---|
| China (Alibaba) | Qwen series |
| China (Zhipu) | GLM-4 |
| China (DeepSeek) | DeepSeek series |
| China (MiniMax) | MiniMax-M1 |
| France (Mistral AI) | Mistral series |
| USA (Meta) | Llama series |
| USA (IBM) | Granite series |
| USA (Google) | Gemma series |
| International (BigCode) | StarCoder series |

---

## Updating the Bootstrap for Your Team

If you're the admin deploying this to your team, update the model in:

1. `configs/vscode/settings.json` → `continue.models[0].model`
2. `configs/opencode/.opencode.json` → `model`
3. `scripts/install-*.sh` → the `ollama pull` lines

Then re-push via Intune. Developers will get the new model on next sync.
