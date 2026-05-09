import 'package:flutter/material.dart';

enum SkillArchetype {
  chain,
  nova,
  firewall,
  meteor,
  barrage,
  focus,
  bounty,
  frost,
  rupture,
  sentinel,
  mothership,
  snake,
  summon,
}

extension SkillArchetypeExt on SkillArchetype {
  IconData get icon {
    return switch (this) {
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
      SkillArchetype.mothership => Icons.rocket_launch_rounded,
      SkillArchetype.snake => Icons.gesture,
      SkillArchetype.summon => Icons.pets,
    };
  }

  Color get color {
    return switch (this) {
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
      SkillArchetype.mothership => const Color(0xFFCE93D8),
      SkillArchetype.snake => const Color(0xFFFFAB40),
      SkillArchetype.summon => const Color(0xFFFF6D00),
    };
  }

  String get label {
    return name[0].toUpperCase() + name.substring(1);
  }
}

class SkillDefinition {
  const SkillDefinition({
    required this.id,
    required this.title,
    required this.archetype,
  });

  final String id;
  final String title;
  final SkillArchetype archetype;

  static const int maxLevel = 5;

  String descriptionForLevel(int level) {
    return switch (archetype) {
      SkillArchetype.chain => switch (level) {
          1 => 'Stats: +1 chain target (2 total).',
          2 => 'Special: Seek enemies nearest the nexus.',
          3 => 'Stats: +1 chain target (3 total).',
          4 => 'Special: Chains snap 20% faster.',
          _ => 'Big upgrade: +2 chain targets (5 total) and massive arc damage.',
        },
      SkillArchetype.nova => switch (level) {
          1 => 'Stats: Pulse deals 150% base damage.',
          2 => 'Special: Clips enemies outside the ward ring.',
          3 => 'Stats: Damage increases to 210%.',
          4 => 'Special: Pulse frequency increases under pressure.',
          _ => 'Big upgrade: Screen-wide shockwave (300% damage).',
        },
      SkillArchetype.firewall => switch (level) {
          1 => 'Stats: Deals 135% base damage.',
          2 => 'Special: Aligns to threats near the nexus.',
          3 => 'Special: Applies 30% DPS lingering burn.',
          4 => 'Special: Cooldown reduced by 15%.',
          _ => 'Big upgrade: Full-spectrum dragon-gate (235% damage).',
        },
      SkillArchetype.meteor => switch (level) {
          1 => 'Stats: Strike deals 255% base damage.',
          2 => 'Special: Impact splash punishes clustered invaders.',
          3 => 'Stats: Damage increases to 360%.',
          4 => 'Special: Targeting sigils lock 20% faster.',
          _ => 'Big upgrade: Rain of chrome comets (500% damage).',
        },
      SkillArchetype.barrage => switch (level) {
          1 => 'Stats: +6% attack speed.',
          2 => 'Special: Recovery speed increases.',
          3 => 'Stats: +12% total attack speed.',
          4 => 'Special: Rapid slashes hold pressure.',
          _ => 'Big upgrade: +30% attack speed surge.',
        },
      SkillArchetype.focus => switch (level) {
          1 => 'Stats: +8% direct damage.',
          2 => 'Special: Priority targets take sharper cuts.',
          3 => 'Stats: +16% total direct damage.',
          4 => 'Special: Close threats take double damage.',
          _ => 'Big upgrade: +40% major damage surge.',
        },
      SkillArchetype.bounty => switch (level) {
          1 => 'Stats: +8% gold from kills.',
          2 => 'Special: Soul-coded marks improve payout spikes.',
          3 => 'Stats: +16% total gold rewards.',
          4 => 'Special: Floor clears preserve economy momentum.',
          _ => 'Big upgrade: Massive data-soul bounty payouts (+40%).',
        },
      SkillArchetype.frost => switch (level) {
          1 => 'Stats: -2.5% enemy movement speed.',
          2 => 'Special: Chilled enemies stay exposed 20% longer.',
          3 => 'Stats: -7.5% total enemy movement speed.',
          4 => 'Special: Pressure waves lose momentum.',
          _ => 'Big upgrade: Glacial stasis (-15% speed floor).',
        },
      SkillArchetype.rupture => switch (level) {
          1 => 'Stats: +3.5% damage against wounded enemies.',
          2 => 'Special: Execute threshold increases by 5%.',
          3 => 'Stats: +10.5% total execute damage.',
          4 => 'Special: Finishers stabilize breach points.',
          _ => 'Big upgrade: Hexed enemies collapse (+25% damage).',
        },
      SkillArchetype.sentinel => switch (level) {
          1 => 'Stats: 1 auto-seeking blade (43% damage).',
          2 => 'Special: Prioritize enemies near the nexus.',
          3 => 'Stats: +1 blade (2 total).',
          4 => 'Special: Blades strike with 20% more impact.',
          _ => 'Big upgrade: Cloud of steel (4 blades, 75% damage).',
        },
      SkillArchetype.mothership => switch (level) {
          1 => 'Stats: 3 seeker drones (35% damage).',
          2 => 'Special: Improved seeking and flight range.',
          3 => 'Stats: +1 drone (4 total).',
          4 => 'Special: Drones explode on impact (Area damage).',
          _ => 'Big upgrade: Permanent hunter swarm (6 drones).',
        },
      SkillArchetype.snake => switch (level) {
          1 => 'Stats: Fire snake (140% dmg) that chases targets.',
          2 => 'Special: Leaves a lingering damage trail (30% dmg).',
          3 => 'Stats: Speed +20%, trail duration +25%.',
          4 => 'Special: Splits into two smaller serpents.',
          _ => 'Big upgrade: Ouroboros (300% dmg, double trail).',
        },
      SkillArchetype.summon => switch (level) {
          1 => 'Stats: Fire Wolf (185% dmg) pounces on foes.',
          2 => 'Special: Fire Salamander joins (Aura damage).',
          3 => 'Stats: Health +25%, Attack power +20%.',
          4 => 'Special: Fire Phoenix rises (Sweep damage).',
          _ => 'Big upgrade: Great Spirit Menagerie (All 3 active).',
        },
    };
  }
}

