import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../idle_game.dart';
import 'enemy.dart';

class SentinelBlade extends PositionComponent with HasGameReference<IdleGame> {
  SentinelBlade({required this.orbitIndex, this.level = 1}) : super(priority: 62);

  final int orbitIndex;
  final int level;
  double _orbitAngle = 0;
  Enemy? _target;
  double _attackTimer = 0;
  
  static const double _orbitRadius = 60;
  static const double _orbitSpeed = 2.4;
  static const double _attackRange = double.infinity;
  static const double _attackCooldown = 0.8;
  static const double _dashSpeed = 650;

  final Paint _bladePaint = Paint()
    ..color = const Color(0xFFE1F5FE)
    ..style = PaintingStyle.fill;

  final Paint _glowPaint = Paint()
    ..color = const Color(0xFF00B0FF).withValues(alpha: 0.4)
    ..style = PaintingStyle.fill;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state.isRunOver) {
      removeFromParent();
      return;
    }
    if (game.state.hasPendingLevelUp) return;

    final heroPos = game.hero.position;
    _attackTimer = math.max(0, _attackTimer - dt);

    if (_target != null && (!_target!.isAlive || (_target!.position - heroPos).length2 > _attackRange * _attackRange)) {
      _target = null;
    }

    if (_target == null) {
      _findTarget(heroPos);
    }

    if (_target != null && _attackTimer <= 0) {
      _dashAtTarget(dt);
    } else {
      _returnToOrbit(heroPos, dt);
    }
  }

  void _findTarget(Vector2 heroPos) {
    final enemies = game.aliveEnemies;
    if (enemies.isEmpty) return;

    Enemy? best;
    double minDist = double.infinity;
    for (final e in enemies) {
      final d2 = (e.position - heroPos).length2;
      if (d2 < _attackRange * _attackRange && d2 < minDist) {
        minDist = d2;
        best = e;
      }
    }
    _target = best;
  }

  void _dashAtTarget(double dt) {
    if (_target == null) return;
    
    final toTarget = _target!.position - position;
    if (toTarget.length < 10) {
      _target!.takeDamage(game.state.sentinelDamage, source: position, type: DamageType.basic);
      if (game.state.meta.hasKeystone('twinblade') && _target!.isAlive) {
        _target!.takeDamage(
          game.state.sentinelDamage * 0.6,
          source: position,
          type: DamageType.basic,
        );
      }
      _attackTimer = _attackCooldown;
      return;
    }
    
    position += toTarget.normalized() * _dashSpeed * dt;
    angle = math.atan2(toTarget.y, toTarget.x) + math.pi / 4;
  }

  void _returnToOrbit(Vector2 heroPos, double dt) {
    _orbitAngle += _orbitSpeed * dt;
    final offset = orbitIndex * (math.pi * 2 / 8);
    final targetOrbitPos = heroPos + Vector2(
      math.cos(_orbitAngle + offset) * _orbitRadius,
      math.sin(_orbitAngle + offset) * _orbitRadius,
    );

    final toOrbit = targetOrbitPos - position;
    if (toOrbit.length2 > 1) {
      position += toOrbit * 5 * dt;
    } else {
      position = targetOrbitPos;
    }
    
    // Point outwards from center when orbiting
    final fromHero = position - heroPos;
    angle = math.atan2(fromHero.y, fromHero.x) + math.pi / 4;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Draw a small diamond-shaped blade
    canvas.save();
    canvas.rotate(math.pi / 4); // Adjust for the diamond shape
    
    final sizeBase = 12.0 * (level >= 3 ? 1.3 : 1.0);
    final rect = Rect.fromCenter(center: Offset.zero, width: sizeBase, height: sizeBase);
    
    // Evolution: Larger glow at high levels
    final glowSize = 4.0 * (level >= 4 ? 1.8 : 1.0);
    canvas.drawRect(rect.inflate(glowSize), _glowPaint);
    canvas.drawRect(rect, _bladePaint);

    // Evolution: Mastery Level 5 - Orbiting Shards
    if (level >= 5) {
      final shardPaint = Paint()
        ..color = const Color(0xFFE1F5FE).withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;
      
      final shardGlow = Paint()
        ..color = const Color(0xFF00B0FF).withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      // Note: we can use _orbitAngle as a base for shard rotation too
      for (var i = 0; i < 3; i++) {
        final shardAngle = (_orbitAngle * 2.0) + (i * math.pi * 2 / 3);
        final dist = 14.0;
        final shardPos = Offset(math.cos(shardAngle) * dist, math.sin(shardAngle) * dist);
        final shardRect = Rect.fromCenter(center: shardPos, width: 4, height: 4);
        canvas.drawRect(shardRect.inflate(2), shardGlow);
        canvas.drawRect(shardRect, shardPaint);
      }
    }
    
    canvas.restore();
  }
}
