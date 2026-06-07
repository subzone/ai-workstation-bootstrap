#!/usr/bin/env python3
"""Generate unit tests for a file. Usage: python3 generate.py <file_path>"""
import sys, os, json, urllib.request

def llm(prompt, model='qwen2.5-coder:7b'):
    req = urllib.request.Request('http://localhost:11434/api/generate',
        data=json.dumps({'model': model, 'prompt': prompt, 'stream': False, 'options': {'temperature': 0.2, 'num_predict': 1024}}).encode(),
        headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.loads(resp.read())['response']

FRAMEWORK_MAP = {
    '.py': ('pytest', 'test_{name}.py', 'tests/'),
    '.js': ('jest', '{name}.test.js', '__tests__/'),
    '.ts': ('jest', '{name}.test.ts', '__tests__/'),
    '.java': ('junit', '{name}Test.java', 'src/test/java/'),
    '.go': ('go test', '{name}_test.go', ''),
    '.rs': ('cargo test', '{name}_test.rs', 'tests/'),
}

def detect_framework(filepath):
    ext = os.path.splitext(filepath)[1]
    return FRAMEWORK_MAP.get(ext, ('unknown', 'test_{name}', 'tests/'))

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 generate.py <file_path>")
        sys.exit(1)
    filepath = sys.argv[1]
    if not os.path.exists(filepath):
        print(f"❌ File not found: {filepath}")
        sys.exit(1)
    with open(filepath) as f:
        source = f.read()
    if len(source) > 6000:
        source = source[:6000] + "\n... (truncated)"
    framework, test_pattern, test_dir = detect_framework(filepath)
    basename = os.path.splitext(os.path.basename(filepath))[0]
    test_filename = test_pattern.format(name=basename)
    prompt = f"""Generate unit tests for this file using {framework}.
Cover all public functions/methods. Include edge cases.
Output ONLY the test file content, no explanations.

Source file ({os.path.basename(filepath)}):
```
{source}
```"""
    print(f"🧪 Generating {framework} tests for {filepath}...")
    tests = llm(prompt)
    # Write test file
    out_dir = test_dir if os.path.isabs(test_dir) else os.path.join(os.path.dirname(filepath), test_dir)
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, test_filename)
    with open(out_path, 'w') as f:
        f.write(tests)
    print(f"✅ Tests written to {out_path}")

if __name__ == '__main__':
    main()
