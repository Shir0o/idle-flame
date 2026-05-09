import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../zenith_zero_game.dart';

class DamageText extends TextComponent with HasGameReference<ZenithZeroGame> {
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
  static int _aliveCount = 0;
  static const int _maxAlive = 80;
  static bool get atCap => _aliveCount >= _maxAlive;

  static TextPaint _getPaint(Color color) {
    return _paintCache.putIfAbsent(
      color,
      () => TextPaint(
        style: TextStyle(
          color: color,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
          shadows: [
            const Shadow(color: Colors.black, offset: Offset(-1.5, -1.5)),
            const Shadow(color: Colors.black, offset: Offset(1.5, -1.5)),
            const Shadow(color: Colors.black, offset: Offset(-1.5, 1.5)),
            const Shadow(color: Colors.black, offset: Offset(1.5, 1.5)),
            Shadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
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
  static const double _duration = 0.8;

  @override
  void onMount() {
    super.onMount();
    _aliveCount++;
  }

  @override
  void onRemove() {
    _aliveCount = math.max(0, _aliveCount - 1);
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state.hasPendingLevelUp || game.state.isRunOver) return;
    _age += dt;
    final t = (_age / _duration).clamp(0.0, 1.0);

    // Arching movement
    final eased = Curves.easeOutQuad.transform(t);
    final arch = math.sin(t * math.pi) * 15 * (_drift.x > 0 ? 1 : -1);
    position = _start + _drift * eased + Vector2(arch, 0);

    // Pop and Scale down to zero
    final pop = _initialScale * (1.1 + math.sin(t * math.pi) * 0.2);
    scale = Vector2.all(pop * (1.0 - t));

    if (_age >= _duration) removeFromParent();
  }
}
