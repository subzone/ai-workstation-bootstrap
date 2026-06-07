#!/usr/bin/env python3
"""code-rag-mcp — Local code & document RAG exposed as MCP server.

Indexes codebases and documents locally using Ollama embeddings + ChromaDB.
Any MCP-compatible tool (Claude, Kiro, OpenCode, Continue, Copilot) can query it.

Usage:
    # Index a project
    code-rag index /path/to/project

    # Index documents
    code-rag index ~/docs --collection docs

    # Run as MCP server (stdio transport)
    code-rag serve
"""

import json
import hashlib
import os
import sys
import time
from pathlib import Path
from typing import Optional

# ─── Config ───
OLLAMA_URL = os.environ.get("OLLAMA_URL", "http://localhost:11434")
EMBED_MODEL = os.environ.get("EMBED_MODEL", "nomic-embed-text")
DB_PATH = os.environ.get("CODE_RAG_DB", str(Path.home() / ".code-rag" / "db"))
CHUNK_SIZE = int(os.environ.get("CHUNK_SIZE", "1500"))
CHUNK_OVERLAP = int(os.environ.get("CHUNK_OVERLAP", "200"))

# File extensions to index
CODE_EXTENSIONS = {
    ".py", ".js", ".ts", ".tsx", ".jsx", ".go", ".rs", ".java", ".kt",
    ".cs", ".cpp", ".c", ".h", ".rb", ".php", ".swift", ".scala",
    ".sh", ".bash", ".yaml", ".yml", ".toml", ".json", ".sql",
    ".tf", ".hcl", ".dockerfile", ".vue", ".svelte",
}
DOC_EXTENSIONS = {".md", ".txt", ".rst", ".adoc", ".org", ".csv"}
ALL_EXTENSIONS = CODE_EXTENSIONS | DOC_EXTENSIONS

IGNORE_DIRS = {
    "node_modules", ".git", "__pycache__", ".venv", "venv", "dist",
    "build", "target", ".next", ".nuxt", "vendor", ".terraform",
}


