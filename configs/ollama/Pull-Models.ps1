# Pull-Models.ps1 — Download approved AI models
# Run after Ollama is installed and serving

$models = @(
    "qwen3.5:4b",           # Primary: RAG, chat, summarization (3.2GB)
    "qwen2.5-coder:1.5b",  # Autocomplete: fast inline suggestions (1.0GB)
    "nomic-embed-text"      # Embeddings: local codebase indexing (274MB)
)

Write-Host "Pulling approved models from Ollama registry..."
Write-Host "Total download: ~4.5GB"
Write-Host ""

foreach ($model in $models) {
    Write-Host "Pulling $model..." -ForegroundColor Cyan
    & ollama pull $model
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to pull $model" -ForegroundColor Red
        exit 1
    }
    Write-Host "OK: $model" -ForegroundColor Green
}

Write-Host ""
Write-Host "All models ready. Verify with: ollama list" -ForegroundColor Green
