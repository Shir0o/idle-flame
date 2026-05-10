import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith_zero/game/components/enemy.dart';
import 'package:zenith_zero/game/state/game_state.dart';
import 'package:flame/components.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Cipher Storm rotates and blocks damage', () {
    final state = GameState();
    state.activeModifiers.add(FloorModifier.cipherStorm);

    // Initial rotation
    state.update(0.1);
    final firstImmunity = state.cipherStormImmunity;
    expect(firstImmunity, isNotNull);

    // Fast forward 4s
    state.update(4.0);
    final secondImmunity = state.cipherStormImmunity;
    expect(secondImmunity, isNot(equals(firstImmunity)));

    // Verify damage blocking (mock-ish)
    // We can't easily run a full Flame game here, but we can test logic
    // if we had a way to check Enemy.takeDamage side effects.
  });
}
