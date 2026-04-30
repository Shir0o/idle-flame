import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/state/game_state.dart';
import '../game/state/meta_catalog.dart';
import '../game/state/meta_state.dart';

class MetaShopScreen extends StatefulWidget {
  const MetaShopScreen({super.key});

  @override
  State<MetaShopScreen> createState() => _MetaShopScreenState();
}

class _MetaShopScreenState extends State<MetaShopScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer2<GameState, MetaState>(
      builder: (_, game, meta, _) {
        return ColoredBox(
          color: Colors.black.withValues(alpha: 0.82),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFFF8A00).withValues(alpha: 0.6),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Header(game: game, meta: meta),
                        const SizedBox(height: 14),
                        _TabBar(
                          current: _tab,
                          onChanged: (v) => setState(() => _tab = v),
                        ),
                        const SizedBox(height: 12),
                        if (_tab == 0)
                          _BoonsList(meta: meta)
                        else
                          _KeystonesList(meta: meta),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFF5252),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              meta.clearLastEmbersEarned();
                              game.resetProgress();
                            },
                            icon: const Icon(Icons.restart_alt),
                            label: const Text('Retry Run'),
                          ),
                        ),
                      ],
                    ),
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

class _Header extends StatelessWidget {
  const _Header({required this.game, required this.meta});
  final GameState game;
  final MetaState meta;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.local_fire_department,
            color: Color(0xFFFF8A00), size: 32),
        const SizedBox(height: 6),
        const Text(
          'Nexus Breached',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Floor ${game.floor} · ${game.totalKills} kills · ${game.gold} gold',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFF8A00).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFFF8A00).withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_fire_department,
                  color: Color(0xFFFF8A00), size: 18),
              const SizedBox(width: 6),
              Text(
                meta.lastEmbersEarned > 0
                    ? '+${meta.lastEmbersEarned} Embers earned · ${meta.embers} total'
                    : '${meta.embers} Embers',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.current, required this.onChanged});
  final int current;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _tab('Boons', 0)),
        const SizedBox(width: 8),
        Expanded(child: _tab('Keystones', 1)),
      ],
    );
  }

  Widget _tab(String label, int index) {
    final active = current == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(index),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFFFF8A00).withValues(alpha: 0.16)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: active
                  ? const Color(0xFFFF8A00).withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active
                  ? const Color(0xFFFF8A00)
                  : Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _BoonsList extends StatelessWidget {
  const _BoonsList({required this.meta});
  final MetaState meta;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final def in metaUpgradeCatalog) ...[
          _BoonRow(def: def, meta: meta),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _BoonRow extends StatelessWidget {
  const _BoonRow({required this.def, required this.meta});
  final MetaUpgradeDef def;
  final MetaState meta;

  @override
  Widget build(BuildContext context) {
    final tier = meta.upgradeTier(def.id);
    final maxed = tier >= def.maxTier;
    final canBuy = !maxed && meta.canPurchaseUpgrade(def);
    final nextCost = maxed ? 0 : def.costForTier(tier + 1);
    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        def.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (def.maxTier > 1)
                      Text(
                        '$tier / ${def.maxTier}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    else if (tier > 0)
                      const _OwnedTag(),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  def.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _BuyButton(
            label: maxed ? 'Maxed' : '$nextCost',
            enabled: canBuy,
            onTap: canBuy ? () => meta.purchaseUpgrade(def) : null,
          ),
        ],
      ),
    );
  }
}

class _KeystonesList extends StatelessWidget {
  const _KeystonesList({required this.meta});
  final MetaState meta;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final def in keystoneCatalog) ...[
          _KeystoneRow(def: def, meta: meta),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _KeystoneRow extends StatelessWidget {
  const _KeystoneRow({required this.def, required this.meta});
  final KeystoneDef def;
  final MetaState meta;

  @override
  Widget build(BuildContext context) {
    final owned = meta.hasKeystone(def.id);
    final canBuy = meta.canPurchaseKeystone(def);
    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF64FFDA).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        archetypeLabel(def.archetype),
                        style: const TextStyle(
                          color: Color(0xFF64FFDA),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        def.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (owned) const _OwnedTag(),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  def.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _BuyButton(
            label: owned ? 'Owned' : '${def.cost}',
            enabled: canBuy,
            onTap: canBuy ? () => meta.purchaseKeystone(def) : null,
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: child,
    );
  }
}

class _OwnedTag extends StatelessWidget {
  const _OwnedTag();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF64FFDA).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Owned',
        style: TextStyle(
          color: Color(0xFF64FFDA),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BuyButton extends StatelessWidget {
  const _BuyButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? const Color(0xFFFF8A00)
        : Colors.white.withValues(alpha: 0.25);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.55)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (enabled)
                const Icon(Icons.local_fire_department,
                    color: Color(0xFFFF8A00), size: 13),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
