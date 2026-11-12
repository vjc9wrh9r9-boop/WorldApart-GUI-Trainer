# -*- coding: utf-8 -*-
"""把版本切换表的条目 ID 统一重编号成主表体系（按功能名匹配）。
   主表 = BWF_不问凡尘_V1.CT（最新版游戏）；
   其余 BWF_tbl_*.CT 的父/子条目按名称对齐主表 ID，保证界面按钮在切表后依然有效。
"""
import os
import re
import sys
import xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = HERE
RUNTIME = os.path.join(ROOT, 'build', 'runtime')
MAIN_CT = 'BWF_不问凡尘_V1.CT'


def norm(s):
    """功能名归一化：去空白和标点，便于跨版本匹配"""
    return re.sub(r'[\s\-—_/／（）()【】\[\]·,，。:：]', '', s or '')


def parse(path):
    """返回 [(kind, id, name)]，kind: 'aa' 父功能 / 'leaf' 子条目"""
    root = ET.fromstring(open(path, encoding='utf-8').read().lstrip('\ufeff'))
    out = []

    def walk(entries):
        for ce in entries.findall('CheatEntry'):
            d = (ce.findtext('Description') or '').strip('"')
            vt = ce.findtext('VariableType')
            cid = ce.findtext('ID')
            if vt == 'Auto Assembler Script':
                out.append(('aa', cid, d))
                sub = ce.find('CheatEntries')
                if sub is not None:
                    for k in sub.findall('CheatEntry'):
                        kd = (k.findtext('Description') or '').strip('"')
                        kvt = k.findtext('VariableType')
                        out.append(('aa' if kvt == 'Auto Assembler Script' else 'leaf',
                                    k.findtext('ID'), kd))
                        ksub = k.find('CheatEntries')
                        if ksub is not None:
                            for g in ksub.findall('CheatEntry'):
                                out.append(('leaf', g.findtext('ID'),
                                            (g.findtext('Description') or '').strip('"')))
            else:
                sub = ce.find('CheatEntries')
                if sub is not None:
                    walk(sub)
    walk(root.find('CheatEntries'))
    return out


def main():
    if not os.path.isdir(RUNTIME):
        print('错误: 找不到 %s' % RUNTIME)
        sys.exit(1)
    main_path = os.path.join(RUNTIME, MAIN_CT)
    if not os.path.exists(main_path):
        print('错误: 主表不存在 %s' % MAIN_CT)
        sys.exit(1)
    main_items = parse(main_path)
    # 名称 -> 主表 ID（仅主表出现的名字）
    canon = {}
    for kind, cid, name in main_items:
        canon.setdefault(norm(name), cid)
    print('主表条目 %d 个，建立名称索引 %d 条' % (len(main_items), len(canon)))

    targets = [f for f in sorted(os.listdir(RUNTIME))
               if f.startswith('BWF_tbl_') and f.endswith('.CT')]
    for f in targets:
        p = os.path.join(RUNTIME, f)
        s = open(p, encoding='utf-8').read()
        items = parse(p)
        mapping = {}
        for kind, cid, name in items:
            want = canon.get(norm(name))
            if want and want != cid:
                if cid in mapping and mapping[cid] != want:
                    print('  跳过冲突 %s: %s 同时映射到 %s/%s'
                          % (f, cid, mapping[cid], want))
                    continue
                mapping[cid] = want
        if not mapping:
            print('%s: ID 已对齐，无需改动' % f)
            continue
        # 冲突检查：目标 ID 不能被本表其他未映射条目占用
        target_ids = set(mapping.values())
        src_ids = set(mapping.keys())
        occupied = {cid for _, cid, _ in items} - src_ids
        clash = target_ids & occupied
        if clash:
            # 只剔除指向被占用目标的映射项，其余照常重编号
            before = len(mapping)
            mapping = {o: n for o, n in mapping.items() if n not in clash}
            print('%s: 剔除冲突目标 %s（%d -> %d 条）'
                  % (f, sorted(clash), before, len(mapping)))
            if not mapping:
                continue
        # 两步重编号：先全部改成临时 ID，再落到目标
        steps = []
        for i, (old, new) in enumerate(sorted(mapping.items(), key=lambda x: int(x[0]))):
            tmp = 'TMP%d' % (900000 + i)
            s = re.sub(r'<ID>%s</ID>' % re.escape(old), '<ID>%s</ID>' % tmp, s)
            steps.append((tmp, new))
        for tmp, new in steps:
            s = s.replace('<ID>%s</ID>' % tmp, '<ID>%s</ID>' % new)
        try:
            ET.fromstring(s.lstrip('\ufeff'))
        except Exception as e:
            print('%s: 重编号后 XML 非法（%r），保留原文件' % (f, e))
            continue
        open(p, 'w', encoding='utf-8').write(s)
        print('%s: 重编号 %d 条 -> %s' % (f, len(mapping),
                                        ', '.join('%s→%s' % kv for kv in sorted(
                                            mapping.items(), key=lambda x: int(x[0])))))
    print('统一 ID 完成')


main()
