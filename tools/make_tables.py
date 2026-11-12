# -*- coding: utf-8 -*-
"""从作者原始老表生成三张"版本切换表"（去广告、无 LuaScript）
   09-29 / 10-01 / 10-17 -> BWF_tbl_0929.CT / BWF_tbl_1001.CT / BWF_tbl_1017.CT
"""
import os
import xml.etree.ElementTree as ET

ROOT = r'E:/workbuddy 数据/2026-10-15-00-57-48/bwf'
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
            removed.append(block[block.find('<Description>') + 13:
                                 block.find('</Description>')][:30])
            while end < len(xml) and xml[end] in '\r\n':
                end += 1
            i = end
        else:
            out.append(block)
            i = end
    return ''.join(out), removed


TABLES = [
    ('0929', r'E:/360MoveData/Users/新建文件夹/不问凡尘-缤纷颜色-bilibili-2026-09-29更V2.CT'),
    ('1001', r'E:/360MoveData/Users/新建文件夹/不问凡尘-缤纷颜色-bilibili-2026-10-01更V2.CT'),
    ('1017', r'E:/360MoveData/Users/新建文件夹/不问凡尘/不问凡尘-缤纷颜色-bilibili-2026-10-17更V1.CT'),
]

for tag, src in TABLES:
    s = open(src, encoding='utf-8').read()
    assert '<LuaScript>' not in s, '%s 意外包含 LuaScript' % tag
    s, ads = strip_ads(s)
    out = os.path.join(OUT, 'BWF_tbl_%s.CT' % tag)
    open(out, 'w', encoding='utf-8').write(s)
    root = ET.fromstring(s.lstrip('\ufeff'))
    n = len(list(root.iter('CheatEntry')))
    print('%s: 去广告 %d 条, 输出 %d 字节, 条目 %d 个 -> %s'
          % (tag, len(ads), len(s.encode('utf-8')), n, os.path.basename(out)))
print('done')
