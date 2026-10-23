# 不问凡尘 · 护肝修改器 GUI 版 / WorldApart GUI Trainer

[![Version](https://img.shields.io/badge/version-2.0-green)]() [![Game](https://img.shields.io/badge/game-%E4%B8%8D%E9%97%AE%E5%87%A1%E5%B0%98-orange)]() [![Platform](https://img.shields.io/badge/platform-Windows%20x64-blue)]()

**中文** | [English](#english)

把《不问凡尘》（WorldApart）的 Cheat Engine 修改流程，封装成一个**双击即用**的中文图形界面。
CE 全程后台运行，无弹窗、无闪屏、不写注册表。

> 功能数据来自 B 站 UP 主「缤纷颜色」的公开 CT 表，本工具只是界面封装与自动化整合。
> **使用前请去 B 站支持原作者**：[缤纷颜色的空间](https://space.bilibili.com/365816484)

---

## 特性 / Features

- **11 项功能全图形化**：人物属性 / 修为 / 灵石 / 物品数量 / NPC 友好度 / 人物属性 / 炼器 / 炼丹 / 炼丹危险度 / 声望 / 探索技能
- **免安装 CE**：内置精简版 Cheat Engine，隐藏后台运行
- **多版本游戏自适应**：启动时扫描游戏内存特征码，自动加载对应版本的修改表（支持 09-29 / 10-01 / 10-17 / 10-23 四代表）
- **昼夜双主题**：黑水墨 / 白水墨一键切换
- **写入回执**：写入后自动回读确认，告诉你"成功"还是"没生效"
- **自检系统**：读不到数据时，5 秒定位是"没连上 / 没触发 / 版本不匹配"
- **全局快捷键**：`Ctrl+1` 物品→99、`Ctrl+2` 友好度→499，全屏可用
- **异常自愈**：异常退出残留的游戏代码补丁，下次启动自动还原
- **检查更新**：启动时自动检查 GitHub 上的新版本

## 下载 / Download

前往 [Releases](https://github.com/vjc9wrh9r9-boop/WorldApart-GUI-Trainer/releases/latest) 下载 `不问凡尘修改器_V2.0.exe`。

## 使用说明 / Manual

完整图文说明见仓库内 [`使用说明.txt`](./使用说明.txt)（随发行包附带）。

## 使用 / Usage

1. 先开游戏，再双击修改器（管理员权限）
2. 状态变绿 = 已附加游戏
3. 勾选功能 → 回游戏打开对应界面 → 点"配 置" → "读 取" → 改数字 → "全 部 写 入"
4. 状态栏会显示写入结果

详细说明见 `使用说明.txt`（随压缩包附带）。

## 原理 / How it works

- 内置精简版 Cheat Engine（mzhost），通过 Lua 定时器与 GUI 以**临时文件**通信（`%TEMP%\bwf_cmd.txt` / `bwf_status.txt`），全程无网络
- 修改表用 Auto Assembler 脚本 hook 游戏函数，把运行时对象地址写入符号，GUI 按 ID 读写
- 启动时扫描 `GameAssembly.dll` 的 AOB 特征码判断游戏版本，自动 `loadTable` 切换对应表
- 退出前执行所有脚本的 `[DISABLE]` 段还原游戏代码；启动时自检并修复异常退出留下的残留补丁

## 版本适配表 / Compatibility

| 修改表 | 对应游戏版本 | 功能数 |
|---|---|---|
| 10-23 表（内置） | Steam 最新版 | 11 项 |
| 10-17 表（内置，自动切换） | 10-13 更新后的版本 | 10 项 |
| 10-01 表（内置，自动切换） | 10-01 更新后的版本 | 8 项 |
| 09-29 表（内置，自动切换） | 最早版本 | 1 项 |

## 目录结构 / Repository layout

```
src/main.py          GUI 主程序（tkinter，无第三方 UI 依赖）
tools/build_ct.py    CT 表后处理：去广告 + 注入无人值守 Lua
tools/swap_ct.py     一键换表重打包（作者出新表后 1 分钟适配）
tools/make_tables.py 从作者历史表生成版本切换表
tools/detect_aob.py  特征码有效性检测（诊断工具）
version.json         自动更新元数据
```

> **本仓库不含** Cheat Engine 运行时与修改表数据，请从原作者网盘获取。

## English

A GUI wrapper that turns the Cheat-Engine-based trainer workflow for **WorldApart (不问凡尘)** into a one-click Chinese desktop app. Bundles a slimmed-down CE runtime that runs hidden, auto-detects the installed game version by scanning AOB signatures in `GameAssembly.dll`, and loads the matching cheat table. Features write-verification, a built-in self-diagnostic, global hotkeys (Ctrl+1 item x99, Ctrl+2 affinity 499), day/night ink-wash themes, and an update checker. Trainer data comes from the public CT tables by Bilibili creator **缤纷颜色** — please support the original author. For personal study only; do not use commercially.

## 致谢 / Credits

- [缤纷颜色](https://space.bilibili.com/365816484) —— CT 表与功能设计
- [Cheat Engine](https://www.cheatengine.org/) —— Dark Byte 及社区
- [tkinter](https://wiki.python.org/moin/TkInter)、[Pillow](https://python-pillow.org/)

## 许可 / License

见 [LICENSE](LICENSE)。仅供个人学习研究，禁止商用与转售。

---

**免责声明**：本工具与任何官方渠道无关。使用产生的后果（包括账号封禁）由使用者自行承担。
