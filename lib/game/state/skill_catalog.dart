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
        1 => 'Stat: slashes jump to +1 target (2 total).',
        2 => 'Special: chained slashes seek enemies nearest the nexus.',
        3 => 'Stat: arc potency and jump efficiency increase.',
        4 => 'Special: chains snap faster through clustered drones.',
        _ => 'Big upgrade: the spellblade cuts through whole packs.',
      },
      SkillArchetype.nova => switch (level) {
        1 => 'Stat: mana-reactor pulse deals 150% base damage.',
        2 => 'Special: the pulse clips enemies outside the ward ring.',
        3 => 'Stat: arcane voltage and surge pressure increase.',
        4 => 'Special: the reactor surges harder under pressure.',
        _ => 'Big upgrade: nova becomes a city-block shockwave.',
      },
      SkillArchetype.firewall => switch (level) {
        1 => 'Stat: burning rune-wall deals 135% base damage.',
        2 => 'Special: the wall aligns to threats near the nexus.',
        3 => 'Special: glyph burn applies a lingering DOT to enemies.',
        4 => 'Special: ward intensity and cooldown-refresh improve.',
        _ => 'Big upgrade: the lane becomes a full-spectrum dragon-gate.',
      },
      SkillArchetype.meteor => switch (level) {
        1 => 'Stat: falling-blade strike deals 255% base damage.',
        2 => 'Special: impact splash punishes clustered invaders.',
        3 => 'Stat: falling-blade damage and impact force increase.',
        4 => 'Special: targeting sigils lock faster onto priority threats.',
        _ => 'Big upgrade: the strike becomes a rain of chrome comets.',
      },
      SkillArchetype.barrage => switch (level) {
        1 => 'Stat: attack speed increases by 6%.',
        2 => 'Special: the auto-ward recovers faster after pauses.',
        3 => 'Stat: cadence improves again.',
        4 => 'Special: rapid slashes hold pressure on crowded lanes.',
        _ => 'Big upgrade: the nexus enters overclocked sword-chant.',
      },
      SkillArchetype.focus => switch (level) {
        1 => 'Stat: direct damage increases by 8%.',
        2 => 'Special: priority targets take sharper mana cuts.',
        3 => 'Stat: direct damage increases again.',
        4 => 'Special: close threats are punished by overloaded wards.',
        _ => 'Big upgrade: all blade magic gains a major damage surge.',
      },
      SkillArchetype.bounty => switch (level) {
        1 => 'Stat: gold from kills increases by 8%.',
        2 => 'Special: soul-coded marks improve payout spikes.',
        3 => 'Stat: kill rewards increase again.',
        4 => 'Special: floor clears preserve more economy momentum.',
        _ => 'Big upgrade: data-soul bounties pay out massively.',
      },
      SkillArchetype.frost => switch (level) {
        1 => 'Stat: enemies move 2.5% slower under cryo-hex.',
        2 => 'Special: chilled enemies stay exposed longer.',
        3 => 'Stat: enemy movement slows again.',
        4 => 'Special: pressure waves lose momentum near the nexus.',
        _ => 'Big upgrade: the lane is locked in glacial stasis.',
      },
      SkillArchetype.rupture => switch (level) {
        1 => 'Stat: damage against wounded enemies increases by 3.5%.',
        2 => 'Special: low-health armor is easier to sever.',
        3 => 'Stat: execute pressure increases.',
        4 => 'Special: finishers stabilize crowded breach points.',
        _ => 'Big upgrade: hexed enemies collapse under final cuts.',
      },
      SkillArchetype.sentinel => switch (level) {
        1 => 'Stat: summon 1 auto-seeking ghost blade (43% damage).',
        2 => 'Special: blades prioritize enemies near the nexus.',
        3 => 'Stat: additional blades join the orbital swarm.',
        4 => 'Special: blades strike with increased impact force.',
        _ => 'Big upgrade: the swarm becomes a literal cloud of steel.',
      },
      SkillArchetype.mothership => switch (level) {
        1 => 'Stat: deploy a hub with 3 seeker drones (35% damage).',
        2 => 'Special: drones gain seeking agility and longer flight range.',
        3 => 'Stat: mothership launch bays expand, increasing drone count.',
        4 => 'Special: drones explode on impact, dealing area damage.',
        _ => 'Big upgrade: the fleet becomes a permanent swarm of hunters.',
      },
      SkillArchetype.snake => switch (level) {
        1 => 'Stat: ignite a fire snake (140% dmg) that chases targets.',
        2 => 'Special: the snake leaves a lingering damage trail.',
        3 => 'Stat: snake speed and trail duration increase.',
        4 => 'Special: the snake splits into two smaller serpents.',
        _ => 'Big upgrade: the Ouroboros consumes entire waves.',
      },
      SkillArchetype.summon => switch (level) {
        1 => 'Stat: summon a Fire Wolf (185% dmg) to pounce on foes.',
        2 => 'Special: Fire Salamander joins, scorching nearby foes.',
        3 => 'Stat: summon health and attack power increase.',
        4 => 'Special: Fire Phoenix rises, sweeping the field in flames.',
        _ => 'Big upgrade: the Great Spirit Menagerie is unleashed.',
      },
    };
  }
}

