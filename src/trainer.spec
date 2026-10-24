# -*- mode: python ; coding: utf-8 -*-

EXCLUDES = [
    'ssl', '_ssl',                    # 不联网
    'linux',                          # 无用平台模块
    'tkinter.test', 'test',
    'unittest', 'doctest', 'pydoc',
    'distutils', 'setuptools', 'pkg_resources', 'pip',
    'email', 'http', 'xmlrpc', 'urllib.request', 'urllib.error',
    'xml', 'xml.etree', 'xml.dom', 'xml.sax',
    'sqlite3', 'multiprocessing', 'asyncio', 'concurrent',
    'decimal', '_decimal',
    'bz2', '_bz2',
    'curses', 'readline',
    'numpy', 'pandas', 'scipy', 'matplotlib',
]


a = Analysis(
    ['main.py'],
    pathex=[],
    binaries=[],
    datas=[('res.zip', '.'), ('app.ico', '.')],
    hiddenimports=['PIL.Image', 'PIL.ImageDraw', 'PIL.ImageFilter', 'PIL.ImageChops', 'lzma', 'zipfile'],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=EXCLUDES,
    noarchive=False,
    optimize=0,
)

# PIL 的二进制插件只保留 _imaging（AVIF/WebP/字体/色彩管理 全用不到，约 6.6MB）
_DROP = ('_avif', '_webp', '_imagingft', '_imagingcms', '_imagingtk')
a.binaries = [b for b in a.binaries
              if not any(k in str(b[0]).lower() for k in _DROP)]

pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='BWF_Trainer',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    uac_admin=True,
    icon=['app.ico'],
)
