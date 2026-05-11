import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith_zero/game/state/game_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Floor Reward Room triggers on F10/F20 but not others', () {
    final state = GameState();
    addTearDown(state.dispose);

    // F5: No reward room
    state.devJumpFloor(4);
    state.registerKill(isBoss: true);
    expect(state.pendingFloorReward, isFalse);
    expect(state.floor, 6);

    // F10: Reward room
    state.devJumpFloor(4); // 6 + 4 = 10
    expect(state.floor, 10);
    state.registerKill(isBoss: true);
    expect(state.pendingFloorReward, isTrue);
    expect(state.floor, 10); // Should NOT advance yet

    // Resolve F10
    final initialGold = state.gold;
    state.resolveFloorReward(FloorBoon.gold25);
    expect(state.gold, initialGold + 25);
    expect(state.floor, 11);
    expect(state.pendingFloorReward, isFalse);

    // F20: Reward room
    state.devJumpFloor(9); // 11 + 9 = 20
    expect(state.floor, 20);
    state.registerKill(isBoss: true);
    expect(state.pendingFloorReward, isTrue);
  });
}
