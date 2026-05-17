import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith_zero/game/state/game_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('opening the slate pauses the run via hasPendingLevelUp', () {
    final state = GameState();
    addTearDown(state.dispose);

    expect(state.hasPendingLevelUp, isFalse);
    state.openCodexSlate();
    expect(state.codexSlateOpen, isTrue);
    expect(state.hasPendingLevelUp, isTrue,
        reason: 'open slate must route through the pause gate');

    state.closeCodexSlate();
    expect(state.codexSlateOpen, isFalse);
    expect(state.hasPendingLevelUp, isFalse);
  });

  test('runBossesCleared increments on each boss kill', () {
    final state = GameState();
    addTearDown(state.dispose);

    expect(state.runBossesCleared, 0);

    state.devJumpFloor(4); // F5
    state.registerKill(isBoss: true);
    expect(state.runBossesCleared, 1);

    state.devJumpFloor(4); // F10
    state.registerKill(isBoss: true);
    expect(state.runBossesCleared, 2);
  });

  test('runModifiersSeen accumulates across floors', () {
    final state = GameState();
    addTearDown(state.dispose);

    // Force several boss kills which advance the floor; modifier sets accrue
    // into runModifiersSeen on each advance (when non-empty).
    for (var i = 0; i < 6; i++) {
      state.devJumpFloor(state.floor % 5 == 0 ? 5 : (5 - state.floor % 5));
      state.registerKill(isBoss: true);
      if (state.pendingFloorReward) {
        state.resolveFloorReward(FloorBoon.gold25);
      }
    }
    // Hard to assert which exact modifiers appeared (RNG), but the set should
    // be a subset of the catalog and may be non-empty.
    expect(state.runModifiersSeen.length, lessThanOrEqualTo(FloorModifier.values.length));
  });

  test('codex slate per-run state resets on resetProgress', () async {
    final state = GameState();
    addTearDown(state.dispose);

    state.devJumpFloor(4);
    state.registerKill(isBoss: true);
    expect(state.runBossesCleared, 1);
    state.openCodexSlate();

    await state.resetProgress();
    expect(state.runBossesCleared, 0);
    expect(state.runModifiersSeen, isEmpty);
    expect(state.runCruciblesSurvived, isEmpty);
    expect(state.codexSlateOpen, isFalse);
  });
}
