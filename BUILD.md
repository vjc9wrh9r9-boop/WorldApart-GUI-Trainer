# 构建指南 / BUILD

从源码构建 `不问凡尘修改器`。

## 前置条件

- Windows x64
- Python 3.10+（64 位）
- **Cheat Engine 精简运行时**（`mzhost.exe` 及配套文件）——本仓库不含，请从
  B 站 UP 主「缤纷颜色」视频简介的网盘获取，解压到 `build/runtime/`
- **作者 CT 表**（`不问凡尘-缤纷颜色-bilibili-YYYY-MM-DD更Vx.CT`）——同样从
  作者网盘获取，放到 `build/runtime/`

## 构建（三步）

```bat
pip install -r requirements.txt

:: 1. 把 runtime 和最新 CT 表放进 build/runtime/
::    （mzhost.exe + 不问凡尘-缤纷颜色-bilibili-XXXX.CT）

:: 2. 一键构建
python tools\build_all.py

:: 3. 产物
不问凡尘修改器_V2.0.exe
```

`build_all.py` 会自动完成：

1. 主表 Lua 注入（无人值守模式：隐藏 CE、去广告、命令通道）
2. 生成历史版本切换表（多版本游戏自适应用）
3. 打包 `src/res.zip`（运行时 + 表，LZMA）
4. PyInstaller 打包单文件 exe（内置管理员清单 + 图标）

## 手工分步

```bat
python tools\build_ct.py build\runtime\BWF_不问凡尘_V1.CT   :: 注入 Lua
python tools\make_tables.py                                  :: 版本切换表
python tools\pack_res.py                                     :: 打 res.zip
cd src && python -m PyInstaller --noconfirm trainer.spec && cd ..
```

## 产物说明

| 文件 | 说明 |
|---|---|
| `src/res.zip` | CE 运行时 + 修改表（LZMA），首次启动解压到 `%LOCALAPPDATA%\BWFMod\runtime` |
| `dist/BWF_Trainer.exe` | 单文件成品（20MB，UAC 管理员清单） |

## 更换修改表

游戏更新后，作者发布新表时：

```bat
python tools\swap_ct.py "新表路径.CT"
```

自动重打包并递增内部运行时版本号（老客户端会通过内置更新检查收到提示）。

## 发布到 GitHub（维护者）

```bat
python scripts\publish_github.py "本次更新说明一句话"
```

同步源码、文档、使用说明、version.json 与 Release 资产。
