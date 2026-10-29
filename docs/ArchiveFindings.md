# Elden Rim archive findings (compiled-script inspection)

The uploaded archive includes compiled Papyrus scripts (`.pex`) and plugins (`.esp`); it is not a texture-only archive.

## Confirmed chain in the uploaded files

1. `0-Elden Rim-Base 3.7.5/EldenSkyrim.esp`
   - Spell record: `EldenSkill` / `Elden Weapon Art - Rebreath` (local form ID shown by the plugin parser as `0500080A`).
   - One of its Magic Effects is `ES_SkillAttack` / `Weapon Art - Action Execution` (`05000800`).
   - That Magic Effect has the Papyrus script `AbilityTauntEffect` attached.
2. `0-Elden Rim-Base 3.7.5/scripts/AbilityTauntEffect.pex`
   - Its compiled string table contains `OnEffectStart`, `PlayIdle`, and `Taunt` (the idle property). This is the direct taunt/idle-playing script path; playing the actual idle would violate the requested no-visible-animation behavior, so this plugin does not call it.
3. `1-Elden Rim-Weapon Art 3.2.7/EldenSkyrim_RimSkills.esp`
   - Magic Effect `EldenRebreatheAttack` / `Art - Rebreath Retaliate move` (`0600B694`) has `EldenRebreatheAttacks` attached.
4. `1-Elden Rim-Weapon Art 3.2.7/scripts/EldenRebreatheAttacks.pex`
   - Its compiled string table contains `OnEffectStart`, `SendAnimationEvent`, `staggerStop`, `IdleStop`, `MCO_DodgeStop`, `IdleCombatStart`, `WarAttackIdle01`, and `EldenRebreathe`. The `IdleName*` fields appear to include `idle`-typed properties, so names such as `MCO_DodgeStop`, `IdleCombatStart`, and `WarAttackIdle01` should not be blindly treated as graph-event strings.
   - This plugin uses only the minimal stop/reset events `staggerStop` and `IdleStop`. It intentionally does not call `PlayIdle(Taunt)`, `EldenRebreathe`, `WarAttackIdle01`, `MCO_DodgeStop`, or `IdleCombatStart`.

## Important limits

The archive contains compiled `.pex` files rather than their original `.psc` source. The above is based on plugin record links plus the PEX string tables, not a fully source-level decompilation of every Papyrus instruction. The native plugin implements the conservative, animation-graph reset subset; it does not recreate stamina recovery, cooldown effects, perks, spells, or other gameplay mechanics from Elden Rim.
