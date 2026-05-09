import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../zenith_zero_game.dart';
import 'enemy.dart';

class EnemyAfterimage extends PositionComponent with HasGameReference<ZenithZeroGame> {
  EnemyAfterimage({
    required Vector2 position,
    required Vector2 size,
    required Path path,
    required Color color,
  }) : _path = path,
       _color = color,
       super(position: position, size: size, anchor: Anchor.center);

  final Path _path;
  final Color _color;
  double _timer = 0.6;
  static const double _duration = 0.6;

  @override
  void render(Canvas canvas) {
    final opacity = (_timer / _duration).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = _color.withValues(alpha: opacity * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    canvas.drawPath(_path, paint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer -= dt;
    if (_timer <= 0) removeFromParent();
  }
}

class SpectralKatana extends PositionComponent with HasGameReference<ZenithZeroGame> {
  SpectralKatana() : super(size: Vector2(40, 4), anchor: Anchor.centerLeft);

  double _angle = 0;
  final double _orbitRadius = 80;
  final double _rotationSpeed = 4.0;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state.isRunOver) {
      removeFromParent();
      return;
    }
    _angle += _rotationSpeed * dt;
    final heroPos = game.hero.position;
    position = heroPos + Vector2(math.cos(_angle), math.sin(_angle)) * _orbitRadius;
    angle = _angle + math.pi / 2;

    // Contact damage
    final hitRadiusSq = 30 * 30;
    for (final enemy in game.targetableEnemies) {
      if ((enemy.position - position).length2 <= hitRadiusSq) {
        enemy.takeDamage(
          game.state.heroDamage * 0.5 * dt * 10, // DPS-like damage
          source: position,
          type: DamageType.basic,
        );
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFFE0F7FA).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(40, 2)
      ..lineTo(0, 4)
      ..close();
    
    canvas.drawPath(path, paint);

    // Glow
    final glowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, glowPaint);
  }
}

class CompanionDrone extends PositionComponent with HasGameReference<ZenithZeroGame> {
  CompanionDrone() : super(size: Vector2.all(12), anchor: Anchor.center);

  double _timer = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state.isRunOver) {
      removeFromParent();
      return;
    }
    _timer += dt;
    final heroPos = game.hero.position;
    final target = heroPos + Vector2(math.cos(_timer) * 40, -50 + math.sin(_timer * 1.5) * 10);
    position.lerp(target, 0.1);
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFFE040FB);
    canvas.drawCircle(Offset(size.x/2, size.y/2), size.x/2, paint);
    
    final eyePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size.x * 0.7, size.y * 0.4), 2, eyePaint);
  }
}

class WardCircle extends PositionComponent with HasGameReference<ZenithZeroGame> {
  WardCircle() : super(anchor: Anchor.center);

  double _phase = 0;
  final double _radius = 120;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state.isRunOver) {
      removeFromParent();
      return;
    }
    _phase += dt;
    position = game.hero.position;

    final radiusSq = _radius * _radius;
    for (final enemy in game.targetableEnemies) {
      if ((enemy.position - position).length2 <= radiusSq) {
        // Slow and Burn
        enemy.position -= (enemy.position - position).normalized() * 10 * dt; // Subtle pushback/slow
        enemy.takeDamage(
          game.state.heroDamage * 0.2 * dt * 5,
          source: position,
          type: DamageType.nova,
        );
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final pulse = 0.8 + 0.2 * math.sin(_phase * 3);
    final paint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.1 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(Offset.zero, _radius, paint);

    final glowPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.05)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset.zero, _radius, glowPaint);
  }
}

class GoldSigil extends PositionComponent with HasGameReference<ZenithZeroGame> {
  GoldSigil({required Vector2 position}) : super(position: position, size: Vector2.all(32), anchor: Anchor.center);

  double _timer = 5.0;

  @override
  void update(double dt) {
    super.update(dt);
    _timer -= dt;
    if (_timer <= 0 || game.state.isRunOver) {
      removeFromParent();
      return;
    }

    // Check collision with hero
    if ((game.hero.position - position).length2 <= 40 * 40) {
      // Trigger gold double (needs GameState support)
      game.state.triggerGoldBoost(3.0);
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(Offset(size.x/2, size.y/2), size.x/2, paint);
    
    final innerPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.x/2, size.y/2), size.x/3, innerPaint);
  }
}
