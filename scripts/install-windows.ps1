#Requires -RunAsAdministrator
<#
.SYNOPSIS
    AI Workstation Bootstrap — Windows (Intune deployment)
.DESCRIPTION
    Silently installs and configures local-first AI developer tools.
    Designed to run as SYSTEM via Intune Win32 app deployment.
#>

$ErrorActionPreference = "Stop"
$LogDir = "C:\ProgramData\ai-bootstrap"
$LogFile = "$LogDir\install.log"
$ConfigSource = "$PSScriptRoot\..\configs"

# --- Logging ---
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

function Log {
    param([string]$Message)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$ts  $Message" | Tee-Object -FilePath $LogFile -Append
}

Log "=== AI Workstation Bootstrap started ==="
Log "User: $env:USERNAME | Machine: $env:COMPUTERNAME"

# --- Pre-flight: Check hardware ---
$ram = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB
$gpu = Get-CimInstance Win32_VideoController | Where-Object { $_.AdapterRAM -gt 4GB }

if ($ram -lt 30) {
    Log "ERROR: Insufficient RAM (${ram}GB). Minimum 32GB required."
    exit 1
}
if (-not $gpu) {
    Log "WARNING: No dedicated GPU detected. Models will run on CPU (slower)."
}
Log "Hardware OK: ${ram}GB RAM, GPU: $($gpu.Name)"

# --- Step 1: Install toolchain ---
Log "Installing VS Code..."
winget install --id Microsoft.VisualStudioCode --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
Log "VS Code installed."

Log "Installing Ollama..."
winget install --id Ollama.Ollama --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
Log "Ollama installed."

Log "Installing OpenCode..."
winget install --id OpenCode.OpenCode --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
Log "OpenCode installed."

# --- Step 2: Start Ollama and pull models ---
Log "Starting Ollama service..."
Start-Process "ollama" -ArgumentList "serve" -WindowStyle Hidden
Start-Sleep -Seconds 5

Log "Pulling qwen3.5:4b (RAG/Chat)..."
& ollama pull qwen3.5:4b 2>&1 | Out-Null
Log "Pulled qwen3.5:4b"

Log "Pulling qwen2.5-coder:1.5b (Autocomplete)..."
& ollama pull qwen2.5-coder:1.5b 2>&1 | Out-Null
Log "Pulled qwen2.5-coder:1.5b"

Log "Pulling nomic-embed-text (Embeddings)..."
& ollama pull nomic-embed-text 2>&1 | Out-Null
Log "Pulled nomic-embed-text"

# --- Step 3: Inject configurations ---
Log "Deploying configurations..."

# VS Code settings
$vscodeDir = "$env:APPDATA\Code\User"
New-Item -ItemType Directory -Path $vscodeDir -Force | Out-Null
Copy-Item "$ConfigSource\vscode\settings.json" "$vscodeDir\settings.json" -Force
Log "VS Code config deployed."

# OpenCode config
$opencodeDir = "$env:USERPROFILE\.opencode"
New-Item -ItemType Directory -Path $opencodeDir -Force | Out-Null
Copy-Item "$ConfigSource\opencode\.opencode.json" "$opencodeDir\.opencode.json" -Force
Copy-Item "$ConfigSource\opencode\mcp-servers.json" "$opencodeDir\mcp-servers.json" -Force
Log "OpenCode config deployed."

# Meetily config
$meetilyDir = "$env:APPDATA\Meetily"
New-Item -ItemType Directory -Path $meetilyDir -Force | Out-Null
Copy-Item "$ConfigSource\meetily\config.toml" "$meetilyDir\config.toml" -Force
Log "Meetily config deployed."

# --- Done ---
"installed" | Out-File "$LogDir\.installed" -Encoding ASCII
Log "=== AI Workstation Bootstrap completed successfully ==="
exit 0
