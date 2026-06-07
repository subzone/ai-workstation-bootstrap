# System Requirements

## Minimum

| Component | Requirement |
|---|---|
| RAM | 8 GB (runs `llama3.2:3b` — limited quality) |
| Storage | 10 GB free (OS + 1 model + index) |
| CPU | Any 64-bit (x86_64 or ARM64) |
| OS | macOS 12+, Ubuntu 20.04+, Windows 10+ |
| Internet | Required once (model download), then offline |

## Recommended

| Component | Requirement |
|---|---|
| RAM | 16 GB (runs `qwen3.5:4b` comfortably) |
| Storage | 20 GB free |
| CPU | Apple M1+ or 8-core Intel/AMD |
| GPU | Not required — Apple Neural Engine or integrated GPU sufficient |
| OS | macOS 14+, Ubuntu 22.04+, Windows 11 |

## Optimal (power users, larger models)

| Component | Requirement |
|---|---|
| RAM | 32+ GB (runs 9B models, multiple concurrent) |
| Storage | 40 GB free |
| GPU | NVIDIA 8GB+ VRAM or Apple M-series with 16GB+ unified memory |

## What uses what

| Model | RAM at runtime | Disk |
|---|---|---|
| `llama3.2:3b` | ~3 GB | 2.0 GB |
| `qwen3.5:4b` | ~5 GB | 3.2 GB |
| `qwen2.5-coder:1.5b` | ~2 GB | 1.0 GB |
| `nomic-embed-text` | ~1 GB | 274 MB |
| `qwen3.5:9b` | ~8 GB | 6.3 GB |
| Code-RAG index (10K files) | ~200 MB | ~50 MB |

> Note: Ollama loads models on demand and unloads after idle timeout. Only the active model uses RAM.

## Software Prerequisites

| Tool | Required | Installed by bootstrap |
|---|---|---|
| Git | ✅ Must exist before running installer | No |
| Python 3.10+ | ✅ Must exist | No |
| Homebrew (macOS) | Installed if missing | Yes |
| Node.js 18+ | For MCP servers | Yes (via brew/apt) |
| Ollama | Core runtime | Yes |
| VS Code / IntelliJ / Visual Studio | At least one IDE | Yes (chosen during install) |

## Network Requirements

| When | What | Destination |
|---|---|---|
| Install (once) | Model downloads | `registry.ollama.ai` |
| Install (once) | npm packages for MCP | `registry.npmjs.org` |
| Install (once) | IDE extensions | marketplace URLs |
| Runtime | MCP → Jira/GitHub/etc. | Your corporate tools |
| Runtime | Ollama inference | `localhost:11434` only |

After initial install, the AI tools work fully offline. Only MCP integrations (Jira, GitHub) need network access to reach your corporate services.

## Disk Space Breakdown

Full install with default model set:

```
Ollama binary:           ~100 MB
qwen3.5:4b:             3.2 GB
qwen2.5-coder:1.5b:    1.0 GB
nomic-embed-text:        274 MB
Bootstrap repo:           5 MB
Code-RAG index:         ~50 MB (varies by project)
VS Code extension:       ~20 MB
────────────────────────────────
Total:                  ~4.7 GB
```