def get_embed(text: str) -> list[float]:
    """Get embedding from Ollama."""
    import urllib.request
    req = urllib.request.Request(
        f"{OLLAMA_URL}/api/embed",
        data=json.dumps({"model": EMBED_MODEL, "input": text}).encode(),
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        data = json.loads(resp.read())
        return data["embeddings"][0]


def chunk_code(content: str, filepath: str) -> list[dict]:
    """Chunk code by logical boundaries (functions/classes) with fallback to size."""
    chunks = []
    lines = content.split("\n")

    # Try splitting on function/class boundaries
    boundaries = []
    for i, line in enumerate(lines):
        stripped = line.strip()
        if any(stripped.startswith(kw) for kw in
               ("def ", "class ", "function ", "func ", "fn ", "pub fn ",
                "export ", "async function", "const ", "module ", "package ")):
            boundaries.append(i)

    if len(boundaries) > 1:
        # Split on boundaries
        for idx, start in enumerate(boundaries):
            end = boundaries[idx + 1] if idx + 1 < len(boundaries) else len(lines)
            chunk_text = "\n".join(lines[start:end])
            if len(chunk_text.strip()) > 20:
                chunks.append({
                    "text": chunk_text[:CHUNK_SIZE],
                    "filepath": filepath,
                    "start_line": start + 1,
                    "end_line": end,
                    "type": "code",
                })
    else:
        # Fallback: fixed-size chunks
        text = content
        for i in range(0, len(text), CHUNK_SIZE - CHUNK_OVERLAP):
            chunk = text[i:i + CHUNK_SIZE]
            if len(chunk.strip()) > 20:
                chunks.append({
                    "text": chunk,
                    "filepath": filepath,
                    "start_line": content[:i].count("\n") + 1,
                    "end_line": content[:i + len(chunk)].count("\n") + 1,
                    "type": "code" if Path(filepath).suffix in CODE_EXTENSIONS else "doc",
                })
    return chunks


def get_db():
    """Get or create ChromaDB client."""
    import chromadb
    Path(DB_PATH).mkdir(parents=True, exist_ok=True)
    return chromadb.PersistentClient(path=DB_PATH)


def index_path(target: str, collection_name: str = "codebase"):
    """Index a directory into ChromaDB."""
    db = get_db()
    collection = db.get_or_create_collection(
        name=collection_name,
        metadata={"hnsw:space": "cosine"},
    )

    target_path = Path(target).resolve()
    files_indexed = 0
    chunks_total = 0

    for fpath in target_path.rglob("*"):
        if any(p in fpath.parts for p in IGNORE_DIRS):
            continue
        if fpath.suffix.lower() not in ALL_EXTENSIONS:
            continue
        if fpath.stat().st_size > 500_000:  # skip files > 500KB
            continue

        try:
            content = fpath.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            continue

        rel_path = str(fpath.relative_to(target_path))
        chunks = chunk_code(content, rel_path)

        for chunk in chunks:
            doc_id = hashlib.sha256(
                f"{rel_path}:{chunk['start_line']}".encode()
            ).hexdigest()[:16]

            try:
                embedding = get_embed(chunk["text"][:2000])
                collection.upsert(
                    ids=[doc_id],
                    embeddings=[embedding],
                    documents=[chunk["text"]],
                    metadatas=[{
                        "filepath": chunk["filepath"],
                        "start_line": chunk["start_line"],
                        "end_line": chunk["end_line"],
                        "type": chunk["type"],
                        "collection": collection_name,
                    }],
                )
                chunks_total += 1
            except Exception as e:
                print(f"  ⚠️  Skip {rel_path}: {e}", file=sys.stderr)

        files_indexed += 1
        if files_indexed % 10 == 0:
            print(f"  Indexed {files_indexed} files, {chunks_total} chunks...",
                  file=sys.stderr)

    print(f"✅ Indexed {files_indexed} files → {chunks_total} chunks in '{collection_name}'",
          file=sys.stderr)


def search(query: str, collection_name: str = "codebase",
           n_results: int = 10) -> list[dict]:
    """Search the index."""
    db = get_db()
    try:
        collection = db.get_collection(collection_name)
    except Exception:
        return []

    query_embedding = get_embed(query)
    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=n_results,
        include=["documents", "metadatas", "distances"],
    )

    hits = []
    for i in range(len(results["ids"][0])):
        hits.append({
            "text": results["documents"][0][i],
            "filepath": results["metadatas"][0][i]["filepath"],
            "start_line": results["metadatas"][0][i]["start_line"],
            "type": results["metadatas"][0][i]["type"],
            "score": 1 - results["distances"][0][i],  # cosine similarity
        })
    return hits


def list_collections() -> list[str]:
    """List all indexed collections."""
    db = get_db()
    return [c.name for c in db.list_collections()]


# ─── MCP Server (stdio transport) ───

