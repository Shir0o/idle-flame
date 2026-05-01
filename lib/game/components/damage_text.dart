import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../idle_game.dart';

class DamageText extends TextComponent with HasGameReference<IdleGame> {
  DamageText({
    required Vector2 position,
    required int amount,
    this.color = const Color(0xFFFFEB3B),
    double scale = 1,
  }) : _initialScale = scale,
       _drift = Vector2((_rng.nextDouble() - 0.5) * 42, -72),
       _start = position.clone(),
       super(
         text: amount.toString(),
         position: position,
         anchor: Anchor.bottomCenter,
         priority: 1000,
         textRenderer: _getPaint(color),
       ) {
    this.scale = Vector2.all(scale);
  }

  static final Map<Color, TextPaint> _paintCache = {};

  static TextPaint _getPaint(Color color) {
    return _paintCache.putIfAbsent(
      color,
      () => TextPaint(
        style: TextStyle(
          color: color,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          shadows: const [
            Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
            Shadow(color: Colors.black, blurRadius: 9),
          ],
        ),
      ),
    );
  }

  final Color color;
  final double _initialScale;
  final Vector2 _drift;
  final Vector2 _start;
  double _age = 0;

  static final math.Random _rng = math.Random();
  static const double _duration = 0.72;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state.hasPendingLevelUp || game.state.isRunOver) return;
    _age += dt;
    final t = (_age / _duration).clamp(0.0, 1.0);
    final eased = Curves.easeOutCubic.transform(t);
    position = _start + _drift * eased;
    final pop = _initialScale * (1 + math.sin(t * math.pi) * 0.18);
    scale = Vector2.all(pop);
    if (_age >= _duration) removeFromParent();
  }
}
