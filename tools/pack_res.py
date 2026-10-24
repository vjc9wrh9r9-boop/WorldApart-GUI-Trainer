# -*- coding: utf-8 -*-
"""把 build/runtime 目录打包成 src/res.zip（CE 运行时 + 全部修改表）
   构建前置：build/runtime/ 需要包含 mzhost.exe 等运行时，以及作者 CT 表。
"""
import os
import sys
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RUNTIME = os.path.join(ROOT, 'build', 'runtime')
OUT = os.path.join(ROOT, 'src', 'res.zip')


def main():
    if not os.path.isdir(RUNTIME):
        print('错误: 找不到 %s' % RUNTIME)
        print('请先把 Cheat Engine 精简运行时（mzhost.exe 等）和作者 CT 表放进该目录，')
        print('再运行 build_ct.py 注入 Lua、make_tables.py 生成版本切换表。')
        sys.exit(1)
    files = []
    EXCLUDE_EXT = ('.orig', '.bak')
    for dp, _, fn in os.walk(RUNTIME):
        for f in fn:
            if f.endswith(EXCLUDE_EXT):
                continue
            if f.lower().endswith('.ct') and not f.startswith('BWF_'):
                continue          # 作者原始表不打进包（版权+体积），构建者自备
            p = os.path.join(dp, f)
            files.append((p, os.path.relpath(p, RUNTIME).replace('\\', '/')))
    if not any(f.endswith('.exe') for _, f in files):
        print('警告: runtime 目录里没有 exe（缺 mzhost.exe？）')
    with zipfile.ZipFile(OUT + '.tmp', 'w', zipfile.ZIP_LZMA) as z:
        for p, rel in sorted(files):
            z.write(p, rel)
            print('  + %s' % rel)
    os.replace(OUT + '.tmp', OUT)
    print('res.zip 完成: %.2f MB, %d 个文件' % (os.path.getsize(OUT) / 1048576, len(files)))


main()
