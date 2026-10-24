# -*- coding: utf-8 -*-
"""扫描 build/runtime 里的所有作者原始 CT 表（非 BWF_ 前缀），
   逐张生成"版本切换表"（去广告、无 LuaScript）-> BWF_tbl_<日期>.CT
   修改器运行时按特征码命中自动选择加载哪张。
"""
import os
import re
import sys
import time
import xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, 'build', 'runtime')

AD_MARKS = ('哔哩哔哩', '缤纷颜色', '配套演示视频', 'bilibili.com', 'bilibili',
            'BV1beJY6oExx', 'ShellExecute', '点击观看')


def strip_ads(xml):
    out, i, removed = [], 0, []
    while True:
        s = xml.find('<CheatEntry>', i)
        if s < 0:
            out.append(xml[i:])
            break
        out.append(xml[i:s])
        depth, j, end = 0, s, -1
        while True:
            a = xml.find('<CheatEntry>', j)
            b = xml.find('</CheatEntry>', j)
            if b < 0:
                break
            if 0 <= a < b:
                depth += 1
                j = a + len('<CheatEntry>')
            else:
                depth -= 1
                j = b + len('</CheatEntry>')
                if depth == 0:
                    end = j
                    break
        if end < 0:
            out.append(xml[s:])
            break
        block = xml[s:end]
        if any(m in block for m in AD_MARKS):
            removed.append(1)
            while end < len(xml) and xml[end] in '\r\n':
                end += 1
            i = end
        else:
            out.append(block)
            i = end
    return ''.join(out), removed


def main():
    if not os.path.isdir(OUT):
        print('错误: 找不到 %s（先放运行时和 CT 表）' % OUT)
        sys.exit(1)
    srcs = sorted(f for f in os.listdir(OUT)
                  if f.lower().endswith('.ct') and not f.startswith('BWF_'))
    if not srcs:
        print('提示: runtime 里没有作者原始表，跳过版本切换表生成')
        return
    n_out = 0
    for f in srcs:
        src = os.path.join(OUT, f)
        m = re.search(r'\d{4}-(\d{2})-(\d{2})', f)
        tag = (m.group(1) + m.group(2)) if m else \
            time.strftime('%m%d', time.localtime(os.path.getmtime(src)))
        out = os.path.join(OUT, 'BWF_tbl_%s.CT' % tag)
        if os.path.exists(out) and os.path.getmtime(out) >= os.path.getmtime(src):
            print('%s: 已是最新，跳过' % tag)
            n_out += 1
            continue
        s = open(src, encoding='utf-8').read()
        assert '<LuaScript>' not in s, '%s 意外包含 LuaScript' % f
        s, ads = strip_ads(s)
        open(out, 'w', encoding='utf-8').write(s)
        root = ET.fromstring(s.lstrip('\ufeff'))
        n = len(list(root.iter('CheatEntry')))
        print('%s: 去广告 %d 条, 输出 %d 字节, 条目 %d 个 -> %s'
              % (tag, len(ads), len(s.encode('utf-8')), n, os.path.basename(out)))
        n_out += 1
    print('版本切换表: %d 张' % n_out)


main()
