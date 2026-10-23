# -*- coding: utf-8 -*-
"""不问凡尘修改器 V1.0 - tkinter 版启动器

设计原则：整个 UI 只有一个线程（Tk 主循环），所有操作通过 after() 定时器驱动，
不存在任何跨线程 UI 调用，从根本上避免卡死/崩溃。
"""
import os
import sys
import time
import json
import struct
import queue
import ctypes
import zipfile
import threading
import subprocess
import tkinter as tk
from ctypes import wintypes
from tkinter import ttk, messagebox

APP_NAME = "不问凡尘修改器"
VERSION = "2.0"
RT_VER = "11"          # runtime 资源版本：与旧目录不一致时强制重新解压覆盖

TMP = os.environ.get('TEMP') or os.environ.get('TMP') or r'C:\Windows\Temp'
LOCAL = os.environ.get('LOCALAPPDATA') or TMP
APP_DIR = os.path.join(LOCAL, 'BWFMod')
RT_DIR = os.path.join(APP_DIR, 'runtime')
STAMP = os.path.join(APP_DIR, 'v1.stamp')
CMD_FILE = os.path.join(TMP, 'bwf_cmd.txt')
STATUS_FILE = os.path.join(TMP, 'bwf_status.txt')

RESOURCES_URL = "https://link3.cc/haochihc"

DISCLAIMER = (
    "1. 本修改器仅供个人学习、研究交流使用，请勿用于任何商业用途。\n"
    "2. 使用本工具产生的一切后果（包括但不限于游戏账号封禁、数据异常）由使用者自行承担。\n"
    "3. 请在下载后 24 小时内删除本程序，支持正版游戏。\n"
    "4. 本程序不收集任何个人信息，所有数据均保留在本地。\n"
    "5. 数据来源于 B 站 UP 主「缤纷颜色」，本工具仅在其公开资料基础上做界面封装与自动化整合，相关版权归原作者所有。\n"
    "6. 使用中如遇问题欢迎反馈：B 站搜索「缤纷颜色」，可在视频评论区留言或私信。\n"
    "7. 继续使用即表示您已阅读并同意以上条款。"
)

FEATURES = [
    {"id": 1, "name": "创建人物修改", "hint": "建号界面：数值是问号时上下调一下就能读", "values": [
        (2, "道途点"), (3, "灵根点数 / 本源点数"), (5, "修为"), (12, "昵称长度"), (13, "昵称")]},
    {"id": 23, "name": "灵石 / 宗派贡献修改", "hint": "进游戏后随便买个东西，再读取", "values": [(24, "修改数值")]},
    {"id": 39, "name": "NPC 友好度修改", "hint": "送礼界面：点一下要送的物品（不用确认）", "values": [(40, "当前友好度"), (42, "当前人物友好度上限")]},
    {"id": 55, "name": "修为修改", "hint": "先打开【人物属性】界面，再点读取", "values": [(57, "修为值"), (58, "丹田灵气"), (56, "善恶值")]},
    {"id": 1429, "name": "物品数量修改", "hint": "背包里点选一件物品（选中），再点读取", "values": [(4, "数量")]},
    {"id": 25, "name": "人物属性修改", "hint": "必须打一场野怪，战斗胜利后再读取（切磋不算）", "values": [
        (26, "当前血量"), (27, "血量上限"), (32, "当前灵力"), (31, "灵力上限"),
        (28, "攻击"), (29, "防御"), (30, "速度"), (33, "暴击率"),
        (34, "暴击伤害"), (35, "命中"), (36, "闪避"), (37, "当前精力")]},
    {"id": 44, "name": "炼器修改", "hint": "打开炼器界面后再点读取", "values": [(45, "器契"), (47, "火力值")]},
    {"id": 50, "name": "炼丹修改", "hint": "打开炼丹界面后再点读取", "values": [(51, "丹毒")]},
    {"id": 1431, "name": "炼丹危险度修改", "hint": "打开炼丹界面后再点读取", "values": [(1432, "炼丹危险度")]},
    {"id": 1433, "name": "声望修改", "values": [(1434, "修改声望数值")]},
    {"id": 1435, "name": "探索技能修改",
     "hint": "对应技能点数要有 1 点以上才读得到，读到的数值需自己核对",
     "values": [(1436, "医术"), (1437, "辩道"), (1438, "神识"), (1439, "体魄"),
                (6, "灵机"), (1440, "神识2"), (1441, "灵机2"),
                (1442, "辩道2"), (1443, "体魄2")]},
]

# ---------------- 视觉主题：仙侠水墨 ----------------
FONT_TITLE = ("楷体", 34, "bold")
FONT_HEAD = ("楷体", 19, "bold")
FONT_SUB = ("Microsoft YaHei UI", 9)
FONT_NORMAL = ("Microsoft YaHei UI", 10)
FONT_SMALL = ("Microsoft YaHei UI", 9)

class C:
    """主题色命名空间（昼夜切换）"""
    THEME_NAME = 'night'


THEME_NIGHT = dict(
    INK="#0C1412", PANEL="#101C18", PANEL_HI="#16261F",
    LINE="#243830", LINE_SOFT="#1A2A24",
    GOLD="#C9A961", GOLD_HI="#EBD9A6", GOLD_DIM="#7A6A42",
    JADE="#4FAF8B", JADE_HI="#7BE3B8",
    TEXT="#E8E3D6", TEXT2="#8A9A93", TEXT3="#5E6F68",
    RED="#B4635A", BTN="#15231E", BTN_HI="#1E3229",
    TB_BG="#0A110F", TB_CLOSE_HF="#4A1E1A", TB_CLOSE_ED="#B5534A",
    TB_CLOSE_TF="#F3BDB4",
)
THEME_DAY = dict(
    INK="#ECE6D6", PANEL="#F4EFE1", PANEL_HI="#FAF6EA",
    LINE="#C6BC9E", LINE_SOFT="#DCD4BE",
    GOLD="#8A6D2F", GOLD_HI="#4A3A12", GOLD_DIM="#B0A274",
    JADE="#2E7D5F", JADE_HI="#1F5C46",
    TEXT="#2A2620", TEXT2="#6B6355", TEXT3="#847A66",
    RED="#A03D33", BTN="#F0EADA", BTN_HI="#E5DCC6",
    TB_BG="#E7E0CD", TB_CLOSE_HF="#E0C4BC", TB_CLOSE_ED="#A05248",
    TB_CLOSE_TF="#7A2A22",
)


def apply_theme(name):
    t = THEME_DAY if name == 'day' else THEME_NIGHT
    for k, v in t.items():
        setattr(C, k, v)
    C.THEME_NAME = name


THEME_FILE = os.path.join(APP_DIR, 'theme.txt')


def load_theme_pref():
    try:
        v = open(THEME_FILE, encoding='utf-8').read().strip()
        return v if v in ('day', 'night') else 'night'
    except Exception:
        return 'night'


def save_theme_pref(name):
    try:
        open(THEME_FILE, 'w', encoding='utf-8').write(name)
    except Exception:
        pass

UI_DIR = os.path.join(APP_DIR, 'ui')
MAIN_W, MAIN_H = 720, 864
CFG_W = 540
TITLE_H = 40          # 主窗口自绘标题栏高度
CFG_TITLE_H = 36      # 配置窗口自绘标题栏高度

_U32 = ctypes.WinDLL('user32', use_last_error=True)
_GWL_STYLE = -16
_WS_CAPTION = 0x00C00000
_WS_THICKFRAME = 0x00040000
_SWP = 0x0020 | 0x0001 | 0x0002 | 0x0004   # FRAMECHANGED|NOSIZE|NOMOVE|NOZORDER


def _tb_icon():
    """标题栏小图标：从 app.ico 取一帧转 20x20 PNG，缓存复用"""
    out = os.path.join(UI_DIR, 'tb_icon.png')
    try:
        if os.path.exists(out) and os.path.getsize(out) > 200:
            return out
    except Exception:
        pass
    try:
        from PIL import Image
        ico = res_path('app.ico')
        if not os.path.exists(ico):
            return None
        os.makedirs(UI_DIR, exist_ok=True)
        im = Image.open(ico).convert('RGBA')
        try:
            im.size = (64, 64)
            im = Image.open(ico).convert('RGBA')
            im.load()
        except Exception:
            pass
        im = im.resize((22, 22), Image.LANCZOS)
        im.save(out, 'PNG')
        return out
    except Exception:
        return None


_BG_THEMES = {
    'night': dict(top=(10, 18, 16), bot=(24, 37, 31), glow=(46, 38, 20),
                  shade=(26, 22, 12), frame1=(46, 64, 55), frame2=(27, 41, 35),
                  corner1=(150, 124, 70), corner2=(86, 110, 96),
                  diamond=(118, 98, 55), dust_rng=(28, 68)),
    'day': dict(top=(243, 238, 226), bot=(224, 216, 196), glow=(226, 214, 178),
                shade=(196, 186, 158), frame1=(138, 109, 47), frame2=(196, 175, 135),
                corner1=(120, 100, 55), corner2=(90, 110, 95),
                diamond=(120, 100, 55), dust_rng=(150, 180)),
}


