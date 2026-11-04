# Rebreath Auto Repair v0.1.6

## 前置要求（请先确认）

**必需：**
1. **Skyrim Special Edition / Anniversary Edition（PC）**。本包按 Skyrim SE/AE Papyrus 格式构建；Skyrim VR 未验证。
2. **SKSE64，且版本必须与当前 Skyrim 游戏运行时版本完全匹配**。本 Mod 的热键、菜单检测和相关脚本事件使用 SKSE Papyrus 扩展；未正确安装/启动 SKSE64 时，O 键及加载检测不会正常工作。
3. 在 MO2 右侧插件列表中启用 **RebreathAutoRepair.esp**，并确认它没有被标记为缺少主文件。ESP 仅依赖 Skyrim.esm。

**不需要：**
- Address Library for SKSE Plugins（本 Mod 不包含 SKSE 原生 DLL）。
- Papyrus Ini Manipulator（本版已经移除该依赖）。
- SkyUI、MCM。
- Nemesis、FNIS 或行为文件生成器（本 Mod 不安装或修改行为文件）。

**关于 Elden Rim / MCO：** 本 Mod 本身不依赖 Elden Rim 的 ESP FormID，也不施放 Elden Rim 法术。它向玩家行为图发送四个事件；其中 `MCO_DodgeStop` 只有在当前行为图/动作框架识别该事件时才会产生对应作用。它不会替你安装或修复 MCO 行为文件。

## v0.1.6 本版功能

- 手动热键：物理键盘 **O**（DirectInput `DIK_O = 0x18 = 24`）。
- 自动触发先等待玩家 3D 加载、Loading Menu 关闭及退出菜单模式。
- 加载门槛满足后，先执行独立的 **3.0 秒读档淡入保护期**；期间再次进入加载/菜单状态会重新开始保护期。
- 保护期完成后，再累计独立的 **1.5 秒游戏内倒计时**；菜单/加载状态中断时暂停累计，恢复后继续。
- 自动修复每次读档执行一轮原版四事件：`IdleStop` → `staggerStop` → `MCO_DodgeStop` → `IdleCombatStart`。
- O 键可以取消尚未执行的自动倒计时并立即执行同一套四事件，便于分辨自动触发问题与动画事件效果问题。
- 不修改 Elden Rim 全局变量；不施放回气、嘲讽或攻击技能。

## 关于“等游戏画面显示后再计时”的技术边界

Papyrus 没有通用接口读取 GPU 实际呈现帧的像素，也不能直接保证已经显示器上真正显示了第一帧世界画面。本版使用 `Player.Is3DLoaded()`、`UI.IsMenuOpen("Loading Menu") == false`、`Utility.IsInMenuMode() == false` 作为游戏逻辑层就绪条件，并额外留出 3 秒淡入保护，再开始 1.5 秒倒计时。这比从 `OnPlayerLoadGame` 到达时立即计时稳妥，但不是逐像素可见性检测；若其他加载/UI Mod 将黑屏延长超过 3 秒，需要根据实际情况调整源码中的 `_postLoadFadeGrace`。

## 安装（MO2）

1. 禁用并移除之前的 Rebreath Auto Repair v0.1.2、v0.1.3、v0.1.5，以及此前单独安装的延时补丁/源码测试包，避免旧 PEX 或旧 ESP 覆盖新版。
2. 在 MO2 左侧安装本 ZIP，启用 **Rebreath Auto Repair v0.1.6**。
3. 在 MO2 右侧插件列表启用 `RebreathAutoRepair.esp`。
4. 使用 SKSE64 启动游戏。建议先备份存档或用副本测试。
5. 读档等待世界画面稳定；自动流程会在加载就绪门槛和 3 秒保护期之后再额外等待 1.5 秒。
6. 手动验证时，在世界画面正常显示后按 **O**。屏幕提示“四个原版事件已发送”代表 Papyrus 已调用四次发送函数，不等于行为图一定接受事件或人物一定恢复。

## 日志（可选，用于排错）

若需要检查 Papyrus Trace，可在实际生效的 Skyrim.ini 中启用：

```ini
[Papyrus]
bEnableLogging=1
bEnableTrace=1
```

通常日志位于：
`Documents\\My Games\\Skyrim Special Edition\\Logs\\Script\\Papyrus.0.log`

MO2 使用配置文件专属 INI 时，请修改当前 Profile 对应的 Skyrim.ini。日志选项只是排错辅助，不是运行前置。

## 构建与验证

本包由 GitHub Actions 在 Windows runner 上使用固定版本 SKSE Papyrus headers 和 Papyrus Compiler 编译。构建时还会验证：
- ESP 文件头为 `TES4`，Quest FormID 为 `0x01000800`；
- Quest 的 Start Game Enabled 标志已设置；
- `.esp.seq` 内容为小端 FormID `00 08 00 01`；
- PEX 可被编译器读回，且包含 O 键事件及四个动画事件名称。

构建工作流：`.github/workflows/build-papyrus-pex.yml`。
