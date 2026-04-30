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
        1 => 'Stat: blade-cast arcs jump to another target.',
        2 => 'Special: chained slashes seek enemies nearest the nexus.',
        3 => 'Stat: arc range expands across wider neon lanes.',
        4 => 'Special: chains snap faster through clustered drones.',
        _ => 'Big upgrade: the spellblade cuts through whole packs.',
      },
      SkillArchetype.nova => switch (level) {
        1 => 'Stat: unlock a mana-reactor pulse around the nexus.',
        2 => 'Special: the pulse clips enemies outside the ward ring.',
        3 => 'Stat: pulse radius and arcane voltage increase.',
        4 => 'Special: the reactor surges harder under pressure.',
        _ => 'Big upgrade: nova becomes a city-block shockwave.',
      },
      SkillArchetype.firewall => switch (level) {
        1 => 'Stat: project a burning rune-wall across the lane.',
        2 => 'Special: the wall aligns to threats near the nexus.',
        3 => 'Stat: wall width and glyph burn increase.',
        4 => 'Special: the ward refreshes better against dense waves.',
        _ => 'Big upgrade: the lane becomes a full-spectrum ward gate.',
      },
      SkillArchetype.meteor => switch (level) {
        1 => 'Stat: call an orbital spellblade onto the deepest enemy.',
        2 => 'Special: impact splash punishes clustered invaders.',
        3 => 'Stat: blast radius and falling-blade damage increase.',
        4 => 'Special: targeting sigils lock faster onto priority threats.',
        _ => 'Big upgrade: the strike becomes a rain of chrome comets.',
      },
      SkillArchetype.barrage => switch (level) {
        1 => 'Stat: attack cadence improves.',
        2 => 'Special: the auto-ward recovers faster after pauses.',
        3 => 'Stat: cadence improves again.',
        4 => 'Special: rapid slashes hold pressure on crowded lanes.',
        _ => 'Big upgrade: the nexus enters overclocked sword-chant.',
      },
      SkillArchetype.focus => switch (level) {
        1 => 'Stat: direct spellblade damage increases.',
        2 => 'Special: priority targets take sharper mana cuts.',
        3 => 'Stat: direct damage increases again.',
        4 => 'Special: close threats are punished by overloaded wards.',
        _ => 'Big upgrade: all blade magic gains a major damage surge.',
      },
      SkillArchetype.bounty => switch (level) {
        1 => 'Stat: kill rewards increase.',
        2 => 'Special: soul-coded marks improve payout spikes.',
        3 => 'Stat: kill rewards increase again.',
        4 => 'Special: floor clears preserve more economy momentum.',
        _ => 'Big upgrade: data-soul bounties pay out massively.',
      },
      SkillArchetype.frost => switch (level) {
        1 => 'Stat: enemies move slower under cryo-hex.',
        2 => 'Special: chilled enemies stay exposed longer.',
        3 => 'Stat: enemy movement slows again.',
        4 => 'Special: pressure waves lose momentum near the nexus.',
        _ => 'Big upgrade: the lane is locked in glacial stasis.',
      },
      SkillArchetype.rupture => switch (level) {
        1 => 'Stat: wounded enemies take more effective damage.',
        2 => 'Special: low-health armor is easier to sever.',
        3 => 'Stat: execute pressure increases.',
        4 => 'Special: finishers stabilize crowded breach points.',
        _ => 'Big upgrade: hexed enemies collapse under final cuts.',
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
