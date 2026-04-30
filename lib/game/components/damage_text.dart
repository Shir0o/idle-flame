import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class DamageText extends TextComponent {
  DamageText({
    required Vector2 position,
    required int amount,
    this.color = const Color(0xFFFFEB3B),
    double scale = 1,
  }) : _baseFontSize = 20 * scale,
       _drift = Vector2((_rng.nextDouble() - 0.5) * 42, -72),
       _start = position.clone(),
       super(
         text: amount.toString(),
         position: position,
         anchor: Anchor.bottomCenter,
         priority: 1000,
         textRenderer: TextPaint(
           style: TextStyle(
             color: color,
             fontSize: 20 * scale,
             fontWeight: FontWeight.w800,
             shadows: const [
               Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
               Shadow(color: Colors.black, blurRadius: 9),
             ],
           ),
         ),
       );

  final Color color;
  final double _baseFontSize;
  final Vector2 _drift;
  final Vector2 _start;
  double _age = 0;

  static final math.Random _rng = math.Random();
  static const double _duration = 0.72;

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    final t = (_age / _duration).clamp(0.0, 1.0);
    final eased = Curves.easeOutCubic.transform(t);
    position = _start + _drift * eased;
    final alpha = (1 - Curves.easeIn.transform(t)).clamp(0.0, 1.0);
    final pop = 1 + math.sin(t * math.pi) * 0.18;
    textRenderer = TextPaint(
      style: TextStyle(
        color: color.withValues(alpha: alpha),
        fontSize: _baseFontSize * pop,
        fontWeight: FontWeight.w800,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: alpha),
            blurRadius: 4,
            offset: const Offset(1, 1),
          ),
          Shadow(
            color: Colors.black.withValues(alpha: alpha * 0.75),
            blurRadius: 9,
          ),
        ],
      ),
    );
    if (_age >= _duration) removeFromParent();
  }
}
