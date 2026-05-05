import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/state/game_state.dart';
import '../game/state/mech_catalog.dart';
import '../game/state/meta_catalog.dart';
import '../game/state/meta_state.dart';
import '../game/state/skill_catalog.dart';
import 'meta_screen.dart';

Future<bool> showDevKeyDialog(BuildContext context, GameState state) async {
  final controller = TextEditingController();
  final success = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          String? error;
          return AlertDialog(
            backgroundColor: const Color(0xFF111827),
            title: const Text(
              'Enter Access Key',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Key',
                    hintStyle: const TextStyle(color: Colors.white38),
                    errorText: error,
                    errorStyle: const TextStyle(color: Color(0xFFFF5252)),
                  ),
                  onSubmitted: (val) {
                    if (state.unlockDevMode(val)) {
                      Navigator.of(dialogContext).pop(true);
                    } else {
                      setState(() => error = 'Invalid Key');
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (state.unlockDevMode(controller.text)) {
                    Navigator.of(dialogContext).pop(true);
                  } else {
                    setState(() => error = 'Invalid Key');
                  }
                },
                child: const Text('Unlock'),
              ),
            ],
          );
        },
      );
    },
  );
  return success ?? false;
}

class Hud extends StatelessWidget {
  const Hud({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: const [
          Positioned(left: 16, right: 16, bottom: 16, child: _NexusHealthBar()),
          Positioned(left: 0, right: 0, top: 80, child: _IdleRewardToast()),
          Positioned.fill(child: _LevelUpPicker()),
          Positioned.fill(child: _RunOverPanel()),
          Positioned(top: 12, left: 16, child: _FloorBadge()),
          Positioned(top: 12, right: 16, child: _GoldBadge()),
          Positioned(top: 80, right: 16, child: _MuteButton()),
          Positioned(top: 92, left: 16, child: _ArsenalPanel()),
          Positioned(right: 16, bottom: 16, child: _DevTools()),
        ],
      ),
    );
  }
}

class _ArsenalPanel extends StatelessWidget {
  const _ArsenalPanel();

