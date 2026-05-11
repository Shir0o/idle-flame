import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith_zero/game/state/meta_catalog.dart';
import 'package:zenith_zero/game/state/meta_state.dart';
import 'package:zenith_zero/game/state/skill_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MetaState Ember Spending & Keystones', () {
    test('purchaseUpgrade debits embers and increments tier', () {
      final meta = MetaState();
      meta.devGrantEmbers(100);
      final def = metaUpgradeCatalog.firstWhere((e) => e.id == 'wider_pick');

      expect(meta.upgradeTier('wider_pick'), 0);
      expect(meta.canPurchaseUpgrade(def), true);

      final success = meta.purchaseUpgrade(def);
      expect(success, true);
      expect(meta.upgradeTier('wider_pick'), 1);
      expect(meta.embers, 100 - def.costForTier(1));
    });

    test('purchaseUpgrade fails if insufficient embers', () {
      final meta = MetaState();
      meta.embers = 10;
      final def = metaUpgradeCatalog.firstWhere((e) => e.id == 'wider_pick');

      expect(meta.canPurchaseUpgrade(def), false);
      final success = meta.purchaseUpgrade(def);
      expect(success, false);
      expect(meta.upgradeTier('wider_pick'), 0);
      expect(meta.embers, 10);
    });

    test('purchaseUpgrade fails if already at max tier', () {
      final meta = MetaState();
      final def = metaUpgradeCatalog.firstWhere((e) => e.id == 'wider_pick');
      meta.devGrantEmbers(1000);

      // Buy first tier
      meta.purchaseUpgrade(def);
      expect(meta.upgradeTier('wider_pick'), def.maxTier);

      // Try to buy again
      expect(meta.canPurchaseUpgrade(def), false);
      final success = meta.purchaseUpgrade(def);
      expect(success, false);
    });

    test('purchaseKeystone debits embers and unlocks keystone', () {
      final meta = MetaState();
      meta.devGrantEmbers(200);
      final def = keystoneCatalog.firstWhere((e) => e.id == 'whiplash');

      expect(meta.hasKeystone('whiplash'), false);
      expect(meta.canPurchaseKeystone(def), true);

      final success = meta.purchaseKeystone(def);
      expect(success, true);
      expect(meta.hasKeystone('whiplash'), true);
      expect(meta.embers, 200 - def.cost);
    });

    test('purchaseKeystone fails if already owned', () {
      final meta = MetaState();
      meta.devGrantEmbers(500);
      final def = keystoneCatalog.firstWhere((e) => e.id == 'whiplash');

      meta.purchaseKeystone(def);
      expect(meta.hasKeystone('whiplash'), true);

      expect(meta.canPurchaseKeystone(def), false);
      final success = meta.purchaseKeystone(def);
      expect(success, false);
    });
  });

  group('MetaState Sutra & Awakening', () {
    test('incrementSutra increases count up to 25', () {
      final meta = MetaState();
      const archetype = SkillArchetype.chain;

      expect(meta.sutraCount(archetype), 0);
      meta.incrementSutra(archetype);
      expect(meta.sutraCount(archetype), 1);

      // Set to 24 manually for testing if I could, but I'll just loop
      for (var i = 0; i < 30; i++) {
        meta.incrementSutra(archetype);
      }
      expect(meta.sutraCount(archetype), 25);
    });

    test('awakenPath requires all archetypes in path to be Sutra 25', () {
      final meta = MetaState();
      const path = SkillPath.daemon;
      final archetypesInPath = SkillArchetype.values
          .where((a) => a.path == path)
          .toList();

      expect(meta.isAwakened(path), false);

      // Set only some to 25
      for (var i = 0; i < 25; i++) {
        meta.incrementSutra(archetypesInPath[0]);
      }
      meta.awakenPath(path);
      expect(meta.isAwakened(path), false);

      // Set all to 25
      for (final archetype in archetypesInPath) {
        for (var i = 0; i < 25; i++) {
          meta.incrementSutra(archetype);
        }
      }

      meta.awakenPath(path);
      expect(meta.isAwakened(path), true);

      // Verify sutras reset
      for (final archetype in archetypesInPath) {
        expect(meta.sutraCount(archetype), 0);
      }
    });
  });

  group('MetaState Persistence', () {
    test('save and load round-trip', () async {
      final meta = MetaState();
      meta.devGrantEmbers(1000);
      meta.recordDiscovery('test_id', reward: 0);

      final upgrade = metaUpgradeCatalog.first;
      meta.purchaseUpgrade(upgrade);

      final keystone = keystoneCatalog.first;
      meta.purchaseKeystone(keystone);

      meta.incrementSutra(SkillArchetype.chain);

      // MetaState mutations trigger _save() which is async.
      // We need to yield to the event loop to let them complete.
      for (var i = 0; i < 10; i++) {
        await null;
      }

      final meta2 = MetaState();
      await meta2.load();

      expect(meta2.embers, 1000 - upgrade.costForTier(1) - keystone.cost);
      expect(meta2.discoveredIds, contains('test_id'));
      expect(meta2.upgradeTier(upgrade.id), 1);
      expect(meta2.hasKeystone(keystone.id), true);
      expect(meta2.sutraCount(SkillArchetype.chain), 1);
    });
  });

  group('MetaState F25 Unlocks', () {
    test('claimNextF25Unlock unlocks in order', () {
      final meta = MetaState();

      for (final expected in MetaState.f25UnlockPool) {
        final unlocked = meta.claimNextF25Unlock();
        expect(unlocked, expected);
        expect(meta.f25Unlocks, contains(expected));
      }

      expect(meta.claimNextF25Unlock(), isNull);
    });
  });
}
