# -*- coding: utf-8 -*-
"""直接在运行中的游戏内存里验证 CT 的 aobscan 特征码是否还存在
   → 命中 = 表没问题，问题在激活流程；全不命中 = 游戏版本已变，表失效"""
import ctypes, ctypes.wintypes as w, os, re, sys, time

k32 = ctypes.WinDLL('kernel32', use_last_error=True)
psapi = ctypes.WinDLL('psapi', use_last_error=True)

PROCESS_VM_READ = 0x0010
PROCESS_QUERY_INFORMATION = 0x0400
LIST_MODULES_ALL = 0x03


class MODULEINFO(ctypes.Structure):
    _fields_ = [('lpBaseOfDll', ctypes.c_void_p),
                ('SizeOfImage', w.DWORD),
                ('EntryPoint', ctypes.c_void_p)]


def find_pids(name):
    """Toolhelp32 枚举进程"""
    TH32CS_SNAPPROCESS = 0x2

    class PE32(ctypes.Structure):
        _fields_ = [('dwSize', w.DWORD), ('cntUsage', w.DWORD),
                    ('th32ProcessID', w.DWORD), ('th32DefaultHeapID', ctypes.POINTER(ctypes.c_ulong)),
                    ('th32ModuleID', w.DWORD), ('cntThreads', w.DWORD),
                    ('th32ParentProcessID', w.DWORD), ('pcPriClassBase', ctypes.c_long),
                    ('dwFlags', w.DWORD), ('szExeFile', ctypes.c_char * 260)]

    out = []
    snap = k32.CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)
    pe = PE32()
    pe.dwSize = ctypes.sizeof(PE32)
    ok = k32.Process32First(snap, ctypes.byref(pe))
    while ok:
        if pe.szExeFile.decode('gbk', 'ignore').lower() == name.lower():
            out.append(pe.th32ProcessID)
        ok = k32.Process32Next(snap, ctypes.byref(pe))
    k32.CloseHandle(snap)
    return out


def modules(pid):
    h = k32.OpenProcess(PROCESS_VM_READ | PROCESS_QUERY_INFORMATION, False, pid)
    if not h:
        return None, []
    arr = (w.HMODULE * 1024)()
    need = w.DWORD()
    if not psapi.EnumProcessModulesEx(h, arr, ctypes.sizeof(arr),
                                      ctypes.byref(need), LIST_MODULES_ALL):
        return h, []
    n = need.value // ctypes.sizeof(w.HMODULE)
    res = []
    for i in range(n):
        hm = w.HMODULE(arr[i])
        mi = MODULEINFO()
        if psapi.GetModuleInformation(h, hm, ctypes.byref(mi), ctypes.sizeof(mi)):
            name = ctypes.create_unicode_buffer(512)
            psapi.GetModuleBaseNameW(h, hm, name, 512)
            res.append((name.value, mi.lpBaseOfDll or 0, mi.SizeOfImage))
    return h, res


def scan(h, base, size, needle, chunk=8 << 20):
    """分块搜索，块间重叠 len(needle)-1"""
    hits = []
    off = 0
    ov = len(needle) - 1
    buf = ctypes.create_string_buffer(chunk + ov)
    read = ctypes.c_size_t()
    while off < size:
        n = min(chunk + ov, size - off)
        addr = ctypes.c_void_p(base + off)
        if not k32.ReadProcessMemory(h, addr, buf, n, ctypes.byref(read)):
            off += chunk
            continue
        data = buf.raw[:read.value]
        i = 0
        while True:
            i = data.find(needle, i)
            if i < 0:
                break
            hits.append(base + off + i)
            i += 1
            if len(hits) > 50:
                return hits
        off += chunk
    return hits


def main():
    pids = find_pids('WorldApart.exe')
    print('WorldApart.exe 进程:', pids)
    if not pids:
        return
    # 选内存最大的（真正游戏）
    target = None
    for pid in pids:
        h, mods = modules(pid)
        if h:
            k32.CloseHandle(h)
        if mods:
            target = (pid, mods)
    if not target:
        print('打不开进程（需要管理员权限）')
        return
    pid, mods = target
    print('目标 PID', pid, '模块数', len(mods))
    ga = [(n, b, s) for n, b, s in mods if n.lower() == 'gameassembly.dll']
    if not ga:
        print('找不到 GameAssembly.dll，模块列表前 10:')
        for m in mods[:10]:
            print('   ', m)
        return
    name, base, size = ga[0]
    print('GameAssembly.dll base=0x%X size=%.1f MB' % (base, size / 1048576))

    h = k32.OpenProcess(PROCESS_VM_READ | PROCESS_QUERY_INFORMATION, False, pid)
    ct = open(r'E:/workbuddy 数据/2026-10-15-00-57-48/bwf/build/runtime/BWF_不问凡尘_V1.CT',
              encoding='utf-8').read()
    pats = re.findall(r'aobscanmodule\(\s*\w+\s*,\s*([A-Za-z0-9_.]+)\s*,\s*([0-9A-Fa-f ]+?)\s*\)', ct)
    print()
    print('=== 特征码扫描 ===')
    ok = 0
    for _, pat in pats:
        needle = bytes(int(x, 16) for x in pat.split())
        t0 = time.time()
        hits = scan(h, base, size, needle)
        mark = '命中 %d' % len(hits) if hits else '未命中'
        if hits:
            ok += 1
        print('  %-52s %s  (%.1fs)' % (pat.strip()[:52], mark, time.time() - t0))
        if hits:
            print('        首个地址 0x%X (RVA 0x%X)' % (hits[0], hits[0] - base))
    # 精确失配时，用特征码前 10 字节找候选位置（判断是"搬家"还是"彻底变了"）
    print()
    print('=== 失效特征码的模糊定位（前 10 字节）===')
    for _, pat in pats:
        needle = bytes(int(x, 16) for x in pat.split())
        if scan(h, base, size, needle):
            continue
        head = needle[:10]
        cands = scan(h, base, size, head)
        print('  %-52s 候选 %d 个' % (pat.strip()[:52], len(cands)))
        for a in cands[:3]:
            print('        RVA 0x%X' % (a - base))

    k32.CloseHandle(h)
    print()
    print('=== 判定 ===')
    print('  命中 %d / %d' % (ok, len(pats)))
    if ok == 0:
        print('  → 全部未命中：游戏已更新，CT 失效（等作者出新表）')
    elif ok == len(pats):
        print('  → 全部命中：表没问题，问题在我们的激活流程')
    else:
        print('  → 部分命中：游戏改了其中一部分功能')


main()
