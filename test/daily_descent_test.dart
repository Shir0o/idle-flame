import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith_zero/game/state/game_state.dart';
import 'package:zenith_zero/game/state/meta_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('dailySeedFor is stable and per-key deterministic', () {
    expect(GameState.dailySeedFor('2026-05-17'),
        GameState.dailySeedFor('2026-05-17'));
    expect(GameState.dailySeedFor('2026-05-17'),
        isNot(GameState.dailySeedFor('2026-05-18')));
  });

  test('two daily runs with the same seed produce the same modifier roll', () async {
    final metaA = MetaState();
    final stateA = GameState(meta: metaA, seed: GameState.dailySeedFor('2026-05-17'));
    addTearDown(stateA.dispose);
    // Roll modifiers for floor 2 (non-boss).
    final rollA = stateA.activeModifiers.toList();
    stateA.devJumpFloor(0); // no-op, but ensures setup
    // Drive an advance by clearing a boss-floor without reward (F5).
    stateA.devJumpFloor(4);
    stateA.registerKill(isBoss: true);
    final modsA = stateA.activeModifiers.toSet();

    final metaB = MetaState();
    final stateB = GameState(meta: metaB, seed: GameState.dailySeedFor('2026-05-17'));
    addTearDown(stateB.dispose);
    final rollB = stateB.activeModifiers.toList();
    stateB.devJumpFloor(4);
    stateB.registerKill(isBoss: true);
    final modsB = stateB.activeModifiers.toSet();

    expect(rollA, rollB);
    expect(modsA, modsB);
  });

  test('startDailyRun gates on the daily-best key for today', () async {
    final meta = MetaState();
    final state = GameState(meta: meta);
    addTearDown(state.dispose);

    await state.startDailyRun();
    expect(state.isDaily, isTrue);

    // Simulate death: record a daily best.
    final today = MetaState.currentDailyKey();
    meta.recordDailyBest(today, 8, 120);
    expect(meta.dailyBests.containsKey(today), isTrue);

    // Resetting clears isDaily.
    await state.resetProgress();
    expect(state.isDaily, isFalse);

    // Second attempt on the same day is gated.
    await state.startDailyRun();
    expect(state.isDaily, isFalse,
        reason: 'startDailyRun should be a no-op when today already has a best');
  });

  test('recordDailyBest only updates when the new attempt is better', () {
    final meta = MetaState();
    const key = '2026-05-17';

    meta.recordDailyBest(key, 8, 100);
    expect(meta.dailyBests[key], (floor: 8, embers: 100));

    // Lower floor: ignored.
    meta.recordDailyBest(key, 5, 999);
    expect(meta.dailyBests[key], (floor: 8, embers: 100));

    // Same floor, more embers: update.
    meta.recordDailyBest(key, 8, 150);
    expect(meta.dailyBests[key], (floor: 8, embers: 150));

    // Higher floor: update regardless of embers.
    meta.recordDailyBest(key, 12, 50);
    expect(meta.dailyBests[key], (floor: 12, embers: 50));
  });

  test('daily best persists across MetaState load', () async {
    final meta = MetaState();
    const key = '2026-05-17';
    meta.recordDailyBest(key, 14, 200);
    // _save is async — wait a tick to let SharedPreferences flush.
    await Future.delayed(Duration.zero);

    final loaded = MetaState();
    await loaded.load();
    expect(loaded.dailyBests[key], (floor: 14, embers: 200));
  });
}
