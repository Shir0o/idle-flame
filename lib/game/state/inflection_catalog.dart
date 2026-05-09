import 'skill_catalog.dart';

enum InflectionRarity { common, rare }

class InflectionDefinition {
  const InflectionDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.archetype,
    this.rarity = InflectionRarity.common,
  });

  final String id;
  final String name;
  final String description;
  final SkillArchetype archetype;
  final InflectionRarity rarity;
}

final List<InflectionDefinition> inflectionCatalog = List.unmodifiable([
  // CHAIN
  InflectionDefinition(
    id: 'chain_volatile',
    name: 'Volatile',
    description: 'Final jump in a chain crits.',
    archetype: SkillArchetype.chain,
  ),
  InflectionDefinition(
    id: 'chain_greedy',
    name: 'Greedy',
    description: 'Gold drops scale with chain length.',
    archetype: SkillArchetype.chain,
  ),
  InflectionDefinition(
    id: 'chain_echoblade',
    name: 'Echoblade',
    description: 'First jump repeats once.',
    archetype: SkillArchetype.chain,
  ),
  InflectionDefinition(
    id: 'chain_tetherbias',
    name: 'Tetherbias',
    description: '-1 jump count, +50% damage per jump.',
    archetype: SkillArchetype.chain,
  ),

  // NOVA
  InflectionDefinition(
    id: 'nova_aftershock',
    name: 'Aftershock',
    description: 'Novas pulse a second time for 40% damage.',
    archetype: SkillArchetype.nova,
  ),
  InflectionDefinition(
    id: 'nova_reactive',
    name: 'Reactive',
    description: 'Nova radius increases when Nexus HP is low.',
    archetype: SkillArchetype.nova,
  ),
  InflectionDefinition(
    id: 'nova_implosion',
    name: 'Implosion',
    description: 'Pulls enemies toward the center.',
    archetype: SkillArchetype.nova,
  ),
  InflectionDefinition(
    id: 'nova_burning',
    name: 'Burning',
    description: 'Applies a 2s burn to enemies hit.',
    archetype: SkillArchetype.nova,
  ),

  // FIREWALL
  InflectionDefinition(
    id: 'firewall_scorch',
    name: 'Scorch',
    description: 'Increases burn damage by 50%.',
    archetype: SkillArchetype.firewall,
  ),
  InflectionDefinition(
    id: 'firewall_ward',
    name: 'Ward',
    description: 'Enemies passing through are slowed by 40%.',
    archetype: SkillArchetype.firewall,
  ),
  InflectionDefinition(
    id: 'firewall_flicker',
    name: 'Flicker',
    description: 'Firewall has a 20% chance to not trigger cooldown.',
    archetype: SkillArchetype.firewall,
  ),
  InflectionDefinition(
    id: 'firewall_dense',
    name: 'Dense',
    description: 'Firewall width reduced by 25%, damage increased by 40%.',
    archetype: SkillArchetype.firewall,
  ),

  // METEOR
  InflectionDefinition(
    id: 'meteor_cluster',
    name: 'Cluster',
    description: 'Spawns 2 smaller meteors on impact.',
    archetype: SkillArchetype.meteor,
  ),
  InflectionDefinition(
    id: 'meteor_crater',
    name: 'Crater',
    description: 'Leaves a slowing field for 3s.',
    archetype: SkillArchetype.meteor,
  ),
  InflectionDefinition(
    id: 'meteor_shrapnel',
    name: 'Shrapnel',
    description: 'Impact fires 8 needles in all directions.',
    archetype: SkillArchetype.meteor,
  ),
  InflectionDefinition(
    id: 'meteor_precise',
    name: 'Precise',
    description: 'Impact damage +50% against Elite enemies.',
    archetype: SkillArchetype.meteor,
  ),

  // BARRAGE
  InflectionDefinition(
    id: 'barrage_haste',
    name: 'Haste',
    description: 'Attack speed +10%.',
    archetype: SkillArchetype.barrage,
  ),
  InflectionDefinition(
    id: 'barrage_momentum',
    name: 'Momentum',
    description: 'Each attack builds +1% speed (max 20%) until hit.',
    archetype: SkillArchetype.barrage,
  ),
  InflectionDefinition(
    id: 'barrage_wind',
    name: 'Wind-cut',
    description: 'Attacks fire a small air wave forward.',
    archetype: SkillArchetype.barrage,
  ),
  InflectionDefinition(
    id: 'barrage_focus',
    name: 'Focus-sync',
    description: 'Attacks have a 5% chance to trigger Focus.',
    archetype: SkillArchetype.barrage,
  ),

  // FOCUS
  InflectionDefinition(
    id: 'focus_deadly',
    name: 'Deadly',
    description: 'Crit damage +25%.',
    archetype: SkillArchetype.focus,
  ),
  InflectionDefinition(
    id: 'focus_calm',
    name: 'Calm',
    description: 'Crit chance +5%.',
    archetype: SkillArchetype.focus,
  ),
  InflectionDefinition(
    id: 'focus_insight',
    name: 'Insight',
    description: 'Killing an enemy with a crit restores 2% Nexus HP.',
    archetype: SkillArchetype.focus,
  ),
  InflectionDefinition(
    id: 'focus_sharp',
    name: 'Sharp',
    description: 'Ignore 20% of enemy armor.',
    archetype: SkillArchetype.focus,
  ),

  // BOUNTY
  InflectionDefinition(
    id: 'bounty_invest',
    name: 'Investment',
    description: 'Gain +1 gold per floor clear.',
    archetype: SkillArchetype.bounty,
  ),
  InflectionDefinition(
    id: 'bounty_overflow',
    name: 'Overflow',
    description: 'Excess gold increases damage slightly.',
    archetype: SkillArchetype.bounty,
  ),
  InflectionDefinition(
    id: 'bounty_lucky',
    name: 'Lucky',
    description: '10% chance for double gold from any source.',
    archetype: SkillArchetype.bounty,
  ),
  InflectionDefinition(
    id: 'bounty_collector',
    name: 'Collector',
    description: 'Gold attracts from further away.',
    archetype: SkillArchetype.bounty,
  ),

  // FROST
  InflectionDefinition(
    id: 'frost_brittle',
    name: 'Brittle',
    description: 'Chilled enemies take +20% from Edge skills.',
    archetype: SkillArchetype.frost,
  ),
  InflectionDefinition(
    id: 'frost_lingering',
    name: 'Lingering',
    description: 'Chill duration doubles, slow halved.',
    archetype: SkillArchetype.frost,
  ),
  InflectionDefinition(
    id: 'frost_bite',
    name: 'Frostbite',
    description: 'Chilled enemies tick for tiny damage.',
    archetype: SkillArchetype.frost,
  ),
  InflectionDefinition(
    id: 'frost_snowblind',
    name: 'Snowblind',
    description: 'Chilled enemies miss attacks 10% of the time.',
    archetype: SkillArchetype.frost,
  ),

  // RUPTURE
  InflectionDefinition(
    id: 'rupture_vulnerable',
    name: 'Vulnerable',
    description: 'Marked enemies take +15% more damage.',
    archetype: SkillArchetype.rupture,
  ),
  InflectionDefinition(
    id: 'rupture_chain',
    name: 'Chain-react',
    description: 'Executions trigger a small Rupture explosion.',
    archetype: SkillArchetype.rupture,
  ),
  InflectionDefinition(
    id: 'rupture_deep',
    name: 'Deep-cut',
    description: 'Execute threshold +5%.',
    archetype: SkillArchetype.rupture,
  ),
  InflectionDefinition(
    id: 'rupture_bleed',
    name: 'Bleed',
    description: 'Marked enemies lose 1% HP per second.',
    archetype: SkillArchetype.rupture,
  ),

  // SENTINEL
  InflectionDefinition(
    id: 'sentinel_swift',
    name: 'Swift',
    description: 'Blade dash speed +25%.',
    archetype: SkillArchetype.sentinel,
  ),
  InflectionDefinition(
    id: 'sentinel_echo',
    name: 'Echo-strike',
    description: 'Blades have a 15% chance to hit twice.',
    archetype: SkillArchetype.sentinel,
  ),
  InflectionDefinition(
    id: 'sentinel_guard',
    name: 'Guardian',
    description: 'Blades prioritize enemies closest to the Nexus.',
    archetype: SkillArchetype.sentinel,
  ),
  InflectionDefinition(
    id: 'sentinel_twin',
    name: 'Twin-link',
    description: 'Blades share a tether that damages enemies between them.',
    archetype: SkillArchetype.sentinel,
  ),

  // MOTHERSHIP
  InflectionDefinition(
    id: 'mothership_carrier',
    name: 'Carrier-class',
    description: '-1 drone count, drones do double damage.',
    archetype: SkillArchetype.mothership,
  ),
  InflectionDefinition(
    id: 'mothership_swarm',
    name: 'Swarm-class',
    description: '+2 drones, drones do 60% damage each.',
    archetype: SkillArchetype.mothership,
  ),
  InflectionDefinition(
    id: 'mothership_flare',
    name: 'Flare',
    description: 'Drones explode on death for AoE.',
    archetype: SkillArchetype.mothership,
  ),
  InflectionDefinition(
    id: 'mothership_link',
    name: 'Network-link',
    description: 'Drones share kill-credit for streak stacks.',
    archetype: SkillArchetype.mothership,
  ),

  // SNAKE
  InflectionDefinition(
    id: 'snake_toxin',
    name: 'Toxic-trail',
    description: 'Trail applies 30% slow.',
    archetype: SkillArchetype.snake,
  ),
  InflectionDefinition(
    id: 'snake_vibrant',
    name: 'Vibrant',
    description: 'Snake speed +30%.',
    archetype: SkillArchetype.snake,
  ),
  InflectionDefinition(
    id: 'snake_coils',
    name: 'Tight-coils',
    description: 'Snake length halved, damage doubled.',
    archetype: SkillArchetype.snake,
  ),
  InflectionDefinition(
    id: 'snake_venom',
    name: 'Venom',
    description: 'Hits increase damage taken by 10% (stacks).',
    archetype: SkillArchetype.snake,
  ),

  // SUMMON
  InflectionDefinition(
    id: 'summon_fury',
    name: 'Furious',
    description: 'Summons attack 20% faster.',
    archetype: SkillArchetype.summon,
  ),
  InflectionDefinition(
    id: 'summon_vital',
    name: 'Vitality',
    description: 'Summons have +50% health.',
    archetype: SkillArchetype.summon,
  ),
  InflectionDefinition(
    id: 'summon_bound',
    name: 'Soul-bound',
    description: '10% of damage taken is shared with summons.',
    archetype: SkillArchetype.summon,
  ),
  InflectionDefinition(
    id: 'summon_nova',
    name: 'Nova-touch',
    description: 'Summons pulse with a mini-nova on spawn.',
    archetype: SkillArchetype.summon,
  ),
]);
