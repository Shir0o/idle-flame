import 'package:flutter/material.dart';

enum MechType { tank, ultra, bulky }

class MechVisual {
  const MechVisual({
    required this.body,
    required this.accent,
    required this.outline,
    required this.bodyWidth,
    required this.bodyHeight,
    required this.headRadius,
    required this.headOffsetY,
  });

  final Color body;
  final Color accent;
  final Color outline;
  final double bodyWidth;
  final double bodyHeight;
  final double headRadius;
  final double headOffsetY;
}

class MechDefinition {
  const MechDefinition({
    required this.type,
    required this.title,
    required this.description,
    required this.visual,
    required this.maxHpMultiplier,
    required this.damageMultiplier,
    required this.attackSpeedMultiplier,
    required this.spriteSize,
  });

  final MechType type;
  final String title;
  final String description;
  final MechVisual visual;
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
    visual: MechVisual(
      body: Color(0xFF0E5C6B),
      accent: Color(0xFF00E5FF),
      outline: Color(0xFF7BF6FF),
      bodyWidth: 0.82,
      bodyHeight: 0.62,
      headRadius: 0.18,
      headOffsetY: -0.42,
    ),
    maxHpMultiplier: 1.25,
    damageMultiplier: 0.95,
    attackSpeedMultiplier: 0.9,
    spriteSize: 124,
  ),
  MechDefinition(
    type: MechType.ultra,
    title: 'Ultra Mech',
    description: 'Fast frame built for constant blade pressure.',
    visual: MechVisual(
      body: Color(0xFF7A1B5C),
      accent: Color(0xFFFFEB3B),
      outline: Color(0xFFFF77C8),
      bodyWidth: 0.5,
      bodyHeight: 0.72,
      headRadius: 0.14,
      headOffsetY: -0.46,
    ),
    maxHpMultiplier: 0.9,
    damageMultiplier: 1,
    attackSpeedMultiplier: 1.22,
    spriteSize: 92,
  ),
  MechDefinition(
    type: MechType.bulky,
    title: 'Bulky Mech',
    description: 'Siege frame with harder hits and slower rhythm.',
    visual: MechVisual(
      body: Color(0xFFB04A1B),
      accent: Color(0xFFFF5252),
      outline: Color(0xFFFFB199),
      bodyWidth: 0.88,
      bodyHeight: 0.7,
      headRadius: 0.2,
      headOffsetY: -0.38,
    ),
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
