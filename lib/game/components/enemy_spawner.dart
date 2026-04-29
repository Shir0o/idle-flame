import 'dart:math';

import 'package:flame/components.dart';

import '../idle_game.dart';
import 'enemy.dart';

class EnemySpawner extends Component with HasGameReference<IdleGame> {
  final Random _rng = Random();
  double _timer = 0;

  static const double _spawnInterval = 1.5;
  static const double _offscreenPad = 40;

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    if (_timer >= _spawnInterval) {
      _timer = 0;
      _spawn();
    }
  }

  void _spawn() {
    final size = game.size;
    final edge = _rng.nextInt(4);
    late Vector2 pos;
    switch (edge) {
      case 0:
        pos = Vector2(_rng.nextDouble() * size.x, -_offscreenPad);
        break;
      case 1:
        pos = Vector2(size.x + _offscreenPad, _rng.nextDouble() * size.y);
        break;
      case 2:
        pos = Vector2(_rng.nextDouble() * size.x, size.y + _offscreenPad);
        break;
      default:
        pos = Vector2(-_offscreenPad, _rng.nextDouble() * size.y);
    }
    parent?.add(Enemy(position: pos, maxHp: game.state.enemyMaxHp));
  }
}
