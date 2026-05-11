import 'package:flutter_test/flutter_test.dart';
import 'package:zenith_zero/game/state/inflection_catalog.dart';
import 'package:zenith_zero/game/state/mech_catalog.dart';
import 'package:zenith_zero/game/state/meta_catalog.dart';
import 'package:zenith_zero/game/state/skill_catalog.dart';
import 'package:zenith_zero/game/state/triad_catalog.dart';

void main() {
  group('Catalog Invariants', () {
    test('Skill Catalog has no duplicate IDs and valid archetypes', () {
      final ids = <String>{};
      for (final def in skillCatalog) {
        expect(
          ids.contains(def.id),
          false,
          reason: 'Duplicate skill ID: ${def.id}',
        );
        ids.add(def.id);

        // Ensure every archetype has a label
        expect(def.archetype.label, isNotEmpty);
      }
      expect(
        skillCatalog.length,
        SkillArchetype.values.length,
        reason: 'Every archetype should have a skill definition',
      );
    });

    test('Meta Upgrade Catalog has no duplicate IDs', () {
      final ids = <String>{};
      for (final def in metaUpgradeCatalog) {
        expect(
          ids.contains(def.id),
          false,
          reason: 'Duplicate meta upgrade ID: ${def.id}',
        );
        ids.add(def.id);
      }
    });

    test('Keystone Catalog has no duplicate IDs and valid archetypes', () {
      final ids = <String>{};
      for (final def in keystoneCatalog) {
        expect(
          ids.contains(def.id),
          false,
          reason: 'Duplicate keystone ID: ${def.id}',
        );
        ids.add(def.id);

        // Ensure archetype is valid
        expect(SkillArchetype.values, contains(def.archetype));
      }
    });

    test('Mech Catalog has no duplicate types', () {
      final types = <MechType>{};
      for (final def in mechCatalog) {
        expect(
          types.contains(def.type),
          false,
          reason: 'Duplicate mech type: ${def.type}',
        );
        types.add(def.type);
      }
      expect(
        mechCatalog.length,
        MechType.values.length,
        reason: 'Every MechType should have a definition',
      );
    });

    test('Triad Catalog has no duplicate IDs and valid archetypes', () {
      final ids = <String>{};
      for (final def in triadCatalog) {
        expect(
          ids.contains(def.id),
          false,
          reason: 'Duplicate triad ID: ${def.id}',
        );
        ids.add(def.id);

        // Ensure archetypes exist
        for (final archetype in def.archetypes) {
          expect(
            SkillArchetype.values,
            contains(archetype),
            reason: 'Triad ${def.id} refers to unknown archetype $archetype',
          );
        }
      }
    });

    test('Inflection Catalog has no duplicate IDs and valid archetypes', () {
      final ids = <String>{};
      for (final def in inflectionCatalog) {
        expect(
          ids.contains(def.id),
          false,
          reason: 'Duplicate inflection ID: ${def.id}',
        );
        ids.add(def.id);

        // Ensure archetype is valid
        expect(SkillArchetype.values, contains(def.archetype));
      }
    });

    test('Fusion Catalog has no duplicate IDs and valid paths', () {
      final ids = <String>{};
      for (final def in fusionCatalog) {
        expect(
          ids.contains(def.id),
          false,
          reason: 'Duplicate fusion ID: ${def.id}',
        );
        ids.add(def.id);

        expect(
          def.paths.length,
          2,
          reason: 'Fusion ${def.id} should have exactly 2 paths',
        );
        for (final path in def.paths) {
          expect(SkillPath.values, contains(path));
        }
      }
    });

    test('Evolution Catalog covers all archetypes', () {
      for (final archetype in SkillArchetype.values) {
        expect(
          evolutionCatalog.containsKey(archetype),
          true,
          reason: 'Missing evolution for $archetype',
        );
        final (evo1, evo2) = evolutionCatalog[archetype]!;
        expect(evo1.name, isNotEmpty);
        expect(evo2.name, isNotEmpty);
      }
    });
  });
}
