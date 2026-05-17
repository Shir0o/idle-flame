import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith_zero/game/state/game_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  GameState advanceTo(int targetFloor) {
    final state = GameState();
    addTearDown(state.dispose);
    state.devJumpFloor(targetFloor - state.floor);
    // _advanceFloor isn't directly callable; the dev jump skips the
    // bookkeeping that populates activeEchoes. Re-run boss-kill flow at the
    // target boss floor instead — the test for echo cadence uses the
    // computeEchoesForFloor result returned via lastBossRewardSubtitle.
    return state;
  }

  test('F25 Architect: no echoes, original reward (PERMANENT UNLOCK)', () {
    final state = advanceTo(25);
    state.registerKill(isBoss: true);
    expect(state.lastBossRewardLabel, 'ARCHITECT DEFEATED');
    expect(state.activeEchoes, isEmpty);
  });

  test('F30 Architect: Watcher echo, scaled ember reward + Codex bounty', () {
    final state = advanceTo(30);
    final initial = state.meta.embers;

    state.registerKill(isBoss: true);

    expect(state.lastBossRewardLabel, 'ARCHITECT ECHO DEFEATED');
    // Reward: 100 + 30*10 = 400, plus 25 first-clear bounty = 425
    expect(state.meta.embers, initial + 425);
    expect(state.meta.discoveredIds, contains('echo:watcher'));
    expect(state.lastBossRewardSubtitle, contains('Codex'));
  });

  test('F35 Architect: Sovereign echo (cycle moves on)', () {
    final state = advanceTo(35);
    state.registerKill(isBoss: true);
    expect(state.meta.discoveredIds, contains('echo:sovereign'));
  });

  test('F40 Architect: Hivefather echo', () {
    final state = advanceTo(40);
    state.registerKill(isBoss: true);
    expect(state.meta.discoveredIds, contains('echo:hivefather'));
  });

  test('F45 Architect: Twin echo (closes the first cycle)', () {
    final state = advanceTo(45);
    state.registerKill(isBoss: true);
    expect(state.meta.discoveredIds, contains('echo:twin'));
  });

  test('F50 Architect: stack of 2 (Watcher + Sovereign)', () {
    final state = advanceTo(50);
    state.registerKill(isBoss: true);
    expect(state.meta.discoveredIds, contains('echo:watcher'));
    expect(state.meta.discoveredIds, contains('echo:sovereign'));
    expect(state.meta.discoveredIds, isNot(contains('echo:hivefather')));
  });

  test('F90 Architect: all four echoes stack', () {
    final state = advanceTo(90);
    state.registerKill(isBoss: true);
    for (final e in EchoType.values) {
      expect(state.meta.discoveredIds, contains('echo:${e.name}'));
    }
  });

  test('Echo bounty does not double-pay on repeat clears', () {
    final state = advanceTo(30);
    state.meta.recordDiscovery('echo:watcher'); // pre-mark as known
    final preEmbers = state.meta.embers;

    state.registerKill(isBoss: true);

    // Only the 100 + 30*10 = 400 base reward; no +25 first-clear bounty.
    expect(state.meta.embers, preEmbers + 400);
    expect(state.lastBossRewardSubtitle, isNot(contains('Codex')));
  });
}
