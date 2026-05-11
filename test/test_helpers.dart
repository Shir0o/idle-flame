import 'package:zenith_zero/game/zenith_zero_game.dart';
import 'package:zenith_zero/game/audio/game_audio.dart';

class MockGameAudio extends GameAudio {
  @override
  Future<void> load() async {}
  @override
  void playHit() {}
  @override
  void playBasicAttack() {}
  @override
  void playSkillCast() {}
  @override
  void playSkillDamage(SkillSound sound) {}
  @override
  void playRandomSkillDamage() {}
  @override
  void playEnemyDeath() {}
  @override
  Future<void> dispose() async {}
}

class TestZenithZeroGame extends ZenithZeroGame {
  TestZenithZeroGame({required super.state}) : super(audio: MockGameAudio());
}
