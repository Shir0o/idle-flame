import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import '../game/state/game_state.dart';
import '../game/state/mech_catalog.dart';
import '../game/state/meta_catalog.dart';
import '../game/state/meta_state.dart';
import '../game/state/skill_catalog.dart';
import '../game/state/triad_catalog.dart';
import '../game/state/inflection_catalog.dart';
import 'meta_screen.dart';
import 'sigil_matrix.dart';

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
          Positioned(left: 16, bottom: 16, child: _NexusHealthBar()),
          Positioned.fill(child: _WelcomeToast()),
          Positioned.fill(child: _BossRewardToast()),
          Positioned.fill(child: _LevelUpPicker()),
          Positioned.fill(child: _EvolutionPicker()),
          Positioned.fill(child: _FusionPicker()),
          Positioned.fill(child: _CantPicker()),
          Positioned.fill(child: _RunOverPanel()),
          Positioned(
            top: 12,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [_FloorBadge(), SizedBox(height: 8), _ArsenalPanel()],
            ),
          ),
          Positioned(top: 12, right: 16, child: _GoldBadge()),
          Positioned(top: 80, right: 16, child: _MuteButton()),
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
              final def = findSkillById(entry.key);
              if (def == null) return null;
              return (def: def, level: entry.value);
            }).nonNulls.toList();

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
                            icon: Icons.history_rounded,
                            color: const Color(0xFF64FFDA),
                            label: 'Total Runs: ${state.totalRuns}',
                            description: 'Total descents into the Neon Void.',
                            onTap: () {},
                          ),
                          _MenuItem(
                            icon: Icons.local_fire_department_rounded,
                            color: const Color(0xFFFF8A00),
                            label: 'Lifetime Embers: ${meta.lifetimeEmbers}',
                            description:
                                'Total Embers harvested from the Void.',
                            onTap: () {},
                          ),
                          _MenuItem(
                            icon: Icons.dangerous_rounded,

                            color: const Color(0xFFFF5252),
                            label: 'Total Kills: ${state.lifetimeKills}',
                            description:
                                'Lifetime enemies breached across all runs.',
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
                          if (state.activeTriadIds.isNotEmpty) ...[
                            const _MenuHeader('ACTIVE TRIADS'),
                            for (final triadId in state.activeTriadIds)
                              Builder(builder: (context) {
                                final triad = triadCatalog.firstWhereOrNull((t) => t.id == triadId);
                                if (triad == null) return const SizedBox.shrink();
                                return _MenuItem(
                                  icon: Icons.hub,
                                  color: const Color(0xFF64FFDA),
                                  label: triad.name,
                                  description: triad.description,
                                  onTap: () {},
                                );
                              }),
                          ],
                          if (state.edgeLevel > 0 || state.daemonLevel > 0 || state.hexLevel > 0) ...[
                            const _MenuHeader('CURRENT RESOURCES'),
                            if (state.edgeLevel > 0)
                              _MenuItem(
                                icon: Icons.bolt_rounded,
                                color: SkillPath.edge.color,
                                label: 'Stance',
                                description: '${state.edgeStance}/5 pips · Focus one target to build Stance. Spend at 3 for Crit, 5 for Cleave.',
                                onTap: () {},
                              ),
                            if (state.daemonLevel > 0)
                              _MenuItem(
                                icon: Icons.lan_rounded,
                                color: SkillPath.daemon.color,
                                label: 'Bandwidth',
                                description: '${state.daemonBandwidth.toStringAsFixed(0)}/100 units · Daemon skills consume Bandwidth. If empty, firing rate is halved.',
                                onTap: () {},
                              ),
                            if (state.hexLevel > 0)
                              _MenuItem(
                                icon: Icons.local_fire_department_rounded,
                                color: SkillPath.hex.color,
                                label: 'Cinder',
                                description: '${state.hexCinder.toStringAsFixed(0)}/100 charge · Kills build Cinder. At 100, your next Hex skill is doubled.',
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
                                _ActiveSkillRow(
                                  archetype: entry.key,
                                  def: s.def,
                                  level: s.level,
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
        return _Panel(
          child: InkWell(
            onTap: () => _showArsenalMenu(context, state, meta),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF64FFDA).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                color: Color(0xFF64FFDA),
                size: 18,
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
    return Selector<GameState, ({int floor, FloorPhase phase, double time, CrucibleEvent? event, Set<FloorModifier> modifiers})>(
      selector: (_, state) => (
        floor: state.floor,
        phase: state.floorPhase,
        time: state.floorTime,
        event: state.crucibleEvent,
        modifiers: state.activeModifiers,
      ),
      builder: (_, data, _) => InkWell(
        onTap: () => _handleTap(state),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
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
                      if (data.floor % 5 == 0) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252), size: 14),
                        const SizedBox(width: 2),
                        const Text(
                          'BOSS',
                          style: TextStyle(
                            color: Color(0xFFFF5252),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 140,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (data.time / 32.0).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFFFFC107),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _phaseLabel(data.phase),
                        style: TextStyle(
                          color: _phaseColor(data.phase),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${(32.0 - data.time).clamp(0.0, 32.0).toStringAsFixed(1)}s',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  if (data.phase == FloorPhase.crucible && data.event != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Crucible: ${_eventName(data.event!)}',
                      style: const TextStyle(
                        color: Color(0xFFFF5252),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (data.modifiers.isNotEmpty) ...[
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: data.modifiers.map((mod) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _Panel(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _modIcon(mod),
                          color: _modColor(mod),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _modName(mod),
                          style: TextStyle(
                            color: _modColor(mod),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )).toList(),
              ),
            ],
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

  String _phaseLabel(FloorPhase phase) {
    switch (phase) {
      case FloorPhase.trickle: return 'Trickle';
      case FloorPhase.press: return 'Press';
      case FloorPhase.crucible: return 'Crucible';
    }
  }

  Color _phaseColor(FloorPhase phase) {
    switch (phase) {
      case FloorPhase.trickle: return const Color(0xFF64FFDA);
      case FloorPhase.press: return const Color(0xFFFFD54F);
      case FloorPhase.crucible: return const Color(0xFFFF5252);
    }
  }

  String _eventName(CrucibleEvent event) {
    switch (event) {
      case CrucibleEvent.pressure: return 'Pressure';
      case CrucibleEvent.hivebreak: return 'Hivebreak';
      case CrucibleEvent.sigilStorm: return 'Sigil Storm';
      case CrucibleEvent.eclipse: return 'Eclipse';
      case CrucibleEvent.quiet: return 'Quiet';
      case CrucibleEvent.fractalPack: return 'Fractal Pack';
      case CrucibleEvent.lastCant: return 'Last Cant';
      case CrucibleEvent.bossEcho: return 'Boss Echo';
    }
  }

  String _modName(FloorModifier mod) {
    switch (mod) {
      case FloorModifier.bandwidthBlackout: return 'Bandwidth Blackout';
      case FloorModifier.cinderDamp: return 'Cinder Damp';
      case FloorModifier.stanceStutter: return 'Stance Stutter';
      case FloorModifier.quickening: return 'Quickening';
      case FloorModifier.solarFlare: return 'Solar Flare';
      case FloorModifier.veilOfAsh: return 'Veil of Ash';
      case FloorModifier.hereticTide: return 'Heretic Tide';
      case FloorModifier.cipherStorm: return 'Cipher Storm';
      case FloorModifier.echoTide: return 'Echo Tide';
      case FloorModifier.discountKit: return 'Discount Kit';
      case FloorModifier.manaBloom: return 'Mana Bloom';
      case FloorModifier.glyphCache: return 'Glyph Cache';
    }
  }

  IconData _modIcon(FloorModifier mod) {
    switch (mod) {
      case FloorModifier.bandwidthBlackout: return Icons.wifi_off;
      case FloorModifier.cinderDamp: return Icons.water_drop;
      case FloorModifier.stanceStutter: return Icons.broken_image;
      case FloorModifier.quickening: return Icons.speed;
      case FloorModifier.solarFlare: return Icons.wb_sunny;
      case FloorModifier.veilOfAsh: return Icons.visibility_off;
      case FloorModifier.hereticTide: return Icons.waves;
      case FloorModifier.cipherStorm: return Icons.security;
      case FloorModifier.echoTide: return Icons.record_voice_over;
      case FloorModifier.discountKit: return Icons.local_offer;
      case FloorModifier.manaBloom: return Icons.local_florist;
      case FloorModifier.glyphCache: return Icons.diamond;
    }
  }

  Color _modColor(FloorModifier mod) {
    switch (mod) {
      case FloorModifier.bandwidthBlackout:
      case FloorModifier.cinderDamp:
      case FloorModifier.stanceStutter:
      case FloorModifier.quickening:
      case FloorModifier.solarFlare:
      case FloorModifier.veilOfAsh:
      case FloorModifier.hereticTide:
      case FloorModifier.cipherStorm:
        return const Color(0xFFFF8A80); // Red-ish for restrictions/pressures
      case FloorModifier.echoTide:
      case FloorModifier.discountKit:
      case FloorModifier.manaBloom:
      case FloorModifier.glyphCache:
        return const Color(0xFF64FFDA); // Cyan for boons
    }
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
                          _MenuHeader(
                            'CURRENCY & PROGRESS',
                            onReset: () {
                              state.devResetCurrency();
                              meta.devResetEmbers();
                            },
                          ),
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
                            icon: Icons.restart_alt,
                            color: const Color(0xFFFF8A80),
                            label: 'Reset All Skills',
                            description: 'Remove all skills from current run.',
                            onTap: () => state.devResetAllSkills(),
                          ),
                          _MenuItem(
                            icon: Icons.star,
                            color: const Color(0xFFFFD166),
                            label: 'Max Meta',
                            description:
                                'Instantly unlock and max all meta-upgrades.',
                            onTap: () => meta.devMaxAll(),
                          ),
                          _MenuItem(
                            icon: Icons.restart_alt,
                            color: const Color(0xFFFF8A80),
                            label: 'Reset Meta',
                            description: 'Lock and reset all meta-upgrades.',
                            onTap: () => meta.devResetAll(),
                          ),
                          _MenuHeader(
                            'FLOOR & COMBAT',
                            onReset: () => state.devResetFloor(),
                          ),
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
                          _MenuHeader(
                            'ENGINE & UTILITIES',
                            onReset: () => state.devResetEngine(),
                          ),
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
                                'Cycle between 1x, 2x, 5x, and 0x (Paused).',
                            onTap: () => state.cycleGameSpeed(),
                          ),
                          _MenuItem(
                            icon: Icons.fitness_center_rounded,
                            color: const Color(0xFFFF5252),
                            label:
                                'Enemy Strength (${state.devEnemyStrength.round()}x)',
                            description:
                                'Cycle between 1x, 2x, 5x, and 10x enemy HP/DMG.',
                            onTap: () => state.cycleEnemyStrength(),
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
    bool showDescriptions = true;
    final expanded = <SkillArchetype, bool>{
      for (final a in SkillArchetype.values) a: true,
    };

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: const Color(0xFF0B1220),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: const Color(0xFF64FFDA).withValues(alpha: 0.18),
              ),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF64FFDA,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.science_rounded,
                            color: Color(0xFF64FFDA),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Skill Selector',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Tune any in-run skill instantly.',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: showDescriptions
                              ? 'Hide descriptions'
                              : 'Show descriptions',
                          onPressed: () => setDialogState(
                            () => showDescriptions = !showDescriptions,
                          ),
                          icon: Icon(
                            showDescriptions
                                ? Icons.notes_rounded
                                : Icons.notes_outlined,
                            color: Colors.white70,
                            size: 18,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white54,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Row(
                      children: [
                        _BulkActionButton(
                          icon: Icons.auto_awesome_rounded,
                          label: 'Max All',
                          color: const Color(0xFF64FFDA),
                          onTap: () => state.devMaxAllSkills(),
                        ),
                        const SizedBox(width: 8),
                        _BulkActionButton(
                          icon: Icons.restart_alt_rounded,
                          label: 'Reset All',
                          color: const Color(0xFFFF8A80),
                          onTap: () => state.devResetAllSkills(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: state,
                      builder: (_, _) {
                        final byArchetype =
                            <SkillArchetype, List<SkillDefinition>>{};
                        for (final def in skillCatalog) {
                          byArchetype
                              .putIfAbsent(def.archetype, () => [])
                              .add(def);
                        }
                        return ListView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          children: [
                            for (final archetype in SkillArchetype.values) ...[
                              _ArchetypeSection(
                                archetype: archetype,
                                skills: byArchetype[archetype] ?? const [],
                                state: state,
                                showDescriptions: showDescriptions,
                                expanded: expanded[archetype] ?? true,
                                onToggle: () => setDialogState(
                                  () => expanded[archetype] =
                                      !(expanded[archetype] ?? true),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MenuHeader extends StatelessWidget {
  const _MenuHeader(this.title, {this.onReset});
  final String title;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF64FFDA);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 12,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onReset != null) ...[
            const SizedBox(width: 12),
            _BulkActionButton(
              icon: Icons.restart_alt_rounded,
              label: 'RESET',
              color: const Color(0xFFFF8A80),
              onTap: onReset!,
            ),
          ],
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
        ],
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
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

class _ActiveSkillRow extends StatelessWidget {
  const _ActiveSkillRow({
    required this.archetype,
    required this.def,
    required this.level,
  });

  final SkillArchetype archetype;
  final SkillDefinition def;
  final int level;

  @override
  Widget build(BuildContext context) {
    final color = archetype.color;
    final maxed = level >= SkillDefinition.maxLevel;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.22),
                  color.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(archetype.icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        def.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _LevelPips(level: level, color: color),
                    if (maxed) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 12,
                        color: color,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  def.descriptionForLevel(level),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Consumer<GameState>(
                  builder: (context, state, _) {
                    final inflectionIds = state.getInflectionsFor(def.id);
                    if (inflectionIds.isEmpty) return const SizedBox.shrink();
                    return Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: inflectionIds.map((infId) {
                        final inf = inflectionCatalog.firstWhereOrNull((i) => i.id == infId);
                        if (inf == null) return const SizedBox.shrink();
                        return Tooltip(
                          message: inf.description,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: color.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              inf.name.toUpperCase(),
                              style: TextStyle(
                                color: color,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BulkActionButton extends StatelessWidget {
  const _BulkActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.35)),
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
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelPips extends StatelessWidget {
  const _LevelPips({required this.level, required this.color});

  final int level;
  final Color color;

  static const double size = 7;
  static const double spacing = 3;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= SkillDefinition.maxLevel; i++) ...[
          if (i > 1) SizedBox(width: spacing),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i <= level
                  ? color
                  : Colors.white.withValues(alpha: 0.12),
              border: Border.all(
                color: i <= level
                    ? color
                    : Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
              boxShadow: i <= level
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ]
                  : null,
            ),
          ),
        ],
      ],
    );
  }
}

class _ArchetypeSection extends StatelessWidget {
  const _ArchetypeSection({
    required this.archetype,
    required this.skills,
    required this.state,
    required this.showDescriptions,
    required this.expanded,
    required this.onToggle,
  });

  final SkillArchetype archetype;
  final List<SkillDefinition> skills;
  final GameState state;
  final bool showDescriptions;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final color = archetype.color;
    final ownedCount = skills
        .where((s) => state.skillLevel(s.id) > 0)
        .length;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(archetype.icon, color: color, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  archetype.label.toUpperCase(),
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$ownedCount/${skills.length}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _BulkActionButton(
                          icon: Icons.last_page_rounded,
                          label: 'Max',
                          color: color,
                          onTap: () => state.devMaxArchetypeSkills(archetype),
                        ),
                        const SizedBox(width: 4),
                        _BulkActionButton(
                          icon: Icons.first_page_rounded,
                          label: 'Reset',
                          color: const Color(0xFFFF8A80),
                          onTap: () => state.devResetArchetypeSkills(archetype),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: Colors.white54,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            if (showDescriptions && skills.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(
                      color: color.withValues(alpha: 0.6),
                      width: 2,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 1; i <= SkillDefinition.maxLevel; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2, right: 6),
                              width: 18,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'L$i',
                                style: TextStyle(
                                  color: color.withValues(alpha: 0.85),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                skills.first.descriptionForLevel(i),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            for (final def in skills)
              _AddSkillRow(def: def, state: state),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _AddSkillRow extends StatelessWidget {
  const _AddSkillRow({required this.def, required this.state});

  final SkillDefinition def;
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final level = state.skillLevel(def.id);
    final maxed = level >= SkillDefinition.maxLevel;
    final color = def.archetype.color;
    final dim = level == 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  def.title,
                  style: TextStyle(
                    color: dim
                        ? Colors.white.withValues(alpha: 0.65)
                        : Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _LevelPips(level: level, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              _SkillStepButton(
                icon: Icons.first_page_rounded,
                tooltip: 'Set to 0',
                color: const Color(0xFFFF8A80),
                enabled: level > 0,
                onTap: () => state.devSetSkillLevel(def.id, 0),
              ),
              _SkillStepButton(
                icon: Icons.remove_rounded,
                tooltip: 'Decrease',
                color: Colors.white70,
                enabled: level > 0,
                onTap: () => state.devSetSkillLevel(def.id, level - 1),
              ),
              _SkillStepButton(
                icon: Icons.add_rounded,
                tooltip: 'Increase',
                color: color,
                enabled: !maxed,
                onTap: () => state.devSetSkillLevel(def.id, level + 1),
              ),
              _SkillStepButton(
                icon: Icons.last_page_rounded,
                tooltip: 'Max out',
                color: color,
                enabled: !maxed,
                onTap: () =>
                    state.devSetSkillLevel(def.id, SkillDefinition.maxLevel),
              ),
              if (level > 0)
                _SkillStepButton(
                  icon: Icons.tune_rounded,
                  tooltip: 'Add Random Inflection',
                  color: Colors.amber,
                  enabled: true,
                  onTap: () => state.devGrantRandomInflection(def.id),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Consumer<GameState>(
            builder: (context, state, _) {
              final inflectionIds = state.getInflectionsFor(def.id);
              if (inflectionIds.isEmpty) return const SizedBox.shrink();
              return Wrap(
                spacing: 4,
                runSpacing: 4,
                children: inflectionIds.map((infId) {
                  final inf = inflectionCatalog.firstWhereOrNull((i) => i.id == infId);
                  if (inf == null) return const SizedBox.shrink();
                  return Tooltip(
                    message: inf.description,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: color.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        inf.name.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SkillStepButton extends StatelessWidget {
  const _SkillStepButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = enabled ? color : Colors.white.withValues(alpha: 0.18);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: c.withValues(alpha: enabled ? 0.12 : 0.04),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: c.withValues(alpha: 0.35)),
          ),
          child: Icon(icon, color: c, size: 16),
        ),
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
                      const SizedBox(height: 20),
                      const SigilMatrix(size: 240),
                      const SizedBox(height: 20),
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
                            onTap: (infId) =>
                                state.selectUpgrade(choice.definition.id, inflectionId: infId),
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

class _FusionPicker extends StatelessWidget {
  const _FusionPicker();

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (_, state, _) {
        final choices = state.pendingFusionChoices;
        if (choices.isEmpty || state.isRunOver) return const SizedBox.shrink();
        return ColoredBox(
          color: Colors.black.withValues(alpha: 0.75),
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
                        'FUSION FORM',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'A rare cross-path resonance has stabilized.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ...choices.map(
                        (choice) => _ChoiceCardGeneric(
                          title: choice.title,
                          description: choice.description,
                          tierLabel: choice.tierLabel,
                          color: Colors.amber,
                          onTap: () => state.selectFusion(choice.definition.id),
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

class _CantPicker extends StatelessWidget {
  const _CantPicker();

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (_, state, _) {
        final choices = state.pendingCantChoices;
        if (choices.isEmpty || state.isRunOver) return const SizedBox.shrink();
        return ColoredBox(
          color: Colors.black.withValues(alpha: 0.8),
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
                        'HERETIC CANT',
                        style: TextStyle(
                          color: Color(0xFFFF5252),
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Choose a forbidden line from the system core.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ...choices.map(
                        (choice) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ChoiceCardGeneric(
                            title: choice.title,
                            description: choice.description,
                            tierLabel: choice.tierLabel,
                            color: const Color(0xFFFF5252),
                            onTap: () => state.selectCant(choice.definition.id),
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

class _ChoiceCardGeneric extends StatelessWidget {
  const _ChoiceCardGeneric({
    required this.title,
    required this.description,
    required this.tierLabel,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String description;
  final String tierLabel;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tierLabel,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.auto_awesome, color: color, size: 16),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
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
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
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
      builder: (_, data, _) => _Panel(
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
              const _PathResources(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PathResources extends StatelessWidget {
  const _PathResources();

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, _) {
        final edgeActive = state.pathLevels(SkillPath.edge) > 0;
        final daemonActive = state.pathLevels(SkillPath.daemon) > 0;
        final hexActive = state.pathLevels(SkillPath.hex) > 0;

        if (!edgeActive && !daemonActive && !hexActive) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (edgeActive) _buildEdgeResources(state),
              if (daemonActive) _buildDaemonResources(state),
              if (hexActive) _buildHexResources(state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEdgeResources(GameState state) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (i) {
          final active = i < state.edgeStance;
          return Container(
            width: 12,
            height: 4,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: active
                  ? SkillPath.edge.color
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(1),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: SkillPath.edge.color.withValues(alpha: 0.5),
                        blurRadius: 4,
                      )
                    ]
                  : null,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDaemonResources(GameState state) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Stack(
        children: [
          Container(
            height: 4,
            width: 100,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          Container(
            height: 4,
            width: state.daemonBandwidth,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00E5FF),
                  SkillPath.daemon.color,
                ],
              ),
              borderRadius: BorderRadius.circular(1),
              boxShadow: [
                BoxShadow(
                  color: SkillPath.daemon.color.withValues(alpha: 0.4),
                  blurRadius: 4,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHexResources(GameState state) {
    return Stack(
      children: [
        Container(
          height: 4,
          width: 100,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        Container(
          height: 4,
          width: state.hexCinder,
          decoration: BoxDecoration(
            color: SkillPath.hex.color,
            borderRadius: BorderRadius.circular(1),
            boxShadow: [
              BoxShadow(
                color: SkillPath.hex.color.withValues(alpha: 0.4),
                blurRadius: 4,
              )
            ],
          ),
        ),
      ],
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
        return const MetaScreen();
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
  final void Function(String? inflectionId) onTap;
  final bool isLocked;
  final bool canLock;
  final bool canBanish;
  final VoidCallback? onToggleLock;
  final VoidCallback? onBanish;

  @override
  Widget build(BuildContext context) {
    final archetype = choice.definition.archetype;
    final color = archetype.color;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isLocked
                ? const Color(0xFF64FFDA)
                : color.withValues(alpha: 0.35),
            width: isLocked ? 2 : 1.5,
          ),
          boxShadow: isLocked
              ? [
                  BoxShadow(
                    color: const Color(0xFF64FFDA).withValues(alpha: 0.15),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => onTap(null),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withValues(alpha: 0.2),
                            color.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Icon(archetype.icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  choice.tierLabel,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (choice.isNew)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF64FFDA,
                                    ).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'NEW',
                                    style: TextStyle(
                                      color: Color(0xFF64FFDA),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              const Spacer(),
                              if (canLock)
                                _CardActionIcon(
                                  icon: isLocked ? Icons.lock : Icons.lock_outline,
                                  color: isLocked
                                      ? const Color(0xFF64FFDA)
                                      : Colors.white30,
                                  onTap: onToggleLock,
                                  tooltip: isLocked ? 'Unlock' : 'Lock for next pick',
                                ),
                              if (canBanish) ...[
                                const SizedBox(width: 8),
                                _CardActionIcon(
                                  icon: Icons.close,
                                  color: Colors.white30,
                                  onTap: onBanish,
                                  tooltip: 'Banish from run',
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            choice.definition.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            choice.description,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _LevelPips(level: choice.level, color: color),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (choice.inflectionOptions.isNotEmpty) ...[
              const Divider(color: Colors.white10, height: 1),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    ...choice.inflectionOptions.map((inf) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _InflectionButton(
                              inflection: inf,
                              color: color,
                              onTap: () => onTap(inf.id),
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InflectionButton extends StatelessWidget {
  const _InflectionButton({
    required this.inflection,
    required this.color,
    required this.onTap,
  });

  final InflectionDefinition inflection;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRare = inflection.rarity == InflectionRarity.rare;
    final borderColor = isRare ? Colors.amber : color.withValues(alpha: 0.2);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isRare ? Colors.amber.withValues(alpha: 0.1) : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: borderColor,
            width: isRare ? 1.5 : 1.0,
          ),
          boxShadow: isRare
              ? [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.2),
                    blurRadius: 4,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    inflection.name.toUpperCase(),
                    style: TextStyle(
                      color: isRare ? Colors.amber : color,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (isRare)
                  const Icon(
                    Icons.auto_awesome,
                    color: Colors.amber,
                    size: 10,
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              inflection.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 9,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardActionIcon extends StatelessWidget {
  const _CardActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
  });
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

class _EvolutionPicker extends StatelessWidget {
  const _EvolutionPicker();

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (_, state, _) {
        final archetype = state.pendingEvolutionArchetype;
        if (archetype == null || state.isRunOver) return const SizedBox.shrink();

        final evos = evolutionCatalog[archetype]!;

        return ColoredBox(
          color: Colors.black.withValues(alpha: 0.8),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'EVOLUTION',
                      style: TextStyle(
                        color: Color(0xFF64FFDA),
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The ${archetype.label.toUpperCase()} has reached peak resonance.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 32),
                    _EvolutionCard(
                      name: evos.$1.name,
                      description: evos.$1.description,
                      onTap: () => state.selectEvolution(1),
                    ),
                    const SizedBox(height: 16),
                    _EvolutionCard(
                      name: evos.$2.name,
                      description: evos.$2.description,
                      onTap: () => state.selectEvolution(2),
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

class _EvolutionCard extends StatelessWidget {
  const _EvolutionCard({
    required this.name,
    required this.description,
    required this.onTap,
  });
  final String name;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF64FFDA).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF64FFDA).withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Color(0xFF64FFDA),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeToast extends StatefulWidget {
  const _WelcomeToast();

  @override
  State<_WelcomeToast> createState() => _WelcomeToastState();
}

class _WelcomeToastState extends State<_WelcomeToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    _offset = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: const Offset(0, -0.1),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, _) {
        if (!state.sessionWelcomeShown || state.lastVoidReward > 0) {
          if (!_controller.isAnimating && state.lastVoidReward > 0) {
            _controller.forward(from: 0).then((_) => state.clearVoidReward());
          } else if (!_controller.isAnimating && !state.sessionWelcomeShown) {
            _controller.forward(from: 0).then((_) => state.dismissWelcome());
          }

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              if (_controller.value == 0) return const SizedBox.shrink();
              return SlideTransition(
                position: _offset,
                child: FadeTransition(
                  opacity: _opacity,
                  child: Center(
                    child: _Panel(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (state.lastVoidReward > 0) ...[
                            const Icon(
                              Icons.auto_awesome,
                              color: Color(0xFFFFC107),
                              size: 32,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Void Harvest',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '+${state.lastVoidReward} gold earned while away',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ] else ...[
                            const Icon(
                              Icons.cyclone,
                              color: Color(0xFF64FFDA),
                              size: 32,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Zenith Zero',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            const Text(
                              'IDLE DESCENT',
                              style: TextStyle(
                                color: Color(0xFF64FFDA),
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _BossRewardToast extends StatefulWidget {
  const _BossRewardToast();

  @override
  State<_BossRewardToast> createState() => _BossRewardToastState();
}

class _BossRewardToastState extends State<_BossRewardToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 15),
    ]).animate(_controller);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: const Offset(0, -0.05),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<GameState, ({String? label, String? subtitle})>(
      selector: (_, state) =>
          (label: state.lastBossRewardLabel, subtitle: state.lastBossRewardSubtitle),
      builder: (context, data, _) {
        if (data.label == null) return const SizedBox.shrink();
        if (!_controller.isAnimating) {
          _controller.forward(from: 0).then((_) {
            if (mounted) context.read<GameState>().clearBossReward();
          });
        }
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.value == 0) return const SizedBox.shrink();
            return Align(
              alignment: const Alignment(0, -0.5),
              child: SlideTransition(
                position: _offset,
                child: FadeTransition(
                  opacity: _opacity,
                  child: _Panel(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.military_tech,
                          color: Color(0xFFFFD166),
                          size: 32,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          data.label!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.5,
                          ),
                        ),
                        if (data.subtitle != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            data.subtitle!,
                            style: const TextStyle(
                              color: Color(0xFFFFD166),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
