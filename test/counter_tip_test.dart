import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith_zero/game/components/enemy.dart';
import 'package:zenith_zero/game/zenith_zero_game.dart';
import 'package:zenith_zero/game/state/game_state.dart';
import 'package:flame/components.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Counter Tip triggers on first discovery and auto-clears', () async {
    final state = GameState();
    final game = ZenithZeroGame(state: state);
    game.onGameResize(Vector2(400, 800));
    await game.onLoad();

    // First encounter with Aegis
    final aegis = Enemy(position: Vector2.zero(), baseMaxHp: 10, type: EnemyType.aegis);
    game.world.add(aegis);
    aegis.onMount(); // Trigger discovery

    expect(state.counterTipLabel, 'AEGIS');
    expect(state.meta.discoveredIds, contains('enemy:aegis'));

    // Second encounter with Aegis
    state.clearCounterTip();
    expect(state.counterTipLabel, isNull);

    final aegis2 = Enemy(position: Vector2.zero(), baseMaxHp: 10, type: EnemyType.aegis);
    game.world.add(aegis2);
    aegis2.onMount();

    expect(state.counterTipLabel, isNull); // Should not trigger again
  });
}
