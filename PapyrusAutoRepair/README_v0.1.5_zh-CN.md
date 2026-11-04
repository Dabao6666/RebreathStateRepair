# Rebreath Auto Repair v0.1.5

- 手动热键改为物理键盘 O（DirectInput DIK_O = 0x18 = 24）。
- 自动触发先等待玩家 3D 加载、Loading Menu 关闭及非菜单模式。
- 加载门槛通过后，先等待独立的 3.0 秒淡入保护期；期间如再次进入加载/菜单状态，保护期重置。
- 淡入保护期完成后，再累计独立的 1.5 秒游戏时间倒计时；菜单/加载中断会暂停计时。
- O 键发送原版顺序的四个动画事件：IdleStop、staggerStop、MCO_DodgeStop、IdleCombatStart。
- O 热键会取消仍在等待的自动触发，并立即执行手动测试；屏幕提示和 Papyrus Trace 用来区分脚本未运行与事件无效。
- 不修改 Elden Rim 全局变量、不施放回气或嘲讽技能、不依赖 Papyrus Ini Manipulator。

## 可见画面的限制

Papyrus 没有直接检查 GPU 实际显示帧像素的通用接口。本版使用 Player.Is3DLoaded()、UI.IsMenuOpen("Loading Menu") 和 Utility.IsInMenuMode() 作为加载完成门槛，并额外等待 3 秒淡入保护。这是比单纯 OnPlayerLoadGame 更稳妥的逻辑层近似，但不是逐像素的显示确认。若其他 UI/加载 Mod 将黑屏延长超过 3 秒，仍需要根据日志增加 `_postLoadFadeGrace`。

## GitHub Actions

`.github/workflows/build-papyrus-pex.yml` 会在推送 PapyrusAutoRepair 文件后启动 Windows 编译任务，使用固定版本 SKSE Papyrus headers 与 Papyrus Compiler，生成 PEX 并组装 MO2 ZIP artifact。