final List<SkillDefinition> skillCatalog = List.unmodifiable([
  SkillDefinition(
      id: 'chain', title: 'Neon Katana Chain', archetype: SkillArchetype.chain),
  SkillDefinition(
      id: 'nova', title: 'Mana Reactor Nova', archetype: SkillArchetype.nova),
  SkillDefinition(
      id: 'firewall', title: 'Rune Firewall', archetype: SkillArchetype.firewall),
  SkillDefinition(
      id: 'meteor', title: 'Orbital Spellblade', archetype: SkillArchetype.meteor),
  SkillDefinition(
      id: 'barrage', title: 'Overclocked Iaido', archetype: SkillArchetype.barrage),
  SkillDefinition(
      id: 'focus', title: 'Void Edge Focus', archetype: SkillArchetype.focus),
  SkillDefinition(
      id: 'bounty', title: 'Soulcoin Brand', archetype: SkillArchetype.bounty),
  SkillDefinition(
      id: 'frost', title: 'Cryo Hex Ash', archetype: SkillArchetype.frost),
  SkillDefinition(
      id: 'rupture', title: 'Rupture Hex', archetype: SkillArchetype.rupture),
  SkillDefinition(
      id: 'sentinel',
      title: 'Ghost Blade Sentinel',
      archetype: SkillArchetype.sentinel),
  SkillDefinition(
      id: 'mothership',
      title: 'Tactical Mothership',
      archetype: SkillArchetype.mothership),
  SkillDefinition(
      id: 'snake', title: 'Fire Snake Ignite', archetype: SkillArchetype.snake),
  SkillDefinition(
      id: 'summon', title: 'Fire Wolf Spirit', archetype: SkillArchetype.summon),
]);