def serve_mcp():
    """Run as MCP server over stdio."""
    # MCP protocol: JSON-RPC 2.0 over stdin/stdout
    def send(msg):
        out = json.dumps(msg)
        sys.stdout.write(f"Content-Length: {len(out)}\r\n\r\n{out}")
        sys.stdout.flush()

    def read_message():
        headers = {}
        while True:
            line = sys.stdin.readline()
            if line == "\r\n" or line == "\n":
                break
            if ":" in line:
                k, v = line.split(":", 1)
                headers[k.strip()] = v.strip()
        length = int(headers.get("Content-Length", 0))
        body = sys.stdin.read(length)
        return json.loads(body)

    # Tool definitions
    tools = [
        {
            "name": "search_codebase",
            "description": "Search indexed codebase and documents using semantic similarity. Returns relevant code snippets, file paths, and line numbers.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "Natural language query or code pattern to search for",
                    },
                    "collection": {
                        "type": "string",
                        "description": "Collection to search (default: 'codebase'). Use 'docs' for documentation.",
                        "default": "codebase",
                    },
                    "limit": {
                        "type": "integer",
                        "description": "Max results to return",
                        "default": 5,
                    },
                },
                "required": ["query"],
            },
        },
        {
            "name": "list_indexed_collections",
            "description": "List all indexed code/document collections available for search.",
            "inputSchema": {"type": "object", "properties": {}},
        },
        {
            "name": "index_project",
            "description": "Index a project directory for semantic code search. Run this before searching a new codebase.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "Absolute path to project directory",
                    },
                    "collection": {
                        "type": "string",
                        "description": "Collection name (default: 'codebase')",
                        "default": "codebase",
                    },
                },
                "required": ["path"],
            },
        },
    ]

    while True:
        try:
            msg = read_message()
        except (EOFError, json.JSONDecodeError):
            break

        method = msg.get("method", "")
        req_id = msg.get("id")

        if method == "initialize":
            send({"jsonrpc": "2.0", "id": req_id, "result": {
                "protocolVersion": "2024-11-05",
                "capabilities": {"tools": {}},
                "serverInfo": {"name": "code-rag", "version": "0.1.0"},
            }})
        elif method == "notifications/initialized":
            pass  # no response needed
        elif method == "tools/list":
            send({"jsonrpc": "2.0", "id": req_id, "result": {"tools": tools}})
        elif method == "tools/call":
            tool_name = msg["params"]["name"]
            args = msg["params"].get("arguments", {})

            if tool_name == "search_codebase":
                results = search(
                    args["query"],
                    args.get("collection", "codebase"),
                    args.get("limit", 5),
                )
                text = "\n\n".join(
                    f"**{r['filepath']}** (L{r['start_line']}, score: {r['score']:.2f}):\n```\n{r['text'][:500]}\n```"
                    for r in results
                ) or "No results found. Try indexing first: index_project"
                send({"jsonrpc": "2.0", "id": req_id, "result": {
                    "content": [{"type": "text", "text": text}],
                }})

            elif tool_name == "list_indexed_collections":
                cols = list_collections()
                send({"jsonrpc": "2.0", "id": req_id, "result": {
                    "content": [{"type": "text", "text": json.dumps(cols)}],
                }})

            elif tool_name == "index_project":
                try:
                    index_path(args["path"], args.get("collection", "codebase"))
                    send({"jsonrpc": "2.0", "id": req_id, "result": {
                        "content": [{"type": "text", "text": f"Indexed {args['path']} into '{args.get('collection', 'codebase')}'"}],
                    }})
                except Exception as e:
                    send({"jsonrpc": "2.0", "id": req_id, "result": {
                        "content": [{"type": "text", "text": f"Error: {e}"}],
                    }})
        else:
            if req_id:
                send({"jsonrpc": "2.0", "id": req_id, "error": {
                    "code": -32601, "message": f"Unknown method: {method}",
                }})


# ─── CLI ───

def main():
    if len(sys.argv) < 2:
        print("Usage: code-rag <command> [args]")
        print("Commands: index <path> [--collection name], search <query>, serve, collections")
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == "serve":
        serve_mcp()
    elif cmd == "index":
        path = sys.argv[2] if len(sys.argv) > 2 else "."
        collection = "codebase"
        if "--collection" in sys.argv:
            idx = sys.argv.index("--collection")
            collection = sys.argv[idx + 1]
        index_path(path, collection)
    elif cmd == "search":
        query = " ".join(sys.argv[2:])
        results = search(query)
        for r in results:
            print(f"\n{'─'*60}")
            print(f"📄 {r['filepath']} (L{r['start_line']}) — score: {r['score']:.2f}")
            print(r["text"][:300])
    elif cmd == "collections":
        for c in list_collections():
            print(f"  • {c}")
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)


if __name__ == "__main__":
    main()
