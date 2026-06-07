#!/usr/bin/env python3
"""Automated standup generator — pulls activity from git, Jira, GitHub, calendar
and generates a formatted standup update via local LLM."""

import json
import subprocess
import os
import sys
from datetime import datetime, timedelta
from pathlib import Path

OLLAMA_URL = os.environ.get("OLLAMA_URL", "http://localhost:11434")
MODEL = os.environ.get("STANDUP_MODEL", "qwen2.5-coder:7b")
SLACK_WEBHOOK = os.environ.get("SLACK_STANDUP_WEBHOOK", "")
TEAMS_WEBHOOK = os.environ.get("TEAMS_STANDUP_WEBHOOK", "")


def git_activity(since_hours=24):
    """Get git commits from all repos in ~/Code or current dir."""
    email = subprocess.run(
        ["git", "config", "user.email"], capture_output=True, text=True
    ).stdout.strip()

    commits = subprocess.run(
        ["git", "log", f"--since={since_hours} hours ago", f"--author={email}",
         "--pretty=format:%h %s", "--all"],
        capture_output=True, text=True, cwd=os.getcwd()
    ).stdout.strip()

    return commits if commits else "No commits in the last 24h"


def jira_activity():
    """Get Jira activity via MCP (if configured)."""
    try:
        result = subprocess.run(
            ["npx", "-y", "mcp-server-atlassian", "--query",
             "assignee=currentUser() AND updated >= -1d ORDER BY updated DESC"],
            capture_output=True, text=True, timeout=15
        )
        return result.stdout.strip() if result.stdout.strip() else None
    except Exception:
        return None


def github_activity():
    """Get GitHub PRs via gh CLI."""
    try:
        prs = subprocess.run(
            ["gh", "search", "prs", "--author=@me", "--updated=>=" +
             (datetime.now() - timedelta(days=1)).strftime("%Y-%m-%d"),
             "--json", "title,state,repository,updatedAt", "--limit", "10"],
            capture_output=True, text=True, timeout=15
        )
        if prs.stdout.strip():
            items = json.loads(prs.stdout)
            return "\n".join(
                f"- [{pr['state']}] {pr['repository']['name']}: {pr['title']}"
                for pr in items
            )
    except Exception:
        pass
    return None


def calendar_today():
    """Get today's meetings (basic — reads from MS365 MCP or falls back)."""
    # Placeholder: in production this calls the MS365 MCP
    return None


def generate_standup(activity_data):
    """Send activity to local LLM and get formatted standup."""
    prompt = f"""/no_think
Based on this developer activity from the last 24 hours, generate a concise standup update.

Format exactly as:
**Yesterday:**
• (bullet points of completed work)

**Today:**
• (inferred next steps based on in-progress items)

**Blockers:**
• None (or list if apparent from context)

Developer activity:
{activity_data}

Keep it under 8 bullet points total. Be specific — mention ticket IDs, PR numbers, file names. Respond ONLY with the formatted standup, no preamble."""

    payload = {
        "model": MODEL,
        "prompt": prompt,
        "stream": False,
        "options": {"temperature": 0.3, "num_predict": 512}
    }

    import urllib.request
    req = urllib.request.Request(
        f"{OLLAMA_URL}/api/generate",
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        result = json.loads(resp.read())
        return result["response"].strip()


def post_slack(message):
    """Post to Slack via webhook."""
    if not SLACK_WEBHOOK:
        return False
    import urllib.request
    payload = json.dumps({"text": message}).encode()
    req = urllib.request.Request(SLACK_WEBHOOK, data=payload,
                                headers={"Content-Type": "application/json"})
    urllib.request.urlopen(req, timeout=10)
    return True


def post_teams(message):
    """Post to Teams via webhook."""
    if not TEAMS_WEBHOOK:
        return False
    import urllib.request
    payload = json.dumps({"text": message}).encode()
    req = urllib.request.Request(TEAMS_WEBHOOK, data=payload,
                                headers={"Content-Type": "application/json"})
    urllib.request.urlopen(req, timeout=10)
    return True


def main():
    print("📋 Gathering activity...")

    sections = []

    # Git
    git = git_activity()
    sections.append(f"Git commits:\n{git}")

    # GitHub PRs
    gh = github_activity()
    if gh:
        sections.append(f"GitHub PRs:\n{gh}")

    # Jira
    jira = jira_activity()
    if jira:
        sections.append(f"Jira tickets:\n{jira}")

    # Calendar
    cal = calendar_today()
    if cal:
        sections.append(f"Today's meetings:\n{cal}")

    activity = "\n\n".join(sections)

    if not activity.strip() or activity == "Git commits:\nNo commits in the last 24h":
        print("⚠️  No activity found. Nothing to report.")
        sys.exit(0)

    print("🤖 Generating standup...")
    standup = generate_standup(activity)

    # Header
    name = subprocess.run(["git", "config", "user.name"],
                         capture_output=True, text=True).stdout.strip() or "Developer"
    date = datetime.now().strftime("%B %d")
    header = f"🟢 **{name}** — {date}\n\n"
    full_message = header + standup

    print("\n" + "─" * 50)
    print(full_message)
    print("─" * 50)

    # Post if webhooks configured
    if "--post" in sys.argv:
        posted = False
        if post_slack(full_message):
            print("✅ Posted to Slack")
            posted = True
        if post_teams(full_message):
            print("✅ Posted to Teams")
            posted = True
        if not posted:
            print("ℹ️  No webhook configured. Set SLACK_STANDUP_WEBHOOK or TEAMS_STANDUP_WEBHOOK")
    else:
        print("\nRun with --post to send to Slack/Teams")


if __name__ == "__main__":
    main()
