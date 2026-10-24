# -*- coding: utf-8 -*-
"""一键发版到 GitHub：同步源码/文档/使用说明 + version.json + Release 资产
   用法: python publish_github.py "更新说明一句话"（可选，不填则用默认）
"""
import base64, json, os, re, subprocess, sys, time, urllib.request
from urllib.parse import quote

TOKEN = None
for ln in subprocess.run(['git', 'credential', 'fill'],
                         input='protocol=https\nhost=github.com\n\n',
                         capture_output=True, text=True).stdout.splitlines():
    if ln.startswith('password='):
        TOKEN = ln[9:]
OWNER, REPO = 'vjc9wrh9r9-boop', 'WorldApart-GUI-Trainer'
ROOT = r'E:/workbuddy 数据/2026-10-15-00-57-48/bwf'
REPO_DIR = os.path.join(ROOT, 'github_repo')
DIST = os.path.join(ROOT, 'py_gui', 'dist', 'BWF_Trainer_v13.exe')
MANUAL_SRC = r'E:/360MoveData/Users/新建文件夹/不问凡尘使用说明.txt'

NOTE = sys.argv[1] if len(sys.argv) > 1 else '性能优化与问题修复'


def api(method, path, payload=None):
    data = None if payload is None else json.dumps(payload, ensure_ascii=False).encode('utf-8')
    last = None
    for attempt in range(6):
        try:
            req = urllib.request.Request('https://api.github.com' + path, data=data,
                                         method=method,
                                         headers={'Authorization': 'token ' + TOKEN,
                                                  'User-Agent': 'bwf',
                                                  'Content-Type': 'application/json'})
            with urllib.request.urlopen(req, timeout=60) as r:
                body = r.read()
            return json.loads(body) if body else {}
        except urllib.error.HTTPError:
            raise
        except Exception as e:
            last = e
            time.sleep(2 + attempt * 2)
    raise last


def enc(p):
    from urllib.parse import quote
    return quote(p, safe='/')


SHA_MAP = {}


def put_file(path, data, msg):
    b64 = base64.b64encode(data).decode('ascii')
    for attempt in range(5):
        try:
            body = {'message': msg, 'content': b64}
            if path in SHA_MAP:
                body['sha'] = SHA_MAP[path]
            api('PUT', '/repos/%s/%s/contents/%s' % (OWNER, REPO, enc(path)), body)
            print('  + %s (%d B)' % (path, len(data)))
            return
        except urllib.error.HTTPError as e:
            if e.code == 422:
                try:
                    cur = api('GET', '/repos/%s/%s/contents/%s' % (OWNER, REPO, enc(path)))
                    body = {'message': msg, 'content': b64, 'sha': cur['sha']}
                    api('PUT', '/repos/%s/%s/contents/%s' % (OWNER, REPO, enc(path)), body)
                    print('  + %s (%d B, sha 补取)' % (path, len(data)))
                    return
                except Exception as e2:
                    print('  sha 补取失败 (%s): %r' % (path, e2))
            print('  重试 %d (%s): %r' % (attempt + 1, path, e))
            time.sleep(3)
        except Exception as e:
            print('  重试 %d (%s): %r' % (attempt + 1, path, e))
            time.sleep(3)
    raise RuntimeError('推送失败: ' + path)


