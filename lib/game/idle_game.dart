import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'components/enemy_spawner.dart';
import 'components/hero.dart';
import 'state/game_state.dart';

class IdleGame extends FlameGame {
  IdleGame({required this.state});

  final GameState state;
  late final HeroComponent hero;
  late final EnemySpawner spawner;

  @override
  Color backgroundColor() {
    final t = ((state.floor - 1) * 0.05).clamp(0.0, 0.7);
    return Color.lerp(
      const Color(0xFF0D0D1A),
      const Color(0xFF35103F),
      t,
    )!;
  }

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.position = Vector2.zero();

    hero = HeroComponent();
    spawner = EnemySpawner();
    world.add(hero);
    world.add(spawner);
  }
}
