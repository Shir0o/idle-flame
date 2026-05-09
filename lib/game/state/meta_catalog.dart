import 'skill_catalog.dart';

class MetaUpgradeDef {
  const MetaUpgradeDef({
    required this.id,
    required this.title,
    required this.description,
    required this.tierCosts,
  });

  final String id;
  final String title;
  final String description;
  final List<int> tierCosts;

  int get maxTier => tierCosts.length;
  int costForTier(int tier) => tierCosts[tier - 1];
}

class KeystoneDef {
  const KeystoneDef({
    required this.id,
    required this.archetype,
    required this.title,
    required this.description,
    required this.cost,
  });

  final String id;
  final SkillArchetype archetype;
  final String title;
  final String description;
  final int cost;
}

const List<MetaUpgradeDef> metaUpgradeCatalog = [
  MetaUpgradeDef(
    id: 'wider_pick',
    title: 'Wider Pick',
    description: 'See 4 upgrade choices on level-up instead of 3.',
    tierCosts: [60],
  ),
  MetaUpgradeDef(
    id: 'reroll',
    title: 'Reroll',
    description: 'Reroll the offered choices on level-up.',
    tierCosts: [60, 120, 200],
  ),
  MetaUpgradeDef(
    id: 'banish',
    title: 'Banish',
    description: 'Permanently remove an offered choice from this run.',
    tierCosts: [80, 160],
  ),
  MetaUpgradeDef(
    id: 'lock',
    title: 'Lock',
    description: 'Lock one offered choice to carry to the next level-up.',
    tierCosts: [80],
  ),
  MetaUpgradeDef(
    id: 'rare_cadence',
    title: 'Rare Cadence',
    description: 'Guarantees a brand-new skill every 3rd level-up (instead of 5th).',
    tierCosts: [120],
  ),
  MetaUpgradeDef(
    id: 'pre_pick',
    title: 'Pre-Pick',
    description: 'Choose one starting skill at the start of every run.',
    tierCosts: [100],
  ),
];

const List<KeystoneDef> keystoneCatalog = [
  KeystoneDef(
    id: 'whiplash',
    archetype: SkillArchetype.chain,
    title: 'Whiplash',
    description: 'Basic attacks strike the primary target twice.',
    cost: 100,
  ),
  KeystoneDef(
    id: 'aftershock',
    archetype: SkillArchetype.nova,
    title: 'Aftershock',
    description: 'Each nova fires a smaller second pulse 0.5s later.',
    cost: 100,
  ),
  KeystoneDef(
    id: 'backdraft',
    archetype: SkillArchetype.firewall,
    title: 'Backdraft',
    description: 'Firewall fires a second wall 0.4s after the first.',
    cost: 100,
  ),
  KeystoneDef(
    id: 'cluster',
    archetype: SkillArchetype.meteor,
    title: 'Cluster',
    description: 'Meteor splits into three staggered impacts.',
    cost: 100,
  ),
  KeystoneDef(
    id: 'twin_shot',
    archetype: SkillArchetype.barrage,
    title: 'Twin Shot',
    description: 'Every 4th basic attack fires twice.',
    cost: 100,
  ),
  KeystoneDef(
    id: 'crit',
    archetype: SkillArchetype.focus,
    title: 'Crit',
    description: '8% chance for basic attacks to deal 3x damage.',
    cost: 100,
  ),
  KeystoneDef(
    id: 'streak',
    archetype: SkillArchetype.bounty,
    title: 'Streak',
    description: 'Kills within 1s compound gold (up to 1.5x).',
    cost: 100,
  ),
  KeystoneDef(
    id: 'shatter',
    archetype: SkillArchetype.frost,
    title: 'Shatter',
    description: 'Frost-slowed enemies explode for AoE on death.',
    cost: 100,
  ),
  KeystoneDef(
    id: 'spread',
    archetype: SkillArchetype.rupture,
    title: 'Spread',
    description: 'Execute kills mark the nearest enemy for bonus damage.',
    cost: 100,
  ),
  KeystoneDef(
    id: 'twinblade',
    archetype: SkillArchetype.sentinel,
    title: 'Twinblade',
    description: 'Sentinel dashes strike twice on contact.',
    cost: 100,
  ),
];

String archetypeLabel(SkillArchetype a) {
  return switch (a) {
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
    SkillArchetype.mothership => 'Mothership',
    SkillArchetype.snake => 'Snake',
    SkillArchetype.summon => 'Summon',
  };
}
