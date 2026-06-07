# MCP Server Authentication Setup

Each MCP server needs credentials to access corporate tools. This guide walks you through setting up each one. Tokens are stored locally on your machine — never sent to any AI service.

---

## 1. GitHub

**What it enables:** Read PRs, issues, code search, create issues from terminal.

```bash
# Generate a Personal Access Token:
# 1. Go to https://github.com/settings/tokens
# 2. Click "Generate new token (classic)"
# 3. Select scopes: repo, read:org, read:user
# 4. Copy the token

# Set it:
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxx"

# Persist (add to your shell profile):
echo 'export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxx"' >> ~/.zshrc
```

**Verify:** `gh auth status` should show authenticated.

---

## 2. Microsoft 365 (Mail, Calendar, Files, Teams)

**What it enables:** Read emails, check calendar, search OneDrive files, post to Teams channels.

### Option A: Personal token (developer self-service)

```bash
# 1. Go to https://portal.azure.com → App registrations → New registration
# 2. Name: "AI Workstation - <your name>"
# 3. Redirect URI: http://localhost:3000/callback
# 4. Under "API permissions" add:
#    - Mail.Read, Calendars.Read, Files.Read, Chat.Read
# 5. Under "Certificates & secrets" → New client secret → Copy value

export MS365_TENANT_ID="your-azure-tenant-id"
export MS365_CLIENT_ID="app-registration-client-id"
export MS365_CLIENT_SECRET="client-secret-value"
```

### Option B: Admin pre-provisions (recommended for teams)

Your IT admin creates one app registration with delegated permissions and distributes the client ID. Each developer authenticates on first use via browser popup.

Ask your admin for the `MS365_TENANT_ID` and `MS365_CLIENT_ID` values.

---

## 3. Jira

**What it enables:** Read tickets, search issues, view sprint boards, transition tickets.

```bash
# 1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
# 2. Click "Create API token"
# 3. Label: "AI Workstation"
# 4. Copy the token

export JIRA_URL="https://yourcompany.atlassian.net"
export JIRA_EMAIL="your.email@company.com"
export JIRA_API_TOKEN="your-api-token"
```

**Verify:** `curl -u "$JIRA_EMAIL:$JIRA_API_TOKEN" "$JIRA_URL/rest/api/3/myself" | jq .displayName`

---

## 4. Confluence

**What it enables:** Search docs, read pages, find runbooks and technical specs.

```bash
# Uses the SAME Atlassian API token as Jira

export CONFLUENCE_URL="https://yourcompany.atlassian.net/wiki"
export CONFLUENCE_EMAIL="your.email@company.com"
export CONFLUENCE_API_TOKEN="your-api-token"  # same token as Jira
```

---

## Storing Credentials Securely

### macOS (Keychain) — Recommended

Rather than plain environment variables, store in Keychain:

```bash
# Store
security add-generic-password -a "$USER" -s "GITHUB_TOKEN" -w "ghp_xxx"
security add-generic-password -a "$USER" -s "JIRA_API_TOKEN" -w "your-token"
security add-generic-password -a "$USER" -s "MS365_CLIENT_SECRET" -w "your-secret"

# Retrieve (use in shell profile)
export GITHUB_TOKEN=$(security find-generic-password -a "$USER" -s "GITHUB_TOKEN" -w)
export JIRA_API_TOKEN=$(security find-generic-password -a "$USER" -s "JIRA_API_TOKEN" -w)
export MS365_CLIENT_SECRET=$(security find-generic-password -a "$USER" -s "MS365_CLIENT_SECRET" -w)
```

### Windows (Credential Manager)

```powershell
# Store
cmdkey /generic:GITHUB_TOKEN /user:token /pass:ghp_xxx
cmdkey /generic:JIRA_API_TOKEN /user:token /pass:your-token

# Retrieve in scripts (PowerShell)
$cred = Get-StoredCredential -Target "GITHUB_TOKEN"
$env:GITHUB_TOKEN = $cred.GetNetworkCredential().Password
```

### Linux (secret-tool / GNOME Keyring)

```bash
# Store
secret-tool store --label="GitHub Token" service ai-workstation key GITHUB_TOKEN <<< "ghp_xxx"

# Retrieve
export GITHUB_TOKEN=$(secret-tool lookup service ai-workstation key GITHUB_TOKEN)
```

---

## Quick Verification

After setting up all tokens, verify everything works:

```bash
# GitHub
gh api user --jq .login

# Jira
curl -s -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  "$JIRA_URL/rest/api/3/myself" | python3 -c "import json,sys; print(json.load(sys.stdin)['displayName'])"

# MS365 (will open browser for auth on first run)
npx -y @subzone81/ms-365-mcp --test
```

If all three print your name/email, you're good to go.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| "401 Unauthorized" on Jira | Regenerate API token at id.atlassian.com |
| GitHub "Bad credentials" | Token expired — create new one at github.com/settings/tokens |
| MS365 "AADSTS700016" | Wrong tenant ID — ask your IT admin |
| "Connection refused" on any MCP | Ollama must be running: `ollama serve` |
| MCP server hangs | Kill with `pkill -f mcp-server` and retry |
