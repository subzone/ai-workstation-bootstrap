# Bill of Materials (BOM)

All external packages, tools, and models used in this bootstrap. Listed for compliance, audit, and attribution purposes.

## Core Runtime

| Package | Version | License | Author/Org | Purpose |
|---|---|---|---|---|
| Ollama | 0.22+ | MIT | Ollama Inc | Local model inference server |
| Python | 3.10+ | PSF | Python Software Foundation | Script runtime |
| Node.js | 20+ | MIT | OpenJS Foundation | MCP server runtime (npx) |
| Git | 2.x | GPL-2.0 | Git Project | Version control, activity tracking |

## AI Models (downloaded via Ollama)

| Model | License | Author/Org | Size | Purpose |
|---|---|---|---|---|
| qwen3.5:4b | Apache-2.0 | Alibaba Qwen Team | 3.2 GB | Primary chat/code |
| qwen3.5:9b | Apache-2.0 | Alibaba Qwen Team | 6.3 GB | Enhanced reasoning |
| qwen2.5-coder:1.5b | Apache-2.0 | Alibaba Qwen Team | 1.0 GB | Autocomplete (FIM) |
| qwen2.5-coder:7b | Apache-2.0 | Alibaba Qwen Team | 4.7 GB | Code review/gen |
| nomic-embed-text | Apache-2.0 | Nomic AI | 274 MB | Embeddings/RAG |
| deepseek-v3:7b | DeepSeek License | DeepSeek AI | 4.2 GB | Code + reasoning |
| mistral:7b | Apache-2.0 | Mistral AI | 4.1 GB | Multilingual |
| glm4:9b | GLM-4 License | Zhipu AI | 5.5 GB | Bilingual (CN/EN) |
| granite3.1-dense:8b | Apache-2.0 | IBM Research | 4.9 GB | Enterprise |
| llama3.2:3b | Llama 3.2 License | Meta | 2.0 GB | Lightweight |
| gemma3:4b | Gemma License | Google | 3.3 GB | Compact |

## IDE Extensions

| Extension | License | Author | Platform |
|---|---|---|---|
| Continue | Apache-2.0 | Continue Dev Inc | VS Code |
| DevoxxGenie | Apache-2.0 | Devoxx | IntelliJ IDEA |
| LocalPilot | MIT | FutureStack Solution | Visual Studio |

## MCP Servers (npm packages)

| Package | License | Author/Org | Purpose |
|---|---|---|---|
| @subzone81/ms-365-mcp | MIT | Milenko Mitrovic | Microsoft 365 Graph API |
| @modelcontextprotocol/server-github | MIT | MCP Foundation | GitHub API |
| mcp-server-atlassian | MIT | Community | Jira + Confluence |
| mcp-server-kubernetes | MIT | Community | Kubernetes cluster |
| @hashicorp/terraform-mcp-server | MPL-2.0 | HashiCorp | Terraform registry/state |
| @microsoft/azure-devops-mcp | MIT | Microsoft | Azure DevOps |
| mcp-jenkins | MIT | Community | Jenkins CI/CD |

## Python Dependencies (tools)

| Package | License | Author | Used By |
|---|---|---|---|
| chromadb | Apache-2.0 | Chroma Inc | code-rag (vector store) |
| (stdlib only) | PSF | Python | All other tools |

## Infrastructure Tools (optional)

| Tool | License | Author | Purpose |
|---|---|---|---|
| Terraform | BSL 1.1 | HashiCorp | Infrastructure as Code |
| kubectl | Apache-2.0 | Kubernetes Project | Cluster management |
| Helm | Apache-2.0 | Helm Project | K8s package manager |
| k9s | Apache-2.0 | Fernand Galiana | K8s TUI |
| Ansible | GPL-3.0 | Red Hat | Configuration management |

## System Dependencies

| Tool | License | Installed By |
|---|---|---|
| Homebrew | BSD-2-Clause | macOS installer |
| apt/dnf/pacman | Various | Linux installer |
| winget | MIT | Windows installer |

---

## License Compatibility Notes

- All model licenses permit local inference for commercial use
- `Llama 3.2 License` requires acceptance of Meta's terms (auto-accepted via Ollama pull)
- `BSL 1.1` (Terraform) — free for non-competing use; standard DevOps use is permitted
- `GPL-3.0` (Ansible) — impacts if you redistribute Ansible itself; using it as a tool is fine
- All MCP servers are MIT/Apache — no copyleft obligations

## Data Flow Summary

```
Developer's Code → Local Ollama (localhost:11434) → Response back to IDE
                   ↕
              ChromaDB (~/.code-rag/db/) ← nomic-embed-text
                   
No data leaves the machine. No network calls except:
- Initial model download (registry.ollama.ai) — one-time
- MCP servers connecting to corporate tools (Jira, GitHub, etc.) — via developer's own tokens
```
