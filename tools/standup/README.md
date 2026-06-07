# Automated Standup Generator

Generates daily standup updates from your actual activity — git commits, GitHub PRs, Jira tickets — using the local LLM.

## Usage

```bash
# Generate and print (review before posting)
./standup

# Generate and post to Slack/Teams
./standup --post
```

## Setup

### 1. Environment variables (optional, for auto-posting)

```bash
export SLACK_STANDUP_WEBHOOK="https://hooks.slack.com/services/xxx/yyy/zzz"
# or
export TEAMS_STANDUP_WEBHOOK="https://outlook.office.com/webhook/xxx"
```

### 2. Auto-run at 9am (macOS)

```bash
# Edit the plist to set the correct path
sed -i '' "s|STANDUP_PATH|$(pwd)|g" com.ai-workstation.standup.plist

# Install
cp com.ai-workstation.standup.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.ai-workstation.standup.plist
```

### 3. Auto-run at 9am (Linux/Windows via cron)

```bash
# crontab -e
0 9 * * 1-5 cd /path/to/standup && python3 standup.py --post
```

## Data Sources

| Source | Method | What it captures |
|---|---|---|
| Git | `git log --since=24h` | Your commits across branches |
| GitHub | `gh` CLI | PRs opened, reviewed, merged |
| Jira | MCP server | Tickets transitioned |
| Calendar | MS365 MCP | Today's meetings |

## Example Output

```
🟢 Milenko — June 7

**Yesterday:**
• Merged PR #142: Fix pagination on /users endpoint
• Moved PLAT-389 to "In Review"
• Reviewed PR #145 on platform-api (2 comments)

**Today:**
• Continue PLAT-401 (auth refactor — branch exists, 3 files touched)
• Sprint planning at 10:30

**Blockers:**
• None
```

## Configuration

| Env var | Default | Purpose |
|---|---|---|
| `OLLAMA_URL` | `http://localhost:11434` | Ollama endpoint |
| `STANDUP_MODEL` | `qwen3.5:4b` | Model for summarization |
| `SLACK_STANDUP_WEBHOOK` | (none) | Slack incoming webhook URL |
| `TEAMS_STANDUP_WEBHOOK` | (none) | Teams incoming webhook URL |
