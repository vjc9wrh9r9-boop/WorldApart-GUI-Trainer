# -*- coding: utf-8 -*-
"""把 packaged/ 结构全量同步到 GitHub（API 方式，含删除孤立文件）"""
import base64
import json
import os
import subprocess
import time
import urllib.request
from urllib.parse import quote

TOKEN = None
for ln in subprocess.run(['git', 'credential', 'fill'],
                         input='protocol=https\nhost=github.com\n\n',
                         capture_output=True, text=True).stdout.splitlines():
    if ln.startswith('password='):
        TOKEN = ln[9:]
OWNER, REPO = 'vjc9wrh9r9-boop', 'WorldApart-GUI-Trainer'
REPO_DIR = os.getcwd()


def api(method, path, payload=None, tries=6):
    data = None if payload is None else json.dumps(
        payload, ensure_ascii=False).encode('utf-8')
    last = None
    for attempt in range(tries):
        try:
            req = urllib.request.Request('https://api.github.com' + path,
                                         data=data, method=method,
                                         headers={'Authorization': 'token ' + TOKEN,
                                                  'User-Agent': 'bwf',
                                                  'Content-Type': 'application/json'})
            with urllib.request.urlopen(req, timeout=60) as r:
                body = r.read()
            return json.loads(body) if body else {}
        except urllib.error.HTTPError as e:
            if e.code in (404, 422):
                raise
            last = e
        except Exception as e:
            last = e
        time.sleep(2 + attempt * 2)
    raise last


def enc(p):
    return quote(p, safe='/')


target = {}
for dp, _, fn in os.walk(REPO_DIR):
    if '.git' in dp:
        continue
    for f in fn:
        p = os.path.join(dp, f)
        rel = os.path.relpath(p, REPO_DIR).replace('\\', '/')
        target[rel] = p

tree = api('GET', '/repos/%s/%s/git/trees/main?recursive=1' % (OWNER, REPO))
existing = {i['path']: i['sha'] for i in tree.get('tree', []) if i['type'] == 'blob'}
print('[现有] %d 个文件' % len(existing))

added = updated = removed = 0
for rel, p in sorted(target.items()):
    data = open(p, 'rb').read()
    body = {'message': 'chore: %s' % rel,
            'content': base64.b64encode(data).decode('ascii')}
    if rel in existing:
        body['sha'] = existing[rel]
    api('PUT', '/repos/%s/%s/contents/%s' % (OWNER, REPO, enc(rel)), body)
    if rel in existing:
        updated += 1
    else:
        added += 1
    print('  + %s (%d B)' % (rel, len(data)))

for rel in sorted(set(existing) - set(target)):
    api('DELETE', '/repos/%s/%s/contents/%s?sha=%s' % (OWNER, REPO, enc(rel), existing[rel]))
    removed += 1
    print('  - %s' % rel)

print('完成: 新增 %d, 更新 %d, 删除 %d' % (added, updated, removed))