def main():
    # 预取仓库文件 sha（一次请求，避免逐文件 GET 抖动）
    global SHA_MAP
    try:
        tree = api('GET', '/repos/%s/%s/git/trees/main?recursive=1' % (OWNER, REPO))
        SHA_MAP = {i['path']: i['sha'] for i in tree.get('tree', [])
                   if i['type'] == 'blob'}
        print('[预取] 仓库现有文件 %d 个' % len(SHA_MAP))
    except Exception as e:
        print('[预取] 失败（按全新仓库处理）:', repr(e))
        SHA_MAP = {}

    # 读本地版本号
    main_py = open(os.path.join(GUI := os.path.join(ROOT, 'py_gui'), 'main.py'),
                   encoding='utf-8').read()
    ver = re.search(r'^VERSION = "([^"]+)"', main_py, re.M).group(1)
    print('[发版] V%s  说明: %s' % (ver, NOTE))

    # 1) 同步仓库文件
    print('[1/4] 同步仓库文件')
    put_file('src/main.py', open(os.path.join(GUI, 'main.py'), 'rb').read(),
             'feat: V%s' % ver)
    for f in ('build_ct.py', 'swap_ct.py', 'make_tables.py', 'detect_aob.py'):
        put_file('tools/' + f, open(os.path.join(ROOT, f), 'rb').read(),
                 'chore: tools V%s' % ver)
    put_file('README.md', open(os.path.join(REPO_DIR, 'README.md'), 'rb').read(),
             'docs: README V%s' % ver)
    put_file('LICENSE', open(os.path.join(REPO_DIR, 'LICENSE'), 'rb').read(),
             'chore: license')
    put_file('NOTICE.md', open(os.path.join(REPO_DIR, 'NOTICE.md'), 'rb').read(),
             'chore: notice')
    if os.path.exists(MANUAL_SRC):
        put_file('使用说明.txt', open(MANUAL_SRC, 'rb').read(),
                 'docs: 使用说明 V%s' % ver)

    # 2) 更新 version.json
    print('[2/4] version.json')
    info = {'version': ver,
            'date': time.strftime('%Y-%m-%d'),
            'note': NOTE,
            'download': 'https://github.com/%s/%s/releases/latest' % (OWNER, REPO),
            'download_mirror': ('https://gh-proxy.com/https://github.com/%s/%s/'
                                'releases/download/v%s/BWF-Trainer-V%s.exe'
                                % (OWNER, REPO, ver, ver))}
    put_file('version.json', json.dumps(info, ensure_ascii=False, indent=2).encode('utf-8'),
             'chore: version.json V%s' % ver)

    # 3) Release：删旧同名资产 + 上传新 exe
    print('[3/4] Release 资产')
    tag = 'v' + ver
    rels = api('GET', '/repos/%s/%s/releases' % (OWNER, REPO))
    rel = next((r for r in rels if r['tag_name'] == tag), None)
    if rel is None:
        rel = api('POST', '/repos/%s/%s/releases' % (OWNER, REPO),
                  {'tag_name': tag, 'name': 'V%s' % ver, 'body': NOTE,
                   'draft': False, 'prerelease': False})
    rel_id = rel['id']
    for a in rel.get('assets', []):
        if a['name'].startswith('BWF-Trainer-'):
            urllib.request.urlopen(urllib.request.Request(
                'https://api.github.com/repos/%s/%s/releases/assets/%d' % (OWNER, REPO, a['id']),
                method='DELETE', headers={'Authorization': 'token ' + TOKEN, 'User-Agent': 'bwf'}))
            print('  - 删除旧资产 %s' % a['name'])
    asset = 'BWF-Trainer-V%s.exe' % ver
    up = ('https://uploads.github.com/repos/%s/%s/releases/%d/assets?name=%s'
          % (OWNER, REPO, rel_id, urllib.request.quote(asset)))
    req = urllib.request.Request(up, data=open(DIST, 'rb').read(), method='POST',
                                 headers={'Authorization': 'token ' + TOKEN, 'User-Agent': 'bwf',
                                          'Content-Type': 'application/octet-stream'})
    with urllib.request.urlopen(req, timeout=300) as r:
        res = json.loads(r.read())
    print('  + %s (%d B)' % (res['name'], res['size']))

    # 4) 更新 Release 正文
    print('[4/4] Release 正文')
    api('PATCH', '/repos/%s/%s/releases/%d' % (OWNER, REPO, rel_id),
        {'name': 'V%s —— %s' % (ver, NOTE), 'body': NOTE})

    print()
    print('发版完成:')
    print('  https://github.com/%s/%s' % (OWNER, REPO))
    print('  https://github.com/%s/%s/releases/latest' % (OWNER, REPO))


main()
