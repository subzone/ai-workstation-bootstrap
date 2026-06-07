# code-rag — Local Code & Document RAG (MCP Server)

Semantic search over your codebase and documents, running fully local. Exposes an MCP interface so **any AI coding tool** can use it.

## Compatible With

| Tool | Integration |
|---|---|
| Claude Code | Native MCP |
| Kiro | MCP tools |
| GitHub Copilot | Via VS Code MCP extension |
| Continue (VS Code) | MCP context provider |
| OpenCode | MCP config |
| Antigravity | MCP protocol |
| Any MCP client | stdio transport |

## How It Works

```
Your Code → chunk by functions → embed via nomic-embed-text (Ollama) → ChromaDB (local)
                                                                              ↓
AI Tool asks "how does auth work?" → embed query → cosine search → return top snippets
```

## Install

```bash
pip install chromadb
# Ollama + nomic-embed-text must be running (already in bootstrap)
```

## Usage

### Index a project
```bash
python3 code_rag.py index /path/to/project
python3 code_rag.py index /path/to/project --collection my-service
python3 code_rag.py index ~/docs --collection documentation
```

### Search
```bash
python3 code_rag.py search "how does authentication middleware work"
python3 code_rag.py search "database connection pooling"
```

### List indexed collections
```bash
python3 code_rag.py collections
```

### Run as MCP server
```bash
python3 code_rag.py serve
```

## MCP Configuration

Add to your `mcp-servers.json` (or `.claude`, `.kiro`, etc.):

```json
{
  "code-rag": {
    "command": "python3",
    "args": ["/path/to/code_rag.py", "serve"],
    "env": {
      "OLLAMA_URL": "http://localhost:11434",
      "EMBED_MODEL": "nomic-embed-text"
    }
  }
}
```

### For Claude Code (`~/.claude/claude_desktop_config.json`)
```json
{
  "mcpServers": {
    "code-rag": {
      "command": "python3",
      "args": ["~/.local/bin/code_rag.py", "serve"]
    }
  }
}
```

### For Kiro
Add to your project's `.kiro/mcp.json` or global MCP config.

### For Continue (VS Code)
```json
{
  "experimental": {
    "modelContextProtocolServers": [
      {
        "transport": { "type": "stdio", "command": "python3", "args": ["~/.local/bin/code_rag.py", "serve"] }
      }
    ]
  }
}
```

## MCP Tools Exposed

| Tool | Description |
|---|---|
| `search_codebase` | Semantic search — returns code snippets with file paths and line numbers |
| `index_project` | Index a new project directory |
| `list_indexed_collections` | Show what's been indexed |

## How Chunking Works

- **Code files:** Split on function/class boundaries (def, class, func, fn, export, etc.)
- **Documents:** Fixed-size chunks with overlap
- **Embedding model:** `nomic-embed-text` (768 dimensions, fast, local)
- **Vector store:** ChromaDB with HNSW index, cosine similarity
- **Storage:** `~/.code-rag/db/` (~50MB per 10K file project)

## Environment Variables

| Var | Default | Purpose |
|---|---|---|
| `OLLAMA_URL` | `http://localhost:11434` | Ollama endpoint |
| `EMBED_MODEL` | `nomic-embed-text` | Embedding model |
| `CODE_RAG_DB` | `~/.code-rag/db` | ChromaDB storage path |
| `CHUNK_SIZE` | `1500` | Max chars per chunk |
| `CHUNK_OVERLAP` | `200` | Overlap between chunks |

## Re-indexing

Run `index` again on the same path — it uses `upsert`, so changed files get updated and unchanged files are skipped (by content hash).