  void _showArsenalMenu(BuildContext context, GameState state, MetaState meta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (menuContext) {
        return Consumer2<GameState, MetaState>(
          builder: (context, state, meta, _) {
            final possessedSkills = state.skillLevels.entries.map((entry) {
              final def = skillCatalog.firstWhere((d) => d.id == entry.key);
              return (def: def, level: entry.value);
            }).toList();

            final byArchetype = <SkillArchetype, List<_PossessedSkill>>{};
            for (final item in possessedSkills) {
              byArchetype.putIfAbsent(item.def.archetype, () => []).add(item);
            }

            final activeKeystones = keystoneCatalog
                .where((k) => meta.hasKeystone(k.id))
                .map((k) => (def: k, archetype: k.archetype))
                .toList();

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.grid_view_rounded,
                            color: Color(0xFF64FFDA),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Arsenal',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(menuContext),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white10),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          if (state.devMode) ...[
                            const _MenuHeader('PERFORMANCE'),
                            _MenuItem(
                              icon: Icons.speed,
                              color: const Color(0xFF64FFDA),
                              label:
                                  'DPS: ${state.estimatedDps.toStringAsFixed(1)}',
                              description:
                                  'Enemy HP: ${state.enemyMaxHp.toStringAsFixed(1)} · TTK: ${state.estimatedTimeToKill.isFinite ? state.estimatedTimeToKill.toStringAsFixed(2) : 'n/a'}s',
                              onTap: () {},
                            ),
                            _MenuItem(
                              icon: Icons.monetization_on,
                              color: const Color(0xFFFFC107),
                              label: 'Gold/Kill: ${state.goldPerKill}',
                              description:
                                  'Est. Gold/Sec: ${state.estimatedGoldPerSecond.toStringAsFixed(2)}',
                              onTap: () {},
                            ),
                          ],
                          const _MenuHeader('DUNGEON STATISTICS'),
                          _MenuItem(
                            icon: Icons.dangerous_rounded,
                            color: const Color(0xFFFF5252),
                            label: 'Total Kills: ${state.lifetimeKills}',
                            description: 'Lifetime enemies breached across all runs.',
                            onTap: () {},
                          ),

                          _MenuItem(
                            icon: Icons.trending_up,
                            color: const Color(0xFF64FFDA),
                            label:
                                'Difficulty: ${(1 + (state.floor - 1) * 0.15).toStringAsFixed(2)}x',
                            description:
                                'Current floor health and damage multiplier.',
                            onTap: () {},
                          ),
                          const _MenuHeader('MECH FRAME'),
                          _MenuItem(
                            icon: Icons.smart_toy_rounded,
                            color: const Color(0xFF64FFDA),
                            label: mechDefinitionFor(state.selectedMech).title,
                            description: mechDefinitionFor(
                              state.selectedMech,
                            ).description,
                            onTap: () {},
                          ),
                          if (activeKeystones.isNotEmpty) ...[
                            const _MenuHeader('ACTIVE KEYSTONES'),
                            for (final k in activeKeystones)
                              _MenuItem(
                                icon: k.archetype.icon,
                                color: k.archetype.color,
                                label: k.def.title,
                                description: k.def.description,
                                onTap: () {},
                              ),
                          ],
                          if (metaUpgradeCatalog.any(
                            (def) => meta.upgradeTier(def.id) > 0,
                          )) ...[
                            const _MenuHeader('PERMANENT BOONS'),
                            for (final def in metaUpgradeCatalog.where(
                              (def) => meta.upgradeTier(def.id) > 0,
                            ))
                              _MenuItem(
                                icon: _boonIcon(def.id),
                                color: Colors.white,
                                label: def.maxTier > 1
                                    ? '${def.title} (Lv ${meta.upgradeTier(def.id)})'
                                    : def.title,
                                description: def.description,
                                onTap: () {},
                              ),
                          ],
                          const _MenuHeader('ACTIVE SKILLS'),
                          if (byArchetype.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              child: Text(
                                'No skills acquired yet.',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          else
                            for (final entry in byArchetype.entries)
                              for (final s in entry.value)
                                _MenuItem(
                                  icon: entry.key.icon,
                                  color: entry.key.color,
                                  label: '${s.def.title} (Lv ${s.level})',
                                  description: s.def.descriptionForLevel(
                                    s.level,
                                  ),
                                  onTap: () {},
                                ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<GameState, MetaState>(
      builder: (context, state, meta, _) {
        final possessedSkills = state.skillLevels.entries.map((entry) {
          final def = skillCatalog.firstWhere((d) => d.id == entry.key);
          return (def: def, level: entry.value);
        }).toList();

        final byArchetype = <SkillArchetype, List<_PossessedSkill>>{};
        for (final item in possessedSkills) {
          byArchetype.putIfAbsent(item.def.archetype, () => []).add(item);
        }

        final activeKeystones = keystoneCatalog
            .where((k) => meta.hasKeystone(k.id))
            .map((k) => (def: k, archetype: k.archetype))
            .toList();

        return _Panel(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: InkWell(
              onTap: () => _showArsenalMenu(context, state, meta),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(
                      Icons.grid_view_rounded,
                      color: Color(0xFF64FFDA),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Arsenal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (byArchetype.isNotEmpty || activeKeystones.isNotEmpty)
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Show icons of possessed archetypes
                              for (final archetype in byArchetype.keys.take(5))
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Icon(
                                    archetype.icon,
                                    color: archetype.color.withValues(
                                      alpha: 0.8,
                                    ),
                                    size: 12,
                                  ),
                                ),
                              // Add icons of keystones for archetypes not already listed
                              if (byArchetype.keys.length < 5)
                                for (final k
                                    in activeKeystones
                                        .where(
                                          (k) => !byArchetype.containsKey(
                                            k.archetype,
                                          ),
                                        )
                                        .take(5 - byArchetype.keys.length))
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Icon(
                                      k.archetype.icon,
                                      color: k.archetype.color.withValues(
                                        alpha: 0.4,
                                      ),
                                      size: 12,
                                    ),
                                  ),
                              if (byArchetype.keys.length +
                                      activeKeystones
                                          .where(
                                            (k) => !byArchetype.containsKey(
                                              k.archetype,
                                            ),
                                          )
                                          .length >
                                  5)
                                const Text(
                                  '...',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.open_in_new_rounded,
                      color: Colors.white.withValues(alpha: 0.4),
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

typedef _PossessedSkill = ({SkillDefinition def, int level});

IconData _boonIcon(String id) {
  return switch (id) {
    'wider_pick' => Icons.view_column_rounded,
    'reroll' => Icons.refresh_rounded,
    'banish' => Icons.block_rounded,
    'lock' => Icons.lock_rounded,
    'rare_cadence' => Icons.auto_awesome_rounded,
    'pre_pick' => Icons.ads_click_rounded,
    _ => Icons.stars_rounded,
  };
}

class _FloorBadge extends StatefulWidget {
  const _FloorBadge();

  @override
  State<_FloorBadge> createState() => _FloorBadgeState();
}

class _FloorBadgeState extends State<_FloorBadge> {
  int _tapCount = 0;
  DateTime? _lastTap;

  void _handleTap(GameState state) {
    final now = DateTime.now();
    if (_lastTap != null && now.difference(_lastTap!).inMilliseconds > 1000) {
      _tapCount = 0;
    }
    _tapCount++;
    _lastTap = now;

    if (_tapCount >= 5) {
      _tapCount = 0;
      showDevKeyDialog(context, state).then((success) {
        if (success && mounted) _showToggleFeedback(context, state.devMode);
      });
    }
  }

  void _showToggleFeedback(BuildContext context, bool enabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: enabled
            ? const Color(0xFF64FFDA)
            : const Color(0xFFFF5252),
        content: Text(
          enabled ? 'Developer Mode: ENABLED' : 'Developer Mode: DISABLED',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<GameState>();
    return Selector<GameState, ({int floor, int kills})>(
      selector: (_, state) => (floor: state.floor, kills: state.killsOnFloor),
      builder: (_, data, _) => InkWell(
        onTap: () => _handleTap(state),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Floor ${data.floor}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 140,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: data.kills / GameState.killsPerFloor,
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFFFFC107),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${data.kills}/${GameState.killsPerFloor} kills',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Selector<GameState, double>(
              selector: (_, state) => state.devTimeScale,
              builder: (context, timeScale, _) {
                if (timeScale == 1.0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _Panel(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.speed,
                          color: Color(0xFF64FFDA),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${timeScale.round()}x',
                          style: const TextStyle(
                            color: Color(0xFF64FFDA),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GoldBadge extends StatelessWidget {
  const _GoldBadge();

  @override
  Widget build(BuildContext context) {
    return Selector<GameState, int>(
      selector: (_, state) => state.gold,
      builder: (_, gold, _) => _Panel(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.attach_money, color: Color(0xFFFFC107), size: 18),
            Text(
              '$gold',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MuteButton extends StatelessWidget {
  const _MuteButton();

  @override
  Widget build(BuildContext context) {
    return Selector<GameState, bool>(
      selector: (_, state) => state.muted,
      builder: (_, muted, _) => _Panel(
        child: InkWell(
          onTap: () => context.read<GameState>().toggleMuted(),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  muted ? Icons.volume_off : Icons.volume_up,
                  color: muted ? Colors.white54 : const Color(0xFF64FFDA),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  muted ? 'MUTED' : 'SOUND ON',
                  style: TextStyle(
                    color: muted ? Colors.white54 : const Color(0xFF64FFDA),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DevTools extends StatefulWidget {
  const _DevTools();

  @override
  State<_DevTools> createState() => _DevToolsState();
}

class _DevToolsState extends State<_DevTools> {
  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (menuContext) {
        return Consumer2<GameState, MetaState>(
          builder: (context, state, meta, _) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.tune_rounded,
                            color: Color(0xFF64FFDA),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Developer Mode',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(menuContext),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white10),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          _MenuHeader('CURRENCY & PROGRESS'),
                          _MenuItem(
                            icon: Icons.add_circle,
                            color: const Color(0xFF64FFDA),
                            label: 'Add Skill',
                            description:
                                'Choose and instantly level up any skill.',
                            onTap: () {
                              Navigator.pop(menuContext);
                              _pickSkill(context);
                            },
                          ),
                          _MenuItem(
                            icon: Icons.local_fire_department,
                            color: const Color(0xFFFF8A00),
                            label: 'Add Embers',
                            description: 'Grant 100 meta-currency embers.',
                            onTap: () => meta.devGrantEmbers(100),
                          ),
                          _MenuItem(
                            icon: Icons.attach_money,
                            color: const Color(0xFFFFC107),
                            label: 'Add Gold',
                            description: 'Grant 1000 in-run gold.',
                            onTap: () => state.devGrantGold(1000),
                          ),
                          _MenuItem(
                            icon: Icons.auto_awesome,
                            color: const Color(0xFF64FFDA),
                            label: 'Max All Skills',
                            description:
                                'Instantly max out every in-run skill.',
                            onTap: () => state.devMaxAllSkills(),
                          ),
                          _MenuItem(
                            icon: Icons.star,
                            color: const Color(0xFFFFD166),
                            label: 'Max Meta',
                            description:
                                'Instantly unlock and max all meta-upgrades.',
                            onTap: () => meta.devMaxAll(),
                          ),
                          _MenuHeader('FLOOR & COMBAT'),
                          _MenuItem(
                            icon: Icons.keyboard_double_arrow_up,
                            color: const Color(0xFF64FFDA),
                            label: 'Jump Floor Forward',
                            description: 'Advance to the next floor.',
                            onTap: () => state.devJumpFloor(1),
                          ),
                          _MenuItem(
                            icon: Icons.keyboard_double_arrow_down,
                            color: const Color(0xFFFFC107),
                            label: 'Jump Floor Backward',
                            description: 'Go back one floor.',
                            onTap: () => state.devJumpFloor(-1),
                          ),
                          _MenuItem(
                            icon: Icons.keyboard_double_arrow_right,
                            color: const Color(0xFF64FFDA),
                            label: 'Force Level Up',
                            description:
                                'Trigger the upgrade selection screen.',
                            onTap: () => state.devForceLevelUp(),
                          ),
                          _MenuItem(
                            icon: Icons.delete_sweep,
                            color: const Color(0xFFFF5252),
                            label: 'Kill All',
                            description:
                                'Wipe all enemies and collect rewards.',
                            onTap: () => state.requestDevKillAll(),
                          ),
                          _MenuHeader('ENGINE & UTILITIES'),
                          _MenuItem(
                            icon: state.devPauseSpawning
                                ? Icons.play_arrow
                                : Icons.pause,
                            color: const Color(0xFF64FFDA),
                            label: state.devPauseSpawning
                                ? 'Resume Spawning'
                                : 'Pause Spawning',
                            description: 'Toggle enemy generation.',
                            onTap: () => state.toggleDevPauseSpawning(),
                          ),
                          _MenuItem(
                            icon: Icons.healing,
                            color: const Color(0xFFFF5252),
                            label: 'Heal Nexus',
                            description: 'Instantly restore health to 100%.',
                            onTap: () => state.devHealNexus(),
                          ),
                          _MenuItem(
                            icon: state.devTimeScale > 1.0
                                ? Icons.speed
                                : Icons.shutter_speed,
                            color: const Color(0xFF64FFDA),
                            label:
                                'Game Speed (${state.devTimeScale.round()}x)',
                            description:
                                'Cycle between 1x, 2x, and 5x simulation speed.',
                            onTap: () => state.cycleGameSpeed(),
                          ),
                          _MenuItem(
                            icon: state.showPerfOverlay
                                ? Icons.bar_chart
                                : Icons.bar_chart_outlined,
                            color: const Color(0xFF64FFDA),
                            label: 'Performance Overlay',
                            description:
                                'Toggle FPS and component stats display.',
                            onTap: () => state.togglePerfOverlay(),
                          ),
                          _MenuItem(
                            icon: state.godMode
                                ? Icons.shield
                                : Icons.shield_outlined,
                            color: const Color(0xFF64FFDA),
                            label: 'God Mode',
                            description: 'Prevent all damage to the Nexus.',
                            onTap: () => state.toggleGodMode(),
                          ),
                          _MenuItem(
                            icon: state.devDisableUpgrades
                                ? Icons.upgrade
                                : Icons.upgrade_outlined,
                            color: state.devDisableUpgrades
                                ? const Color(0xFFFF5252)
                                : const Color(0xFF64FFDA),
                            label: 'Disable Upgrades',
                            description:
                                'Stop level-up prompts from interrupting.',
                            onTap: () => state.toggleDevDisableUpgrades(),
                          ),
                          _MenuItem(
                            icon: Icons.toggle_on,
                            color: const Color(0xFF64FFDA),
                            label: 'Disable Dev Mode',
                            description:
                                'Hide this menu and the metrics panel.',
                            onTap: () {
                              Navigator.pop(menuContext);
                              state.toggleDevMode();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  duration: Duration(seconds: 2),
                                  backgroundColor: Color(0xFFFF5252),
                                  content: Text(
                                    'Developer Mode: DISABLED',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          _MenuHeader('DANGER ZONE'),
                          _MenuItem(
                            icon: Icons.restart_alt,
                            color: const Color(0xFFFF5252),
                            label: 'Reset Progress',
                            description:
                                'Clear current run (Gold, Floor, Upgrades).',
                            onTap: () {
                              Navigator.pop(menuContext);
                              _confirmReset(context);
                            },
                          ),
                          _MenuItem(
                            icon: Icons.delete_forever,
                            color: const Color(0xFFFF5252),
                            label: 'Wipe All Progress',
                            description: 'Total factory reset of ALL progress.',
                            onTap: () {
                              Navigator.pop(menuContext);
                              _confirmFullWipe(context);
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<GameState, bool>(
      selector: (_, state) => state.devMode,
      builder: (context, devMode, _) {
        if (!devMode) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8, right: 8),
          child: FloatingActionButton(
            mini: true,
            backgroundColor: const Color(0xFF111827),
            foregroundColor: const Color(0xFF64FFDA),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF64FFDA), width: 1.5),
            ),
            onPressed: () => _showMenu(context),
            child: const Icon(Icons.settings),
          ),
        );
      },
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final state = context.read<GameState>();
    final reset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: const Text(
          'Reset Progress?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This clears gold, floor progress, and all upgrades.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset'),
          ),
        ],
      ),
    );
    if (reset == true) {
      await state.resetProgress();
    }
  }

  Future<void> _confirmFullWipe(BuildContext context) async {
    final state = context.read<GameState>();
    final meta = context.read<MetaState>();
    final wipe = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: const Text(
          'Wipe ALL Progress?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This clears EVERYTHING: gold, floors, upgrades, AND Meta Embers/Keystones. This cannot be undone.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Wipe All'),
          ),
        ],
      ),
    );
    if (wipe == true) {
      await state.resetProgress();
      await meta.wipe();
    }
  }

  Future<void> _pickSkill(BuildContext context) async {
    final state = context.read<GameState>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: const Text(
          'Add skill',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 360,
          height: 460,
          child: AnimatedBuilder(
            animation: state,
            builder: (_, _) {
              final byArchetype = <SkillArchetype, List<SkillDefinition>>{};
              for (final def in skillCatalog) {
                byArchetype.putIfAbsent(def.archetype, () => []).add(def);
              }
              return ListView(
                children: [
                  for (final archetype in SkillArchetype.values) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Text(
                        archetype.label.toUpperCase(),
                        style: TextStyle(
                          color: archetype.color.withValues(alpha: 0.56),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final def in byArchetype[archetype] ?? const [])
                          _AddSkillChip(def: def, state: state),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _MenuHeader extends StatelessWidget {
  const _MenuHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddSkillChip extends StatelessWidget {
  const _AddSkillChip({required this.def, required this.state});

  final SkillDefinition def;
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final level = state.skillLevel(def.id);
    final maxed = level >= SkillDefinition.maxLevel;
    final color = maxed
        ? Colors.white.withValues(alpha: 0.32)
        : def.archetype.color;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Text(
        '${def.title}  $level/${SkillDefinition.maxLevel}',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    return Tooltip(
      message: def.descriptionForLevel(level + 1),
      triggerMode: TooltipTriggerMode.tap,
      preferBelow: false,
      child: InkWell(
        onTap: maxed ? null : () => state.devGrantSkill(def.id),
        borderRadius: BorderRadius.circular(6),
        child: chip,
      ),
    );
  }
}

class _LevelUpPicker extends StatelessWidget {
  const _LevelUpPicker();

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (_, state, _) {
        final choices = state.pendingChoices;
        if (choices.isEmpty || state.isRunOver) return const SizedBox.shrink();
        return ColoredBox(
          color: Colors.black.withValues(alpha: 0.68),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 96, 16, 96),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Neon Ascension',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (state.autoSelectSecondsRemaining != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Auto-selecting in ${state.autoSelectSecondsRemaining}s',
                            style: const TextStyle(
                              color: Color(0xFFFFC107),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        'Choose one floor ${state.floor} upgrade',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _PickerActions(state: state),
                      const SizedBox(height: 12),
                      ...choices.map(
                        (choice) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ChoiceCard(
                            choice: choice,
                            isLocked:
                                state.lockedUpgradeId == choice.definition.id,
                            canLock: state.meta.lockEnabled,
                            canBanish: state.banishesRemaining > 0,
                            onTap: () =>
                                state.selectUpgrade(choice.definition.id),
                            onToggleLock: () =>
                                state.toggleLock(choice.definition.id),
                            onBanish: () =>
                                state.banishChoice(choice.definition.id),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PickerActions extends StatelessWidget {
  const _PickerActions({required this.state});
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final canReroll = state.rerollsRemaining > 0;
    if (!canReroll && state.banishesRemaining == 0) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        if (state.meta.rerollsPerRun > 0)
          _ActionChip(
            icon: Icons.refresh,
            label: 'Reroll (${state.rerollsRemaining})',
            enabled: canReroll,
            onTap: canReroll ? state.rerollChoices : null,
          ),
        if (state.meta.banishesPerRun > 0)
          _ActionChip(
            icon: Icons.block,
            label: 'Banish (${state.banishesRemaining})',
            enabled: false,
            onTap: null,
            tooltip: 'Tap a card\'s X to banish it',
          ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.tooltip,
  });
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? const Color(0xFF64FFDA)
        : Colors.white.withValues(alpha: 0.35);
    final chip = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return tooltip == null ? chip : Tooltip(message: tooltip!, child: chip);
  }
}

class _NexusHealthBar extends StatefulWidget {
  const _NexusHealthBar();

  @override
  State<_NexusHealthBar> createState() => _NexusHealthBarState();
}

class _NexusHealthBarState extends State<_NexusHealthBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final godMode = context.select<GameState, bool>((s) => s.godMode);
    return Selector<GameState, ({double hp, double maxHp})>(
      selector: (_, state) => (hp: state.nexusHp, maxHp: state.nexusMaxHp),
      builder: (_, data, _) => Align(
        alignment: Alignment.bottomLeft,
        child: _Panel(
          child: SizedBox(
            width: 210,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      godMode ? Icons.shield : Icons.favorite,
                      color: godMode
                          ? const Color(0xFF64FFDA)
                          : const Color(0xFFFF5252),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        godMode ? 'Nexus (GOD MODE)' : 'Nexus',
                        style: TextStyle(
                          color: godMode
                              ? const Color(0xFF64FFDA)
                              : Colors.white.withValues(alpha: 0.86),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${data.hp.ceil()}/${data.maxHp.round()}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: data.hp / data.maxHp,
                        minHeight: 7,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation(
                          godMode
                              ? const Color(0xFF64FFDA)
                              : const Color(0xFFFF5252),
                        ),
                      ),
                    ),
                    if (godMode)
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return FractionallySizedBox(
                              widthFactor: 0.4,
                              alignment: Alignment(
                                -1.5 + (_controller.value * 3),
                                0,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0),
                                      Colors.white.withValues(alpha: 0.4),
                                      Colors.white.withValues(alpha: 0),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RunOverPanel extends StatelessWidget {
  const _RunOverPanel();

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (_, state, _) {
        if (!state.isRunOver) return const SizedBox.shrink();
        return const MetaShopScreen();
      },
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.choice,
    required this.onTap,
    this.isLocked = false,
    this.canLock = false,
    this.canBanish = false,
    this.onToggleLock,
    this.onBanish,
  });

  final SkillChoice choice;
  final VoidCallback onTap;
  final bool isLocked;
  final bool canLock;
  final bool canBanish;
  final VoidCallback? onToggleLock;
  final VoidCallback? onBanish;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Ink(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isLocked
                      ? const Color(0xFFFFC107)
                      : _accent.withValues(alpha: 0.8),
                  width: isLocked ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _accent.withValues(alpha: 0.16),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _accent.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Icon(_icon, color: _accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _Tag(
                              label: choice.isNew ? 'New Skill' : 'Upgrade',
                              color: _accent,
                            ),
                            _Tag(label: choice.tierLabel, color: _tierColor),
                            _Tag(label: _archetypeLabel, color: _accent),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                choice.definition.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              'Lv ${choice.currentLevel} -> ${choice.level}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.58),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          choice.description,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.68),
                            fontSize: 13,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (canLock || canBanish)
          Positioned(
            top: 4,
            right: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canLock)
                  _CornerIconButton(
                    icon: isLocked ? Icons.lock : Icons.lock_open,
                    color: isLocked
                        ? const Color(0xFFFFC107)
                        : Colors.white.withValues(alpha: 0.6),
                    onTap: onToggleLock,
                  ),
                if (canBanish)
                  _CornerIconButton(
                    icon: Icons.close,
                    color: const Color(0xFFFF5252),
                    onTap: onBanish,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Color get _accent => choice.definition.archetype.color;

  IconData get _icon => choice.definition.archetype.icon;

  Color get _tierColor {
    return switch (choice.level) {
      2 || 4 => const Color(0xFFFF2D95),
      5 => const Color(0xFFFFD166),
      _ => const Color(0xFF64FFDA),
    };
  }

  String get _archetypeLabel => choice.definition.archetype.label;
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _IdleRewardToast extends StatelessWidget {
  const _IdleRewardToast();

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (_, state, _) {
        if (state.lastIdleReward <= 0) return const SizedBox.shrink();
        return Center(
          child: GestureDetector(
            onTap: state.clearIdleReward,
            child: _Panel(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bedtime, color: Color(0xFFFFC107), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '+${state.lastIdleReward} while you were away',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CornerIconButton extends StatelessWidget {
  const _CornerIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 26,
          height: 26,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: child,
    );
  }
}
