import 'skill_catalog.dart';

class TriadDefinition {
  const TriadDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.archetypes,
  });

  final String id;
  final String name;
  final String description;
  final List<SkillArchetype> archetypes;
}

final List<TriadDefinition> triadCatalog = List.unmodifiable([
  TriadDefinition(
    id: 'quicksilver',
    name: 'Quicksilver',
    description:
        'Each barrage hit reduces chain cooldown by 0.5s; focus damage stacks per chain hop.',
    archetypes: [
      SkillArchetype.barrage,
      SkillArchetype.chain,
      SkillArchetype.focus,
    ],
  ),
  TriadDefinition(
    id: 'sovereign_network',
    name: 'Sovereign Network',
    description:
        'Drones patrol firewall lanes; meteor impacts spawn a drone on the lane.',
    archetypes: [
      SkillArchetype.mothership,
      SkillArchetype.firewall,
      SkillArchetype.meteor,
    ],
  ),
  TriadDefinition(
    id: 'spirit_choir',
    name: 'Spirit Choir',
    description:
        'Summons emit nova pulses on attack; frost-shattered enemies under a summon-pulse spawn ice meteors.',
    archetypes: [
      SkillArchetype.nova,
      SkillArchetype.frost,
      SkillArchetype.summon,
    ],
  ),
  TriadDefinition(
    id: 'storm_triad',
    name: 'Storm Triad',
    description:
        'Chain hops chill; novas detonating inside chilled clusters become ice storms.',
    archetypes: [
      SkillArchetype.chain,
      SkillArchetype.nova,
      SkillArchetype.frost,
    ],
  ),
  TriadDefinition(
    id: 'iron_cathedral',
    name: 'Iron Cathedral',
    description:
        'Sentinel blades patrol firewall lanes; lane-trapped enemies are auto-executed at 30% HP threshold.',
    archetypes: [
      SkillArchetype.sentinel,
      SkillArchetype.firewall,
      SkillArchetype.rupture,
    ],
  ),
  TriadDefinition(
    id: 'hellgate_choir',
    name: 'Hellgate Choir',
    description:
        'Summoned spirits ignite snakes on contact; snakes hatch directly from firewall edges.',
    archetypes: [
      SkillArchetype.snake,
      SkillArchetype.summon,
      SkillArchetype.firewall,
    ],
  ),
]);
