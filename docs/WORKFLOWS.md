# Automated Workflows

Daily, weekly, and event-driven automations that run without manual intervention.

## Daily (9:00 AM)

### Standup Generation
Generates your standup update and posts to Slack/Teams.

```bash
# Manual
standup --post

# Automate (macOS — launchd)
cp ~/.ai-bootstrap/repo/tools/standup/com.ai-workstation.standup.plist ~/Library/LaunchAgents/
sed -i '' "s|STANDUP_PATH|$HOME/.local/bin|g" ~/Library/LaunchAgents/com.ai-workstation.standup.plist
launchctl load ~/Library/LaunchAgents/com.ai-workstation.standup.plist

# Automate (Linux — cron)
(crontab -l 2>/dev/null; echo "0 9 * * 1-5 $HOME/.local/bin/standup --post") | crontab -
```

### Dependency Audit
Check for vulnerabilities at start of day.

```bash
# Manual
cd ~/Code/my-project && python3 ~/.ai-bootstrap/repo/tools/dep-audit/audit.py

# Automate (cron — every morning at 8:30)
(crontab -l 2>/dev/null; echo "30 8 * * 1-5 cd ~/Code/my-project && python3 ~/.ai-bootstrap/repo/tools/dep-audit/audit.py > /tmp/dep-audit.txt 2>&1") | crontab -
```

---

## On Every Commit (pre-commit hooks)

### Code Review + Security Scan

```bash
# Install in your project
cd ~/Code/my-project
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
echo "🔍 Running AI code review..."
git diff --staged | python3 ~/.ai-bootstrap/repo/tools/code-review/review.py || exit 1

echo "🔒 Running security scan..."
python3 ~/.ai-bootstrap/repo/tools/security-scan/scan.py || exit 1
EOF
chmod +x .git/hooks/pre-commit
```

Now every `git commit` auto-reviews your changes and blocks if it finds bugs or secrets.

---

## Weekly (Friday 4:00 PM)

### Sprint Report
Generates a markdown summary for your manager.

```bash
# Manual
python3 ~/.ai-bootstrap/repo/tools/sprint-report/report.py --days 7

# Automate (cron — Friday 4pm)
(crontab -l 2>/dev/null; echo "0 16 * * 5 cd ~/Code/my-project && python3 ~/.ai-bootstrap/repo/tools/sprint-report/report.py --days 7 > ~/Documents/sprint-report-\$(date +\%F).md") | crontab -
```

---

## On Demand

### Test Generation
After writing a new file, generate tests:

```bash
python3 ~/.ai-bootstrap/repo/tools/test-gen/generate.py src/services/auth.py
```

### Log Explanation
When debugging:

```bash
# From clipboard
pbpaste | python3 ~/.ai-bootstrap/repo/tools/log-explainer/explain.py

# From file
cat /var/log/app/error.log | python3 ~/.ai-bootstrap/repo/tools/log-explainer/explain.py

# Direct
python3 ~/.ai-bootstrap/repo/tools/log-explainer/explain.py "NullPointerException at UserService.java:42"
```

### Code RAG — Index a new project
```bash
python3 ~/.ai-bootstrap/repo/tools/code-rag/code_rag.py index ~/Code/new-project --collection new-project
```

---

## All-in-One Setup

Run this once to set up all automations:

```bash
#!/bin/bash
# setup-automations.sh — install all daily/weekly/commit automations

# Pre-commit hooks for current project
cat > .git/hooks/pre-commit << 'HOOK'
#!/bin/bash
git diff --staged | python3 ~/.ai-bootstrap/repo/tools/code-review/review.py || exit 1
python3 ~/.ai-bootstrap/repo/tools/security-scan/scan.py || exit 1
HOOK
chmod +x .git/hooks/pre-commit
echo "✅ Pre-commit hooks installed"

# Cron jobs
(crontab -l 2>/dev/null
echo "0 9 * * 1-5 $HOME/.local/bin/standup --post"
echo "30 8 * * 1-5 cd ~/Code/my-project && python3 ~/.ai-bootstrap/repo/tools/dep-audit/audit.py > /tmp/dep-audit.txt 2>&1"
echo "0 16 * * 5 python3 ~/.ai-bootstrap/repo/tools/sprint-report/report.py --days 7 > ~/Documents/sprint-report-\$(date +\%F).md"
) | sort -u | crontab -
echo "✅ Cron jobs: standup (9am), dep-audit (8:30am), sprint-report (Fri 4pm)"

# Index codebase for RAG
echo "Indexing codebase for AI search..."
cd ~/.ai-bootstrap/repo/tools/code-rag && uv run python3 code_rag.py index ~/Code/my-project
echo "✅ Code RAG indexed"
```

---

## Environment Variables

Set these in `~/.zshrc` or `~/.bashrc` for full automation:

```bash
# Webhook for posting standups/reports
export SLACK_STANDUP_WEBHOOK="https://hooks.slack.com/services/xxx/yyy/zzz"

# Model override (optional)
export STANDUP_MODEL="qwen3.5:4b"
export CODE_REVIEW_MODEL="qwen2.5-coder:7b"
```
