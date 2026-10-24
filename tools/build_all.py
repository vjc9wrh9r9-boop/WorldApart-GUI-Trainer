# -*- coding: utf-8 -*-
"""一键构建：运行时/表检查 -> Lua 注入 -> 版本切换表 -> res.zip -> PyInstaller
   前置：build/runtime/ 已包含 CE 精简运行时 + 作者 CT 表（见 BUILD.md）
"""
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SRC = os.path.join(ROOT, 'src')
RUNTIME = os.path.join(ROOT, 'build', 'runtime')
MAIN_CT = os.path.join(RUNTIME, 'BWF_不问凡尘_V1.CT')
PY = sys.executable


def run(cmd, cwd=None):
    print('$', ' '.join(cmd))
    r = subprocess.run(cmd, cwd=cwd or ROOT)
    if r.returncode != 0:
        sys.exit(1)


def main():
    # 0) 前置检查
    if not os.path.exists(os.path.join(RUNTIME, 'mzhost.exe')):
        print('错误: %s 缺少 mzhost.exe' % RUNTIME)
        print('请从作者网盘（B站"缤纷颜色"视频简介）下载 CE 精简运行时并解压到该目录。')
        sys.exit(1)
    cts = [f for f in os.listdir(RUNTIME) if f.endswith('.CT') or f.endswith('.ct')]
    if not cts:
        print('错误: %s 没有 CT 表' % RUNTIME)
        print('请从作者网盘下载最新 CT 表放进该目录。')
        sys.exit(1)
    print('前置检查通过: %d 个 CT 表' % len(cts))

    # 1) 主表注入无人值守 Lua（若尚未注入）
    if not os.path.exists(MAIN_CT):
        # 把作者最新表复制为主表名
        src_ct = max((os.path.join(RUNTIME, f) for f in cts),
                     key=lambda p: os.path.getmtime(p))
        shutil.copy2(src_ct, MAIN_CT)
        print('已将 %s 作为主表' % os.path.basename(src_ct))
    run([PY, os.path.join(HERE, 'build_ct.py'), MAIN_CT])

    # 2) 生成版本切换表
    run([PY, os.path.join(HERE, 'make_tables.py')])

    # 3) 打 res.zip 到 src/
    run([PY, os.path.join(HERE, 'pack_res.py')])

    # 4) 图标就位
    ico_src = os.path.join(SRC, 'app.ico')
    if not os.path.exists(ico_src):
        print('错误: src/app.ico 缺失')
        sys.exit(1)

    # 5) PyInstaller
    run([PY, '-m', 'PyInstaller', '--noconfirm', 'trainer.spec'], cwd=SRC)

    dist = os.path.join(SRC, 'dist')
    exe = [os.path.join(dist, f) for f in os.listdir(dist) if f.endswith('.exe')]
    if not exe:
        sys.exit(1)
    out = os.path.join(ROOT, '不问凡尘修改器_V%s.exe' % _version())
    shutil.copy2(exe[0], out)
    print('构建完成:', out)


def _version():
    import re
    s = open(os.path.join(SRC, 'main.py'), encoding='utf-8').read()
    return re.search(r'^VERSION = "([^"]+)"', s, re.M).group(1)


main()
