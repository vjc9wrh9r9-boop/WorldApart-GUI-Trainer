# -*- coding: utf-8 -*-
"""原子方式重建 repo 的 main 分支树：
   1) 为目标文件创建 blob
   2) 用 base_tree 建树（树里没有的路径 = 删除，build/ 垃圾一次清空）
   3) 建 commit + 更新 ref
"""
import base64
import json
import os
import subprocess
import sys
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


# 收集目标文件
target = {}
SKIP_DIRS = {'.git', 'build', 'dist', '__pycache__'}
for dp, _, fn in os.walk(REPO_DIR):
    parts = set(dp.split(os.sep))
    if parts & SKIP_DIRS:
        continue
    for f in fn:
        if f.endswith(('.exe', '.pyc')) or f == 'res.zip':
            continue
        p = os.path.join(dp, f)
        rel = os.path.relpath(p, REPO_DIR).replace('\\', '/')
        target[rel] = p
print('[目标] %d 个文件' % len(target))

# 当前 head
ref = api('GET', '/repos/%s/%s/git/ref/heads/main' % (OWNER, REPO))
head_commit = ref['object']['sha']
base_tree = api('GET', '/repos/%s/%s/git/commits/%s' % (OWNER, REPO, head_commit))['tree']['sha']
print('[head]', head_commit[:10])

# 建 blob
tree_items = []
for rel, p in sorted(target.items()):
    data = open(p, 'rb').read()
    blob = api('POST', '/repos/%s/%s/git/blobs' % (OWNER, REPO),
               {'content': base64.b64encode(data).decode('ascii'),
                'encoding': 'base64'})
    tree_items.append({'path': rel, 'mode': '100644', 'type': 'blob',
                       'sha': blob['sha']})
    print('  blob %s (%d B)' % (rel, len(data)))

# 建树：不带 base_tree，tree_items 就是完整树（build/ 等垃圾自动消失）
tree = api('POST', '/repos/%s/%s/git/trees' % (OWNER, REPO),
           {'tree': tree_items})
print('[树] %s, %d 项' % (tree['sha'][:10], len(tree['tree'])))

# 建 commit
commit = api('POST', '/repos/%s/%s/git/commits' % (OWNER, REPO),
             {'message': 'V2.0: source restructure\n\n'
                         '- build_all 一键构建 / trainer.spec / requirements / BUILD.md\n'
                         '- 清理误提交的 build/ 历史产物',
              'tree': tree['sha'], 'parents': [head_commit]})
print('[commit]', commit['sha'][:10])

# 更新 ref
api('PATCH', '/repos/%s/%s/git/refs/heads/main' % (OWNER, REPO),
    {'sha': commit['sha'], 'force': False})
print('[完成] main ->', commit['sha'][:10])

# 校验
time.sleep(2)
t2 = api('GET', '/repos/%s/%s/git/trees/main?recursive=1' % (OWNER, REPO))
paths = [i['path'] for i in t2.get('tree', []) if i['type'] == 'blob']
bad = [p for p in paths if p.startswith('build/')]
print('[校验] 文件 %d 个, build/ 残留 %d' % (len(paths), len(bad)))
for p in sorted(paths):
    print('  ', p)
