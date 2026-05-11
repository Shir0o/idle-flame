import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith_zero/game/state/game_state.dart';
import 'package:zenith_zero/game/state/skill_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GameState Persistence & Migration Edge Cases', () {
    test('load() handles missing SharedPreferences keys gracefully', () async {
      final state = GameState();
      await state.load();

      expect(state.gold, 0);
      expect(state.floor, 1);
      expect(state.totalRuns, 1);
      expect(state.skillLevels, isEmpty);
    });

    test('load() handles malformed skillLevels strings', () async {
      SharedPreferences.setMockInitialValues({
        'skillLevels': [
          'chain:3',
          'bad_entry', // No separator
          ':5', // Empty ID
          'nova:not_a_num', // Bad level
          'focus:0', // Zero level
          'barrage:10', // Over maxLevel (should clamp)
        ],
      });

      final state = GameState();
      await state.load();

      expect(state.skillLevel('chain'), 3);
      expect(state.skillLevel('nova'), 0);
      expect(state.skillLevel('focus'), 0);
      expect(state.skillLevel('barrage'), SkillDefinition.maxLevel);
    });

    test('migration from legacy keys (v0.1)', () async {
      SharedPreferences.setMockInitialValues({
        'emberChainLevel': 3,
        'flameNovaLevel': 2,
        'damageLevel': 5,
      });

      final state = GameState();
      await state.load();

      expect(state.skillLevel('chain'), 3);
      expect(state.skillLevel('nova'), 2);
      expect(state.skillLevel('focus'), 5);
    });

    test('migration from legacy slugs (v0.2)', () async {
      SharedPreferences.setMockInitialValues({
        'skillLevels': ['neon_katana_chain:4', 'mana_reactor_nova:1'],
      });

      final state = GameState();
      await state.load();

      expect(state.skillLevel('chain'), 4);
      expect(state.skillLevel('nova'), 1);
    });
  });

  group('Simultaneous Reward Logic', () {
    test('rapid registerKill calls accumulate correctly', () {
      final state = GameState();
      final initialGold = state.gold;
      final killReward = state.goldPerKill;

      for (var i = 0; i < 100; i++) {
        state.registerKill();
      }

      expect(state.gold, initialGold + 100 * killReward);
      expect(state.runKills, 100);
      expect(state.lifetimeKills, 100);
    });
  });
}
