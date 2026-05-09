import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../zenith_zero_game.dart';
import 'enemy.dart';
import 'combat_effects.dart';
import 'fire_snake.dart';

enum SummonType { wolf, salamander, phoenix, avatar }

class FireSummon extends PositionComponent
    with HasGameReference<ZenithZeroGame> {
  FireSummon({
    required Vector2 startPos,
    required this.type,
    required this.level,
    required this.damage,
  }) : super(
          position: startPos,
          priority: 61,
          size: Vector2.all(type == SummonType.avatar ? 40 : 20),
        );

  final SummonType type;
  final int level;
  final double damage;

  double _totalTime = 0;
  double _lifeTime = 0;
  static const double _maxLife = 5.0;

  Enemy? _target;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state.isRunOver) {
      removeFromParent();
      return;
    }
    _totalTime += dt;
    _lifeTime += dt;
    if (_lifeTime >= _maxLife) {
      removeFromParent();
      return;
    }

    // Target acquisition
    if (_target == null || !_target!.isAlive) {
      final targets = game.selectNearestEnemies(position, 1);
      if (targets.isNotEmpty) {
        _target = targets.first;
      }
    }

    _move(dt);
    _applyDamage(dt);
  }

  void _move(double dt) {
    switch (type) {
      case SummonType.wolf:
        _moveWolf(dt);
        break;
      case SummonType.salamander:
        _moveSalamander(dt);
        break;
      case SummonType.phoenix:
        _movePhoenix(dt);
        break;
      case SummonType.avatar:
        _moveAvatar(dt);
        break;
    }
  }

  void _moveWolf(double dt) {
    // Wolf: Jumps/Dashes at target
    if (_target != null) {
      final toTarget = _target!.position - position;
      final dist = toTarget.length;
      final speed = 300.0;
      if (dist > 10) {
        position += toTarget.normalized() * speed * dt;
        angle = math.atan2(toTarget.y, toTarget.x);
      }
    }
  }

  void _moveSalamander(double dt) {
    // Salamander: Slow crawl
    if (_target != null) {
      final toTarget = _target!.position - position;
      final speed = 120.0;
      position += toTarget.normalized() * speed * dt;
      angle = math.atan2(toTarget.y, toTarget.x);
    }
  }

  void _movePhoenix(double dt) {
    // Phoenix: Fast sweeping flight (sine wave)
    final speed = 450.0;
    final forward = Vector2(0, -1);
    if (_target != null) {
      forward.setFrom((_target!.position - position).normalized());
    }

    final side = Vector2(-forward.y, forward.x);
    final wave = math.sin(_totalTime * 8) * 150.0;

    position += forward * speed * dt + side * wave * dt;
    angle = math.atan2(forward.y, forward.x);
  }

  void _moveAvatar(double dt) {
    // Avatar: Faster crawl with occasional dash
    if (_target != null) {
      final toTarget = _target!.position - position;
      final speed = 180.0 + (math.sin(_totalTime * 4).abs() * 200.0);
      position += toTarget.normalized() * speed * dt;
      angle = math.atan2(toTarget.y, toTarget.x);
    }
  }

  void _applyDamage(double dt) {
    final hitRadius = switch (type) {
      SummonType.salamander => 60.0,
      SummonType.avatar => 90.0,
      _ => 30.0,
    };
    final hitRadiusSq = hitRadius * hitRadius;

    final dmgMult = switch (type) {
      SummonType.salamander => 0.6,
      SummonType.avatar => 2.5,
      _ => 1.5,
    };

    for (final enemy in game.targetableEnemies) {
      if ((enemy.position - position).length2 < hitRadiusSq) {
        enemy.takeDamage(
          damage * dt * dmgMult,
          source: position,
          type: DamageType.firewall,
        );

        // Spirit Choir Triad: Summons emit nova pulses on attack
        if (game.state.hasTriad('spirit_choir')) {
          _pulseTimer += dt;
          if (_pulseTimer >= 0.5) {
            _pulseTimer = 0;
            if (game.canSpawnMinorEffect()) {
              parent?.add(
                NovaPulseEffect(
                  effectCenter: position.clone(),
                  radius: 60,
                  level: 1,
                  color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                ),
              );
            }
          }
        }
      }
    }

    // Hellgate Choir Triad: Ignite snakes on contact
    if (game.state.hasTriad('hellgate_choir')) {
      final snakes = parent?.children.whereType<FireSnake>();
      if (snakes != null) {
        for (final snake in snakes) {
          if ((snake.position - position).length2 < 50 * 50) {
            snake.ignite();
          }
        }
      }
    }
  }

  double _pulseTimer = 0;

  @override
  void render(Canvas canvas) {
    final t = (_lifeTime / _maxLife).clamp(0.0, 1.0);
    final alpha = 1.0 - math.pow(t, 4).toDouble();

    switch (type) {
      case SummonType.wolf:
        _renderWolf(canvas, alpha);
        break;
      case SummonType.salamander:
        _renderSalamander(canvas, alpha);
        break;
      case SummonType.phoenix:
        _renderPhoenix(canvas, alpha);
        break;
      case SummonType.avatar:
        _renderAvatar(canvas, alpha);
        break;
    }
  }

  void _renderWolf(Canvas canvas, double alpha) {
    final paint = Paint()
      ..color = const Color(0xFFFF6D00).withValues(alpha: alpha)
      ..style = PaintingStyle.fill;

    final body = Path()
      ..moveTo(12, 0)
      ..lineTo(-8, -8)
      ..lineTo(-12, 0)
      ..lineTo(-8, 8)
      ..close();

    canvas.drawPath(body, paint);

    // Eyes
    final eyePaint = Paint()..color = Colors.white.withValues(alpha: alpha);
    canvas.drawCircle(const Offset(6, -3), 1.5, eyePaint);
    canvas.drawCircle(const Offset(6, 3), 1.5, eyePaint);
  }

  void _renderSalamander(Canvas canvas, double alpha) {
    final paint = Paint()
      ..color = const Color(0xFFFFAB40).withValues(alpha: alpha)
      ..style = PaintingStyle.fill;

    final body = Path()
      ..moveTo(15, 0)
      ..lineTo(0, -10)
      ..lineTo(-15, 0)
      ..lineTo(0, 10)
      ..close();

    canvas.drawPath(body, paint);

    // Aura
    final auraPaint = Paint()
      ..color = const Color(0xFFFF3D00).withValues(alpha: alpha * 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset.zero, 45, auraPaint);
  }

  void _renderPhoenix(Canvas canvas, double alpha) {
    final paint = Paint()
      ..color = const Color(0xFFFFD166).withValues(alpha: alpha)
      ..style = PaintingStyle.fill;

    final body = Path()
      ..moveTo(18, 0)
      ..lineTo(-10, -15)
      ..lineTo(-10, 15)
      ..close();

    // Wings
    final wingT = math.sin(_totalTime * 12);
    final wing = Path()
      ..moveTo(0, 0)
      ..lineTo(-5, -25 * wingT.abs())
      ..lineTo(-15, 0)
      ..close();

    canvas.drawPath(body, paint);
    canvas.save();
    canvas.drawPath(wing, paint);
    canvas.scale(1, -1);
    canvas.drawPath(wing, paint);
    canvas.restore();

    // Tail trail
    final tailPaint = Paint()
      ..color = const Color(0xFFFF3D00).withValues(alpha: alpha * 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(const Offset(-15, 0), 10, tailPaint);
  }

  void _renderAvatar(Canvas canvas, double alpha) {
    // Avatar: Combination of all colors/shapes, but bigger
    final paint = Paint()
      ..color = const Color(0xFFFF6D00).withValues(alpha: alpha)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, 15, paint);

    final auraPaint = Paint()
      ..color = const Color(0xFFFF3D00).withValues(alpha: alpha * 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset.zero, 60, auraPaint);

    // Tech detail
    final eyePaint = Paint()..color = Colors.white.withValues(alpha: alpha);
    canvas.drawCircle(const Offset(8, -5), 3, eyePaint);
    canvas.drawCircle(const Offset(8, 5), 3, eyePaint);

    // Wings (faint)
    final wing = Path()
      ..moveTo(0, 0)
      ..lineTo(-10, -40)
      ..lineTo(-30, 0)
      ..close();
    final wingPaint = Paint()
      ..color = const Color(0xFFFFD166).withValues(alpha: alpha * 0.4);
    canvas.drawPath(wing, wingPaint);
    canvas.save();
    canvas.scale(1, -1);
    canvas.drawPath(wing, wingPaint);
    canvas.restore();
  }
}