def _ui_bg(w, h, path, glow_scale=1.0):
    """生成仙侠水墨背景（昼夜双主题）：渐变 + 暖光 + 金线边框 + 云纹 + 星尘。
       生成一次后按主题缓存到磁盘。"""
    path = path[:-4] + '_' + C.THEME_NAME + '.png'
    try:
        if os.path.exists(path) and os.path.getsize(path) > 2000:
            return path
    except Exception:
        pass
    bt = _BG_THEMES.get(C.THEME_NAME, _BG_THEMES['night'])
    _BG_TOP, _BG_BOT = bt['top'], bt['bot']
    try:
        from PIL import Image, ImageDraw, ImageFilter, ImageChops
    except Exception:
        return None
    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        im = Image.new('RGB', (w, h), _BG_TOP)
        d = ImageDraw.Draw(im)
        for y in range(h):
            t = (y / max(1, h - 1)) ** 0.85
            d.line([(0, y), (w, y)], fill=(
                int(_BG_TOP[0] + (_BG_BOT[0] - _BG_TOP[0]) * t),
                int(_BG_TOP[1] + (_BG_BOT[1] - _BG_TOP[1]) * t),
                int(_BG_TOP[2] + (_BG_BOT[2] - _BG_TOP[2]) * t)))

        glow = Image.new('RGB', (w, h), (0, 0, 0))
        gd = ImageDraw.Draw(glow)
        gd.ellipse((-w * 0.25, -h * 0.42, w * 1.25, h * 0.30), fill=bt['glow'])
        glow = glow.filter(ImageFilter.GaussianBlur(max(30, w // 9)))
        if glow_scale != 1.0:
            glow = glow.point(lambda v: int(v * glow_scale))
        im = ImageChops.add(im, glow)

        shade = Image.new('RGB', (w, h), (0, 0, 0))
        sd = ImageDraw.Draw(shade)
        sd.ellipse((-w * 0.3, h * 0.86, w * 1.3, h * 1.7), fill=bt['shade'])
        shade = shade.filter(ImageFilter.GaussianBlur(max(24, w // 12)))
        im = ImageChops.subtract(im, shade)

        d = ImageDraw.Draw(im)
        m = 12
        d.rectangle((m, m, w - m - 1, h - m - 1), outline=bt['frame1'])
        d.rectangle((m + 4, m + 4, w - m - 5, h - m - 5), outline=bt['frame2'])
        L = 32
        for cx, cy, sx, sy in ((m + 10, m + 10, 1, 1), (w - m - 11, m + 10, -1, 1),
                               (m + 10, h - m - 11, 1, -1), (w - m - 11, h - m - 11, -1, -1)):
            d.line([(cx, cy), (cx + sx * L, cy)], fill=bt['corner1'], width=1)
            d.line([(cx, cy), (cx, cy + sy * L)], fill=bt['corner1'], width=1)
            d.line([(cx, cy), (cx + sx * 13, cy + sy * 13)], fill=bt['corner2'], width=1)
            dd = 4
            ox, oy = cx + sx * (L + 12), cy
            d.polygon([(ox, oy - dd), (ox + dd, oy), (ox, oy + dd), (ox - dd, oy)],
                      outline=bt['diamond'])
        import random as _rnd
        r = _rnd.Random(w * 31 + h)
        for _ in range(w * h // 2400):
            x = r.randrange(22, w - 22)
            yy = r.randrange(22, h - 22)
            v = r.randrange(*bt['dust_rng'])
            d.point((x, yy), fill=(v, v + 8, v + 4))
        im = im.filter(ImageFilter.GaussianBlur(0.4))
        im.save(path, 'PNG')
        return path
    except Exception:
        return None


def res_path(rel):
    base = getattr(sys, '_MEIPASS', os.path.dirname(os.path.abspath(__file__)))
    return os.path.join(base, rel)


# ---------------- Cheat Engine 首次运行预置 ----------------
# CE 打开含 <LuaScript> 的表时会弹 TfrmLuaScriptQuestion 询问是否执行，
# 新机器上必然卡住整条链路。它的策略存在 HKCU\Software\Cheat Engine\LuaScriptAction：
#   0=总是执行  1=仅签名(否则询问)  2=总是询问  3=从不
# 启动前把它预置成 0，CE 就直接跑脚本、完全不弹窗。
def _ensure_ce_policy():
    try:
        import winreg
        key = winreg.CreateKeyEx(winreg.HKEY_CURRENT_USER, r'Software\Cheat Engine',
                                 0, winreg.KEY_SET_VALUE)
        try:
            winreg.SetValueEx(key, 'LuaScriptAction', 0, winreg.REG_DWORD, 0)
            winreg.SetValueEx(key, 'First Time User', 0, winreg.REG_DWORD, 0)
        finally:
            winreg.CloseKey(key)
    except Exception:
        pass


# 进程级看门狗：只盯我们自己启动的那个 CE 进程
#   1) SetWinEventHook(EVENT_OBJECT_SHOW) —— 窗口刚 Show 出来、还没绘制就被按下，
#      肉眼不可见（轮询做不到，最快也有一个间隔的可见时间，就是"闪一下"的来源）
#   2) 50ms 兜底轮询，防止某些窗口不发 SHOW 事件
#   3) 「Execute this lua script?」自动点 Always + Yes，保证 Lua 一定跑起来
# 不依赖 DFM patch / 注册表设置，换任何一台机器都成立。
def _watch_ce(stop_flag, pid_getter):
    SW_HIDE = 0
    BM_CLICK = 0x00F5
    EVENT_OBJECT_SHOW = 0x8002
    WINEVENT_OUTOFCONTEXT = 0x0000
    QS_ALLINPUT = 0x04FF
    PM_REMOVE = 0x0001
    try:
        u32 = ctypes.WinDLL('user32', use_last_error=True)
        k32 = ctypes.WinDLL('kernel32', use_last_error=True)
    except Exception:
        return
    EnumProc = ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)
    WinEventProc = ctypes.WINFUNCTYPE(None, wintypes.HANDLE, wintypes.DWORD, wintypes.HWND,
                                      ctypes.c_long, ctypes.c_long,
                                      wintypes.DWORD, wintypes.DWORD)

    def wtext(h):
        n = u32.GetWindowTextLengthW(h)
        b = ctypes.create_unicode_buffer(n + 1)
        u32.GetWindowTextW(h, b, n + 1)
        return b.value

    def pid_of(h):
        p = wintypes.DWORD(0)
        u32.GetWindowThreadProcessId(h, ctypes.byref(p))
        return p.value

    def click_child(parent, want):
        hit = []

        def cb(c, l):
            if wtext(c).strip() == want:
                hit.append(c)
                return False
            return True

        try:
            u32.EnumChildWindows(parent, EnumProc(cb), 0)
        except Exception:
            return False
        if hit:
            try:
                u32.SendMessageW(hit[0], BM_CLICK, 0, 0)
            except Exception:
                return False
            return True
        return False

    def on_show(hHook, event, hwnd, idObject, idChild, dwThread, dwTime):
        # 窗口对象刚变为可见：立刻抹掉，先于绘制
        try:
            if not hwnd or idObject != 0:
                return
            u32.ShowWindowW(hwnd, SW_HIDE)
        except Exception:
            pass

    proc_ref = WinEventProc(on_show)      # 必须留引用，否则被 GC 后回调失效
    try:
        k32.MsgWaitForMultipleObjects.argtypes = [wintypes.DWORD, ctypes.c_void_p,
                                                  wintypes.BOOL, wintypes.DWORD, wintypes.DWORD]
        k32.MsgWaitForMultipleObjects.restype = wintypes.DWORD
    except Exception:
        pass

    hook = 0
    hooked_pid = 0
    msg = wintypes.MSG()
    start = time.time()

    while time.time() - start < 900:
        if stop_flag():
            break
        pid = 0
        try:
            pid = pid_getter()
        except Exception:
            pid = 0

        # pid 一确定就挂上该进程的事件钩子（带进程过滤，几乎零开销）
        if pid and pid != hooked_pid:
            if hook:
                try:
                    u32.UnhookWinEvent(hook)
                except Exception:
                    pass
                hook = 0
            try:
                hook = u32.SetWinEventHook(EVENT_OBJECT_SHOW, EVENT_OBJECT_SHOW, 0,
                                           proc_ref, pid, 0, WINEVENT_OUTOFCONTEXT)
            except Exception:
                hook = 0
            hooked_pid = pid

        # 等钩子投递的消息（或 50ms 超时）
        try:
            k32.MsgWaitForMultipleObjects(0, None, False, 50, QS_ALLINPUT)
        except Exception:
            time.sleep(0.05)

        # 泵消息：钩子回调就在 DispatchMessage 期间执行
        for _ in range(64):
            try:
                if not u32.PeekMessageW(ctypes.byref(msg), 0, 0, 0, PM_REMOVE):
                    break
                u32.TranslateMessage(ctypes.byref(msg))
                u32.DispatchMessageW(ctypes.byref(msg))
            except Exception:
                break

        # 兜底轮询
        if pid:
            live = []

            def cb(h, l):
                try:
                    if pid_of(h) == pid and u32.IsWindowVisible(h):
                        live.append(h)
                except Exception:
                    pass
                return True

            try:
                u32.EnumWindows(EnumProc(cb), 0)
            except Exception:
                pass
            for h in live:
                try:
                    t = wtext(h).lower()
                except Exception:
                    t = ''
                if 'execute this lua script' in t:
                    click_child(h, 'Always')      # 记住：以后不再询问
                    time.sleep(0.2)
                    click_child(h, 'Yes')         # 确认执行
                    time.sleep(0.2)
                else:
                    u32.ShowWindowW(h, SW_HIDE)   # 其余窗口一律隐藏

    if hook:
        try:
            u32.UnhookWinEvent(hook)
        except Exception:
            pass


# ---------------- 隐藏桌面启动（彻底不闪） ----------------
# python 的 subprocess.STARTUPINFO 没有 lpDesktop 字段，必须自己建结构体走 CreateProcessW。
# CE 的所有窗口都创建在这块独立桌面上，当前桌面里根本不存在这些窗口 —— 物理上看不到。
CREATE_NO_WINDOW = 0x08000000
GENERIC_ALL = 0x10000000
STARTF_USESHOWWINDOW = 0x00000001


class _STARTUPINFOW(ctypes.Structure):
    _fields_ = [
        ("cb", wintypes.DWORD), ("lpReserved", wintypes.LPWSTR), ("lpDesktop", wintypes.LPWSTR),
        ("lpTitle", wintypes.LPWSTR), ("dwX", wintypes.DWORD), ("dwY", wintypes.DWORD),
        ("dwXSize", wintypes.DWORD), ("dwYSize", wintypes.DWORD),
        ("dwXCountChars", wintypes.DWORD), ("dwYCountChars", wintypes.DWORD),
        ("dwFillAttribute", wintypes.DWORD), ("dwFlags", wintypes.DWORD),
        ("wShowWindow", wintypes.WORD), ("cbReserved2", wintypes.WORD),
        ("lpReserved2", ctypes.POINTER(ctypes.c_byte)),
        ("hStdInput", wintypes.HANDLE), ("hStdOutput", wintypes.HANDLE),
        ("hStdError", wintypes.HANDLE),
    ]


class _PROCESS_INFORMATION(ctypes.Structure):
    _fields_ = [("hProcess", wintypes.HANDLE), ("hThread", wintypes.HANDLE),
                ("dwProcessId", wintypes.DWORD), ("dwThreadId", wintypes.DWORD)]


class _HiddenProc:
    """CreateProcessW 启动的进程，接口对齐 subprocess.Popen 的用法"""

    def __init__(self, hproc, pid, hdesk):
        self._h = hproc
        self.pid = pid
        self._hdesk = hdesk
        self._k32 = ctypes.WinDLL('kernel32', use_last_error=True)

    def poll(self):
        try:
            return None if self._k32.WaitForSingleObject(self._h, 0) == 0x102 else 0
        except Exception:
            return 0

    def terminate(self):
        try:
            self._k32.TerminateProcess(self._h, 1)
        except Exception:
            pass

    def wait(self, timeout=None):
        try:
            ms = 0xFFFFFFFF if timeout is None else int(timeout * 1000)
            self._k32.WaitForSingleObject(self._h, ms)
        except Exception:
            pass
        return 0

    def cleanup(self):
        try:
            self._k32.CloseHandle(self._h)
        except Exception:
            pass
        try:
            if self._hdesk:
                ctypes.WinDLL('user32').CloseDesktop(self._hdesk)
        except Exception:
            pass


def spawn_ce_hidden(exe, ct, cwd):
    """把 CE 跑在一个独立桌面上；失败则抛异常，由调用方回退到普通启动"""
    k32 = ctypes.WinDLL('kernel32', use_last_error=True)
    u32 = ctypes.WinDLL('user32', use_last_error=True)
    desk = 'BWFDesk%d' % (int(time.time() * 1000) % 1000000)
    hdesk = 0
    try:
        hdesk = u32.CreateDesktopW(desk, None, None, 0, GENERIC_ALL, None)
    except Exception:
        hdesk = 0
    si = _STARTUPINFOW()
    si.cb = ctypes.sizeof(_STARTUPINFOW)
    if hdesk:
        si.lpDesktop = desk
    si.dwFlags = STARTF_USESHOWWINDOW
    si.wShowWindow = 0
    pi = _PROCESS_INFORMATION()
    cmdline = ctypes.create_unicode_buffer('"%s" "%s"' % (exe, ct))
    ok = k32.CreateProcessW(None, cmdline, None, None, False, CREATE_NO_WINDOW,
                            None, cwd, ctypes.byref(si), ctypes.byref(pi))
    if not ok:
        if hdesk:
            try:
                u32.CloseDesktop(hdesk)
            except Exception:
                pass
        raise RuntimeError('CreateProcessW 失败，错误码 %d' % ctypes.get_last_error())
    return _HiddenProc(pi.hProcess, pi.dwProcessId, hdesk)


# ---------------- 进程查找（ctypes，快速） ----------------
TH32CS_SNAPPROCESS = 0x00000002


class PROCESSENTRY32(ctypes.Structure):
    _fields_ = [
        ("dwSize", wintypes.DWORD),
        ("cntUsage", wintypes.DWORD),
        ("th32ProcessID", wintypes.DWORD),
        ("th32DefaultHeapID", ctypes.POINTER(ctypes.c_ulong)),
        ("th32ModuleID", wintypes.DWORD),
        ("cntThreads", wintypes.DWORD),
        ("th32ParentProcessID", wintypes.DWORD),
        ("pcPriClassBase", ctypes.c_long),
        ("dwFlags", wintypes.DWORD),
        ("szExeFile", ctypes.c_char * 260),
    ]


def find_process(name):
    """找游戏进程。同名进程可能有多个（启动器 + 游戏本体），取内存最大的那个。"""
    try:
        k32 = ctypes.windll.kernel32
        psapi = ctypes.windll.psapi
        snap = k32.CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)
        if snap == -1:
            return 0
        pe = PROCESSENTRY32()
        pe.dwSize = ctypes.sizeof(PROCESSENTRY32)
        ok = k32.Process32First(snap, ctypes.byref(pe))
        target = name.lower()
        cands = []
        while ok:
            exe = pe.szExeFile.decode('gbk', errors='ignore').lower()
            if exe == target:
                cands.append(pe.th32ProcessID)
            ok = k32.Process32Next(snap, ctypes.byref(pe))
        k32.CloseHandle(snap)
        if not cands:
            return 0
        if len(cands) == 1:
            return cands[0]

        class PMC(ctypes.Structure):
            _fields_ = [('cb', ctypes.c_ulong), ('PageFaultCount', ctypes.c_ulong),
                        ('PeakWorkingSetSize', ctypes.c_size_t),
                        ('WorkingSetSize', ctypes.c_size_t),
                        ('QuotaPeakPagedPoolUsage', ctypes.c_size_t),
                        ('QuotaPagedPoolUsage', ctypes.c_size_t),
                        ('QuotaPeakNonPagedPoolUsage', ctypes.c_size_t),
                        ('QuotaNonPagedPoolUsage', ctypes.c_size_t),
                        ('PagefileUsage', ctypes.c_size_t),
                        ('PeakPagefileUsage', ctypes.c_size_t)]

        best_pid, best_mem = 0, -1
        for pid in cands:
            h = 0
            try:
                h = k32.OpenProcess(0x1000, False, pid)   # QUERY_LIMITED_INFORMATION
                if not h:
                    continue
                pmc = PMC()
                pmc.cb = ctypes.sizeof(PMC)
                if psapi.GetProcessMemoryInfo(h, ctypes.byref(pmc), pmc.cb):
                    if pmc.WorkingSetSize > best_mem:
                        best_mem = pmc.WorkingSetSize
                        best_pid = pid
            except Exception:
                pass
            finally:
                if h:
                    try:
                        k32.CloseHandle(h)
                    except Exception:
                        pass
        log_boot('find_process: cands=%s -> pid=%d (%.1f MB)'
                 % (cands, best_pid, max(best_mem, 0) / 1048576.0))
        return best_pid or cands[0]
    except Exception:
        pass
    return 0


# --- 游戏代码自愈：清理上次异常退出残留的 AA hook ---
HOOK_SIGS = [
    '41 8B 4E 18 3B 4E 38',
    '44 39 70 14 0F 8C 97 00 00 00',
    '8B 9B 80 01 00 00 48 89 6C 24 70',
    '8B 41 1C 03 41 18 48 83 C4 20 5B C3',
    '41 8B 57 14 45 33 C0 E8',
    '8B 58 58 0F 57 DB 45 8B C6 4C 89 64 24 20',
    '8B 44 C1 2C 89 43 10 B0 01 48 83 C4 20',
]


def _pe_off2rva(pe, off):
    try:
        e = struct.unpack_from('<I', pe, 0x3C)[0]
        nsec = struct.unpack_from('<H', pe, e + 6)[0]
        optsz = struct.unpack_from('<H', pe, e + 20)[0]
        base = e + 24 + optsz
        for i in range(nsec):
            o = base + i * 40
            vsz, va, rawsz, rawptr = struct.unpack_from('<IIII', pe, o + 8)
            if rawptr <= off < rawptr + rawsz:
                return off - rawptr + va
    except Exception:
        pass
    return None


def heal_game_code(pid):
    """只在内存首字节是 E9 且磁盘对应位置是原特征码时恢复，避免误改"""
    try:
        k32 = ctypes.WinDLL('kernel32', use_last_error=True)
        psapi = ctypes.WinDLL('psapi', use_last_error=True)
        h = k32.OpenProcess(0x0410 | 0x0020 | 0x0008, False, pid)
        if not h:
            return
        try:
            arr = (wintypes.HMODULE * 1024)()
            need = wintypes.DWORD()
            psapi.EnumProcessModulesEx(h, arr, ctypes.sizeof(arr), ctypes.byref(need), 0x03)
            base = path = 0
            for i in range(need.value // ctypes.sizeof(wintypes.HMODULE)):
                hm = wintypes.HMODULE(arr[i])
                nm = ctypes.create_unicode_buffer(260)
                psapi.GetModuleBaseNameW(h, hm, nm, 260)
                if nm.value.lower() == 'gameassembly.dll':
                    class MI(ctypes.Structure):
                        _fields_ = [('b', ctypes.c_void_p), ('s', wintypes.DWORD),
                                    ('e', ctypes.c_void_p)]
                    mi = MI()
                    psapi.GetModuleInformation(h, hm, ctypes.byref(mi), ctypes.sizeof(mi))
                    base = mi.b or 0
                    pth = ctypes.create_unicode_buffer(1024)
                    psapi.GetModuleFileNameExW(h, hm, pth, 1024)
                    path = pth.value
                    break
            if not base or not path or not os.path.exists(path):
                return
            pe = open(path, 'rb').read()
            fixed = 0
            for sig in HOOK_SIGS:
                needle = bytes(int(x, 16) for x in sig.split())
                off = pe.find(needle)
                if off < 0:
                    continue
                rva = _pe_off2rva(pe, off)
                if rva is None:
                    continue
                buf = ctypes.create_string_buffer(len(needle))
                got = ctypes.c_size_t()
                if not k32.ReadProcessMemory(h, ctypes.c_void_p(base + rva), buf,
                                             len(needle), ctypes.byref(got)):
                    continue
                cur = buf.raw[:got.value]
                if cur == needle:
                    continue
                if not cur:
                    continue
                di = -1
                for k in range(min(len(cur), len(needle))):
                    if cur[k] != needle[k]:
                        di = k
                        break
                if di < 0 or cur[di] != 0xE9:      # 第一个差异不是 jmp，不是我们留下的
                    continue
                old = wintypes.DWORD()
                if not k32.VirtualProtectEx(h, ctypes.c_void_p(base + rva), len(needle),
                                            0x40, ctypes.byref(old)):
                    continue
                n = ctypes.c_size_t()
                k32.WriteProcessMemory(h, ctypes.c_void_p(base + rva), needle,
                                       len(needle), ctypes.byref(n))
                k32.VirtualProtectEx(h, ctypes.c_void_p(base + rva), len(needle),
                                     old.value, ctypes.byref(old))
                fixed += 1
                log_boot('heal: restored hook @RVA 0x%X' % rva)
            if fixed:
                log_boot('heal: %d 处残留 hook 已还原' % fixed)
        finally:
            k32.CloseHandle(h)
    except Exception as e:
        log_boot('heal error: %r' % e)


# --- 游戏版本识别：按特征码命中情况自动加载对应版本的表 ---
TABLE_SIGS = [
    ('shengwang', '8B 44 C1 2C 89 43 10 B0 01 48 83 C4 20'),
    ('lianqi',    '8B 58 58 0F 57 DB 45 8B C6 4C 89 64 24 20'),
    ('wupin',     '41 8B 57 14 45 33 C0 E8'),
    ('shane',     '8B 41 1C 03 41 18 48 83 C4 20 5B C3'),
    ('qinmi',     '8B 9B 80 01 00 00 48 89 6C 24 70'),
    ('lingshi',   '44 39 70 14 0F 8C 97 00 00 00'),
    ('daotudian', '41 8B 4E 18 3B 4E 38'),
]
TABLE_NAMES = {
    'v1017+': ('最新表', '全部 11 项'),
    'v1001':  ('10-01 表', '8 项（无声望/炼丹危险度/探索技能）'),
    'v0929':  ('09-29 表', '仅创建人物修改'),
    'none':   ('无匹配', '0 项'),
}


# --- 自动更新：GitHub 仓库的 version.json ---
UPDATE_JSON_URL = "https://raw.githubusercontent.com/vjc9wrh9r9-boop/WorldApart-GUI-Trainer/main/version.json"
RELEASE_PAGE = "https://github.com/vjc9wrh9r9-boop/WorldApart-GUI-Trainer/releases/latest"


def open_release_page():
    try:
        os.startfile(RELEASE_PAGE)
    except Exception:
        try:
            import webbrowser
            webbrowser.open(RELEASE_PAGE)
        except Exception:
            pass



def _scan_game_sigs(pid):
    """在游戏 GameAssembly.dll 里搜特征码，返回 (版本标识, 命中数)"""
    k32 = ctypes.WinDLL('kernel32', use_last_error=True)
    psapi = ctypes.WinDLL('psapi', use_last_error=True)
    h = k32.OpenProcess(0x0410, False, pid)
    if not h:
        return 'none', 0
    try:
        arr = (wintypes.HMODULE * 1024)()
        need = wintypes.DWORD()
        psapi.EnumProcessModulesEx(h, arr, ctypes.sizeof(arr), ctypes.byref(need), 0x03)
        base = size = 0
        for i in range(need.value // ctypes.sizeof(wintypes.HMODULE)):
            hm = wintypes.HMODULE(arr[i])
            nm = ctypes.create_unicode_buffer(260)
            psapi.GetModuleBaseNameW(h, hm, nm, 260)
            if nm.value.lower() == 'gameassembly.dll':
                class MI(ctypes.Structure):
                    _fields_ = [('b', ctypes.c_void_p), ('s', wintypes.DWORD),
                                ('e', ctypes.c_void_p)]
                mi = MI()
                psapi.GetModuleInformation(h, hm, ctypes.byref(mi), ctypes.sizeof(mi))
                base, size = mi.b or 0, mi.s
                break
        if not base:
            return 'none', 0
        sigs = [(n, bytes(int(x, 16) for x in p.split())) for n, p in TABLE_SIGS]
        hits = set()
        maxsz = max(len(nd) for _, nd in sigs)
        chunk = 8 << 20
        off = 0
        buf = ctypes.create_string_buffer(chunk + maxsz - 1)
        rd = ctypes.c_size_t()
        while off < size:
            n = min(chunk + maxsz - 1, size - off)
            if not k32.ReadProcessMemory(h, ctypes.c_void_p(base + off), buf, n,
                                         ctypes.byref(rd)):
                off += chunk
                continue
            data = buf.raw[:rd.value]
            for nm, nd in sigs:
                if nm not in hits and data.find(nd) >= 0:
                    hits.add(nm)
            if len(hits) == len(sigs):
                break
            off += chunk
        if 'shengwang' in hits:
            return 'v1017+', len(hits)
        if 'lianqi' in hits:
            return 'v1001', len(hits)
        if 'daotudian' in hits:
            return 'v0929', len(hits)
        return 'none', len(hits)
    finally:
        k32.CloseHandle(h)


def single_instance():
    try:
        k32 = ctypes.windll.kernel32
        k32.CreateMutexW(None, True, "Global\\BWFModLauncherPy1")
        return k32.GetLastError() != 183  # ERROR_ALREADY_EXISTS
    except Exception:
        return True


def activate_existing():
    """已有实例在跑时，把它拉到前台，而不是让用户以为"双击没反应" """
    try:
        u32 = ctypes.windll.user32
        hwnd = u32.FindWindowW(None, APP_NAME)
        if not hwnd:
            return False
        if u32.IsIconic(hwnd):
            u32.ShowWindow(hwnd, 9)          # SW_RESTORE
        u32.BringWindowToTop(hwnd)
        u32.SetForegroundWindow(hwnd)
        return True
    except Exception:
        return False


def log_boot(msg):
    """启动日志：窗口没出现时用来定位卡在哪一步"""
    try:
        os.makedirs(APP_DIR, exist_ok=True)
        with open(os.path.join(APP_DIR, 'startup.log'), 'a', encoding='utf-8') as f:
            f.write(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {msg}\n")
    except Exception:
        pass


# ================= Tk 应用 =================
class App:
    def __init__(self):
        self.root = tk.Tk()
        self.root.withdraw()          # 先藏起来，画完再显示 → 启动也零白框
        self.root.title(APP_NAME)
        C.THEME_NAME = load_theme_pref()
        apply_theme(C.THEME_NAME)
        try:
            sw = self.root.winfo_screenwidth()
            sh = self.root.winfo_screenheight()
            px = max(0, (sw - MAIN_W) // 2)
            py = max(0, (sh - MAIN_H) // 2 - 24)
        except Exception:
            px, py = 200, 80
        self.root.geometry(f"{MAIN_W}x{MAIN_H}+{px}+{py}")
        self.root.resizable(False, False)
        self.root.configure(bg=C.INK)
        try:
            ico = res_path("app.ico")
            if os.path.exists(ico):
                self.root.iconbitmap(ico)
        except Exception:
            pass

        # 去掉系统白色标题栏（自绘）
        self._drag = None
        self._tb_imgs = []
        self.hwnd = self._apply_borderless(self.root, MAIN_W, MAIN_H)

        # 状态
        self.cmd_seq = 0
        self.cmd_lines = []
        self.status_main = "正在启动修改组件…"
        self.status_detail = ""
        self.attached_pid = 0
        self.host_ready = False
        self.sent_pid = False
        self.pid_retry_at = 0.0
        self.last_status = ""
        self.last_proc_check = 0.0
        self.last_ping = 0.0
        self.pending_gets = {}
        self.bg_events = []
        self.host_proc = None
        self.exiting = False
        self.task_q = queue.Queue()      # 后台结果 -> UI
        self.cmd_q = queue.Queue()       # UI -> 后台写命令
        self.check_running = False       # 游戏检测线程是否在跑
        self.booting = False
        self.boot_done = False
        self.diag_running = False
        self.fake_att = False
        self.feat_fail = set()
        self.pending_on = {}
        self.pending_sets = {}
        self.verify_vals = {}
        self.write_total = 0
        self.write_ok = 0
        self.write_t0 = 0.0

        # 配置窗口状态
        self.cfg_win = None
        self.notice_win = None
        self.cfg_feature = None
        self.cfg_rows = []  # [(label, entry_var, frame)]

        self.build_main_ui()
        threading.Thread(target=self.cmd_worker, daemon=True).start()
        self.root.protocol("WM_DELETE_WINDOW", self.on_exit)
        if not os.environ.get('BWF_NOBOOT'):
            self.root.after(120, self.boot)
            self.root.after(500, self.tick)
            self.root.after(8000, lambda: threading.Thread(
                target=self._check_update_bg, daemon=True).start())
        self._ctl_start()
        self._hotkey_start()
        # 全部画完后一次性显示（第一帧就是完整界面）
        try:
            self.root.update_idletasks()
            self.root.deiconify()
            self.root.update_idletasks()
        except Exception:
            pass

    # ---------- 全局快捷键（Ctrl+1 物品 99 / Ctrl+2 友好度 499） ----------
    HOTKEYS = {
        1: ('Ctrl+1', 1429, 4, '99', '物品数量'),
        2: ('Ctrl+2', 39, 40, '499', 'NPC 友好度'),
    }

    def _hotkey_start(self):
        self.hotkey_q = queue.Queue()
        self.hotkey_stop = False
        self.hotkey_tid = 0
        threading.Thread(target=self._hotkey_loop, daemon=True).start()
        self.root.after(150, self._hotkey_poll)

    def _hotkey_loop(self):
        u32 = ctypes.WinDLL('user32', use_last_error=True)
        k32 = ctypes.WinDLL('kernel32', use_last_error=True)
        self.hotkey_tid = k32.GetCurrentThreadId()
        reg = {}
        for hid in self.HOTKEYS:
            try:
                reg[hid] = bool(u32.RegisterHotKey(None, hid, 0x0002, 0x30 + hid))
            except Exception:
                reg[hid] = False
        log_boot('hotkeys register: %s' % reg)
        if not any(reg.values()):
            return
        msg = wintypes.MSG()
        while not self.hotkey_stop:
            try:
                r = u32.GetMessageW(ctypes.byref(msg), None, 0, 0)
            except Exception:
                break
            if r == 0 or r == -1:
                break
            if msg.message == 0x0312:          # WM_HOTKEY
                try:
                    self.hotkey_q.put(int(msg.wParam))
                except Exception:
                    pass
        for hid in reg:
            try:
                u32.UnregisterHotKey(None, hid)
            except Exception:
                pass

    def _hotkey_poll(self):
        try:
            while True:
                try:
                    k = self.hotkey_q.get_nowait()
                except queue.Empty:
                    break
                self._hotkey_fire(k)
        except Exception:
            pass
        try:
            self.root.after(120, self._hotkey_poll)
        except Exception:
            pass

    def _hotkey_fire(self, k):
        info = self.HOTKEYS.get(k)
        if not info:
            return
        name, fid, vid, val, label = info
        if not self.attached_pid:
            self.set_status(detail='%s：还没连上游戏，先开游戏再按' % name)
            return
        self.send_cmd('ON|%d' % fid)
        self.send_cmd('SET|%d|%s' % (vid, val))
        for i, f in enumerate(FEATURES):
            if f['id'] == fid:
                try:
                    if not self.feat_vars[i].get():
                        self.feat_vars[i].set(True)
                        self._paint_feature(i, True)
                except Exception:
                    pass
                break
        self.set_status(detail='%s → %s %s（先在游戏里打开对应界面）' % (name, label, val))
        log_boot('hotkey %s -> %s=%s' % (name, label, val))

    def _hotkey_close(self):
        try:
            self.hotkey_stop = True
            if getattr(self, 'hotkey_tid', 0):
                ctypes.WinDLL('user32').PostThreadMessageW(self.hotkey_tid, 0x0012, 0, 0)
        except Exception:
            pass

    # ---------- 测试通道（仅 BWF_CTL=1 时启用，正常使用不生效） ----------
    def _ctl_start(self):
        if not os.environ.get('BWF_CTL'):
            return
        self._ctl_last = None
        self._ctl_poll()

    def _ctl_poll(self):
        try:
            p = os.path.join(TMP, 'bwf_ctl.txt')
            if os.path.exists(p):
                with open(p, encoding='utf-8') as f:
                    txt = f.read()
                if txt != getattr(self, '_ctl_last', None):
                    self._ctl_last = txt
                    self._ctl_exec(txt)
        except Exception:
            pass
        try:
            self.root.after(120, self._ctl_poll)
        except Exception:
            pass

    def _sim_click(self, x, y, cv=None):
        c = cv if cv is not None else self.cv
        c.event_generate('<Motion>', x=x, y=y, warp=False)
        c.event_generate('<Button-1>', x=x, y=y, warp=False)
        self.root.update()

    def _ctl_exec(self, txt):
        out = []
        for line in txt.splitlines():
            a = line.split()
            if not a or a[0].startswith('#'):
                continue
            try:
                c = a[0]
                if c == 'click' and len(a) >= 3:
                    self._sim_click(int(a[1]), int(a[2]))
                    out.append('ok click')
                elif c == 'clickcfg' and len(a) >= 3:
                    cv = None
                    for w in self.cfg_win.winfo_children():
                        if isinstance(w, tk.Canvas):
                            cv = w
                    self._sim_click(int(a[1]), int(a[2]), cv)
                    out.append('ok clickcfg')
                elif c == 'state':
                    out.append('state ' + ''.join(
                        '1' if v.get() else '0' for v in self.feat_vars))
                elif c == 'cfgstate':
                    out.append('cfg ' + ('open' if (self.cfg_win and
                                                    self.cfg_win.winfo_exists() and
                                                    self.cfg_win.winfo_ismapped())
                                         else 'closed'))
                elif c == 'status':
                    s = ''
                    try:
                        with open(STATUS_FILE, encoding='utf-8', errors='replace') as f:
                            s = f.read().strip()
                    except Exception:
                        s = 'none'
                    out.append('status ' + s)
                elif c == 'geom':
                    out.append('geom %dx%d' % (self.root.winfo_width(),
                                               self.root.winfo_height()))
                elif c == 'readvals':
                    vals = []
                    for rid, var in self.cfg_rows:
                        vals.append('%s=%s' % (rid, var.get()))
                    out.append('vals ' + ' '.join(vals))
                elif c == 'disclaimer':
                    self.root.after(20, self.on_disclaimer)
                    out.append('ok disclaimer')
                elif c == 'hotkey' and len(a) >= 2:
                    self.hotkey_q.put(int(a[1]))
                    out.append('ok hotkey ' + a[1])
                elif c == 'load' and len(a) >= 2:
                    self.send_cmd('LOAD|%s' % a[1])
                    out.append('ok load ' + a[1])
                elif c == 'who':
                    self.send_cmd('WHO')
                    out.append('ok who')
                elif c == 'diag':
                    self.root.after(20, self.on_diag)
                    out.append('ok diag')
                elif c == 'fakeattach':
                    self.fake_att = True
                    self.attached_pid = int(a[1]) if len(a) > 1 else 9999
                    self.last_proc_check = time.time() + 3600
                    out.append('att=%d' % self.attached_pid)
                else:
                    out.append('err ' + line)
            except Exception as ex:
                out.append('exc %s: %r' % (line, ex))
        try:
            with open(os.path.join(TMP, 'bwf_ctl_out.txt'), 'w', encoding='utf-8') as f:
                f.write('\n'.join(out) + '\n')
        except Exception:
            pass

    # ---------- 通用绘制部件 ----------
    def _diamond(self, cv, x, y, r, fill='', outline=None):
        cv.create_polygon(x, y - r, x + r, y, x, y + r, x - r, y,
                          fill=fill, outline=outline)

    # ---------- 命中测试（canvas 级，不做逐 item tag_bind） ----------
    def _init_canvas(self, cv):
        cv._bwf_hits = []
        cv._bwf_hover = None
        cv.bind('<Button-1>', lambda e, c=cv: self._cv_click(c, e), add='+')
        cv.bind('<Motion>', lambda e, c=cv: self._cv_motion(c, e), add='+')
        cv.bind('<B1-Motion>', lambda e, c=cv: self._cv_drag(c, e), add='+')
        cv.bind('<ButtonRelease-1>', lambda e, c=cv: self._cv_release(c, e), add='+')
        cv.bind('<Leave>', lambda e, c=cv: self._cv_leave(c), add='+')
        return cv

    def _hit_add(self, cv, x0, y0, x1, y1, kind, payload, **extra):
        if not hasattr(cv, '_bwf_hits'):
            self._init_canvas(cv)
        d = {'x0': x0, 'y0': y0, 'x1': x1, 'y1': y1, 'kind': kind, 'payload': payload}
        d.update(extra)
        cv._bwf_hits.append(d)
        return d

    def _hit_at(self, cv, x, y):
        for h in reversed(getattr(cv, '_bwf_hits', [])):
            if h['x0'] <= x <= h['x1'] and h['y0'] <= y <= h['y1']:
                return h
        return None

    def _cv_click(self, cv, e):
        h = self._hit_at(cv, e.x, e.y)
        self._drag = None
        if os.environ.get('BWF_DBG'):
            log_boot('CLICK (%d,%d) hit=%s' % (e.x, e.y, h and h['kind']))
        if h is None:
            return
        try:
            if h['kind'] == 'row':
                self.on_feature_toggle(h['payload'])
            elif h['kind'] == 'drag':
                self._begin_drag(h.get('hwnd'), e)
            else:
                cmd = h.get('cmd')
                if cmd:
                    cmd()
        except Exception:
            import traceback
            log_boot('CLICK ERR ' + traceback.format_exc())

    def _begin_drag(self, hwnd, e):
        try:
            r = wintypes.RECT()
            _U32.GetWindowRect(hwnd, ctypes.byref(r))
            self._drag = (hwnd, e.x_root - r.left, e.y_root - r.top)
        except Exception:
            self._drag = None

    def _cv_drag(self, cv, e):
        d = getattr(self, '_drag', None)
        if not d:
            return
        hwnd, ox, oy = d
        try:
            _U32.SetWindowPos(hwnd, 0, e.x_root - ox, e.y_root - oy, 0, 0,
                              0x0001 | 0x0004 | 0x0010)   # NOSIZE|NOZORDER|NOACTIVATE
        except Exception:
            pass

    def _cv_release(self, cv, e):
        self._drag = None

    def _cv_motion(self, cv, e):
        h = self._hit_at(cv, e.x, e.y)
        try:
            cv.config(cursor='hand2' if h is not None else 'arrow')
        except Exception:
            pass
        if h is getattr(cv, '_bwf_hover', None):
            return
        old = getattr(cv, '_bwf_hover', None)
        cv._bwf_hover = h
        if old is not None:
            self._paint_hit(cv, old, False)
        if h is not None:
            self._paint_hit(cv, h, True)

    def _cv_leave(self, cv):
        old = getattr(cv, '_bwf_hover', None)
        cv._bwf_hover = None
        try:
            cv.config(cursor='arrow')
        except Exception:
            pass
        if old is not None:
            self._paint_hit(cv, old, False)

    def _paint_hit(self, cv, h, active):
        try:
            if h['kind'] == 'row':
                idx = h['payload']
                on = self.feat_vars[idx].get()
                if active:
                    cv.itemconfig(h['bg'], fill='#20362B' if on else C.PANEL_HI)
                    cv.itemconfig(h['num'], fill=C.GOLD)
                else:
                    cv.itemconfig(h['bg'], fill=C.PANEL_HI if on else C.PANEL)
                    cv.itemconfig(h['num'], fill=C.TEXT3)
            else:
                cv.itemconfig(h['rect'],
                              fill=h.get('hover_fill', C.BTN_HI) if active else h['fill'],
                              outline=h.get('hover_edge', C.GOLD) if active else h['edge'])
                if h.get('text'):
                    cv.itemconfig(h['text'],
                                  fill=h.get('hover_tfill', C.GOLD_HI) if active else h['tfill'])
        except Exception:
            pass

    def _rect_button(self, cv, x, y, w, h, text, cmd, key, accent=False, small=False,
                     parent_bind=None):
        """直角描边按钮，带 hover"""
        tag = f'btn_{key}'
        edge = C.GOLD if accent else '#8A7448'
        fill = C.BTN
        tfill = C.GOLD_HI if accent else C.GOLD
        r = cv.create_rectangle(x, y, x + w, y + h, fill=fill, outline=edge, tags=(tag,))
        t = cv.create_text(x + w / 2, y + h / 2 + 1, text=text,
                           font=FONT_SMALL if small or not accent else FONT_NORMAL,
                           fill=tfill, tags=(tag,))
        self._hit_add(cv, x, y, x + w, y + h, 'btn', None,
                      cmd=cmd, rect=r, text=t, edge=edge, fill=fill, tfill=tfill, tag=tag)
        return tag

    # ---------- 无边框窗口 + 自绘标题栏 ----------
    def _hwnd_of(self, win):
        try:
            win.update_idletasks()
            h = _U32.GetParent(win.winfo_id())
            return h or win.winfo_id()
        except Exception:
            return 0

    def _strip_caption(self, win):
        """去掉系统白色标题栏，保留最小化/关闭能力"""
        try:
            hwnd = self._hwnd_of(win)
            if not hwnd:
                return 0
            st = _U32.GetWindowLongW(hwnd, _GWL_STYLE)
            st &= ~(_WS_CAPTION | _WS_THICKFRAME)
            _U32.SetWindowLongW(hwnd, _GWL_STYLE, st)
            _U32.SetWindowPos(hwnd, 0, 0, 0, 0, 0, _SWP)
            win.update_idletasks()
            return hwnd
        except Exception:
            return 0

    def _apply_borderless(self, win, w, h):
        """去系统标题栏 + 校准客户区尺寸（去边框后 Tk 的边框计算会偏差）"""
        hwnd = self._strip_caption(win)

        def fit():
            try:
                self._strip_caption(win)
                tw, th = w, h
                for _ in range(4):
                    win.geometry(f"{tw}x{th}")
                    win.update_idletasks()
                    rc = wintypes.RECT()
                    _U32.GetClientRect(hwnd, ctypes.byref(rc))
                    cw = rc.right - rc.left
                    ch = rc.bottom - rc.top
                    dw, dh = cw - w, ch - h
                    if dw == 0 and dh == 0:
                        break
                    tw -= dw
                    th -= dh
            except Exception:
                pass

        fit()
        # 延迟兜底：只有尺寸确实不对才动，避免"本来对了又被改一次"造成可见跳动
        def check():
            try:
                rc = wintypes.RECT()
                _U32.GetClientRect(hwnd, ctypes.byref(rc))
                if (rc.right - rc.left, rc.bottom - rc.top) != (w, h):
                    fit()
            except Exception:
                pass
        try:
            win.after(120, check)
        except Exception:
            pass
        return hwnd

    def _draw_toolbar(self, cv, win, w, title, hwnd, th=None, on_close=None):
        """自绘标题栏：图标 + 标题 + 最小化 / 关闭，可拖动"""
        th = th or TITLE_H
        cv.create_rectangle(0, 0, w, th, fill=C.TB_BG, outline='')
        cv.create_line(0, th, w, th, fill=C.GOLD_DIM)
        cv.create_line(0, th - 1, w, th - 1, fill=C.LINE_SOFT)

        ip = _tb_icon()
        tx = 14
        if ip:
            try:
                img = tk.PhotoImage(file=ip)
                cv.create_image(tx, th // 2, image=img, anchor='w')
                img._keep = True
                if not hasattr(self, '_tb_imgs'):
                    self._tb_imgs = []
                self._tb_imgs.append(img)
                tx += 30
            except Exception:
                pass
        cv.create_text(tx, th // 2 + 1, text=title, font=("楷体", 13, "bold"),
                       fill=C.GOLD, anchor='w')

        # 右侧：关闭 / 最小化
        bw, bh = 34, th - 10
        by = (th - bh) // 2
        bx_close = w - 12 - bw
        bx_min = bx_close - bw - 4

        rc = cv.create_rectangle(bx_close, by, bx_close + bw, by + bh,
                                 fill=C.TB_BG, outline=C.TB_BG)
        tc = cv.create_text(bx_close + bw / 2, by + bh / 2 + 1, text="✕",
                            font=("Segoe UI", 11), fill=C.TEXT2)
        self._hit_add(cv, bx_close, by, bx_close + bw, by + bh, 'btn', None,
                      cmd=on_close or self.on_exit, rect=rc, text=tc, fill=C.TB_BG,
                      edge=C.TB_BG, tfill=C.TEXT2, hover_fill=C.TB_CLOSE_HF,
                      hover_edge=C.TB_CLOSE_ED, hover_tfill=C.TB_CLOSE_TF)

        rm = cv.create_rectangle(bx_min, by, bx_min + bw, by + bh,
                                 fill=C.TB_BG, outline=C.TB_BG)
        tm = cv.create_text(bx_min + bw / 2, by + bh / 2 + 1, text="—",
                            font=("Segoe UI", 11), fill=C.TEXT2)
        self._hit_add(cv, bx_min, by, bx_min + bw, by + bh, 'btn', None,
                      cmd=lambda w_=win: w_.iconify(), rect=rm, text=tm,
                      fill=C.TB_BG, edge=C.TB_BG, tfill=C.TEXT2,
                      hover_fill=C.BTN_HI, hover_edge=C.GOLD, hover_tfill=C.GOLD_HI)

        # 昼夜切换按钮
        bw2 = 40
        bx_th = bx_min - bw2 - 4
        tt = "昼" if C.THEME_NAME == 'night' else "夜"
        rt = cv.create_rectangle(bx_th, by, bx_th + bw2, by + bh,
                                 fill=C.TB_BG, outline=C.TB_BG)
        tt2 = cv.create_text(bx_th + bw2 / 2, by + bh / 2 + 1, text=tt,
                             font=("楷体", 11, "bold"), fill=C.GOLD)
        self._hit_add(cv, bx_th, by, bx_th + bw2, by + bh, 'btn', None,
                      cmd=self.toggle_theme, rect=rt, text=tt2,
                      fill=C.TB_BG, edge=C.TB_BG, tfill=C.GOLD,
                      hover_fill=C.BTN_HI, hover_edge=C.GOLD, hover_tfill=C.GOLD_HI)

        # 拖动区（标题栏其余部分）
        self._hit_add(cv, 0, 0, bx_min - 2, th, 'drag', None, hwnd=hwnd)

    def toggle_theme(self):
        detail = ''
        try:
            detail = self.cv.itemcget(self.tx_detail, 'text')
        except Exception:
            pass
        main_txt = getattr(self, 'status_main', '')
        C.THEME_NAME = 'day' if C.THEME_NAME == 'night' else 'night'
        save_theme_pref(C.THEME_NAME)
        apply_theme(C.THEME_NAME)
        self.hide_config()
        self.hide_notice()
        self.draw_main()
        self.set_status(main_txt, detail)

    # ---------- 主界面 ----------
    def build_main_ui(self):
        W, H = MAIN_W, MAIN_H
        self.cv = tk.Canvas(self.root, width=W, height=H, highlightthickness=0,
                            bd=0, bg=C.INK)
        self.cv.pack(fill='both', expand=True)
        self._init_canvas(self.cv)
        self.draw_main()

    def draw_main(self):
        """绘制整个主界面（昼夜切换时全量重绘）"""
        W, H = MAIN_W, MAIN_H
        cv = self.cv
        cv.delete('all')
        cv._bwf_hits = []
        cv.config(bg=C.INK)
        self.root.config(bg=C.INK)
        self.feat_vars = []
        self.feat_items = []
        self._tb_imgs = []

        bgp = _ui_bg(W, H, os.path.join(UI_DIR, f'bg_main_{W}x{H}.png'))
        if bgp and os.path.exists(bgp):
            try:
                self._bg_img = tk.PhotoImage(file=bgp)
                self.cv.create_image(0, 0, image=self._bg_img, anchor='nw')
            except Exception:
                pass

        # ---- 标题栏（自绘）----
        self._draw_toolbar(self.cv, self.root, W, APP_NAME, self.hwnd)

        # ---- 标题区（居中）----
        cx = W / 2
        self.cv.create_text(cx, 80, text="不问凡尘", font=FONT_TITLE,
                            fill=C.GOLD_HI, anchor='center')
        self.cv.create_line(cx - 208, 103, cx - 148, 103, fill=C.GOLD_DIM)
        self.cv.create_line(cx + 148, 103, cx + 208, 103, fill=C.GOLD_DIM)
        self._diamond(self.cv, cx - 218, 103, 3, outline=C.GOLD_DIM)
        self._diamond(self.cv, cx + 218, 103, 3, outline=C.GOLD_DIM)
        self.cv.create_text(cx, 121, text=f"修  改  器    ·    {VERSION}",
                            font=("楷体", 13), fill=C.GOLD, anchor='center')

        # ---- 状态卡 ----
        sx, sy, sw_, sh = 40, 146, W - 80, 70
        self.cv.create_rectangle(sx, sy, sx + sw_, sy + sh, fill=C.PANEL, outline=C.LINE)
        self.cv.create_line(sx, sy, sx, sy + sh, fill=C.GOLD_DIM, width=2)
        self.dot = self.cv.create_oval(sx + 22, sy + 30, sx + 31, sy + 39,
                                       fill=C.RED, outline='')
        self.tx_status = self.cv.create_text(sx + 44, sy + 24, text=self.status_main,
                                             font=FONT_NORMAL, fill=C.TEXT, anchor='w')
        self.tx_detail = self.cv.create_text(sx + 44, sy + 47, text="",
                                             font=FONT_SMALL, fill=C.TEXT2, anchor='w')
        self._hit_add(cv, sx, sy, sx + sw_, sy + sh, 'btn', None,
                      cmd=self._on_status_click)
        self._rect_button(self.cv, sx + sw_ - 218, sy + 20, 88, 30, "自 检",
                          self.on_diag, 'diag', small=True)
        self._rect_button(self.cv, sx + sw_ - 122, sy + 20, 102, 30, "重新检测",
                          self.on_recheck, 'recheck', small=True)

        # ---- 功能列表标题 ----
        self.cv.create_text(40, 238, text="功 能 铭 刻", font=("楷体", 14, "bold"),
                            fill=C.GOLD, anchor='w')
        self.cv.create_text(W - 40, 239, text="勾选即启用 · 进游戏触发一次后可在配置中改写数值",
                            font=FONT_SMALL, fill=C.TEXT3, anchor='e')
        self.cv.create_line(40, 252, W - 40, 252, fill=C.LINE_SOFT)

        # ---- 功能行 ----
        self.feat_vars = []
        self.feat_items = []
        y = 264
        ROW_H, GAP = 40, 4
        for i, f in enumerate(FEATURES):
            self.feat_vars.append(tk.BooleanVar(value=False))
            self.feat_items.append(self._build_feature_row(i, f, y, ROW_H))
            y += ROW_H + GAP

        # ---- 底部 ----
        by = y + 8
        self.cv.create_line(40, by, W - 40, by, fill=C.LINE_SOFT)
        self.cv.create_text(W / 2, by + 18,
                            text="先开游戏再开修改器 · 勾选后进游戏触发一次 · "
                                 "Ctrl+1 物品→99 ／ Ctrl+2 友好度→499",
                            font=FONT_SMALL, fill=C.TEXT3)
        self._rect_button(self.cv, 40, by + 36, 108, 32, "免责声明",
                          self.on_disclaimer, 'disc', small=True)
        self._rect_button(self.cv, 156, by + 36, 108, 32, "更多资源",
                          self.on_resources, 'res', small=True)
        self._rect_button(self.cv, W - 176, by + 36, 136, 32, "退 出 修 改 器",
                          self.on_exit, 'exit', accent=True)

    def _build_feature_row(self, i, f, y, h):
        cv = self.cv
        x0, x1 = 40, MAIN_W - 40
        tag = f'row{i}'
        bg_id = cv.create_rectangle(x0, y, x1, y + h, fill=C.PANEL, outline='', tags=(tag,))
        rowhit = self._hit_add(cv, x0, y, x1, y + h, 'row', i)
        bar = cv.create_rectangle(x0, y + 9, x0 + 3, y + h - 9,
                                  fill=C.GOLD_DIM, outline='', tags=(tag,))
        bs = 18
        bx = x0 + 20
        byy = y + (h - bs) // 2
        box = cv.create_rectangle(bx, byy, bx + bs, byy + bs, fill='',
                                  outline=C.GOLD_DIM, width=1, tags=(tag,))
        tick = cv.create_line(bx + 4, byy + 9, bx + 8, byy + 13, bx + 14, byy + 5,
                              fill=C.INK, width=2, state='hidden', tags=(tag,))
        name = cv.create_text(bx + bs + 18, y + h / 2 + 1, text=f["name"],
                              font=FONT_NORMAL, fill=C.TEXT, anchor='w', tags=(tag,))
        num = cv.create_text(x1 - 104, y + h / 2 + 1, text="%02d" % (i + 1),
                             font=("Consolas", 9), fill=C.TEXT3, anchor='e', tags=(tag,))
        rowhit['bg'] = bg_id
        rowhit['num'] = num
        # 配置按钮最后登记 -> 命中测试倒序查找时优先于整行
        if f["values"]:
            self._rect_button(cv, x1 - 90, y + (h - 28) // 2, 74, 28, "配 置",
                              (lambda idx=i: self.open_config(idx)), f'cfg{i}', small=True)
        return {'bg': bg_id, 'bar': bar, 'box': box, 'tick': tick, 'name': name, 'num': num}

    def _paint_feature(self, idx, on):
        it = self.feat_items[idx]
        try:
            fail = idx in getattr(self, 'feat_fail', ())
            if on:
                self.cv.itemconfig(it['bg'], fill=C.PANEL_HI)
                self.cv.itemconfig(it['bar'], fill=C.RED if fail else C.JADE_HI)
                self.cv.itemconfig(it['box'], fill=C.JADE, outline=C.JADE_HI)
                self.cv.itemconfig(it['tick'], state='normal')
                self.cv.itemconfig(it['name'], fill=C.RED if fail else C.GOLD_HI)
            else:
                self.cv.itemconfig(it['bg'], fill=C.PANEL)
                self.cv.itemconfig(it['bar'], fill=C.GOLD_DIM)
                self.cv.itemconfig(it['box'], fill='', outline=C.GOLD_DIM)
                self.cv.itemconfig(it['tick'], state='hidden')
                self.cv.itemconfig(it['name'], fill=C.TEXT)
        except Exception:
            pass

    # ---------- 状态刷新（仅主线程） ----------
    def set_status(self, main=None, detail=None):
        if main is not None:
            self.status_main = main
        if detail is not None:
            self.status_detail = detail
        try:
            self.cv.itemconfig(self.tx_status, text=self.status_main)
            self.cv.itemconfig(self.tx_detail, text=self.status_detail)
            ready = bool(self.attached_pid)
            self.cv.itemconfig(self.dot, fill=C.JADE_HI if ready else C.RED)
        except Exception:
            pass

    # ---------- 启动（后台线程，UI 线程只等结果） ----------
    def boot(self):
        if self.booting:
            return
        self.booting = True
        self.set_status("正在初始化运行环境…", "首次运行需要解压组件，请稍候")
        threading.Thread(target=self._boot_worker, daemon=True).start()

    def _wait_pong(self, timeout):
        """启动后主动 PING，确认 Lua 真跑起来了。
           隐藏桌面上够不到「Execute this lua script?」确认框，所以必须靠这个
           判断要不要回退到普通桌面。"""
        t0 = time.time()
        seq = 900000
        ok = False
        while time.time() - t0 < timeout:
            if self.exiting:
                break
            try:
                with open(CMD_FILE, 'w', encoding='utf-8') as f:
                    f.write('PING|0|0|%d' % seq)
                seq += 1
            except Exception:
                pass
            time.sleep(1.0)
            try:
                with open(STATUS_FILE, 'r', encoding='utf-8', errors='replace') as f:
                    if 'PONG' in f.read():
                        ok = True
                        break
            except Exception:
                pass
        # 抬高序号基线：Lua 的 lastSeq 已经跳到 seq，
        # 不抬高的话主线程从 1 开始发的命令会全被当成旧命令丢弃
        self.cmd_seq = max(self.cmd_seq, seq)
        return ok

    def _boot_worker(self):
        try:
            log_boot('boot: start')
            # 清掉上一次残留的命令/状态文件：Lua 侧 lastSeq 若还停在大值，
            # 新实例从 1 开始发命令会被整批丢弃（表现为"点了没反应"）
            for _f in (CMD_FILE, STATUS_FILE):
                try:
                    os.remove(_f)
                except Exception:
                    pass
            stale = True
            try:
                with open(STAMP, 'r', encoding='utf-8') as f:
                    stale = f.read().strip() != RT_VER
            except Exception:
                stale = True
            if stale or not os.path.exists(os.path.join(RT_DIR, 'mzhost.exe')):
                log_boot('boot: extracting runtime (ver %s) -> %s' % (RT_VER, RT_DIR))
                self.extract_runtime()
            else:
                log_boot('boot: runtime up to date')
            _ensure_ce_policy()
            log_boot('boot: ce policy set')
            ct = os.path.join(RT_DIR, 'BWF_不问凡尘_V1.CT')
            if not os.path.exists(ct):
                cand = [f for f in os.listdir(RT_DIR) if f.upper().endswith('.CT')]
                if not cand:
                    self.task_q.put(("error", "缺少表文件，请重新解压程序"))
                    return
                ct = os.path.join(RT_DIR, cand[0])
            host = os.path.join(RT_DIR, 'mzhost.exe')
            if not os.path.exists(host):
                self.task_q.put(("error", "组件解压不完整，请删除 "
                                         + APP_DIR + " 后重试"))
                return
            log_boot('boot: launching ' + host)
            self.host_proc = None
            threading.Thread(
                target=_watch_ce,
                args=(lambda: self.exiting,
                      lambda: self.host_proc.pid if self.host_proc else 0),
                daemon=True).start()

            # 首选：独立隐藏桌面，窗口根本不会进入用户屏幕
            try:
                self.host_proc = spawn_ce_hidden(host, ct, RT_DIR)
                log_boot('boot: hidden desktop pid %d' % self.host_proc.pid)
                if not self._wait_pong(7):
                    log_boot('boot: hidden desktop 无 PONG，回退普通桌面')
                    try:
                        self.host_proc.terminate()
                        self.host_proc.wait(timeout=2)
                        self.host_proc.cleanup()
                    except Exception:
                        pass
                    self.host_proc = None
                    time.sleep(1.0)
            except Exception as e:
                log_boot('boot: hidden desktop 失败 ' + repr(e))
                self.host_proc = None

            if self.host_proc is None:
                # 回退方案：普通桌面 + 看门狗（会有极短闪现，但功能可用）
                for _f in (CMD_FILE, STATUS_FILE):
                    try:
                        os.remove(_f)
                    except Exception:
                        pass
                self.host_proc = subprocess.Popen(
                    [host, ct], cwd=RT_DIR, close_fds=True,
                    creationflags=0x08000000)
                log_boot('boot: normal desktop pid %d' % self.host_proc.pid)
            self.task_q.put(("booted", ""))
        except Exception as e:
            log_boot('boot: EXCEPTION ' + repr(e))
            self.task_q.put(("error", str(e)))

    def extract_runtime(self):
        zpath = res_path("res.zip")
        if not os.path.exists(zpath):
            raise RuntimeError("内置资源缺失")
        os.makedirs(RT_DIR, exist_ok=True)
        with zipfile.ZipFile(zpath) as z:
            for info in z.infolist():
                target = os.path.join(RT_DIR, info.filename.replace('/', os.sep))
                if not os.path.abspath(target).startswith(os.path.abspath(RT_DIR)):
                    continue
                if info.is_dir():
                    os.makedirs(target, exist_ok=True)
                    continue
                os.makedirs(os.path.dirname(target), exist_ok=True)
                with z.open(info) as src, open(target, 'wb') as dst:
                    dst.write(src.read())
        with open(STAMP, 'w', encoding='utf-8') as f:
            f.write(RT_VER)

    # ---------- 定时器（唯一的状态大脑） ----------
    def tick(self):
        if self.exiting:
            return
        try:
            # 1) 后台结果（线程安全队列）
            while True:
                try:
                    kind, payload = self.task_q.get_nowait()
                except queue.Empty:
                    break
                if kind == "booted":
                    self.set_status("正在启动修改组件…", "")
                elif kind == "error":
                    # 不退出：把错误留在界面上，用户能截图反馈
                    self.set_status("启动失败", str(payload))
                    log_boot('boot error: ' + str(payload))
                    messagebox.showerror(APP_NAME,
                                         f"启动失败：{payload}\n\n"
                                         f"程序会保持打开，可以截图反馈。\n"
                                         f"日志：{os.path.join(APP_DIR, 'startup.log')}")
                elif kind == "game":
                    if getattr(self, 'fake_att', False):
                        continue
                    if payload:
                        if self.attached_pid == 0 and not self.sent_pid:
                            self.sent_pid = True
                            self.pid_retry_at = time.time() + 4
                            self.send_cmd(f"PID|{payload}")
                            self.set_status("正在附加游戏…", "")
                    else:
                        if self.attached_pid == 0:
                            self.set_status("未检测到游戏 WorldApart.exe，请先打开游戏",
                                            "游戏启动后点击【重新检测游戏】")
                        else:
                            self.attached_pid = 0
                            self.sent_pid = False
                            self.set_status("游戏已关闭，等待重新启动…", "")

            # 1.3) 写入超时
            now00 = time.time()
            if self.pending_sets and self.write_t0 and now00 - self.write_t0 > 4.0:
                self.pending_sets.clear()
                self.set_status(detail="写入无响应：点【自检】看看功能有没有激活")
            if self.verify_vals and self.write_t0 and now00 - self.write_t0 > 7.0:
                self.verify_vals.clear()
                self.set_status(detail="已写入，但回读无响应（数值可能已生效，回游戏确认）")

            # 1.4) 激活超时：3.5 秒没等到 OK 就是注入失败（多为游戏版本不匹配）
            now00 = time.time()
            for fid, (idx, t0) in list(self.pending_on.items()):
                if now00 - t0 > 3.5:
                    self.pending_on.pop(fid, None)
                    self.feat_fail.add(idx)
                    self._paint_feature(idx, True)
                    self.set_status(detail='功能注入失败（该行已标红）：游戏版本可能已更新，点【自检】确认')

            # 1.5) 读取超时：Lua 没回执就别一直挂着"读取中"
            now0 = time.time()
            for rid, t0 in list(self.pending_gets.items()):
                if now0 - (t0 or 0) > 3.5:
                    self.pending_gets.pop(rid, None)
                    self.fill_config_value(rid, '??')
                    self.set_status(detail='读取超时：功能可能没触发，或游戏版本不匹配（点【自检】）')

            # 2) 状态快照
            st = self.read_status()
            if st and st != self.last_status:
                self.last_status = st
                self.handle_status(st)

            # 3) 未就绪时定期 PING 探测组件
            now = time.time()
            if not self.host_ready and now - self.last_ping > 2:
                self.last_ping = now
                self.send_cmd("PING")

            # 4) 自动检测游戏：交给后台线程（进程枚举可能被安全软件拖慢）
            if self.attached_pid == 0 and not self.sent_pid:
                if now - self.last_proc_check > 3 and not self.check_running:
                    self.last_proc_check = now
                    self.check_running = True
                    threading.Thread(target=self._bg_check_game, daemon=True).start()

            # 5) PID 重试
            if self.sent_pid and self.attached_pid == 0 and self.pid_retry_at and now > self.pid_retry_at:
                self.sent_pid = False
                self.pid_retry_at = 0

            # 6) 游戏关闭检测（后台）
            if self.attached_pid != 0 and now - self.last_proc_check > 2 and not self.check_running:
                self.last_proc_check = now
                self.check_running = True
                threading.Thread(target=self._bg_check_game, daemon=True).start()
        except Exception:
            pass
        finally:
            self.root.after(500, self.tick)

    def _bg_check_game(self):
        try:
            pid = find_process("WorldApart.exe")
        except Exception:
            pid = 0
        self.check_running = False
        self.task_q.put(("game", pid))

    def handle_status(self, st):
        if not st.startswith("S|"):
            return
        segs = st.split("|")
        att = 0
        if len(segs) >= 2 and segs[1].startswith("att="):
            try:
                att = int(segs[1][4:])
            except ValueError:
                att = 0
        if att:
            self.host_ready = True
            if att != self.attached_pid:
                self.attached_pid = att
                threading.Thread(target=heal_game_code, args=(att,), daemon=True).start()
                threading.Thread(target=self._detect_table_bg, args=(att,), daemon=True).start()
                self.set_status(f"已附加游戏 WorldApart.exe (PID {att})",
                                "现在可以勾选功能；开启后进游戏触发一次数据读取")
        rest = segs[2:] if len(segs) > 2 else []
        if not rest:
            return
        ev = rest[0]
        if ev == "PONG":
            self.host_ready = True
            if self.attached_pid == 0:
                self.set_status("运行组件已就绪，等待游戏…", "")
        elif ev == "ATTACHED":
            self.host_ready = True
        elif ev == "OK":
            self.host_ready = True
            if len(rest) >= 3 and rest[2] == "ON":
                try:
                    fid = int(rest[1])
                except ValueError:
                    fid = 0
                item = self.pending_on.pop(fid, None)
                if item:
                    self.feat_fail.discard(item[0])
                    self._paint_feature(item[0], True)
            elif len(rest) >= 3:
                try:
                    sid = int(rest[1])
                except ValueError:
                    sid = 0
                if sid in self.pending_sets:
                    self.verify_vals[sid] = self.pending_sets.pop(sid)
                    self.write_ok += 1
                    if not self.pending_sets:
                        self.set_status(detail="已写入 %d 项，正在回读确认…" % self.write_ok)
                        for r in list(self.verify_vals):
                            self.pending_gets[r] = time.time()
                            self.send_cmd("GET|%d" % r)
        elif ev == "VAL" and len(rest) >= 3:
            try:
                rid = int(rest[1])
            except ValueError:
                return
            if self.pending_gets.pop(rid, None) is not None:
                self.fill_config_value(rid, rest[2])
                if rid in self.verify_vals:
                    exp = self.verify_vals.pop(rid)
                    got = rest[2]
                    same = (got == exp)
                    if not same:
                        try:
                            same = int(float(got)) == int(float(exp))
                        except Exception:
                            same = False
                    if same:
                        self.write_ok_confirm = getattr(self, 'write_ok_confirm', 0) + 1
                    else:
                        self.write_fail_confirm = getattr(self, 'write_fail_confirm', 0) + 1
                    if not self.verify_vals:
                        okn = getattr(self, 'write_ok_confirm', 0)
                        badn = getattr(self, 'write_fail_confirm', 0)
                        self.write_ok_confirm = 0
                        self.write_fail_confirm = 0
                        if badn == 0:
                            self.set_status(detail="写入成功：%d 项已生效（已回读确认）" % okn)
                        else:
                            self.set_status(detail="写入完成：%d 项成功，%d 项没生效（数值可能被游戏覆盖）"
                                            % (okn, badn))
        elif ev == "ERR":
            msg = "|".join(rest[1:])
            low = msg.lower()
            if ('aobscan' in low or 'not found' in low or 'memrec' in low
                    or 'not all results' in low):
                self.set_status(detail='功能注入失败（游戏版本可能已更新）→ 点【自检】导出报告')
                log_boot('INJECT FAIL: ' + msg)
            else:
                self.set_status(detail="操作返回: " + msg)
        elif ev == "LUAERR":
            self.set_status(detail="脚本提示: " + "|".join(rest[1:]))

    # ---------- 文件通信 ----------
    def read_status(self):
        try:
            with open(STATUS_FILE, 'r', encoding='utf-8', errors='replace') as f:
                return f.read().strip()
        except Exception:
            return ""

    def send_cmd(self, cmd):
        # UI 线程只入队，文件 IO 由后台线程完成（避免杀软扫描导致界面卡死）
        self.cmd_seq += 1
        self.cmd_lines.append(f"{cmd}|{self.cmd_seq}")
        if len(self.cmd_lines) > 40:
            self.cmd_lines = self.cmd_lines[-40:]
        snapshot = "\r\n".join(self.cmd_lines)
        self.cmd_q.put(snapshot)

    def cmd_worker(self):
        last = None
        while True:
            try:
                data = self.cmd_q.get()
            except Exception:
                time.sleep(0.2)
                continue
            if data is None:
                break
            if data == last:
                continue
            last = data
            tmp = CMD_FILE + ".tmp"
            for _ in range(3):
                try:
                    with open(tmp, 'w', encoding='utf-8') as f:
                        f.write(data)
                    os.replace(tmp, CMD_FILE)
                    break
                except Exception:
                    time.sleep(0.1)

    # ---------- 交互 ----------
    def on_feature_toggle(self, idx):
        f = FEATURES[idx]
        on = not self.feat_vars[idx].get()
        self.feat_vars[idx].set(on)
        self._paint_feature(idx, on)
        log_boot('toggle %d (%s) -> %s' % (idx, f['name'], on))
        if on:
            self.feat_fail.discard(idx)
            self.pending_on[f['id']] = (idx, time.time())
            self.send_cmd(f"ON|{f['id']}")
            self.set_status(detail=f"已启用 · {f['name']}（进游戏触发一次）")
        else:
            self.send_cmd(f"OFF|{f['id']}")
            self.set_status(detail=f"已关闭 · {f['name']}")

    def on_recheck(self):
        if self.check_running:
            return
        self.attached_pid = 0
        self.sent_pid = False
        self.pid_retry_at = 0
        self.last_proc_check = 0
        self.set_status("正在检测游戏…", "")
        self.check_running = True
        threading.Thread(target=self._bg_check_game, daemon=True).start()

    def _check_update_bg(self):
        try:
            import urllib.request
            req = urllib.request.Request(UPDATE_JSON_URL,
                                         headers={'User-Agent': 'BWF-Trainer'})
            with urllib.request.urlopen(req, timeout=8) as r:
                info = json.loads(r.read().decode('utf-8'))
            rv = str(info.get('version', '')).strip()
            if not rv or rv == VERSION:
                log_boot('update: up to date')
                return
            note = str(info.get('note', ''))[:50]
            self.update_available = True
            self.update_info = info
            self.set_status('发现新版本 V%s（当前 V%s）' % (rv, VERSION),
                            '%s —— 点击状态卡直接下载新版' % note)
            log_boot('update: new version %s' % rv)
        except Exception as e:
            log_boot('update check failed: %r' % e)

    def _on_status_click(self):
        if getattr(self, 'update_available', False):
            info = getattr(self, 'update_info', {}) or {}
            url = info.get('download_mirror') or info.get('download') or RELEASE_PAGE
            try:
                os.startfile(url)
            except Exception:
                import webbrowser
                webbrowser.open(url)

    def _detect_table_bg(self, pid):
        try:
            time.sleep(2.0)          # 等 heal 与 openProcess 稳定
            mode, hits = _scan_game_sigs(pid)
        except Exception as e:
            log_boot('table detect error: %r' % e)
            return
        log_boot('table detect: %s hits=%d' % (mode, hits))
        if mode == 'v1017+':
            self.set_status('已附加游戏 WorldApart.exe (PID %d)' % pid,
                            '已识别最新版游戏，加载完整功能表')
            return
        tbl = {'v1001': 'BWF_tbl_1001.CT', 'v0929': 'BWF_tbl_0929.CT'}.get(mode)
        if not tbl:
            self.set_status('游戏版本过新或过旧', '当前表无法适配，等作者更新')
            return
        tname, sup = TABLE_NAMES[mode]
        self.send_cmd('LOAD|%s' % tbl)
        self.set_status('已附加游戏 WorldApart.exe (PID %d)' % pid,
                        '已按游戏版本加载%s：支持 %s' % (tname, sup))

    # ---------- 自检：定位“读不到数”的原因 ----------
    def on_diag(self):
        if self.diag_running:
            return
        try:
            os.remove(os.path.join(TMP, 'bwf_dump.txt'))
        except OSError:
            pass
        if self.attached_pid == 0:
            self.set_status("自检：还没连上游戏", "先开游戏，等状态变绿再点【自检】")
            return
        self.diag_running = True
        self.set_status("自检中…", "正在激活全部功能并读取地址表，约 5 秒")
        for f in FEATURES:
            self.send_cmd('ON|%d' % f['id'])
        self.root.after(2600, self._diag_dump)

    def _diag_dump(self):
        self.send_cmd('DUMP|0')
        self.root.after(1800, self._diag_report)

    def _diag_report(self):
        self.diag_running = False
        rows = []
        try:
            with open(os.path.join(TMP, 'bwf_dump.txt'), encoding='utf-8',
                      errors='replace') as f:
                for ln in f:
                    p = ln.rstrip('\r\n').split('\t')
                    if len(p) >= 4:
                        rows.append(p)
        except Exception:
            pass

        def ok_val(v):
            return not (v.startswith('?') or v == 'READERR' or v == '')

        measured = [r for r in rows if r[3] != '']
        total = len(measured)
        good = sum(1 for r in measured if ok_val(r[3]))
        bad = total - good
        fname = {}
        for f in FEATURES:
            fname[str(f['id'])] = f['name']

        out = []
        out.append('不问凡尘修改器 自检报告')
        out.append('时间：' + time.strftime('%Y-%m-%d %H:%M:%S'))
        out.append('附加状态：' + (('已附加 PID %d' % self.attached_pid)
                                  if self.attached_pid else '未附加游戏'))
        out.append('地址表条目：%d（有数值的 %d 项）' % (len(rows), total))
        out.append('能读到值：%d，读不到：%d' % (good, bad))
        out.append('原始地址表：' + os.path.join(TMP, 'bwf_dump.txt'))
        out.append('')

        if self.attached_pid == 0:
            verdict = '没连上游戏。先开游戏，等状态变绿再点自检。'
            self.diag_hint = 'no_game'
        elif total == 0:
            verdict = 'CE 起来了，但地址表是空的（CT 没加载成功）。'
        elif good == 0:
            verdict = ('所有功能都读不到数据 → 游戏版本和这份表不匹配（等作者更新），'
                       '或者功能还没在游戏里触发过。')
        elif bad > 0:
            verdict = '部分功能可用，%d 项读不到（多半是没在游戏里触发）。' % bad
        else:
            verdict = '全部正常，可以正常改。'
        out.append('结论：' + verdict)
        out.append('')

        out.append('--- 各功能状态 ---')
        for f in FEATURES:
            ids = [str(v[0]) for v in f['values']]
            vals = []
            for r in rows:
                if r[0] in ids:
                    vals.append(r[3])
            if not vals:
                st = '无数据'
            elif any(ok_val(v) for v in vals):
                st = '正常'
            else:
                st = '读不到'
            out.append('  %-14s %s (%s)' % (f['name'], st, ', '.join(vals[:3])))

        out.append('')
        out.append('--- 地址表全部条目 ---')
        for r in rows:
            out.append('  ID=%-5s Active=%-5s 值=%-14s %s' % (r[0], r[2], r[3], r[1][:40]))

        txt = '\n'.join(out)
        try:
            dp = os.path.join(APP_DIR, 'diag.txt')
            with open(dp, 'w', encoding='utf-8') as f:
                f.write(txt)
        except Exception:
            dp = '(写日志失败)'

        self.set_status('自检完成', verdict)
        self.show_notice('自检结果', verdict + '\n\n完整报告：\n' + dp)

    def on_disclaimer(self):
        self.show_notice("免责声明", DISCLAIMER)

    def hide_notice(self):
        if getattr(self, 'notice_win', None) is not None:
            try:
                self.notice_win.destroy()
            except Exception:
                pass
            self.notice_win = None

    @staticmethod
    def _wrap_para(text, font, max_w):
        """按像素宽度折行；收尾标点不落到行首（避头点）"""
        import tkinter.font as tkfont
        f = tkfont.Font(font=font)
        no_head = '，。、；：）】」』！？%”’'
        out = []
        for para in text.split('\n'):
            if not para.strip():
                out.append('')
                continue
            cur = ''
            for ch in para:
                if not cur or f.measure(cur + ch) <= max_w or ch in no_head:
                    cur += ch
                else:
                    out.append(cur)
                    cur = ch
            if cur:
                out.append(cur)
        return '\n'.join(out)

    def show_notice(self, title, text):
        """自绘暗色提示窗（与主界面同风格，无系统白框）"""
        self.hide_notice()
        W = 520
        TH = CFG_TITLE_H
        win = tk.Toplevel(self.root)
        win.withdraw()
        win.title(title)
        win.configure(bg=C.INK)
        win.resizable(False, False)
        win.protocol("WM_DELETE_WINDOW", self.hide_notice)
        try:
            ico = res_path("app.ico")
            if os.path.exists(ico):
                win.iconbitmap(ico)
        except Exception:
            pass
        self.notice_win = win

        cv = tk.Canvas(win, width=W, height=600, highlightthickness=0, bd=0, bg=C.INK)
        cv.pack(fill='both', expand=True)
        self._init_canvas(cv)
        pad = 38
        body = self._wrap_para(text.replace('\r\n', '\n').replace('\r', '\n'),
                               FONT_NORMAL, W - pad * 2)
        item = cv.create_text(pad, 26, text=body, font=FONT_NORMAL, fill=C.TEXT,
                              anchor='nw')
        bb = cv.bbox(item) or (0, 0, W, 200)
        body_bottom = bb[3] + 22
        H = TH + body_bottom + 34 + 28
        cv.config(height=H)

        bgp = _ui_bg(W, H, os.path.join(UI_DIR, f'bg_notice_{W}x{H}.png'), 0.42)
        if bgp and os.path.exists(bgp):
            try:
                img = tk.PhotoImage(file=bgp)
                bid = cv.create_image(0, 0, image=img, anchor='nw')
                cv._bgref = img
                cv.tag_lower(bid)
            except Exception:
                pass

        cv.move(item, 0, TH)
        self._rect_button(cv, W // 2 - 58, TH + body_bottom + 8, 116, 34, "确 定",
                          self.hide_notice, 'notice_ok')

        win.update_idletasks()
        chwnd = self._apply_borderless(win, W, H)
        self._draw_toolbar(cv, win, W, title, chwnd, th=TH, on_close=self.hide_notice)

        # 居中于主窗口
        try:
            self.root.update_idletasks()
            mx = self.root.winfo_rootx()
            my = self.root.winfo_rooty()
            mw = self.root.winfo_width()
            mh = self.root.winfo_height()
            x = mx + (mw - W) // 2
            yy = my + (mh - H) // 2
            win.geometry(f"{W}x{H}+{x}+{yy}")
        except Exception:
            pass

        win.deiconify()
        try:
            win.update_idletasks()
            win.update_idletasks()
        except Exception:
            pass
        win.lift()
        win.focus_force()

    def on_resources(self):
        try:
            os.startfile(RESOURCES_URL)
        except Exception:
            import webbrowser
            webbrowser.open(RESOURCES_URL)

    def on_exit(self):
        if self.exiting:
            return
        self.exiting = True
        self._hotkey_close()
        # 先把所有功能关掉：让 CE 执行 AA 脚本的 DISABLE 段，还原游戏代码，
        # 否则直接杀进程会在游戏里留下无效 hook（下次注入扫描不到特征码）
        try:
            if self.host_proc and self.host_proc.poll() is None:
                self.send_cmd('OFFALL')
                t0 = time.time()
                while time.time() - t0 < 2.0:
                    time.sleep(0.1)
                    if 'OFFALL' in self.read_status():
                        break
                time.sleep(0.3)
        except Exception:
            pass
        try:
            if self.host_proc and self.host_proc.poll() is None:
                self.host_proc.terminate()
                try:
                    self.host_proc.wait(timeout=2)
                except Exception:
                    subprocess.run(['taskkill', '/F', '/PID', str(self.host_proc.pid)],
                                   capture_output=True, creationflags=0x08000000)
        except Exception:
            pass
        try:
            if self.host_proc and hasattr(self.host_proc, 'cleanup'):
                self.host_proc.cleanup()      # 关闭进程句柄与隐藏桌面
        except Exception:
            pass
        try:
            self.root.destroy()
        except Exception:
            pass

    # ---------- 配置窗口 ----------
    def open_config(self, idx):
        f = FEATURES[idx]
        if not f["values"]:
            return
        # 每次重建，避免残留状态导致"关掉再开不出来"
        if self.cfg_win is not None:
            try:
                self.cfg_win.destroy()
            except Exception:
                pass
            self.cfg_win = None

        rows = f["values"]
        W = CFG_W
        # 行高自适应：小屏幕上压缩，避免窗口超出屏幕
        row_h = 48
        try:
            avail = self.root.winfo_screenheight() - 130
        except Exception:
            avail = 900
        while row_h > 32 and (CFG_TITLE_H + 112 + len(rows) * row_h + 70) > avail:
            row_h -= 4
        H = CFG_TITLE_H + 112 + len(rows) * row_h + 70

        win = tk.Toplevel(self.root)
        win.withdraw()          # 关键：先藏起来，全部画完再显示，避免白框闪一下
        win.title(f"配 置 · {f['name']}")
        win.configure(bg=C.INK)
        win.resizable(False, False)
        win.protocol("WM_DELETE_WINDOW", self.hide_config)
        try:
            ico = res_path("app.ico")
            if os.path.exists(ico):
                win.iconbitmap(ico)
        except Exception:
            pass
        self.cfg_win = win
        self.cfg_rows = []
        self.cfg_feature = idx
        self.cfg_hint = f.get("hint", "")

        cv = tk.Canvas(win, width=W, height=H, highlightthickness=0, bd=0, bg=C.INK)
        cv.pack(fill='both', expand=True)
        self._init_canvas(cv)
        bgp = _ui_bg(W, H, os.path.join(UI_DIR, f'bg_cfg2_{W}x{H}.png'), 0.42)
        bgid = None
        if bgp and os.path.exists(bgp):
            try:
                img = tk.PhotoImage(file=bgp)
                bgid = cv.create_image(0, 0, image=img, anchor='nw')
                cv._bgref = img
            except Exception:
                pass

        cv.create_text(34, 44, text="数 值 铭 刻", font=FONT_HEAD, fill=C.GOLD_HI, anchor='w')
        cv.create_text(34, 76, text="触发：" + f.get("hint", ""),
                       font=FONT_SMALL, fill=C.JADE_HI, anchor='w')
        self._diamond(cv, W - 44, 46, 5)
        cv.create_line(34, 96, W - 34, 96, fill=C.LINE_SOFT)

        y = 112
        for rid, rname in rows:
            cv.create_rectangle(22, y - 8, W - 22, y + row_h - 8, fill=C.PANEL, outline='')
            cv.create_rectangle(22, y, 25, y + 32, fill=C.GOLD_DIM, outline='')
            cv.create_text(40, y + 17, text=rname, font=FONT_SMALL, fill=C.TEXT, anchor='w')
            var = tk.StringVar()
            ent = tk.Entry(win, textvariable=var, font=FONT_NORMAL, bg='#0B1613',
                           fg=C.GOLD_HI, insertbackground=C.GOLD_HI, relief='flat', bd=0,
                           highlightthickness=1, highlightbackground=C.LINE,
                           highlightcolor=C.GOLD)
            cv.create_window(200, y, window=ent, width=210, height=32, anchor='nw')
            self._rect_button(cv, 422, y, 72, 32, "读 取",
                              (lambda r=rid: self.on_read_value(r)), f'rd{rid}', small=True)
            self.cfg_rows.append((rid, var))
            y += row_h

        by = y + 10
        self._rect_button(cv, W // 2 - 124, by, 116, 34, "全 部 写 入",
                          self.on_write_all, 'cfgwrite')
        self._rect_button(cv, W // 2 + 8, by, 116, 34, "关 闭",
                          self.hide_config, 'cfgclose')

        # 内容整体下移，给自绘标题栏腾位置
        cv.addtag_all('content')
        if bgid is not None:
            cv.dtag(bgid, 'content')
        cv.move('content', 0, CFG_TITLE_H)
        for h in cv._bwf_hits:          # 命中区跟随下移
            h['y0'] += CFG_TITLE_H
            h['y1'] += CFG_TITLE_H

        try:
            self.root.update_idletasks()
            mx = self.root.winfo_rootx()
            my = self.root.winfo_rooty()
            mw = self.root.winfo_width()
            mh = self.root.winfo_height()
            sw = self.root.winfo_screenwidth()
            sh = self.root.winfo_screenheight()
            x = mx + (mw - W) // 2
            yy = my + (mh - H) // 2
            x = max(0, min(x, sw - W))
            yy = max(0, min(yy, sh - H - 40))
            win.geometry(f"{W}x{H}+{x}+{yy}")
        except Exception:
            win.geometry(f"{W}x{H}")

        # 去掉系统标题栏，画自绘标题栏
        win.update_idletasks()
        chwnd = self._apply_borderless(win, W, H)
        self._draw_toolbar(cv, win, W, f"配 置 · {f['name']}", chwnd,
                           th=CFG_TITLE_H, on_close=self.hide_config)

        win.deiconify()
        try:
            win.update_idletasks()      # 立即完成布局+重绘 → 第一帧就带完整画面
            win.update_idletasks()
        except Exception:
            pass
        win.lift()
        win.focus_force()

    def _selftest_report(self, feature_idx):
        lines = []
        try:
            f = FEATURES[feature_idx]
            lines.append(f"feature={f['name']} values={len(f['values'])}")
            w = self.cfg_win
            lines.append("cfg_win mapped=%s geom=%s" % (
                w.winfo_ismapped() if w else None, w.winfo_geometry() if w else None))
            for i, (rid, var) in enumerate(self.cfg_rows):
                lines.append("  row[%d] rid=%s val=%r" % (i, rid, var.get()))
            lines.append("main geom=" + self.root.winfo_geometry())
            lines.append("feat_items=%d" % len(self.feat_items))
        except Exception as e:
            lines.append("SELFTEST ERROR: " + repr(e))
        out = os.path.join(TMP, "bwf_selftest.txt")
        open(out, 'w', encoding='utf-8').write("\n".join(lines))
        print("selftest written:", out)

    def hide_config(self):
        if self.cfg_win is not None and self.cfg_win.winfo_exists():
            self.cfg_win.withdraw()

    def on_read_value(self, rid):
        self.pending_gets[rid] = time.time()
        self.send_cmd(f"GET|{rid}")
        self.set_status(detail="读取中…")

    def fill_config_value(self, rid, val):
        for r, var in self.cfg_rows:
            if r == rid:
                if val.startswith('?') or val == 'READERR' or val == '':
                    var.set('')
                    self.set_status(detail='读不到：' + getattr(self, 'cfg_hint', '去游戏里对应界面操作一次'))
                else:
                    var.set(val)
                break

    def on_write_all(self):
        pairs = [(rid, var.get().strip()) for rid, var in self.cfg_rows]
        pairs = [(r, v) for r, v in pairs if v != ""]
        if not pairs:
            self.set_status(detail="没有需要写入的数值")
            return
        self.pending_sets = {r: v for r, v in pairs}
        self.verify_vals = {}
        self.write_total = len(pairs)
        self.write_ok = 0
        self.write_t0 = time.time()
        self.set_status(detail="正在写入 %d 项…" % len(pairs))
        for r, v in pairs:
            self.send_cmd("SET|%d|%s" % (r, v))


def selftest():
    app = App()
    def step1():
        app.open_config(5)
        app.root.after(1000, step2)
    def step2():
        app._selftest_report(5)
        app.on_exit()
    app.root.after(1200, step1)
    app.root.mainloop()


def uitest():
    """进程内合成事件自测：不启动 CE，直接验证点击命中"""
    os.environ['BWF_NOBOOT'] = '1'
    app = App()
    root = app.root
    res = []

    def click(x, y, canvas=None):
        c = canvas if canvas is not None else app.cv
        c.event_generate('<Motion>', x=x, y=y, warp=False)
        c.event_generate('<Button-1>', x=x, y=y, warp=False)
        root.update()

    try:
        for _ in range(8):
            root.update()
            time.sleep(0.04)

        R0 = 264                       # 第一行 y
        RH = 44                        # 行高 40 + 间距 4
        kinds = [h['kind'] for h in app.cv._bwf_hits]
        res.append(('自绘标题栏已绘制', 'drag' in kinds))

        click(300, R0 + 20)
        res.append(('行1 空白区点击 -> 勾选', app.feat_vars[0].get() is True))
        click(300, R0 + 20)
        res.append(('行1 再点 -> 取消', app.feat_vars[0].get() is False))
        click(69, R0 + 20)
        res.append(('行1 复选框区 -> 勾选', app.feat_vars[0].get() is True))
        click(130, R0 + RH + 20)
        res.append(('行2 名称区 -> 勾选', app.feat_vars[1].get() is True))
        click(300, R0 + 42)
        res.append(('行间隙不误触', app.feat_vars[2].get() is False))
        click(20, R0 + 20)
        res.append(('行左侧空白不误触', app.feat_vars[3].get() is False))

        click(627, R0 + 6 + 14)
        okcfg = app.cfg_win is not None and app.cfg_win.winfo_exists()
        res.append(('行1 配置按钮 -> 打开窗口', okcfg))
        if okcfg:
            root.update()
            cv2 = None
            for w in app.cfg_win.winfo_children():
                if isinstance(w, tk.Canvas):
                    cv2 = w
            n = len(FEATURES[0]['values'])
            by = 112 + n * 48 + 10
            click(CFG_W // 2 + 8 + 58, by + CFG_TITLE_H + 17, canvas=cv2)
            root.update()
            res.append(('配置窗口 关闭按钮', not app.cfg_win.winfo_ismapped()))
            res.append(('配置窗口 标题栏', any(k == 'drag' for k in
                                              [h['kind'] for h in cv2._bwf_hits])))

        click(300, 500)     # 空白处
        res.append(('总计命中区 >= 14', len(app.cv._bwf_hits) >= 14))

        # 标题栏按钮 / 最小化 / 拖动
        tb = [h for h in app.cv._bwf_hits if h['kind'] == 'btn' and h['y1'] <= TITLE_H]
        res.append(('标题栏按钮 = 3', len(tb) == 3))
        try:
            app.root.iconify()
            root.update()
            time.sleep(0.25)
            res.append(('最小化生效', bool(_U32.IsIconic(app.hwnd))))
            app.root.deiconify()
            root.update()
            time.sleep(0.25)
            res.append(('恢复生效', not bool(_U32.IsIconic(app.hwnd))))
        except Exception:
            res.append(('最小化/恢复', False))
        try:
            r0 = wintypes.RECT()
            _U32.GetWindowRect(app.hwnd, ctypes.byref(r0))
            Ev = type('E', (), {})
            e1 = Ev()
            e1.x_root, e1.y_root = r0.left + 100, r0.top + 20
            e2 = Ev()
            e2.x_root, e2.y_root = r0.left + 140, r0.top + 60
            app._begin_drag(app.hwnd, e1)
            app._cv_drag(app.cv, e2)
            app._cv_release(app.cv, e2)
            root.update()
            r1 = wintypes.RECT()
            _U32.GetWindowRect(app.hwnd, ctypes.byref(r1))
            res.append(('拖动位移 (%.0f,%.0f)' % (r1.left - r0.left, r1.top - r0.top),
                        (r1.left - r0.left, r1.top - r0.top) == (40, 40)))
        except Exception:
            res.append(('拖动', False))
    except Exception:
        import traceback
        res.append(('EXC', traceback.format_exc()))

    print('=== UI 自测 ===')
    bad = 0
    for name, ok in res:
        print(('  ✅ ' if ok else '  ❌ ') + str(name) + ('' if ok else '  >> ' + str(ok)))
        if not ok:
            bad += 1
    print('=== %s ===' % ('ALL PASS' if bad == 0 else '%d 项失败' % bad))
    try:
        root.destroy()
    except Exception:
        pass
    return 0 if bad == 0 else 1


def shotcfg():
    """供截图用：打开配置窗口后停留"""
    os.environ['BWF_NOBOOT'] = '1'
    app = App()
    app.root.after(600, lambda: app.open_config(5))
    app.root.after(12000, app.root.destroy)
    app.root.mainloop()


def main():
    if "--selftest" in sys.argv:
        selftest()
        return
    if "--uitest" in sys.argv:
        sys.exit(uitest())
    if "--shotcfg" in sys.argv:
        shotcfg()
        return
    try:
        _main_impl()
    except Exception as e:
        import traceback
        log_boot('FATAL ' + traceback.format_exc())
        try:
            root = tk.Tk()
            root.withdraw()
            root.attributes('-topmost', True)
            messagebox.showerror(APP_NAME, f"启动异常：{e}")
            root.destroy()
        except Exception:
            pass


def _main_impl():
    log_boot('start')
    if not single_instance():
        if activate_existing():
            log_boot('already running -> activated existing window')
        else:
            log_boot('already running -> no window found, show tip')
            root = tk.Tk()
            root.withdraw()
            root.attributes('-topmost', True)
            messagebox.showwarning(
                APP_NAME, "修改器已经在运行中。\n\n请在任务栏中查找已打开的窗口；"
                          "如果看不到，请到任务管理器结束 BWFMod 相关进程后重试。")
            root.destroy()
        return
    log_boot('single instance ok')
    app = App()
    app.root.mainloop()
    log_boot('exit')


if __name__ == '__main__':
    main()
