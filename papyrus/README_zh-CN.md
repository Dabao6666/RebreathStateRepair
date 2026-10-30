# Rebreath Auto Repair v0.1.0

独立 Papyrus 自动状态重置 Mod，不覆盖 Elden Rim 文件，不调用 PlayIdle，不施放回气技能，不播放 Taunt 或原动作。

## 运行依赖
- Skyrim SE/AE 对应版本 SKSE
- Papyrus Ini Manipulator（提供 `iniman` 原生 INI 读取函数；其 `iniman.pex` 和 SKSE DLL 由独立依赖 Mod 提供，不在本压缩包内）

## 安装
将压缩包内 Data 文件夹内容作为 MO2 独立 Mod 安装，并在右侧启用 RebreathAutoRepair.esp。
本 Mod 仅新增一个 Quest、一个强制填充 PlayerRef 的 Reference Alias 和一个脚本，不覆盖 Elden Rim 的记录。
Papyrus Ini Manipulator 需要独立安装。

## 配置
编辑 Data/SKSE/Plugins/RebreathAutoRepair.ini：
- DelayAfter3D：玩家 3D 就绪后的额外等待时间。
- MaxWaitFor3D / PollInterval：等待 3D 加载的上限和轮询间隔。
- RepairAttempts / RetryInterval：重试次数和间隔。
- IdleStop / StaggerStop：默认开启的两个状态重置事件。
- MCODodgeStop / IdleCombatStart：默认关闭，必要时再逐个测试。

## 日志
启用 Skyrim.ini 的 [Papyrus] bEnableLogging=1、bEnableTrace=1 后，查看 Papyrus.0.log。
