import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../idle_game.dart';
import 'enemy.dart';

class HeroComponent extends RectangleComponent with HasGameReference<IdleGame> {
  HeroComponent()
    : super(
        size: Vector2(48, 48),
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFF42A5F5),
      );

  static const double attackRange = 260;

  double _attackTimer = 0;

  @override
  void onMount() {
    super.onMount();
    position = game.size / 2;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = size / 2;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final period = 1.0 / game.state.heroAttacksPerSec;
    _attackTimer += dt;
    if (_attackTimer >= period) {
      _attackTimer = 0;
      _tryAttack();
    }
  }

  void _tryAttack() {
    final siblings = parent?.children ?? const Iterable.empty();
    Enemy? closest;
    double closestDist = attackRange;
    for (final c in siblings) {
      if (c is! Enemy) continue;
      final d = (c.position - position).length;
      if (d < closestDist) {
        closest = c;
        closestDist = d;
      }
    }
    closest?.takeDamage(game.state.heroDamage);
  }
}
