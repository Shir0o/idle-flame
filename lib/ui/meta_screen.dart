import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/components/enemy.dart';
import '../game/state/game_state.dart';
import '../game/state/meta_catalog.dart';
import '../game/state/meta_state.dart';
import '../game/state/skill_catalog.dart';
import '../game/state/triad_catalog.dart';
import '../game/state/inflection_catalog.dart';

class MetaScreen extends StatefulWidget {
  const MetaScreen({super.key});

  @override
  State<MetaScreen> createState() => _MetaScreenState();
}

class _MetaScreenState extends State<MetaScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer2<GameState, MetaState>(
      builder: (_, game, meta, _) {
        return ColoredBox(
          color: Colors.black.withValues(alpha: 0.82),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
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
                        else if (_tab == 1)
                          _KeystonesList(meta: meta)
                        else if (_tab == 2)
                          _BestiaryList(meta: meta)
                        else if (_tab == 3)
                          _CrucibleList(meta: meta)
                        else
                          _CodexList(meta: meta),
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
        const Icon(
          Icons.local_fire_department,
          color: Color(0xFFFF8A00),
          size: 32,
        ),
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
          'Floor ${game.floor} · ${game.runKills} kills · ${game.gold} gold',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        if (game.skillLevels.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: game.skillLevels.keys.map((skillId) {
              final def = findSkillById(skillId);
              if (def == null) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: def.archetype.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: def.archetype.color.withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(
                  def.archetype.icon,
                  color: def.archetype.color,
                  size: 14,
                ),
              );
            }).toList(),
          ),
        ],
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
              const Icon(
                Icons.local_fire_department,
                color: Color(0xFFFF8A00),
                size: 18,
              ),
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _tab('Boons', 0),
        _tab('Keystones', 1),
        _tab('Bestiary', 2),
        _tab('Crucibles', 3),
        _tab('Codex', 4),
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
          width: 80,
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
              fontSize: 12,
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
                        horizontal: 6,
                        vertical: 2,
                      ),
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

