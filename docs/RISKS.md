# Risks & Mitigations

Comprehensive risk assessment for deploying local AI developer tools across an engineering team.

---

## Security Risks

| Risk | Severity | Likelihood | Mitigation |
|---|---|---|---|
| Model generates insecure code suggestions | Medium | High | Pre-commit security scan catches common vulns (SQLi, XSS, secrets). Developers must review all AI output. |
| Ollama exposed on network | High | Low | Config binds to `127.0.0.1` only. Firewall rules enforced. No `0.0.0.0` binding. |
| MCP tokens leaked in config files | High | Medium | Tokens stored in OS keychain (macOS Keychain, Windows Credential Manager, Linux secret-tool). Config files use `${ENV_VAR}` references, not plaintext. |
| Malicious model weights (supply chain) | Medium | Very Low | Models pulled from Ollama official registry (signed manifests). Pin specific model digests for production. No third-party registries. |
| Code-rag index exposes secrets from codebase | Medium | Medium | `.gitignore` patterns respected during indexing. Files > 500KB skipped. Add `.env`, `*.key`, `*.pem` to exclusion list. |
| Developer disables security hooks | Low | Medium | Organizational policy enforced via Intune. Pre-commit hooks can be made mandatory via server-side hooks (GitHub branch protection). |

## Data & Privacy Risks

| Risk | Severity | Likelihood | Mitigation |
|---|---|---|---|
| Code sent to external API | Critical | Low (by design) | `allowCloudFallback: false` in all configs. No cloud API keys provisioned. PostHog/telemetry disabled. Network monitoring can verify zero egress. |
| Meeting transcripts stored insecurely | Medium | Medium | Meetily config: `auto_delete_after_days = 30`. Stored in user's home dir with OS permissions. Full-disk encryption (FileVault/BitLocker/LUKS) recommended. |
| Local traces/history contain sensitive code | Medium | High | Traces stored at `~/.code-rag/db/` and `~/.ai-bootstrap/`. Excluded from cloud backup via `.gitignore` patterns. Cleared on device wipe. |
| Model memorization of proprietary code | Low | Very Low | Local models are frozen weights — no training happens on your data. Learning loop (if enabled) only adjusts routing, not model weights. |

## Operational Risks

| Risk | Severity | Likelihood | Mitigation |
|---|---|---|---|
| Ollama crashes / model not loaded | Low | Medium | Systemd/launchd service auto-restarts. Health check in standup script. `ollama list` in pre-commit hook verifies availability. |
| Disk space exhaustion from models | Medium | Medium | Bootstrap checks available space before pulling. Models total ~5GB for default set. Warn if < 10GB free. |
| Model gives wrong answers (hallucination) | Medium | High | All tools designed as assistants, not autonomous actors. Pre-commit hooks flag issues but developer makes final decision. Code review tool explicitly says "suggestion" not "fix". |
| New model version breaks tool compatibility | Low | Low | Pin model versions in config. `switch-model` validates model exists before switching. Rollback: `switch-model qwen3.5:4b`. |
| Performance degradation with large codebases | Medium | Medium | Code-rag chunks limit (1500 chars). Search returns top-N (default 5). Embedding batched. 16GB RAM handles 50K-file repos. |

## Compliance Risks

| Risk | Severity | Likelihood | Mitigation |
|---|---|---|---|
| Model license violation | Medium | Low | All default models are Apache-2.0 (commercial use OK). BOM.md documents every license. Llama/Gemma require terms acceptance (auto via Ollama). |
| GDPR — processing personal data | Low | Low | No PII processed by AI. Code/docs only. Meetily transcription is opt-in and local-only with auto-delete. |
| Export control (model origin) | Low | Very Low | Models are publicly available weights, not controlled technology. No encryption/military application. IBM Granite and Mistral available as non-Chinese alternatives if required. |
| Audit trail missing | Medium | Medium | Install logs at `~/.ai-bootstrap/install.log`. Git hooks log to stdout (captured in CI). All tool invocations can be logged via shell history. |
| Software supply chain compliance | Medium | Low | All packages from official registries (npm, PyPI, Ollama). BOM.md provides full attribution. No vendored binaries. Dependencies pinnable via lockfiles. |

## Organizational Risks

| Risk | Severity | Likelihood | Mitigation |
|---|---|---|---|
| Developer over-reliance on AI | Medium | High | Tools positioned as "assistants" not "replacements". Code review still required by humans. AI suggestions flagged as such. |
| Uneven adoption across team | Low | High | Interactive installer makes onboarding easy. Model selection accommodates different hardware. Low-RAM machines get lighter models. |
| Maintenance burden | Low | Medium | Bootstrap is self-contained. Model updates via `switch-model`. Configs versioned in Git. 2 days/quarter estimated maintenance. |
| AI generates code with unclear IP ownership | Medium | Medium | All models use permissive licenses (Apache-2.0). Generated code is derivative of prompts, owned by developer/company. Document policy in employee handbook. |
| Shadow AI — developers use unauthorized cloud tools instead | Low | Medium | Copilot disabled in IDE config. Network team can block `api.openai.com`, `api.anthropic.com` at proxy level. Local setup is good enough to reduce incentive. |

---

## Risk Matrix Summary

```
             │ Very Low    Low         Medium      High
─────────────┼────────────────────────────────────────────
Critical     │             Data egress
             │             (mitigated)
High         │ Malicious   Network     Token leak
             │ weights     exposure
Medium       │ Export      License     Hallucination
             │ control     violation   Disk space
             │                         Over-reliance
Low          │             Ollama      Uneven adoption
             │             crash       Maintenance
```

## Recommended Security Checklist

Before rolling out to the team:

- [ ] Full-disk encryption enabled on all developer machines
- [ ] Ollama bound to `127.0.0.1` (verified via `lsof -i :11434`)
- [ ] MCP tokens stored in OS keychain, not env files
- [ ] Pre-commit hooks installed and mandatory (branch protection)
- [ ] Network monitoring confirms zero AI-related egress
- [ ] `.env`, `*.key`, `*.pem` excluded from code-rag indexing
- [ ] Model versions pinned in team config
- [ ] Incident response plan for token leaks
- [ ] Quarterly access review for MCP tokens (Jira, GitHub, AzDO)
- [ ] Developer training: "AI as assistant, not authority"