final List<SkillDefinition> skillCatalog = List.unmodifiable([
  ..._skills(SkillArchetype.chain, [
    'Neon Katana Chain',
    'Monowire Arcana',
    'Chrome Saber Link',
    'Runeblade Relay',
    'Plasma Wakizashi',
    'Glyphwire Cleave',
    'Holo Edge Jump',
    'Circuit Scimitar',
    'Arc Lash Protocol',
    'Prism Blade Thread',
  ]),
  ..._skills(SkillArchetype.nova, [
    'Mana Reactor Nova',
    'Neon Shrine Pulse',
    'Arcane EMP Bloom',
    'Chrome Halo Burst',
    'Sigil Core Detonation',
    'Magenta Ward Surge',
    'Bluefire Shock Ring',
    'Cyber Lotus Pulse',
    'Hex Reactor Wave',
    'Astral Battery Flare',
  ]),
  ..._skills(SkillArchetype.firewall, [
    'Rune Firewall',
    'Dragon Gate Barrier',
    'Neon Torii Ward',
    'Hardlight Sigil Wall',
    'Plasma Glyph Fence',
    'Chrome Pyre Rampart',
    'Blade Ward Lane',
    'Hexgrid Barricade',
    'Firewall Sutra',
    'Circuit Dragon Wall',
    'Void Ember Grate',
    'Phoenix Sigil Wall',
    'Cyber Shinto Gate',
    'Ionized Rune Fence',
    'Astral Dragon Rampart',
  ]),
  ..._skills(SkillArchetype.meteor, [
    'Orbital Spellblade',
    'Chrome Comet Rite',
    'Satellite Oni Fang',
    'Falling Rune Spear',
    'Starfall Katana',
    'Meteor Hex Brand',
    'Skyblade Invocation',
    'Railgun Familiar',
    'Moonsteel Impact',
    'Astral Bombardment',
  ]),
  ..._skills(SkillArchetype.barrage, [
    'Overclocked Iaido',
    'Quickdraw Hex',
    'Blade Drone Flurry',
    'Rapid Mantra Cut',
    'Neon Duelist Loop',
    'Sparkstep Barrage',
    'Chrome Tempo',
    'Auto-Saber Chant',
    'Reflex Rune Engine',
    'Zero-Lag Slash',
  ]),
  ..._skills(SkillArchetype.focus, [
    'Void Edge Focus',
    'Dragonblood Compiler',
    'Mana Core Overdrive',
    'White-Hot Monoblade',
    'Pressure Hex Cut',
    'Deep Rune Ignition',
    'Searing Logic Point',
    'Needleblade Cant',
    'Core Shrine Pressure',
    'Bright Edge Algorithm',
  ]),
  ..._skills(SkillArchetype.bounty, [
    'Soulcoin Brand',
    'Credstick Hex',
    'Treasure Daemon',
    'Minted Mana Spark',
    'Bounty Oni Seal',
    'Taxing Curse',
    'Rich Data Cinder',
    'Spoils Sigil',
    'Vault Familiar',
    'Coin Lotus Bloom',
  ]),
  ..._skills(SkillArchetype.frost, [
    'Cryo Hex Ash',
    'Cold Neon Cinder',
    'Blue Lotus Chill',
    'Rimewire Spark',
    'Winterblade Wick',
    'Slow-Burn Glitch',
    'Frozen Flare Rune',
    'Ashen Sleet Program',
    'Cold Front Charm',
    'Ice Lantern Familiar',
  ]),
  ..._skills(SkillArchetype.rupture, [
    'Rupture Hex',
    'Crackling Wound Code',
    'Splinterblade Heat',
    'Breakpoint Curse',
    'Scarlet Edge Brand',
    'Weakspot Mandala',
    'Final Spark Cut',
    'Shatter Seal',
    'Execution Rune',
    'Last Light Sever',
  ]),
  ..._skills(SkillArchetype.sentinel, [
    'Ghost Blade Sentinel',
    'Spirit Needle Drone',
    'Void Dagger Swarm',
    'Phase Kunai Orbit',
    'Astral Stiletto',
    'Neon Shard Seeker',
    'Chrome Talon Dart',
    'Mana Dart Volley',
    'Echo Blade Phantom',
    'Spectral Spike Array',
  ]),
  ..._skills(SkillArchetype.mothership, [
    'Tactical Mothership',
    'Carrier Command',
    'Drone Swarm Hub',
    'Fleet Coordinator',
    'Void Wing Station',
    'Hive Mind Relay',
    'Orbital Hangar',
    'Strike Wing Core',
    'Battle Carrier',
    'Fleet Nexus',
  ]),
  ..._skills(SkillArchetype.snake, [
    'Fire Snake Ignite',
    'Ouroboros Trail',
    'Cinder Serpent',
    'Magma Cobra',
    'Neon Viper',
    'Solar Boa',
    'Plasma Python',
    'Ember Krait',
    'Volcanic Adder',
    'Abyssal Naga',
  ]),
  ..._skills(SkillArchetype.summon, [
    'Fire Wolf Spirit',
    'Salamander Breath',
    'Phoenix Rebirth',
    'Spirit Menagerie',
    'Inferno Hounds',
    'Sun-Basking Lizard',
    'Skyfire Raptor',
    'Molten Beastheart',
    'Astral Chimera',
    'Elemental Avatar',
  ]),
]);

List<SkillDefinition> _skills(SkillArchetype archetype, List<String> titles) {
  return [
    for (final title in titles)
      SkillDefinition(id: _slug(title), title: title, archetype: archetype),
  ];
}

String _slug(String title) {
  return title
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+$'), '');
}
