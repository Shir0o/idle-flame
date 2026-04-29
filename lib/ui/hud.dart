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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 96, 16, 96),
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
                      'Floor ${state.floor}',
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _accent.withValues(alpha: 0.8)),
          ),
          child: Row(
            children: [
              Icon(_icon, color: _accent, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            choice.definition.title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          'Lv ${choice.level}/${choice.maxLevel}',
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
      SkillArchetype.reach => const Color(0xFF40C4FF),
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
      SkillArchetype.reach => Icons.radar,
      SkillArchetype.bounty => Icons.paid,
      SkillArchetype.frost => Icons.ac_unit,
      SkillArchetype.rupture => Icons.flash_on,
    };
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