class _BestiaryList extends StatelessWidget {
  const _BestiaryList({required this.meta});
  final MetaState meta;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CodexHeader(title: 'ENEMY BESTIARY'),
        _CodexGrid(
          items: EnemyType.values
              .where((t) => t != EnemyType.watcherAdd)
              .map((t) => _CodexItem(
                    id: 'enemy:${t.name}',
                    name: _enemyDisplayName(t),
                    icon: _isBoss(t) ? Icons.shield_moon : Icons.coronavirus,
                    color: _isBoss(t)
                        ? const Color(0xFFFFD166)
                        : const Color(0xFFFF8A80),
                    discovered: meta.discoveredIds.contains('enemy:${t.name}'),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _CrucibleList extends StatelessWidget {
  const _CrucibleList({required this.meta});
  final MetaState meta;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CodexHeader(title: 'CRUCIBLE EVENTS'),
        _CodexGrid(
          items: CrucibleEvent.values
              .map((c) => _CodexItem(
                    id: 'crucible:${c.name}',
                    name: _crucibleDisplayName(c),
                    icon: Icons.local_fire_department,
                    color: const Color(0xFFFF5252),
                    discovered: meta.discoveredIds.contains('crucible:${c.name}'),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _CodexList extends StatelessWidget {
  const _CodexList({required this.meta});
  final MetaState meta;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NEXUS MEMORY-CORE',
          style: TextStyle(
            color: Color(0xFFFF8A00),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        // Skills
        const _CodexHeader(title: 'ARCHETYPES'),
        _CodexGrid(
          items: skillCatalog.map((s) => _CodexItem(
            id: s.id,
            name: s.title,
            icon: s.archetype.icon,
            color: s.archetype.color,
            discovered: meta.discoveredIds.contains(s.id),
          )).toList(),
        ),
        const SizedBox(height: 16),
        // Fusions
        const _CodexHeader(title: 'FUSIONS'),
        _CodexGrid(
          items: fusionCatalog.map((f) => _CodexItem(
            id: f.id,
            name: f.name,
            icon: Icons.auto_awesome,
            color: Colors.amber,
            discovered: meta.discoveredIds.contains(f.id),
          )).toList(),
        ),
        const SizedBox(height: 16),
        // Triads
        const _CodexHeader(title: 'TRIADS'),
        _CodexGrid(
          items: triadCatalog.map((t) => _CodexItem(
            id: 'triad:${t.id}',
            name: t.name,
            icon: Icons.hub,
            color: const Color(0xFF64FFDA),
            discovered: meta.discoveredIds.contains('triad:${t.id}'),
          )).toList(),
        ),
        const SizedBox(height: 16),
        // Inflections
        const _CodexHeader(title: 'INFLECTIONS'),
        _CodexGrid(
          items: inflectionCatalog.map((i) => _CodexItem(
            id: 'inflection:${i.id}',
            name: i.name,
            icon: Icons.tune,
            color: i.rarity == InflectionRarity.rare ? Colors.amber : Colors.white60,
            discovered: meta.discoveredIds.contains('inflection:${i.id}'),
          )).toList(),
        ),
        const SizedBox(height: 16),
        // Evolutions
        const _CodexHeader(title: 'EVOLUTIONS'),
        _CodexGrid(
          items: _allEvolutions().map((e) => _CodexItem(
            id: e.id,
            name: e.name,
            icon: Icons.keyboard_double_arrow_up,
            color: Colors.white,
            discovered: meta.discoveredIds.contains(e.id),
          )).toList(),
        ),
      ],
    );
  }

  List<({String id, String name})> _allEvolutions() {
    final list = <({String id, String name})>[];
    evolutionCatalog.forEach((archetype, evos) {
      list.add((id: '${archetype.name}:1', name: evos.$1.name));
      list.add((id: '${archetype.name}:2', name: evos.$2.name));
    });
    return list;
  }
}

bool _isBoss(EnemyType t) {
  return t == EnemyType.watcher ||
      t == EnemyType.glassSovereign ||
      t == EnemyType.hivefather ||
      t == EnemyType.cipherTwin ||
      t == EnemyType.architect;
}

String _enemyDisplayName(EnemyType t) {
  return switch (t) {
    EnemyType.basic => 'Basic',
    EnemyType.fast => 'Fast',
    EnemyType.tank => 'Tank',
    EnemyType.elite => 'Elite',
    EnemyType.aegis => 'Aegis',
    EnemyType.splinter => 'Splinter',
    EnemyType.sigilBearer => 'Sigil-Bearer',
    EnemyType.wraith => 'Wraith',
    EnemyType.cinderDrinker => 'Cinder-Drinker',
    EnemyType.sutraBound => 'Sutra-Bound',
    EnemyType.watcher => 'The Watcher',
    EnemyType.glassSovereign => 'Glass Sovereign',
    EnemyType.hivefather => 'Hivefather',
    EnemyType.cipherTwin => 'Cipher Twin',
    EnemyType.architect => 'The Architect',
    EnemyType.watcherAdd => 'Watcher Drone',
  };
}

String _crucibleDisplayName(CrucibleEvent e) {
  return switch (e) {
    CrucibleEvent.pressure => 'Pressure',
    CrucibleEvent.hivebreak => 'Hivebreak',
    CrucibleEvent.sigilStorm => 'Sigil Storm',
    CrucibleEvent.eclipse => 'Eclipse',
    CrucibleEvent.quiet => 'Quiet',
    CrucibleEvent.fractalPack => 'Fractal Pack',
    CrucibleEvent.lastCant => 'Last Cant',
    CrucibleEvent.bossEcho => 'Boss Echo',
  };
}

class _CodexHeader extends StatelessWidget {
  const _CodexHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CodexGrid extends StatelessWidget {
  const _CodexGrid({required this.items});
  final List<_CodexItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items,
    );
  }
}

class _CodexItem extends StatelessWidget {
  const _CodexItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.discovered,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool discovered;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: discovered ? name : '???',
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: discovered 
            ? color.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: discovered 
              ? color.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Icon(
          icon,
          color: discovered ? color : Colors.white.withValues(alpha: 0.1),
          size: 20,
        ),
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
                const Icon(
                  Icons.local_fire_department,
                  color: Color(0xFFFF8A00),
                  size: 13,
                ),
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
