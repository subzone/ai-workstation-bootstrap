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
│   ├── install-windows.ps1        # PowerShell for Intune (Windows)
│   └── install-ubuntu.sh          # Bash for Intune (Linux/WSL)
├── configs/
│   ├── vscode/
│   │   └── settings.json          # Enforces local models, disables cloud AI
│   ├── opencode/
│   │   ├── .opencode.json         # Points OpenCode to local Qwen 4B
│   │   └── mcp-servers.json       # Pre-configures Jira, Confluence, MS365 MCPs
│   ├── meetily/
│   │   └── config.toml            # Locks to localhost:11434, no cloud APIs
│   └── ollama/
│       └── Pull-Models.ps1        # Downloads approved models
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

### Linux (Ubuntu)
```bash
curl -fsSL https://raw.githubusercontent.com/subzone/ai-workstation-bootstrap/main/scripts/install-ubuntu.sh | sudo bash
```

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
