# The 80/20 Rule — Smart AI Routing

80% of developer AI queries are simple tasks a local 4B model handles perfectly. Only 20% need a frontier model. This setup routes accordingly — cutting token costs by 80-90% while keeping quality where it matters.

## What runs locally (80% of queries — free)

| Task | Why local is enough |
|---|---|
| Code autocomplete | Pattern matching, 200ms response |
| "Explain this function" | Single-file context |
| Unit test generation | Template-based, predictable |
| Commit messages | Summarize a diff |
| Standup generation | Aggregate + format |
| Regex, boilerplate, formatting | Deterministic patterns |
| Log/error explanation | Pattern recognition |
| Code review (style, simple bugs) | Rule-following |

## What needs cloud (20% of queries — pay only for these)

| Task | Why frontier is needed |
|---|---|
| Multi-file architecture refactors | Large context window + deep reasoning |
| Novel algorithm design | Creative problem-solving |
| Complex debugging (multi-system) | Chain-of-thought across many files |
| Security vulnerability analysis (deep) | Needs latest training data |
| API design decisions | Nuanced trade-off reasoning |

## Configuration

### OpenCode — local default, cloud fallback

Edit `~/.config/opencode/config.json`:

```json
{
  "model": "ollama/qwen3.5:4b",
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "options": { "baseURL": "http://127.0.0.1:11434/v1" },
      "models": { "qwen3.5:4b": {}, "qwen2.5-coder:7b": {} }
    },
    "anthropic": {
      "models": { "claude-sonnet-4-20250514": {} }
    }
  }
}
```

Usage: OpenCode defaults to local. When you need frontier power:
```bash
opencode chat --model anthropic/claude-sonnet-4-20250514 "redesign the auth module for microservices"
```

### OpenSteva — hybrid routing

In `~/.opensteva/config.toml`:

```toml
[intelligence]
default_model = "qwen3.5:4b"          # 80% — free, local
preferred_engine = "ollama"

[intelligence.fallback]
model = "anthropic/claude-sonnet-4-20250514"  # 20% — cloud, when needed
engine = "litellm"
trigger = "manual"                     # or "auto" for complexity-based routing
```

### VS Code Continue — model switching

Continue lets you swap models mid-conversation. Configure both:

```json
"continue.models": [
  {
    "title": "Qwen 3.5 4B (Local — free)",
    "provider": "ollama",
    "model": "qwen3.5:4b"
  },
  {
    "title": "Claude Sonnet (Cloud — complex tasks)",
    "provider": "anthropic",
    "model": "claude-sonnet-4-20250514",
    "apiKey": "${ANTHROPIC_API_KEY}"
  }
]
```

Switch in the UI dropdown when you hit a hard problem.

## Cost Impact

### Before (all cloud)

| Usage | Monthly cost (20 devs) |
|---|---|
| GitHub Copilot Business | $380/mo |
| Claude/GPT API tokens | $2,000-4,000/mo |
| **Total** | **$2,400-4,400/mo** |

### After (80/20 split)

| Usage | Monthly cost (20 devs) |
|---|---|
| Local (80% of queries) | $0 |
| Cloud API (20% complex queries) | $200-400/mo |
| **Total** | **$200-400/mo** |
| **Savings** | **~90%** |

## How Developers Use It Day-to-Day

```
Morning:
  ☀️ Standup generated (local) ─────────── free
  
Coding:
  ⌨️ Autocomplete suggestions (local) ──── free
  💬 "Explain this function" (local) ───── free
  🧪 "Write tests for this" (local) ────── free
  🐛 "Why is this failing?" (local) ────── free
  
Hard problem (1-2 times/day):
  🧠 "Redesign this for scale" (cloud) ─── $0.05
  🏗️ "Review this architecture" (cloud) ── $0.08

End of day:
  📋 Commit messages (local) ───────────── free
  🔒 Security scan (local) ─────────────── free
```

**Average cost per developer: ~$0.50/day instead of ~$10/day**
