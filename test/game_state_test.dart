import 'package:flame_game/game/state/game_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
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

    expect(state.lastIdleReward, greaterThan(0));
    expect(state.gold, state.lastIdleReward);
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
    expect(state.nexusHp, GameState.maxNexusHp);
    expect(state.pendingChoices, isEmpty);
    expect(state.skillLevels, isEmpty);
  });
}
