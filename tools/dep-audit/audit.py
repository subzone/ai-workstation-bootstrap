#!/usr/bin/env python3
"""Dependency audit with LLM summary. Usage: python3 audit.py [/path/to/project]"""
import sys, os, json, urllib.request, subprocess

def llm(prompt, model='qwen2.5-coder:7b'):
    req = urllib.request.Request('http://localhost:11434/api/generate',
        data=json.dumps({'model': model, 'prompt': prompt, 'stream': False, 'options': {'temperature': 0.2, 'num_predict': 1024}}).encode(),
        headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.loads(resp.read())['response']

def detect_and_audit(project_dir):
    """Detect project type and run appropriate audit."""
    if os.path.exists(os.path.join(project_dir, 'package-lock.json')):
        r = subprocess.run(['npm', 'audit', '--json'], capture_output=True, text=True, cwd=project_dir)
        return 'npm', r.stdout
    if os.path.exists(os.path.join(project_dir, 'requirements.txt')) or os.path.exists(os.path.join(project_dir, 'Pipfile')):
        r = subprocess.run(['pip', 'audit', '--format=json'], capture_output=True, text=True, cwd=project_dir)
        return 'pip', r.stdout
    if os.path.exists(os.path.join(project_dir, 'Cargo.lock')):
        r = subprocess.run(['cargo', 'audit', '--json'], capture_output=True, text=True, cwd=project_dir)
        return 'cargo', r.stdout
    return None, None

def main():
    project_dir = sys.argv[1] if len(sys.argv) > 1 else '.'
    project_dir = os.path.abspath(project_dir)
    print(f"🔎 Auditing dependencies in {project_dir}...")
    pkg_mgr, output = detect_and_audit(project_dir)
    if not pkg_mgr:
        print("❌ No supported project detected (need package-lock.json, requirements.txt, or Cargo.lock)")
        sys.exit(1)
    if not output or output.strip() == '{}':
        print(f"✅ {pkg_mgr} audit: no vulnerabilities found.")
        sys.exit(0)
    # Truncate for LLM
    truncated = output[:6000] if len(output) > 6000 else output
    prompt = f"""Summarize this {pkg_mgr} audit output into actionable items.
For each vulnerability list: package, severity (critical/high/medium/low), what to do (upgrade version or replace).
End with a priority-ordered action plan.

Audit output:
{truncated}"""
    print(f"📦 {pkg_mgr} audit complete. Summarizing with LLM...")
    print(llm(prompt))

if __name__ == '__main__':
    main()
