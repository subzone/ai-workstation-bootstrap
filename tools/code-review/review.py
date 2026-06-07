#!/usr/bin/env python3
"""Pre-commit code review via local LLM. Usage: git diff --staged | python3 review.py"""
import sys, json, urllib.request

def llm(prompt, model='qwen2.5-coder:7b'):
    req = urllib.request.Request('http://localhost:11434/api/generate',
        data=json.dumps({'model': model, 'prompt': prompt, 'stream': False, 'options': {'temperature': 0.2, 'num_predict': 1024}}).encode(),
        headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.loads(resp.read())['response']

def main():
    diff = sys.stdin.read().strip()
    if not diff:
        print("No diff provided. Usage: git diff --staged | python3 review.py")
        sys.exit(0)
    # Truncate large diffs
    if len(diff) > 8000:
        diff = diff[:8000] + "\n... (truncated)"
    prompt = f"""Review this git diff for bugs, security issues, and style problems.
For each issue found, output: [SEVERITY] file:line — description
Severities: BUG, SECURITY, STYLE, PERF
If no issues, say "No issues found."

Diff:
```
{diff}
```"""
    print("🔍 Reviewing staged changes...")
    result = llm(prompt)
    print(result)
    # Exit non-zero if BUG or SECURITY found (blocks commit)
    if any(sev in result for sev in ("[BUG]", "[SECURITY]")):
        sys.exit(1)

if __name__ == '__main__':
    main()
