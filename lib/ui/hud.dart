import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/state/game_state.dart';
import '../game/state/skill_catalog.dart';

class Hud extends StatelessWidget {
  const Hud({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: const [
          Positioned(top: 12, left: 16, child: _FloorBadge()),
          Positioned(top: 12, right: 16, child: _GoldBadge()),
          Positioned(left: 0, right: 0, top: 80, child: _IdleRewardToast()),
          Positioned.fill(child: _LevelUpPicker()),
        ],
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

class _LevelUpPicker extends StatelessWidget {
  const _LevelUpPicker();

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (_, state, _) {
        final choices = state.pendingChoices;
        if (choices.isEmpty) return const SizedBox.shrink();
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
                      const SizedBox(height: 6),
                      Text(
                        'Choose one floor ${state.floor} upgrade',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ...choices.map(
                        (choice) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ChoiceCard(
                            choice: choice,
                            onTap: () =>
                                state.selectUpgrade(choice.definition.id),
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

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({required this.choice, required this.onTap});

  final SkillChoice choice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _accent.withValues(alpha: 0.8)),
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
                  border: Border.all(color: _accent.withValues(alpha: 0.45)),
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
