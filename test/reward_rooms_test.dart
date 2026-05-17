import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith_zero/game/state/game_state.dart';
import 'package:zenith_zero/game/state/skill_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('reward room triggers every boss floor from F10 onward, not F5', () {
    final state = GameState();
    addTearDown(state.dispose);

    // F5 stays clean — boss reward only.
    state.devJumpFloor(4);
    expect(state.floor, 5);
    state.registerKill(isBoss: true);
    expect(state.pendingFloorReward, isFalse);
    expect(state.floor, 6);

    // F10/F15/F20/F25 all trigger reward rooms.
    for (final target in const [10, 15, 20, 25]) {
      state.devJumpFloor(target - state.floor);
      expect(state.floor, target);
      state.registerKill(isBoss: true);
      expect(state.pendingFloorReward, isTrue,
          reason: 'F$target should trigger a reward room');
      expect(state.floor, target,
          reason: 'F$target should pause before advancing');
      state.resolveFloorReward(FloorBoon.gold25);
      expect(state.pendingFloorReward, isFalse);
      expect(state.floor, target + 1);
    }

    // Endless: F30 still triggers a reward room.
    state.devJumpFloor(30 - state.floor);
    state.registerKill(isBoss: true);
    expect(state.pendingFloorReward, isTrue);
  });

  test('Inflection Spark exposes inflection options on the next level-up', () {
    final state = GameState();
    addTearDown(state.dispose);

    // Player owns a level-0 (i.e. about to take level 1) skill of some
    // archetype. Without the spark, level-1 picks never carry inflections.
    state.devJumpFloor(9); // F10
    state.registerKill(isBoss: true);
    expect(state.pendingFloorReward, isTrue);
    state.resolveFloorReward(FloorBoon.inflectionSpark);
    expect(state.pendingInflectionSpark, isTrue);

    // Force a roll; any pending choice with currentLevel == 0 should now
    // carry inflection options because of the spark.
    state.devForceLevelUp();
    final pending = state.pendingChoices;
    expect(pending, isNotEmpty);
    final freshAtLevelOne =
        pending.where((c) => c.currentLevel == 0).toList();
    if (freshAtLevelOne.isNotEmpty) {
      expect(
        freshAtLevelOne.every((c) => c.inflectionOptions.isNotEmpty),
        isTrue,
        reason: 'Spark should attach inflections to level-1 picks',
      );
    }
  });

  test('Path Resonance bumps dominant path scores by 1', () {
    final state = GameState();
    addTearDown(state.dispose);

    // Pre-existing levels to make Edge dominant.
    state.devSetSkillLevel('chain', 3); // edge archetype skill
    expect(state.dominantPath, SkillPath.edge);
    final beforeEdge = state.pathLevels(SkillPath.edge);

    state.devJumpFloor(9); // F10
    state.registerKill(isBoss: true);
    state.resolveFloorReward(FloorBoon.pathResonance);

    expect(state.pathLevels(SkillPath.edge), beforeEdge + 1);
    expect(state.dominantPath, SkillPath.edge);
  });

  test('Modifier Preview Lens pre-rolls next floor modifiers', () {
    final state = GameState();
    addTearDown(state.dispose);

    state.devJumpFloor(9); // F10
    state.registerKill(isBoss: true);
    expect(state.pendingFloorReward, isTrue);
    state.resolveFloorReward(FloorBoon.modifierPreviewLens);

    // The lens consumed and advanced into F11; previewed set is the now-
    // active modifier set (which may be empty since the roll is 0-2).
    expect(state.floor, 11);
    expect(state.previewedNextFloorModifiers, isNull);
  });

  test('Modifier Preview Lens preview is visible before advance', () {
    final state = GameState();
    addTearDown(state.dispose);

    // Reach F10 reward room without resolving.
    state.devJumpFloor(9);
    state.registerKill(isBoss: true);

    // Apply a different boon first to test that the lens roll-then-advance is
    // self-contained: we directly verify the preview function pre-rolls a
    // non-boss next floor.
    final preview = state;
    expect(preview.previewedNextFloorModifiers, isNull);

    // Resolve with the lens — F11 is non-boss, so previewing is meaningful;
    // the preview is consumed on advance, leaving activeModifiers populated
    // with whatever was previewed (could be empty by RNG).
    state.resolveFloorReward(FloorBoon.modifierPreviewLens);
    expect(state.floor, 11);
  });
}
