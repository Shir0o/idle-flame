import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/state/game_state.dart';
import '../game/state/skill_catalog.dart';
import 'meta_screen.dart';

class Hud extends StatelessWidget {
  const Hud({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: const [
          Positioned(top: 12, left: 16, child: _FloorBadge()),
          Positioned(top: 12, right: 16, child: _GoldBadge()),
          Positioned(top: 92, left: 16, child: _BalanceDebugPanel()),
          Positioned(left: 16, right: 16, bottom: 16, child: _NexusHealthBar()),
          Positioned(right: 16, bottom: 16, child: _DevResetButton()),
          Positioned(left: 0, right: 0, top: 80, child: _IdleRewardToast()),
          Positioned.fill(child: _LevelUpPicker()),
          Positioned.fill(child: _RunOverPanel()),
        ],
      ),
    );
  }
}

class _BalanceDebugPanel extends StatefulWidget {
  const _BalanceDebugPanel();

  @override
  State<_BalanceDebugPanel> createState() => _BalanceDebugPanelState();
}

class _BalanceDebugPanelState extends State<_BalanceDebugPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (_, state, _) {
        final timeToKill = state.estimatedTimeToKill;
        return _Panel(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.tune,
                          color: Color(0xFF64FFDA),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Balance',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.white.withValues(alpha: 0.64),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_expanded) ...[
                  const SizedBox(height: 8),
                  _MetricRow('DPS', state.estimatedDps.toStringAsFixed(1)),
                  _MetricRow('Enemy HP', state.enemyMaxHp.toStringAsFixed(1)),
                  _MetricRow('Gold/Kill', '${state.goldPerKill}'),
                  _MetricRow(
                    'TTK',
                    timeToKill.isFinite
                        ? '${timeToKill.toStringAsFixed(2)}s'
                        : 'n/a',
                  ),
                  _MetricRow(
                    'Gold/Sec',
                    state.estimatedGoldPerSecond.toStringAsFixed(2),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: state.skillLevels.entries.map((entry) {
                      final def = skillCatalog.firstWhere((d) => d.id == entry.key);
                      return _SkillChip(def.title, entry.value);
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.56),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip(this.label, this.level);

  final String label;
  final int level;

  @override
  Widget build(BuildContext context) {
    final active = level > 0;
    final color = active
        ? const Color(0xFF64FFDA)
        : Colors.white.withValues(alpha: 0.42);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: active ? 0.13 : 0.06),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: color.withValues(alpha: active ? 0.28 : 0.16),
        ),
      ),
      child: Text(
        '$label $level',
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

class _FloorBadge extends StatelessWidget {
  const _FloorBadge();

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (_, state, _) => _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Floor ${state.floor}',
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
                  value: state.killsOnFloor / GameState.killsPerFloor,
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFFFC107)),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${state.killsOnFloor}/${GameState.killsPerFloor} kills',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
              ),
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
    return Consumer<GameState>(
      builder: (_, state, _) => _Panel(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.attach_money, color: Color(0xFFFFC107), size: 18),
            Text(
              '${state.gold}',
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

class _DevResetButton extends StatelessWidget {
  const _DevResetButton();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: IconButton(
        tooltip: 'Reset progress',
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.restart_alt, color: Color(0xFFFF5252)),
        onPressed: () => _confirmReset(context),
      ),
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

class _NexusHealthBar extends StatelessWidget {
  const _NexusHealthBar();

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (_, state, _) => Align(
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
                    const Icon(
                      Icons.favorite,
                      color: Color(0xFFFF5252),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Nexus',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.86),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${state.nexusHp.ceil()}/${state.nexusMaxHp.round()}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: state.nexusHp / state.nexusMaxHp,
                    minHeight: 7,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFF5252)),
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

  Color get _accent {
    return switch (choice.definition.archetype) {
      SkillArchetype.chain => const Color(0xFF00E5FF),
      SkillArchetype.nova => const Color(0xFFFF2D95),
      SkillArchetype.firewall => const Color(0xFFFFD166),
      SkillArchetype.meteor => const Color(0xFF7C4DFF),
      SkillArchetype.barrage => const Color(0xFF64FFDA),
      SkillArchetype.focus => const Color(0xFFFFF176),
      SkillArchetype.bounty => const Color(0xFFFFD54F),
      SkillArchetype.frost => const Color(0xFF80DEEA),
      SkillArchetype.rupture => const Color(0xFFFF5252),
      SkillArchetype.sentinel => const Color(0xFFE1F5FE),
    };
  }

  IconData get _icon {
    return switch (choice.definition.archetype) {
      SkillArchetype.chain => Icons.call_split,
      SkillArchetype.nova => Icons.blur_circular,
      SkillArchetype.firewall => Icons.horizontal_rule,
      SkillArchetype.meteor => Icons.flare,
      SkillArchetype.barrage => Icons.bolt,
      SkillArchetype.focus => Icons.auto_fix_high,
      SkillArchetype.bounty => Icons.paid,
      SkillArchetype.frost => Icons.ac_unit,
      SkillArchetype.rupture => Icons.flash_on,
      SkillArchetype.sentinel => Icons.navigation,
    };
  }

  Color get _tierColor {
    return switch (choice.level) {
      2 || 4 => const Color(0xFFFF2D95),
      5 => const Color(0xFFFFD166),
      _ => const Color(0xFF64FFDA),
    };
  }

  String get _archetypeLabel {
    return switch (choice.definition.archetype) {
      SkillArchetype.chain => 'Chain',
      SkillArchetype.nova => 'Nova',
      SkillArchetype.firewall => 'Firewall',
      SkillArchetype.meteor => 'Meteor',
      SkillArchetype.barrage => 'Barrage',
      SkillArchetype.focus => 'Focus',
      SkillArchetype.bounty => 'Bounty',
      SkillArchetype.frost => 'Frost',
      SkillArchetype.rupture => 'Rupture',
      SkillArchetype.sentinel => 'Sentinel',
    };
  }
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
