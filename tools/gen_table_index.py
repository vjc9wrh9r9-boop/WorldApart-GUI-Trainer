# -*- coding: utf-8 -*-
"""扫描 build/runtime 里的所有 BWF_*.CT，提取每张表的 aobscanmodule 特征码，
   生成 tables.json（运行时按"表指纹命中率"识别该用哪张表）。
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))
RUNTIME = os.path.join(ROOT, 'build', 'runtime')
OUT = os.path.join(RUNTIME, 'tables.json')
MAIN_CT = 'BWF_不问凡尘_V1.CT'


def sigs_of(path):
    s = open(path, encoding='utf-8', errors='replace').read()
    seen, out = set(), []
    for m in re.finditer(
            r'aobscanmodule\(\s*\w+\s*,\s*GameAssembly\.dll\s*,\s*([0-9A-Fa-f ]+?)\s*\)', s):
        sig = re.sub(r'\s+', ' ', m.group(1)).strip().upper()
        if sig and sig not in seen:
            seen.add(sig)
            out.append(sig)
    return out


def main():
    if not os.path.isdir(RUNTIME):
        print('错误: 找不到 %s' % RUNTIME)
        sys.exit(1)
    tables = {}
    for f in sorted(os.listdir(RUNTIME)):
        if not (f.startswith('BWF_') and f.endswith('.CT')):
            continue
        sigs = sigs_of(os.path.join(RUNTIME, f))
        if sigs:
            tables[f] = {'sigs': sigs, 'count': len(sigs)}
        else:
            print('  跳过 %s（无 aobscan 特征码）' % f)
    if not tables:
        print('错误: 没有任何带特征码的表')
        sys.exit(1)
    # 主表排最前，其余按文件名（日期）倒序
    order = [MAIN_CT] + sorted((k for k in tables if k != MAIN_CT), reverse=True)
    ordered = {k: tables[k] for k in order if k in tables}
    json.dump(ordered, open(OUT, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print('tables.json 生成: %d 张表' % len(ordered))
    for k, v in ordered.items():
        print('  %-30s %d 个特征码' % (k, v['count']))


main()
