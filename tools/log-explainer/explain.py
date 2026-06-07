#!/usr/bin/env python3
"""Explain stack traces and error logs. Usage: cat error.log | python3 explain.py or python3 explain.py 'error message'"""
import sys, json, urllib.request, subprocess

def llm(prompt, model='qwen2.5-coder:7b'):
    req = urllib.request.Request('http://localhost:11434/api/generate',
        data=json.dumps({'model': model, 'prompt': prompt, 'stream': False, 'options': {'temperature': 0.2, 'num_predict': 1024}}).encode(),
        headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.loads(resp.read())['response']

def search_code_rag(query):
    """Try to find relevant source via code-rag if available."""
    try:
        result = subprocess.run(
            ['python3', '-c', f'from code_rag import search; search("{query}")'],
            capture_output=True, text=True, timeout=10)
        return result.stdout.strip() if result.returncode == 0 else ""
    except Exception:
        return ""

def main():
    if not sys.stdin.isatty():
        log = sys.stdin.read().strip()
    elif len(sys.argv) > 1:
        log = ' '.join(sys.argv[1:])
    else:
        print("Usage: cat error.log | python3 explain.py  OR  python3 explain.py 'error message'")
        sys.exit(0)
    if not log:
        sys.exit(0)
    # Truncate
    if len(log) > 6000:
        log = log[:6000] + "\n... (truncated)"
    context = search_code_rag(log[:200])
    ctx_section = f"\nRelevant source context:\n{context}" if context else ""
    prompt = f"""Analyze this error log / stack trace. Provide:
1. Root cause (one sentence)
2. Explanation (2-3 sentences)
3. Suggested fix
{ctx_section}

Error:
```
{log}
```"""
    print("🔬 Analyzing error...")
    print(llm(prompt))

if __name__ == '__main__':
    main()
