#!/usr/bin/env python3
"""Generate weekly sprint report from git activity. Usage: python3 report.py [--days 7] [--repo /path]"""
import sys, json, urllib.request, subprocess, argparse
from datetime import datetime, timedelta

def llm(prompt, model='qwen2.5-coder:7b'):
    req = urllib.request.Request('http://localhost:11434/api/generate',
        data=json.dumps({'model': model, 'prompt': prompt, 'stream': False, 'options': {'temperature': 0.2, 'num_predict': 1024}}).encode(),
        headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.loads(resp.read())['response']

def git_log(repo, days):
    since = (datetime.now() - timedelta(days=days)).strftime('%Y-%m-%d')
    result = subprocess.run(
        ['git', '-C', repo, 'log', f'--since={since}', '--pretty=format:%h|%an|%s|%ad', '--date=short'],
        capture_output=True, text=True)
    return result.stdout.strip()

def git_stats(repo, days):
    since = (datetime.now() - timedelta(days=days)).strftime('%Y-%m-%d')
    result = subprocess.run(
        ['git', '-C', repo, 'log', f'--since={since}', '--shortstat', '--pretty=format:'],
        capture_output=True, text=True)
    return result.stdout.strip()

def main():
    parser = argparse.ArgumentParser(description='Sprint report generator')
    parser.add_argument('--days', type=int, default=7)
    parser.add_argument('--repo', default='.')
    parser.add_argument('--output', default=None)
    args = parser.parse_args()

    log = git_log(args.repo, args.days)
    stats = git_stats(args.repo, args.days)
    if not log:
        print("No commits found in the specified period.")
        sys.exit(0)
    prompt = f"""Generate a sprint report in markdown from this git activity.
Include: Summary, Key Accomplishments (bullet points), Contributors, Stats.
Format for managers (non-technical).

Git log (hash|author|message|date):
{log[:6000]}

Stats:
{stats[:2000]}"""
    print("📊 Generating sprint report...")
    report = llm(prompt)
    if args.output:
        with open(args.output, 'w') as f:
            f.write(report)
        print(f"Report saved to {args.output}")
    else:
        print(report)

if __name__ == '__main__':
    main()