SkillDefinition? findSkillById(String id) {
  for (final def in skillCatalog) {
    if (def.id == id) return def;
  }
  return null;
}

class SkillEvolution {
  const SkillEvolution({
    required this.name,
    required this.description,
  });
  final String name;
  final String description;
}

final Map<SkillArchetype, (SkillEvolution, SkillEvolution)> evolutionCatalog = {
  SkillArchetype.chain: (
    const SkillEvolution(
        name: 'Chainstorm', description: 'Stats: +2 jumps, 30% faster snaps.'),
    const SkillEvolution(
        name: 'Tetherblade', description: 'Stats: Massive single target damage.'),
  ),
  SkillArchetype.nova: (
    const SkillEvolution(
        name: 'Pulse Reactor', description: 'Stats: 40% faster pulse frequency.'),
    const SkillEvolution(
        name: 'Singularity', description: 'Special: Novas pull enemies inward.'),
  ),
  SkillArchetype.firewall: (
    const SkillEvolution(
        name: 'Magma Lane', description: 'Stats: Deploys 2 walls, double burn.'),
    const SkillEvolution(
        name: 'Dragon Gate', description: 'Special: Massive width and knockback.'),
  ),
  SkillArchetype.meteor: (
    const SkillEvolution(
        name: 'Starfall', description: 'Stats: 3 extra meteors, faster lock.'),
    const SkillEvolution(
        name: 'Chrome Impact', description: 'Stats: 500% DMG, stuns enemies.'),
  ),
  SkillArchetype.barrage: (
    const SkillEvolution(
        name: 'Overdrive', description: 'Stats: 40% total attack speed surge.'),
    const SkillEvolution(
        name: 'Blade Waltz', description: 'Special: Critical strikes every 3rd hit.'),
  ),
  SkillArchetype.focus: (
    const SkillEvolution(
        name: 'Precision', description: 'Stats: Major direct damage surge (+50%).'),
    const SkillEvolution(
        name: 'Overload', description: 'Special: Splash damage on every hit.'),
  ),
  SkillArchetype.bounty: (
    const SkillEvolution(
        name: 'Soul Harvest', description: 'Stats: +50% gold from all sources.'),
    const SkillEvolution(
        name: 'Jackpot', description: 'Special: Chance for massive elite payout.'),
  ),
  SkillArchetype.frost: (
    const SkillEvolution(
        name: 'Glacier', description: 'Special: Freeze enemies solid for 1s.'),
    const SkillEvolution(
        name: 'Shatter Bloom', description: 'Special: Fold Shatter into base skill.'),
  ),
  SkillArchetype.rupture: (
    const SkillEvolution(
        name: 'Executioner', description: 'Stats: +15% execute threshold.'),
    const SkillEvolution(
        name: 'Vulnerability', description: 'Special: Wounded take 30% more DMG.'),
  ),
  SkillArchetype.sentinel: (
    const SkillEvolution(
        name: 'Cloud of Steel', description: 'Stats: +2 additional blades.'),
    const SkillEvolution(
        name: 'Phantom Edge', description: 'Stats: Blades dash 40% faster.'),
  ),
  SkillArchetype.mothership: (
    const SkillEvolution(
        name: 'Armada', description: 'Stats: +2 additional seeker drones.'),
    const SkillEvolution(
        name: 'Dreadnought', description: 'Stats: One massive 400% DMG drone.'),
  ),
  SkillArchetype.snake: (
    const SkillEvolution(
        name: 'Hydra', description: 'Special: Splits into 4 smaller serpents.'),
    const SkillEvolution(
        name: 'World Eater', description: 'Stats: One massive double-burn snake.'),
  ),
  SkillArchetype.summon: (
    const SkillEvolution(
        name: 'Spirit Horde', description: 'Stats: Summons spawn twice as often.'),
    const SkillEvolution(
        name: 'Avatar', description: 'Stats: One massive spirit with all auras.'),
  ),
};
