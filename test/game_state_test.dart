import 'package:flame/components.dart';
import 'package:zenith_zero/game/components/enemy.dart';
import 'package:zenith_zero/game/zenith_zero_game.dart';
import 'package:zenith_zero/game/state/game_state.dart';
import 'package:zenith_zero/game/state/meta_state.dart';
import 'package:zenith_zero/game/state/mech_catalog.dart';
import 'package:zenith_zero/game/state/skill_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('devMaxAll unlocks everything in MetaState', () {
    final meta = MetaState();
    addTearDown(meta.dispose);

    expect(meta.embers, 0);
    expect(meta.widerPick, isFalse);
    expect(meta.hasKeystone('whiplash'), isFalse);

    meta.devMaxAll();

    expect(meta.widerPick, isTrue);
    expect(meta.rerollsPerRun, 3);
    expect(meta.hasKeystone('whiplash'), isTrue);
    expect(meta.hasKeystone('twinblade'), isTrue);
  });

  test('base balance metrics are internally consistent', () {
    final state = GameState();
    addTearDown(state.dispose);

    expect(state.floor, 1);
    expect(state.enemyMaxHp, greaterThan(0));
    expect(state.estimatedDps, greaterThan(0));
    expect(
      state.estimatedTimeToKill,
      closeTo(state.enemyMaxHp / state.estimatedDps, 0.0001),
    );
    expect(
      state.estimatedGoldPerSecond,
      closeTo(state.goldPerKill / state.estimatedTimeToKill, 0.0001),
    );
  });

  test('kills award gold and floor clears roll upgrade choices', () {
    final state = GameState();
    addTearDown(state.dispose);

    for (var i = 0; i < GameState.killsPerFloor - 1; i++) {
      state.registerKill();
    }

    expect(state.floor, 1);
    expect(state.killsOnFloor, GameState.killsPerFloor - 1);
    expect(state.hasPendingLevelUp, isFalse);

    state.registerKill();

    expect(state.floor, 2);
    expect(state.killsOnFloor, 0);
    expect(state.gold, GameState.killsPerFloor);
    expect(state.pendingChoices, hasLength(3));
    expect(state.hasPendingLevelUp, isTrue);
  });

  test('selecting an upgrade records one level and resumes the run', () {
    final state = GameState();
    addTearDown(state.dispose);

    for (var i = 0; i < GameState.killsPerFloor; i++) {
      state.registerKill();
    }

    final choice = state.pendingChoices.first;
    state.selectUpgrade(choice.definition.id);

    expect(state.hasPendingLevelUp, isFalse);
    expect(state.skillLevel(choice.definition.id), 1);
    expect(state.skillLevels, containsPair(choice.definition.id, 1));
  });

  test('enemy and reward scaling increase with floor', () {
    final state = GameState();
    addTearDown(state.dispose);

    final floorOneHp = state.enemyMaxHp;
    final floorOneGold = state.goldPerKill;

    for (var i = 0; i < GameState.killsPerFloor; i++) {
      state.registerKill();
    }

    expect(state.enemyMaxHp, greaterThan(floorOneHp));
    expect(state.goldPerKill, greaterThanOrEqualTo(floorOneGold));
  });

  test('load grants capped offline reward when run is active', () async {
    final lastSeen = DateTime.now().subtract(const Duration(minutes: 10));
    SharedPreferences.setMockInitialValues({
      'lastSeenAt': lastSeen.millisecondsSinceEpoch,
    });
    final state = GameState();
    addTearDown(state.dispose);

    await state.load();

    expect(state.lastVoidReward, greaterThan(0));
    expect(state.gold, state.lastVoidReward);
  });

  test('reset clears progress, pending choices, and upgrades', () async {
    final state = GameState();
    addTearDown(state.dispose);

    for (var i = 0; i < GameState.killsPerFloor; i++) {
      state.registerKill();
    }
    final choice = state.pendingChoices.first;
    state.selectUpgrade(choice.definition.id);

    await state.resetProgress();

    expect(state.gold, 0);
    expect(state.floor, 1);
    expect(state.killsOnFloor, 0);
    expect(state.nexusHp, state.nexusMaxHp);
    expect(state.pendingChoices, isEmpty);
    expect(state.skillLevels, isEmpty);
  });

  test('hero uses standard combat stats', () {
    final state = GameState();
    addTearDown(state.dispose);

    expect(state.selectedMech, MechType.standard);
    expect(state.nexusMaxHp, GameState.maxNexusHp);
    expect(state.heroDamage, GameState.baseDamage);
    expect(state.heroAttacksPerSec, GameState.baseAttacksPerSec);

    state.damageNexus(state.nexusMaxHp / 2);
    state.selectMech(MechType.standard);

    expect(state.nexusMaxHp, GameState.maxNexusHp);
    expect(state.nexusHp, closeTo(GameState.maxNexusHp / 2, 0.0001));
    expect(state.estimatedDps, GameState.baseDamage);
  });

  test('standard hero persists across load', () async {
    final state = GameState();
    addTearDown(state.dispose);

    state.selectMech(MechType.standard);
    await state.save();

    final loaded = GameState();
    addTearDown(loaded.dispose);
    await loaded.load();

    expect(loaded.selectedMech, MechType.standard);
    expect(loaded.nexusMaxHp, GameState.maxNexusHp);
  });

  test('unlockDevMode only works with the correct key', () {
    final state = GameState();
    addTearDown(state.dispose);

    expect(state.devMode, isFalse);

    // Wrong key
    final wrong = state.unlockDevMode('WRONG');
    expect(wrong, isFalse);
    expect(state.devMode, isFalse);

    // Correct key
    final correct = state.unlockDevMode('TWANGPRO');
    expect(correct, isTrue);
    expect(state.devMode, isTrue);

    // Case insensitive/trimmed
    state.devMode = false;
    final trimmed = state.unlockDevMode('  twangpro  ');
    expect(trimmed, isTrue);
    expect(state.devMode, isTrue);

    // Toggles OFF
    final off = state.unlockDevMode('TWANGPRO');
    expect(off, isTrue);
    expect(state.devMode, isFalse);
  });

  test('godMode prevents nexus damage', () {
    final state = GameState();
    addTearDown(state.dispose);

    expect(state.godMode, isFalse);
    state.damageNexus(10);
    expect(state.nexusHp, state.nexusMaxHp - 10);

    state.toggleGodMode();
    expect(state.godMode, isTrue);
    state.damageNexus(10);
    expect(state.nexusHp, state.nexusMaxHp - 10);
  });

  test('requestDevKillAll increments request counter', () {
    final state = GameState();
    addTearDown(state.dispose);

    expect(state.devKillAllRequest, 0);
    state.requestDevKillAll();
    expect(state.devKillAllRequest, 1);
    state.requestDevKillAll();
    expect(state.devKillAllRequest, 2);
  });

  test('devPauseSpawning and devHealNexus work correctly', () {
    final state = GameState();
    addTearDown(state.dispose);

    expect(state.devPauseSpawning, isFalse);
    state.toggleDevPauseSpawning();
    expect(state.devPauseSpawning, isTrue);

    state.damageNexus(50);
    expect(state.nexusHp, state.nexusMaxHp - 50);
    state.devHealNexus();
    expect(state.nexusHp, state.nexusMaxHp);
  });

  test('cycleGameSpeed and togglePerfOverlay work correctly', () {
    final state = GameState();
    addTearDown(state.dispose);

    expect(state.devTimeScale, 1.0);
    state.cycleGameSpeed();
    expect(state.devTimeScale, 2.0);
    state.cycleGameSpeed();
    expect(state.devTimeScale, 5.0);
    state.cycleGameSpeed();
    expect(state.devTimeScale, 0.0);
    state.cycleGameSpeed();
    expect(state.devTimeScale, 1.0);

    final initialPerf = state.showPerfOverlay;
    state.togglePerfOverlay();
    expect(state.showPerfOverlay, !initialPerf);
  });

  test('cycleEnemyStrength works correctly', () {
    final state = GameState();
    addTearDown(state.dispose);

    expect(state.devEnemyStrength, 1.0);
    state.cycleEnemyStrength();
    expect(state.devEnemyStrength, 2.0);
    state.cycleEnemyStrength();
    expect(state.devEnemyStrength, 5.0);
    state.cycleEnemyStrength();
    expect(state.devEnemyStrength, 10.0);
    state.cycleEnemyStrength();
    expect(state.devEnemyStrength, 1.0);
  });

  test('devForceLevelUp triggers upgrade choices', () {
    final state = GameState();
    addTearDown(state.dispose);

    expect(state.hasPendingLevelUp, isFalse);
    state.devForceLevelUp();
    expect(state.hasPendingLevelUp, isTrue);
    expect(state.pendingChoices, isNotEmpty);
  });

  test('devGrantSkill cycles levels to 0 after maxLevel', () {
    final state = GameState();
    addTearDown(state.dispose);
    const skillId = 'focus';

    // Grant to max level
    for (var i = 0; i < SkillDefinition.maxLevel; i++) {
      state.devGrantSkill(skillId);
    }
    expect(state.skillLevel(skillId), SkillDefinition.maxLevel);

    // Cycle to 0
    state.devGrantSkill(skillId);
    expect(state.skillLevel(skillId), 0);

    // Cycle back to 1
    state.devGrantSkill(skillId);
    expect(state.skillLevel(skillId), 1);
  });

  test('skill levels and evolutions survive save/load round-trip', () async {
    final state = GameState();
    addTearDown(state.dispose);

    // Set some state
    state.devSetSkillLevel('chain', 5);
    state.pendingEvolutionArchetype = SkillArchetype.chain;
    state.selectEvolution(1); // Chainstorm
    state.devSetSkillLevel('nova', 3);

    expect(state.skillLevel('chain'), 5);
    expect(state.getEvolution(SkillArchetype.chain), 1);

    // Save explicitly (flushing the debounce)
    await state.save();
    
    final state2 = GameState();
    addTearDown(state2.dispose);
    await state2.load();

    expect(state2.skillLevel('chain'), 5);
    expect(state2.getEvolution(SkillArchetype.chain), 1);
    expect(state2.skillLevel('nova'), 3);
  });

  test('old skill IDs are migrated to new archetype IDs', () async {
    final prefs = await SharedPreferences.getInstance();
    // Simulate an old save with 127-variant IDs
    await prefs.setStringList('skillLevels', [
      'neon_katana_chain:3',
      'mana_reactor_nova:2',
      'soulcoin_brand:1',
    ]);

    final state = GameState();
    addTearDown(state.dispose);
    await state.load();

    // Verify migration
    expect(state.skillLevel('chain'), 3);
    expect(state.skillLevel('nova'), 2);
    expect(state.skillLevel('bounty'), 1);

    // Verify old IDs are cleaned up from internal map
    expect(state.skillLevels.containsKey('neon_katana_chain'), isFalse);
    expect(state.skillLevels.containsKey('chain'), isTrue);
  });

  test('devMaxAllSkills maxes out every skill', () {
    final state = GameState();
    addTearDown(state.dispose);

    for (final def in skillCatalog) {
      expect(state.skillLevel(def.id), 0);
    }

    state.devMaxAllSkills();

    for (final def in skillCatalog) {
      expect(state.skillLevel(def.id), SkillDefinition.maxLevel);
    }
  });

  test('muted flag defaults to true and persists', () async {
    final state = GameState();
    addTearDown(state.dispose);

    expect(state.muted, isTrue);
    state.toggleMuted();
    expect(state.muted, isFalse);

    await state.save();

    final loaded = GameState();
    addTearDown(loaded.dispose);
    await loaded.load();

    expect(loaded.muted, isFalse);
  });

  test('developer grant methods work correctly', () {
    final state = GameState();
    final meta = state.meta;
    addTearDown(state.dispose);

    expect(state.gold, 0);
    state.devGrantGold(1000);
    expect(state.gold, 1000);

    expect(meta.embers, 0);
    meta.devGrantEmbers(500);
    expect(meta.embers, 500);

    expect(state.floor, 1);
    state.devJumpFloor(10);
    expect(state.floor, 11);
    state.devJumpFloor(-5);
    expect(state.floor, 6);
    state.devJumpFloor(-100);
    expect(state.floor, 1);
  });

  test('lifetime kills persist across runs and resetProgress', () async {
    final state = GameState();
    addTearDown(state.dispose);

    expect(state.runKills, 0);
    expect(state.lifetimeKills, 0);

    for (var i = 0; i < 25; i++) {
      state.registerKill();
    }

    expect(state.runKills, 25);
    expect(state.lifetimeKills, 25);

    await state.resetProgress();

    expect(state.runKills, 0);
    expect(state.lifetimeKills, 25);

    await state.save();

    final loaded = GameState();
    addTearDown(loaded.dispose);
    await loaded.load();

    expect(loaded.lifetimeKills, 25);
  });

  test('totalRuns increments correctly and persists', () async {
    final state = GameState();
    addTearDown(state.dispose);

    // Initial load defaults to 1 (first run)
    await state.load();
    expect(state.totalRuns, 1);

    await state.resetProgress();
    expect(state.totalRuns, 2);

    await state.save();

    final loaded = GameState();
    addTearDown(loaded.dispose);
    await loaded.load();
    expect(loaded.totalRuns, 2);
  });

  test('visual load tier thresholds are stable', () {
    expect(
      visualLoadTierForCounts(enemyCount: 90, componentCount: 420),
      VisualLoadTier.normal,
    );
    expect(
      visualLoadTierForCounts(enemyCount: 91, componentCount: 100),
      VisualLoadTier.busy,
    );
    expect(
      visualLoadTierForCounts(enemyCount: 100, componentCount: 421),
      VisualLoadTier.busy,
    );
    expect(
      visualLoadTierForCounts(enemyCount: 121, componentCount: 100),
      VisualLoadTier.overloaded,
    );
    expect(
      visualLoadTierForCounts(enemyCount: 100, componentCount: 621),
      VisualLoadTier.overloaded,
    );
    expect(
      visualLoadTierForCounts(enemyCount: 151, componentCount: 100),
      VisualLoadTier.critical,
    );
    expect(
      visualLoadTierForCounts(enemyCount: 100, componentCount: 761),
      VisualLoadTier.critical,
    );
  });

  test('selectNearestEnemies returns bounded nearest targets', () {
    final state = GameState();
    addTearDown(state.dispose);
    final game = ZenithZeroGame(state: state);
    final far = Enemy(position: Vector2(80, 0), baseMaxHp: 10);
    final near = Enemy(position: Vector2(5, 0), baseMaxHp: 10);
    final mid = Enemy(position: Vector2(20, 0), baseMaxHp: 10);
    final outsideRange = Enemy(position: Vector2(40, 0), baseMaxHp: 10);
    game.aliveEnemies = [far, near, mid, outsideRange];
    game.targetableEnemies = [far, near, mid, outsideRange];

    expect(game.selectNearestEnemies(Vector2.zero(), 2), [near, mid]);
    expect(game.selectNearestEnemies(Vector2.zero(), 10, range: 25), [
      near,
      mid,
    ]);
  });
}
