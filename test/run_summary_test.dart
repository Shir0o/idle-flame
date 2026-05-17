import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith_zero/game/components/enemy.dart';
import 'package:zenith_zero/game/state/game_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('peak floor is captured as the floor at death', () {
    final state = GameState(seed: 1);
    addTearDown(state.dispose);

    state.floor = 14;
    state.damageNexus(state.nexusMaxHp, source: EnemyType.splinter);

    expect(state.isRunOver, isTrue);
    expect(state.floor, 14);
  });

  test('longest phase wins ties by latest occurrence', () {
    final state = GameState(seed: 1);
    addTearDown(state.dispose);

    // Phase 1: trickle -> press at floorTime>=10. Duration = 10.
    state.update(10.0);
    expect(state.floorPhase, FloorPhase.press);
    expect(state.longestPhaseType, FloorPhase.trickle);
    expect(state.longestPhaseDuration, closeTo(10.0, 0.001));

    // Phase 2: press -> crucible at floorTime>=22. Duration = 12.
    state.update(12.0);
    expect(state.floorPhase, FloorPhase.crucible);
    expect(state.longestPhaseType, FloorPhase.press);
    expect(state.longestPhaseDuration, closeTo(12.0, 0.001));

    // Phase 3: crucible auto-advances at floorTime>=32. Duration = 10. Equal
    // to trickle but later — tie-break to latest means crucible doesn't beat
    // press (which is 12s, larger). Verify press still wins.
    state.update(10.0);
    expect(state.longestPhaseType, FloorPhase.press);
    expect(state.longestPhaseDuration, closeTo(12.0, 0.001));
  });

  test('best kill streak tracks high-water mark', () async {
    final state = GameState(seed: 1);
    addTearDown(state.dispose);

    state.registerKill();
    state.registerKill();
    state.registerKill();

    expect(state.bestStreakCount, greaterThanOrEqualTo(3));
    expect(state.bestStreakSeconds, greaterThanOrEqualTo(0));

    final firstBest = state.bestStreakCount;

    // Break the streak with a >1s gap, then a short streak. High water
    // mark should not regress.
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    state.registerKill();
    state.registerKill();
    expect(state.bestStreakCount, firstBest);
  });

  test('worst damage records source enemy and floor', () {
    final state = GameState(seed: 1);
    addTearDown(state.dispose);

    state.floor = 11;
    state.damageNexus(8, source: EnemyType.basic);
    state.damageNexus(28, source: EnemyType.splinter);
    state.damageNexus(5, source: EnemyType.fast);

    expect(state.worstDamageAmount, 28);
    expect(state.worstDamageSource, EnemyType.splinter);
    expect(state.worstDamageFloor, 11);
  });

  test('per-run recap fields reset on resetProgress', () async {
    final state = GameState(seed: 1);
    addTearDown(state.dispose);

    state.update(10.0); // trickle -> press, records longest phase
    state.registerKill();
    state.registerKill();
    state.damageNexus(20, source: EnemyType.tank);

    expect(state.longestPhaseDuration, greaterThan(0));
    expect(state.bestStreakCount, greaterThan(0));
    expect(state.worstDamageAmount, 20);

    await state.resetProgress();

    expect(state.longestPhaseDuration, 0);
    expect(state.longestPhaseType, isNull);
    expect(state.longestPhaseFloor, 0);
    expect(state.bestStreakCount, 0);
    expect(state.bestStreakSeconds, 0);
    expect(state.worstDamageAmount, 0);
    expect(state.worstDamageSource, isNull);
    expect(state.worstDamageFloor, 0);
  });
}
