import 'package:flutter/material.dart';

enum MechType { standard }

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
    type: MechType.standard,
    title: 'Hero',
    description: 'Standard hero frame.',
    visual: MechVisual(
      body: Color(0xFF0E5C6B),
      accent: Color(0xFF00E5FF),
      outline: Color(0xFF7BF6FF),
      bodyWidth: 0.82,
      bodyHeight: 0.62,
      headRadius: 0.18,
      headOffsetY: -0.42,
    ),
    maxHpMultiplier: 1,
    damageMultiplier: 1,
    attackSpeedMultiplier: 1,
    spriteSize: 124,
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
  return MechType.standard;
}
