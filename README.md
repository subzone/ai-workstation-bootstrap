# AI Workstation Bootstrap

Automated provisioning of local-first AI developer tools for engineering teams. Deployed via Microsoft Intune (Win32 app) or MDM.

## What It Does

When a developer logs into their workstation, this bootstrap:

1. **Installs toolchain** — VS Code, Ollama, OpenCode CLI, Meetily
2. **Provisions models** — Downloads approved local models (Qwen 3.5 4B, Qwen 2.5 Coder 1.5B, Nomic embeddings)
3. **Injects secure configs** — Locks all tools to local inference, pre-configures MCP servers (Jira, Confluence, MS365)

Zero cloud API keys. Zero data exfiltration. Full DLP compliance.

## Repository Structure

```
ai-workstation-bootstrap/
├── scripts/
│   ├── install-interactive.sh     # Interactive installer (macOS)
│   ├── install-macos.sh           # Non-interactive macOS
│   ├── install-ubuntu.sh          # Interactive installer (Linux)
│   └── install-windows.ps1       # PowerShell for Intune (Windows)
├── configs/
│   ├── vscode/settings.json       # Local AI, Copilot disabled
│   ├── opencode/.opencode.json    # Local model, no cloud
│   ├── opencode/mcp-servers.json  # Jira, Confluence, MS365, K8s, TF, Jenkins, AzDO
│   ├── meetily/config.toml        # Locked to localhost
│   └── ollama/Pull-Models.ps1     # Model provisioning
├── tools/
│   ├── standup/                   # Daily standup from git+Jira
│   ├── code-rag/                  # Local RAG MCP server (universal)
│   ├── code-review/               # AI code review (pre-commit)
│   ├── security-scan/             # Secret/vuln detection
│   ├── log-explainer/             # Stack trace → root cause
│   ├── sprint-report/             # Weekly team report
│   ├── dep-audit/                 # Dependency vulnerability audit
│   ├── test-gen/                  # Auto-generate unit tests
│   └── switch-model               # Reconfigure all tools to new model
├── docs/
│   ├── DEVELOPER_GUIDE.md         # What you get, how to use it
│   ├── MCP_SETUP.md               # Token setup for all MCPs
│   ├── MODEL_SELECTION.md         # 8 models, hardware reqs, switching
│   └── TOOLS_GUIDE.md             # Quick reference for all tools
└── README.md
```

## Deployment via Microsoft Intune

### Prerequisites
- Devices in `Engineering_Team` Azure AD group
- Minimum: 32GB RAM, NVIDIA GPU (enforced via Intune requirement rules)
- Network access to `registry.ollama.ai` during initial provisioning

### Steps

1. **Package:** Use [Microsoft Win32 Content Prep Tool](https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool) to wrap `scripts/` + `configs/` into `.intunewin`
2. **Upload:** Intune Endpoint Manager → Apps → Win32 App
3. **Install command:** `powershell.exe -ExecutionPolicy Bypass -File scripts\install-windows.ps1`
4. **Detection rule:** Check for `C:\ProgramData\ai-bootstrap\.installed` marker file
5. **Requirement rules:**
   - RAM ≥ 32GB
   - GPU present (WMI: `Win32_VideoController WHERE AdapterRAM > 4294967296`)
6. **Assignment:** Required → `Engineering_Team` group

## Quick Install

### macOS
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/subzone/ai-workstation-bootstrap/main/scripts/install-interactive.sh)
```

### Linux (Ubuntu/Debian/Fedora)
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/subzone/ai-workstation-bootstrap/main/scripts/install-ubuntu.sh)
```

### Windows (PowerShell as Admin)
```powershell
irm https://raw.githubusercontent.com/subzone/ai-workstation-bootstrap/main/scripts/install-windows.ps1 | iex
```

### Windows via Intune (enterprise deployment)
See [Intune Deployment](#deployment-via-microsoft-intune) below.

## Security & Compliance

| Control | Implementation |
|---|---|
| No cloud API keys | Config files physically omit API key fields |
| No data exfiltration | All inference runs on localhost:11434 |
| Model allowlist | Only approved models are pulled |
| Audit trail | Install script logs to `C:\ProgramData\ai-bootstrap\install.log` |
| DLP compliant | No prompts/code ever leave the device |

## Developer Experience

After login, the engineer gets:
- VS Code with local AI autocomplete (Qwen 2.5 Coder 1.5B)
- OpenCode CLI pre-connected to Jira/Confluence via MCP
- Meetily transcription locked to local Qwen
- Zero configuration required
