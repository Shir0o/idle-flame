import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../idle_game.dart';
import 'damage_text.dart';

class Enemy extends RectangleComponent with HasGameReference<IdleGame> {
  Enemy({required Vector2 position, required this.maxHp})
    : hp = maxHp,
      super(
        position: position,
        size: Vector2(36, 36),
        anchor: Anchor.center,
        paint: Paint()..color = _baseColor,
      );

  final double maxHp;
  double hp;
  double _flashTimer = 0;
  bool _dying = false;
  bool get isAlive => !_dying;

  static const double _speed = 60;
  static const double _stopRadius = 70;
  static const Color _baseColor = Color(0xFFFF2D95);

  @override
  void update(double dt) {
    super.update(dt);
    if (_flashTimer > 0) {
      _flashTimer -= dt;
      if (_flashTimer <= 0) paint.color = _baseColor;
    }
    if (game.state.hasPendingLevelUp) return;
    if (_dying) return;
    final hero = game.hero;
    final toHero = hero.position - position;
    final dist = toHero.length;
    if (dist > _stopRadius) {
      position +=
          toHero.normalized() * _speed * game.state.enemySpeedMultiplier * dt;
    }
  }

  void takeDamage(double amount) {
    if (_dying) return;
    final executeBonus = hp / maxHp <= 0.5
        ? game.state.executeDamageMultiplier
        : 1.0;
    final finalAmount = amount * executeBonus;
    hp -= finalAmount;
    parent?.add(
      DamageText(
        position: position + Vector2(0, -size.y / 2),
        amount: finalAmount.round(),
      ),
    );
    paint.color = Colors.white;
    _flashTimer = 0.08;
    if (hp <= 0) _die();
  }

  void _die() {
    _dying = true;
    game.state.registerKill();
    add(
      ScaleEffect.to(
        Vector2.zero(),
        EffectController(duration: 0.18, curve: Curves.easeIn),
        onComplete: removeFromParent,
      ),
    );
  }
}
