# Rebreath Auto Repair v0.2.0（SCSI 状态清理版）

## 适用环境

- Skyrim Special Edition **1.5.97**。
- SKSE64 **2.0.20**，并通过 SKSE 启动游戏。
- MO2 安装并启用本补丁的 ESP。
- 本版针对用户提供的 **SCSI-泰姆瑞尔的魔法 9.90** 脚本状态，并保留 Elden Rim Rebreath 的原始动画事件复位序列。

本补丁不把 SCSI 或 Elden Rim 的 ESP 设为主文件，因此不会因为插件 FormID 或加载顺序变化而绑定特定记录；但要发挥 SCSI 清理作用，游戏中需要实际安装对应的 SCSI 模组。

## 对 SCSI 9.90 的静态检查结果

检查了压缩包内的 ESP 和 17 个 PEX 脚本，发现两处会影响玩家动画状态的逻辑：

1. `SCSI_MagicBlockingScript`：`OnEffectStart` 将施法者的动画变量 `IsBlocking` 设为 True，只有 `OnEffectFinish` 才设为 False。若读档时出现状态未正确收尾，可能留下格挡状态变量。
2. `SCSI_AddBleedoutFX_Target`：在特定受击/濒死场景发送 `bleedOutStart`，并在更新或效果结束时发送 `bleedOutStop`。

另外，变形术 `SCSI_ActorRaceChangeFX_Target` 会暂时更改目标种族，并在 `OnEffectFinish` 中恢复原种族、移除临时装备及结束 Deferred Kill。它不是普通的动画变量复位逻辑；本补丁不会强制改回种族，以免破坏合法变身状态。

压缩包中两个隐身效果记录引用了 `SCSI_DispelSpellSelfOnEffectStart_timeX`，但这个同名 PEX 不在本次上传的 Scripts 文件夹里。它可能由其他安装包提供；如果 Papyrus 日志出现该脚本类缺失报错，应单独修复原模组文件。这不是本补丁擅自替换原脚本的理由。

## v0.2.0 读档处理

等待玩家 3D 加载、Loading Menu 关闭并退出菜单模式；额外经过 3 秒读档淡入保护，再累计 1.5 秒游戏内时间。然后：

1. 如果玩家 Health 大于 0，清除 SCSI 使用的动画变量 `IsBlocking=False`。
2. 玩家存活时发送 SCSI 使用的 `bleedOutStop`，用于结束可能遗留的 bleedout 动画状态。
3. 按 Elden Rim `EldenRebreatheAttacks.pex` 的原始 Papyrus 调用路径和顺序发送四个事件：
   `IdleStop` → `staggerStop` → `MCO_DodgeStop` → `IdleCombatStart`。
4. 不施放 Elden Rim 回气法术；不播放 Taunt；不调用 PlayIdle；不改动 Elden Rim 全局变量。
5. 不主动 Dispel 玩家法术；不更改种族、装备、perk、属性值或存档数据。

手动测试热键仍为物理键盘 **O**（DIK_O，扫描码 24）。按 O 会立即执行同一套清理和事件调用。

## 安装

1. 在 MO2 左侧禁用旧版 Rebreath Auto Repair v0.1.2、v0.1.3、v0.1.5、v0.1.6 以及单独延时补丁，避免旧文件覆盖。
2. 安装本版 ZIP，启用左侧 Mod。
3. 在 MO2 右侧启用 `RebreathAutoRepair.esp`。
4. 确认没有重复的同名 ESP/PEX 被其他 Mod 覆盖。
5. 用备份存档或存档副本测试。第一次读档先观察自动清理；不成功再按 O 做手动测试。

## 日志

如需排查 Papyrus 日志，在当前生效的 Skyrim.ini 中启用：

```ini
[Papyrus]
bEnableLogging=1
bEnableTrace=1
```

日志一般位于：

```
Documents\My Games\Skyrim Special Edition\Logs\Script\Papyrus.0.log
```

MO2 使用专属 INI 时，应修改当前 Profile 的 Skyrim.ini。

## 安全边界及验证说明

- 清理 `IsBlocking` 的依据是 SCSI 脚本在效果开始/结束时对该变量的成对写入。清理发生在读档后；正常进入游戏后重新使用结界术，SCSI 脚本仍可再次将它设为 True。
- `bleedOutStop` 仅在玩家 Health 大于 0 时发送。
- Papyrus 没有读取 GPU 实际显示帧的接口；3D、菜单状态与 3 秒保护期只是加载完成的逻辑判断。
- GitHub Actions 编译与 PEX 回读通过，只代表脚本可编译、文件结构检查通过；是否能修复用户当前整合包中的问题，仍须在 Skyrim SE 1.5.97 实际读档验证。
