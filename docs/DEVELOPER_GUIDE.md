# Developer Guide — AI Workstation

Your machine has been provisioned with a local-first AI coding stack. Everything runs on your hardware — no API keys, no cloud accounts, no data leaving your device.

## What You Get

### 1. Code Autocomplete (VS Code)
**Works automatically.** As you type, you'll see inline suggestions powered by `qwen2.5-coder:1.5b` running locally.

- Accept suggestion: `Tab`
- Dismiss: `Esc`
- See alternatives: `Alt+]` / `Alt+[`

The Continue extension is pre-configured in your VS Code sidebar (icon: the two curved arrows).

### 2. AI Chat in Editor (VS Code Sidebar)
Open Continue panel (`Cmd+L` on macOS / `Ctrl+L` on Windows) to ask questions about your code:

- "Explain this function"
- "Write tests for this class"
- "Refactor this to use async/await"
- "Find the bug in this code"

Model: `qwen3.5:4b` — runs entirely on your GPU/CPU.

### 3. Terminal Code Assistant (OpenCode)
For deeper coding tasks from the terminal:

```bash
opencode chat "add pagination to the /users endpoint"
opencode chat "why is this test failing" --context ./src/api/users.test.ts
```

OpenCode can read your files, run shell commands, and write code — all locally.

### 4. Meeting Transcription (Meetily)
Running in your system tray. Records and transcribes meetings locally using the Qwen model. Summaries stay on your machine.

### 5. MCP Integrations (Pre-wired)
OpenCode connects to corporate tools via MCP servers:

| Tool | What it does | Example |
|---|---|---|
| **Jira** | Read tickets, create issues | "Show me my open tickets" |
| **Confluence** | Search docs, read pages | "Find the onboarding runbook" |
| **MS365** | Calendar, emails | "What meetings do I have today?" |
| **GitHub** | PRs, issues, code search | "Show recent PRs on the platform repo" |

> Note: MCP tokens are read from your local keychain. First use will prompt you to authenticate once.

## Quick Reference

| Task | How |
|---|---|
| Get code suggestions | Just type in VS Code |
| Ask about code | `Cmd+L` → type question |
| Code from terminal | `opencode chat "your request"` |
| Index a repo for RAG | `opencode index .` |
| Check AI status | `ollama list` (shows loaded models) |
| Restart AI backend | `ollama serve` |

## What's Running

| Service | Port | Purpose |
|---|---|---|
| Ollama | `localhost:11434` | Local model server |
| Continue | (VS Code extension) | Autocomplete + chat |
| OpenCode | (CLI) | Terminal code assistant |
| Meetily | (system tray) | Meeting transcription |

## Performance Notes

- First response after boot may take 5-10 seconds (model loading into memory)
- Subsequent responses: 1-3 seconds
- Autocomplete: ~200ms latency
- 16GB RAM machine: runs the 4B model fine, may swap with large contexts
- 32GB+ RAM: optimal, can run 9B model if needed

## Troubleshooting

| Problem | Fix |
|---|---|
| No autocomplete suggestions | Check Ollama is running: `ollama list` |
| Slow responses | Close other memory-heavy apps; model needs ~4GB RAM |
| "Connection refused" errors | `ollama serve` (restart the backend) |
| Want a different model | Not supported — approved models only (security policy) |
| Need cloud AI for complex task | Contact your team lead — escalation path exists |

## What This Replaces

| Before | After |
|---|---|
| Copy code to ChatGPT | Ask locally — no data leaves |
| GitHub Copilot ($19/mo per seat) | Free, local, same quality for common tasks |
| Stack Overflow for boilerplate | Ask the model, get contextual answers |
| Manual meeting notes | Auto-transcribed locally |

## Privacy & Security

- ✅ **Zero data exfiltration** — all inference on localhost
- ✅ **No API keys to manage** — models are pre-downloaded
- ✅ **DLP compliant** — no prompts or code sent externally
- ✅ **Audit trail** — local logs at `~/.ai-bootstrap/install.log`
- ❌ **Cannot use cloud AI** — enforced by configuration (Copilot disabled, no API key fields)

## Feedback

If the AI gives consistently bad answers for your domain (e.g., company-specific frameworks), let your team lead know — we can fine-tune the local model on approved internal docs.

## Additional Tools

Local AI-powered developer tools (all use Ollama, no external calls):

| Tool | Description | Usage |
|------|-------------|-------|
| **code-review** | LLM code review on staged changes | `git diff --staged \| python3 tools/code-review/review.py` |
| **security-scan** | Regex + LLM scan for secrets, SQLi, XSS | `git diff --staged \| python3 tools/security-scan/scan.py` |
| **log-explainer** | Root cause analysis for stack traces | `cat error.log \| python3 tools/log-explainer/explain.py` |
| **sprint-report** | Weekly git activity summary for managers | `python3 tools/sprint-report/report.py --days 7` |
| **dep-audit** | Dependency vulnerability audit + LLM summary | `python3 tools/dep-audit/audit.py /path/to/project` |
| **test-gen** | Auto-generate unit tests for a file | `python3 tools/test-gen/generate.py src/utils.py` |

See [docs/TOOLS_GUIDE.md](./TOOLS_GUIDE.md) for full details and pre-commit hook setup.
