# -*- coding: utf-8 -*-
"""换新 CT 表 -> 自动重打包 exe
   用法: python swap_ct.py "新CT的完整路径"
"""
import os, re, shutil, subprocess, sys, zipfile

PY = r'D:\AppData\Local\Programs\Python\Python312\python.exe'
ROOT = r'E:\workbuddy 数据\2026-10-15-00-57-48\bwf'
GUI = os.path.join(ROOT, 'py_gui')
RUNTIME = os.path.join(ROOT, 'build', 'runtime')
CT_NAME = 'BWF_不问凡尘_V1.CT'
CT_PATH = os.path.join(RUNTIME, CT_NAME)
OUT_EXE = r'E:\360MoveData\Users\新建文件夹\不问凡尘修改器_V1.exe'


def die(msg):
    print('[失败]', msg)
    sys.exit(1)


def main():
    if len(sys.argv) < 2:
        die('用法: python swap_ct.py "新CT路径"')
    src = sys.argv[1]
    if not os.path.exists(src):
        die('找不到文件: %s' % src)

    raw = open(src, 'rb').read()
    print('[1/5] 新表 %.1f KB' % (len(raw) / 1024))

    # 先备份当前表
    if os.path.exists(CT_PATH):
        shutil.copy2(CT_PATH, CT_PATH + '.bak')

    # 注入无人值守 Lua + 去广告
    env = dict(os.environ)
    env['CT_SRC'] = src
    r = subprocess.run([PY, os.path.join(ROOT, 'build_ct.py'), CT_PATH],
                       cwd=ROOT, env=env, capture_output=True, text=True)
    print(r.stdout.strip()[-300:] if r.stdout else '')
    if r.returncode != 0:
        die('注入脚本失败:\n' + (r.stderr or '')[-600:])

    # 校验 XML
    import xml.etree.ElementTree as ET
    txt = open(CT_PATH, encoding='utf-8').read()
    try:
        ET.fromstring(txt.lstrip('\ufeff'))
    except Exception as e:
        die('生成的 CT 不是合法 XML: %r' % e)
    n = txt.count('<CheatEntry>')
    print('[2/5] CT 校验通过，条目 %d 个' % n)

    # 重打 res.zip（LZMA）
    names = [i.filename for i in zipfile.ZipFile(os.path.join(GUI, 'res.zip')).infolist()]
    tmpz = os.path.join(GUI, 'res.zip.tmp')
    with zipfile.ZipFile(tmpz, 'w', zipfile.ZIP_LZMA) as z:
        for nm in names:
            p = os.path.join(RUNTIME, nm)
            if os.path.exists(p):
                z.write(p, nm)
    os.replace(tmpz, os.path.join(GUI, 'res.zip'))
    print('[3/5] 资源包 %.2f MB' % (os.path.getsize(os.path.join(GUI, 'res.zip')) / 1048576))

    # 提升 RT_VER，强制用户端重新解压
    mpath = os.path.join(GUI, 'main.py')
    s = open(mpath, encoding='utf-8').read()
    m = re.search(r'^RT_VER = "(\d+)"', s, re.M)
    if not m:
        die('main.py 里找不到 RT_VER')
    new_ver = str(int(m.group(1)) + 1)
    s = s.replace('RT_VER = "%s"' % m.group(1), 'RT_VER = "%s"' % new_ver, 1)
    open(mpath, 'w', encoding='utf-8').write(s)
    print('[4/5] 运行时版本 -> %s' % new_ver)

    # 打包
    r = subprocess.run([PY, '-m', 'PyInstaller', '--noconfirm', 'BWF_Trainer_slim.spec'],
                       cwd=GUI, capture_output=True, text=True)
    if r.returncode != 0:
        die('打包失败:\n' + (r.stderr or '')[-800:])

    built = os.path.join(GUI, 'dist', 'BWF_Trainer_v13.exe')
    subprocess.run(['taskkill', '/F', '/T', '/IM', '不问凡尘修改器_V1.exe'],
                   capture_output=True)
    shutil.copy2(built, OUT_EXE)
    print('[5/5] 完成 -> %s (%.1f MB)' % (OUT_EXE, os.path.getsize(OUT_EXE) / 1048576))
    print()
    print('请启动一次确认：状态变绿 -> 勾一个功能 -> 看那一行是否变红')


main()
