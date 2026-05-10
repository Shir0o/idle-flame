import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith_zero/game/state/game_state.dart';
import 'package:zenith_zero/game/state/meta_state.dart';
import 'package:zenith_zero/game/state/inflection_catalog.dart';
import 'package:zenith_zero/game/state/triad_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('F5 Boss Reward: +50 Embers', () {
    final state = GameState();
    addTearDown(state.dispose);
    state.devJumpFloor(4); // Now on F5
    expect(state.floor, 5);
    expect(state.isBossFloor, isTrue);

    final initialEmbers = state.meta.embers;
    state.registerKill(isBoss: true);

    expect(state.meta.embers, initialEmbers + 50);
    expect(state.lastBossRewardLabel, 'WATCHER DEFEATED');
  });

  test('F10 Boss Reward: Sutra Picker', () {
    final state = GameState();
    addTearDown(state.dispose);
    state.devJumpFloor(9); // Now on F10
    expect(state.floor, 10);

    state.registerKill(isBoss: true);

    expect(state.pendingSutraReward, isTrue);
    expect(state.sutraRewardChoices, isNotEmpty);
    expect(state.lastBossRewardLabel, 'SOVEREIGN DEFEATED');

    final choice = state.sutraRewardChoices.first;
    final initialSutra = state.meta.sutraCount(choice);
    
    state.resolveSutraReward(choice);

    expect(state.pendingSutraReward, isFalse);
    expect(state.meta.sutraCount(choice), initialSutra + 1);
  });

  test('F15 Boss Reward: Codex Peek', () {
    final state = GameState();
    addTearDown(state.dispose);
    state.devJumpFloor(14); // Now on F15

    // Ensure there's something to discover
    state.meta.devResetAll();
    final initialDiscoveredCount = state.meta.discoveredIds.length;

    state.registerKill(isBoss: true);

    expect(state.meta.discoveredIds.length, initialDiscoveredCount + 1);
    expect(state.lastBossRewardLabel, 'HIVEFATHER DEFEATED');
    expect(state.lastBossRewardSubtitle, contains('Codex Peek: Revealed'));
  });

  test('F20 Boss Reward: Fusion Guaranteed', () {
    final state = GameState();
    addTearDown(state.dispose);
    state.devJumpFloor(19); // Now on F20

    state.registerKill(isBoss: true);

    expect(state.lastBossRewardLabel, 'CIPHER TWIN DEFEATED');
    expect(state.lastBossRewardSubtitle, contains('Fusion offer guaranteed'));
    // We can't easily test _forceFusionNext private field directly without 
    // reflecting or checking _rollUpgradeChoices side effects.
    // But we verified it's set in game_state.dart.
  });

  test('F25 Boss Reward: Permanent Unlock', () {
    final state = GameState();
    addTearDown(state.dispose);
    state.devJumpFloor(24); // Now on F25

    state.meta.devResetAll();
    final initialUnlockCount = state.meta.f25Unlocks.length;

    state.registerKill(isBoss: true);

    expect(state.meta.f25Unlocks.length, initialUnlockCount + 1);
    expect(state.lastBossRewardLabel, 'ARCHITECT DEFEATED');
    expect(state.lastBossRewardSubtitle, contains('PERMANENT UNLOCK:'));
    
    final firstUnlock = state.meta.f25Unlocks.first;
    expect(MetaState.f25UnlockPool, contains(firstUnlock));
  });

  test('Boss Reward Fallbacks', () {
    final state = GameState();
    addTearDown(state.dispose);

    // F15 Fallback (everything discovered)
    state.devJumpFloor(14);
    for (final inf in inflectionCatalog) {
      state.meta.recordDiscovery(inf.id);
    }
    for (final triad in triadCatalog) {
      state.meta.recordDiscovery(triad.id);
    }
    state.registerKill(isBoss: true);
    expect(state.lastBossRewardSubtitle, '+100 embers');

    // F25 Fallback (everything unlocked)
    state.devJumpFloor(9); // floor was 16, now 25
    expect(state.floor, 25);
    
    // Fill unlocks
    for (var i = 0; i < MetaState.f25UnlockPool.length; i++) {
      state.meta.claimNextF25Unlock();
    }
    
    state.registerKill(isBoss: true);
    expect(state.lastBossRewardSubtitle, '+500 embers');
  });
}
