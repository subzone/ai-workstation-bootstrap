#!/usr/bin/env python3
"""Scan staged changes for security issues. Usage: git diff --staged | python3 scan.py"""
import sys, re, json, urllib.request

def llm(prompt, model='qwen2.5-coder:7b'):
    req = urllib.request.Request('http://localhost:11434/api/generate',
        data=json.dumps({'model': model, 'prompt': prompt, 'stream': False, 'options': {'temperature': 0.2, 'num_predict': 1024}}).encode(),
        headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.loads(resp.read())['response']

PATTERNS = [
    (r'(?i)(api[_-]?key|secret|password|token)\s*[=:]\s*["\'][^"\']{8,}', 'Hardcoded secret'),
    (r'(?i)(AKIA[0-9A-Z]{16})', 'AWS access key'),
    (r'(?i)execute\s*\(\s*[f"\'%]', 'Possible SQL injection'),
    (r'innerHTML\s*=', 'Possible XSS via innerHTML'),
    (r'(?i)(md5|sha1)\s*\(', 'Weak hash algorithm'),
    (r'verify\s*=\s*False', 'SSL verification disabled'),
    (r'eval\s*\(', 'Dangerous eval usage'),
]

def regex_scan(diff):
    findings = []
    for i, line in enumerate(diff.split('\n'), 1):
        if not line.startswith('+'):
            continue
        for pattern, desc in PATTERNS:
            if re.search(pattern, line):
                findings.append(f"  Line {i}: {desc} — {line.strip()[:80]}")
    return findings

def main():
    diff = sys.stdin.read().strip()
    if not diff:
        print("No diff provided. Usage: git diff --staged | python3 scan.py")
        sys.exit(0)
    print("🛡️  Scanning for security issues...")
    findings = regex_scan(diff)
    if not findings:
        print("✅ No security patterns detected.")
        sys.exit(0)
    print(f"⚠️  {len(findings)} potential issue(s) found by regex:")
    print('\n'.join(findings))
    # LLM confirmation
    snippet = '\n'.join(findings[:10])
    prompt = f"""These potential security issues were found in a git diff. For each, confirm if it's a true positive or false positive. Be brief.

{snippet}"""
    print("\n🤖 LLM analysis:")
    print(llm(prompt))
    sys.exit(1)

if __name__ == '__main__':
    main()
