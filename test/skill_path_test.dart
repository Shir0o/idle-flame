import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith_zero/game/state/game_state.dart';
import 'package:zenith_zero/game/state/skill_catalog.dart';
import 'package:flutter/material.dart';

import 'package:zenith_zero/game/state/meta_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('MetaState discovery awards embers and persists', () async {
    final meta = MetaState();
    await meta.load();

    expect(meta.embers, 0);
    expect(meta.discoveredIds, isEmpty);

    meta.recordDiscovery('chain');
    expect(meta.embers, 5);
    expect(meta.discoveredIds, contains('chain'));

    // Re-discovery shouldn't award more
    meta.recordDiscovery('chain');
    expect(meta.embers, 5);

    // New discovery
    meta.recordDiscovery('nova');
    expect(meta.embers, 10);
  });

  test('SkillPath and SkillArchetype mapping is correct', () {
    expect(SkillArchetype.chain.path, SkillPath.edge);
    expect(SkillArchetype.barrage.path, SkillPath.edge);
    expect(SkillArchetype.sentinel.path, SkillPath.edge);
    expect(SkillArchetype.focus.path, SkillPath.edge);
    expect(SkillArchetype.rupture.path, SkillPath.edge);

    expect(SkillArchetype.mothership.path, SkillPath.daemon);
    expect(SkillArchetype.firewall.path, SkillPath.daemon);
    expect(SkillArchetype.meteor.path, SkillPath.daemon);
    expect(SkillArchetype.bounty.path, SkillPath.daemon);

    expect(SkillArchetype.nova.path, SkillPath.hex);
    expect(SkillArchetype.frost.path, SkillPath.hex);
    expect(SkillArchetype.snake.path, SkillPath.hex);
    expect(SkillArchetype.summon.path, SkillPath.hex);
  });

  test('GameState correctly calculates dominant path', () {
    final state = GameState();

    // No skills
    expect(state.dominantPath, isNull);
    expect(state.nexusCoreColor, const Color(0xFF00E5FF));

    // Level up Edge skill
    state.devSetSkillLevel('chain', 3);
    expect(state.dominantPath, SkillPath.edge);
    expect(state.nexusCoreColor, SkillPath.edge.color);

    // Level up Daemon skill to surpass Edge
    state.devSetSkillLevel('mothership', 4);
    expect(state.dominantPath, SkillPath.daemon);
    expect(state.nexusCoreColor, SkillPath.daemon.color);

    // Level up multiple Hex skills to surpass Daemon
    state.devSetSkillLevel('nova', 3);
    state.devSetSkillLevel('frost', 2); // Total Hex = 5
    expect(state.dominantPath, SkillPath.hex);
    expect(state.nexusCoreColor, SkillPath.hex.color);
  });

  test('GameState correctly calculates PathTiers', () {
    final state = GameState();

    // EDGE tiers
    expect(state.edgeTier, PathTier.none);

    state.devSetSkillLevel('chain', 3);
    expect(state.edgeTier, PathTier.initiate);

    state.devSetSkillLevel('barrage', 4); // Total 7
    expect(state.edgeTier, PathTier.adept);

    state.devSetSkillLevel('sentinel', 5); // Total 12
    expect(state.edgeTier, PathTier.master);

    state.devSetSkillLevel('focus', 5);
    state.devSetSkillLevel('rupture', 1); // Total 18
    expect(state.edgeTier, PathTier.apex);

    // DAEMON tiers
    expect(state.daemonTier, PathTier.none);
    state.devSetSkillLevel('mothership', 3);
    expect(state.daemonTier, PathTier.initiate);
  });

  test('GameState rolls Fusions only when cross-path evolutions are met', () {
    final state = GameState();

    // No evolutions -> no fusions
    state.devForceLevelUp();
    expect(state.pendingFusionChoices, isEmpty);

    // One path evolved
    state.devSetSkillLevel('chain', 5);
    state.pendingEvolutionArchetype = SkillArchetype.chain;
    state.selectEvolution(1);

    state.devForceLevelUp();
    expect(state.pendingFusionChoices, isEmpty);

    // Two paths evolved
    state.devSetSkillLevel('mothership', 5);
    state.pendingEvolutionArchetype = SkillArchetype.mothership;
    state.selectEvolution(1);

    // Force random seed or repeat to catch the 15% chance
    bool found = false;
    for (int i = 0; i < 100; i++) {
      state.devForceLevelUp();
      if (state.pendingFusionChoices.isNotEmpty) {
        found = true;
        expect(
          state.pendingFusionChoices.first.definition.paths,
          containsAll([SkillPath.edge, SkillPath.daemon]),
        );
        break;
      }
    }
    expect(
      found,
      isTrue,
      reason: 'Fusion should be offered eventually when eligible',
    );
  });

  test('MetaState handles Sutras and Awakening correctly', () {
    final meta = MetaState();

    // EDGE path archetypes: chain, barrage, sentinel, focus, rupture
    final edgeArchetypes = [
      SkillArchetype.chain,
      SkillArchetype.barrage,
      SkillArchetype.sentinel,
      SkillArchetype.focus,
      SkillArchetype.rupture,
    ];

    expect(meta.isAwakened(SkillPath.edge), isFalse);

    // Increment all to 25
    for (final a in edgeArchetypes) {
      for (int i = 0; i < 25; i++) {
        meta.incrementSutra(a);
      }
      expect(meta.sutraCount(a), 25);
    }

    // Awakening
    meta.awakenPath(SkillPath.edge);
    expect(meta.isAwakened(SkillPath.edge), isTrue);

    // Sutras should reset for that path
    for (final a in edgeArchetypes) {
      expect(meta.sutraCount(a), 0);
    }
  });

  test('GameState rolls Heretic Cants every 5 floors', () {
    final state = GameState();

    // Floor 1-4: normal upgrades
    for (int i = 1; i < 4; i++) {
      state.devJumpFloor(1);
      state.devForceLevelUp();
      expect(state.pendingCantChoices, isEmpty);
    }

    // Floor 5: Cants
    state.devJumpFloor(1); // Now floor 5
    state.devForceLevelUp();
    expect(state.pendingCantChoices, isNotEmpty);
    expect(state.pendingCantChoices.first.tierLabel, 'HERETIC');
  });

  test('Cant effects apply correctly', () {
    final state = GameState();

    // Force a Cant into pending to allow selection
    state.devJumpFloor(4); // floor 5
    state.devForceLevelUp();
    expect(state.pendingCantChoices, isNotEmpty);
    final cantId = state.pendingCantChoices.first.definition.id;

    final baseDmg = state.enemyBreachDamage;
    state.selectCant(cantId);
    expect(state.hasCant(cantId), isTrue);

    if (cantId == 'bloodprice') {
      expect(state.enemyBreachDamage, baseDmg * 1.5);
    }
  });
}
