# Tools Quick Reference

All tools use the local Ollama instance (`localhost:11434`) with `qwen2.5-coder:7b`. No external API calls.

| Tool | What it does | Usage | Prerequisites |
|------|-------------|-------|---------------|
| **standup** | Daily standup summary from git commits | `standup` or `python3 tools/standup/standup.py` | Ollama running, git repo |
| **code-rag** | Semantic code search with RAG | `python3 tools/code-rag/code_rag.py query "how does auth work"` | Ollama running, indexed repo |
| **code-review** | Pre-commit code review via LLM | `git diff --staged \| python3 tools/code-review/review.py` | Ollama running |
| **security-scan** | Scan diffs for secrets, SQLi, XSS | `git diff --staged \| python3 tools/security-scan/scan.py` | Ollama running |
| **log-explainer** | Root cause analysis for errors | `cat error.log \| python3 tools/log-explainer/explain.py` | Ollama running |
| **sprint-report** | Weekly git activity report for managers | `python3 tools/sprint-report/report.py --days 7` | Ollama running, git repo |
| **dep-audit** | Dependency vulnerability audit + summary | `python3 tools/dep-audit/audit.py /path/to/project` | Ollama + npm/pip/cargo audit |
| **test-gen** | Generate unit tests for a source file | `python3 tools/test-gen/generate.py src/utils.py` | Ollama running |

## Pre-commit Hook Setup

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
git diff --staged | python3 /path/to/tools/code-review/review.py || exit 1
git diff --staged | python3 /path/to/tools/security-scan/scan.py || exit 1
```

Make it executable: `chmod +x .git/hooks/pre-commit`
