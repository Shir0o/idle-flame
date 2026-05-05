import 'dart:math';

import 'package:flame/components.dart';

import '../zenith_zero_game.dart';
import 'enemy.dart';

class EnemySpawner extends Component with HasGameReference<ZenithZeroGame> {
  final Random _rng = Random();
  double _timer = 0;

  static const double _spawnInterval = 1.5;
  static const double _offscreenPad = 40;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state.hasPendingLevelUp ||
        game.state.isRunOver ||
        game.state.devPauseSpawning) {
      return;
    }
    _timer += dt;
    if (_timer >= _spawnInterval) {
      _timer = 0;
      _spawn();
    }
  }

  void resetForNewRun() {
    _timer = 0;
  }

  void _spawn() {
    final size = game.size;
    final pos = Vector2(_rng.nextDouble() * size.x, -_offscreenPad);
    parent?.add(Enemy(position: pos, maxHp: game.state.enemyMaxHp));
  }
}
