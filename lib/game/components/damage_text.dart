import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class DamageText extends TextComponent {
  DamageText({required Vector2 position, required int amount})
    : super(
        text: amount.toString(),
        position: position,
        anchor: Anchor.bottomCenter,
        priority: 1000,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Color(0xFFFFEB3B),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: Colors.black, blurRadius: 3, offset: Offset(1, 1)),
            ],
          ),
        ),
      );

  @override
  Future<void> onLoad() async {
    add(MoveByEffect(
      Vector2(0, -50),
      EffectController(duration: 0.6, curve: Curves.easeOut),
      onComplete: removeFromParent,
    ));
  }
}
