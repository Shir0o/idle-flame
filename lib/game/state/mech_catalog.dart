enum MechType { tank, ultra, bulky }

class MechDefinition {
  const MechDefinition({
    required this.type,
    required this.title,
    required this.description,
    required this.assetPath,
    required this.maxHpMultiplier,
    required this.damageMultiplier,
    required this.attackSpeedMultiplier,
    required this.spriteSize,
  });

  final MechType type;
  final String title;
  final String description;
  final String assetPath;
  final double maxHpMultiplier;
  final double damageMultiplier;
  final double attackSpeedMultiplier;
  final double spriteSize;
}

const List<MechDefinition> mechCatalog = [
  MechDefinition(
    type: MechType.tank,
    title: 'Tank Mech',
    description: 'Heavy frame with a reinforced nexus link.',
    assetPath: 'tank_mech',
    maxHpMultiplier: 1.25,
    damageMultiplier: 0.95,
    attackSpeedMultiplier: 0.9,
    spriteSize: 124,
  ),
  MechDefinition(
    type: MechType.ultra,
    title: 'Ultra Mech',
    description: 'Fast frame built for constant blade pressure.',
    assetPath: 'ultra_mech',
    maxHpMultiplier: 0.9,
    damageMultiplier: 1,
    attackSpeedMultiplier: 1.22,
    spriteSize: 92,
  ),
  MechDefinition(
    type: MechType.bulky,
    title: 'Bulky Mech',
    description: 'Siege frame with harder hits and slower rhythm.',
    assetPath: 'bulky_mech',
    maxHpMultiplier: 1.1,
    damageMultiplier: 1.22,
    attackSpeedMultiplier: 0.78,
    spriteSize: 116,
  ),
];

MechDefinition mechDefinitionFor(MechType type) {
  for (final definition in mechCatalog) {
    if (definition.type == type) return definition;
  }
  return mechCatalog.first;
}

MechType mechTypeFromId(String? id) {
  for (final type in MechType.values) {
    if (type.name == id) return type;
  }
  return MechType.tank;
}
