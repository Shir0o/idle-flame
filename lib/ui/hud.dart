import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/state/game_state.dart';

class Hud extends StatelessWidget {
  const Hud({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: const [
          Positioned(top: 12, left: 16, child: _FloorBadge()),
          Positioned(top: 12, right: 16, child: _GoldBadge()),
          Positioned(left: 16, right: 16, bottom: 16, child: _UpgradeBar()),
          Positioned(left: 0, right: 0, top: 80, child: _IdleRewardToast()),
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

class _UpgradeBar extends StatelessWidget {
  const _UpgradeBar();

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (_, state, _) => Row(
        children: [
          Expanded(
            child: _UpgradeButton(
              label: 'Damage',
              level: state.damageLevel,
              value: state.heroDamage.toStringAsFixed(0),
              cost: state.damageUpgradeCost,
              canAfford: state.gold >= state.damageUpgradeCost,
              onTap: state.buyDamage,
              accent: const Color(0xFFE53935),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _UpgradeButton(
              label: 'Atk Speed',
              level: state.attackSpeedLevel,
              value: '${state.heroAttacksPerSec.toStringAsFixed(1)}/s',
              cost: state.attackSpeedUpgradeCost,
              canAfford: state.gold >= state.attackSpeedUpgradeCost,
              onTap: state.buyAttackSpeed,
              accent: const Color(0xFF42A5F5),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradeButton extends StatelessWidget {
  const _UpgradeButton({
    required this.label,
    required this.level,
    required this.value,
    required this.cost,
    required this.canAfford,
    required this.onTap,
    required this.accent,
  });

  final String label;
  final int level;
  final String value;
  final int cost;
  final bool canAfford;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canAfford ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: canAfford ? accent : Colors.white.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: canAfford
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Lv $level',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: accent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.attach_money,
                    color: canAfford
                        ? const Color(0xFFFFC107)
                        : Colors.white.withValues(alpha: 0.4),
                    size: 14,
                  ),
                  Text(
                    '$cost',
                    style: TextStyle(
                      color: canAfford
                          ? const Color(0xFFFFC107)
                          : Colors.white.withValues(alpha: 0.4),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
