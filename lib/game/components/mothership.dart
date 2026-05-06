import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../zenith_zero_game.dart';
import 'enemy.dart';
import 'combat_effects.dart';

class Mothership extends PositionComponent with HasGameReference<ZenithZeroGame> {
  Mothership({this.level = 1}) : super(priority: 65);

  final int level;
  double _spawnTimer = 0;
  double _totalTime = 0;
  
  final Paint _hullPaint = Paint()
    ..color = const Color(0xFFCE93D8)
    ..style = PaintingStyle.fill;
    
  final Paint _glowPaint = Paint()
    ..color = const Color(0xFFE1F5FE).withValues(alpha: 0.6)
    ..style = PaintingStyle.fill;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state.isRunOver || game.state.mothershipLevel == 0) {
      removeFromParent();
      return;
    }
    if (game.state.hasPendingLevelUp) return;

    _totalTime += dt;
    _spawnTimer += dt;

    final heroPos = game.hero.position;
    _orbit(heroPos, dt);

    if (_spawnTimer >= game.state.mothershipSpawnInterval) {
      _spawnTimer = 0;
      _launchDrones();
    }
  }

  void _orbit(Vector2 heroPos, double dt) {
    // Mothership orbits further out and slower than sentinels
    const xBase = 120.0;
    
    // Large figure-eight pattern
    final t = _totalTime * 0.8;
    final hoverX = 24.0 * math.sin(t);
    final hoverY = 16.0 * math.sin(t) * math.cos(t);

    final targetPos = heroPos + Vector2(xBase + hoverX, hoverY);

    // Easing toward the slot
    final k = 1 - math.exp(-4 * dt);
    position += (targetPos - position) * k;

    // Gentle tilt based on movement
    final targetAngle = math.sin(_totalTime * 0.5) * 0.15;
    angle = _lerpAngle(angle, targetAngle, 1 - math.exp(-3 * dt));
  }

  double _lerpAngle(double a, double b, double t) {
    var diff = (b - a) % (2 * math.pi);
    if (diff > math.pi) diff -= 2 * math.pi;
    if (diff < -math.pi) diff += 2 * math.pi;
    return a + diff * t;
  }

  void _launchDrones() {
    final count = game.state.mothershipDroneCount;
    game.audio.playSkillCast();
    
    for (var i = 0; i < count; i++) {
      final offset = Vector2(
        (math.Random().nextDouble() - 0.5) * 20,
        (math.Random().nextDouble() - 0.5) * 20,
      );
      parent?.add(Drone(
        startPos: position + offset,
        level: level,
        damage: game.state.mothershipDroneDamage,
        explode: game.state.mothershipDroneExplode,
      ));
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final size = 28.0;
    
    // Draw Mothership Hull
    final path = Path()
      ..moveTo(size * 0.5, 0)
      ..lineTo(size * 0.3, -size * 0.4)
      ..lineTo(-size * 0.2, -size * 0.5)
      ..lineTo(-size * 0.5, -size * 0.2)
      ..lineTo(-size * 0.5, size * 0.2)
      ..lineTo(-size * 0.2, size * 0.5)
      ..lineTo(size * 0.3, size * 0.4)
      ..close();
      
    // Outer Glow
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFFCE93D8).withValues(alpha: 0.2)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      
    canvas.drawPath(path, _hullPaint);
    
    // Engine Glows
    canvas.drawCircle(Offset(-size * 0.4, -size * 0.2), 3, _glowPaint);
    canvas.drawCircle(Offset(-size * 0.4, size * 0.2), 3, _glowPaint);
    canvas.drawCircle(Offset(size * 0.2, 0), 4, _glowPaint);
    
    // Core Detail
    canvas.drawRect(
      Rect.fromCenter(center: const Offset(0, 0), width: size * 0.4, height: size * 0.1),
      _glowPaint,
    );
  }
}

class Drone extends PositionComponent with HasGameReference<ZenithZeroGame> {
  Drone({
    required Vector2 startPos,
    required this.level,
    required this.damage,
    required this.explode,
  }) : super(position: startPos, size: Vector2.all(8), priority: 64);

  final int level;
  final double damage;
  final bool explode;
  
  Enemy? _target;
  double _age = 0;
  final double _maxLife = 5.0;
  double _speed = 450;
  final List<Vector2> _trail = [];
  static const int _maxTrailPoints = 12;

  @override
  void onMount() {
    super.onMount();
    _speed = 450.0 + (level >= 2 ? 150 : 0);
    _findTarget();
  }

  void _findTarget() {
    final enemies = game.aliveEnemies;
    if (enemies.isEmpty) return;
    
    // Drones prefer enemies furthest along or nearest the nexus
    enemies.sort((a, b) => b.position.x.compareTo(a.position.x));
    _target = enemies.first;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= _maxLife || game.state.isRunOver) {
      removeFromParent();
      return;
    }

    if (_target == null || !_target!.isAlive) {
      _findTarget();
      if (_target == null) {
        // Fly forward if no target
        position += Vector2(math.cos(angle), math.sin(angle)) * _speed * dt;
        return;
      }
    }

    final toTarget = _target!.position - position;
    final dist = toTarget.length;
    
    if (dist < 12) {
      _onHit();
      return;
    }

    // Steering
    final targetAngle = math.atan2(toTarget.y, toTarget.x);
    final turnSpeed = level >= 2 ? 8.0 : 4.0;
    angle = _lerpAngle(angle, targetAngle, 1 - math.exp(-turnSpeed * dt));
    
    position += Vector2(math.cos(angle), math.sin(angle)) * _speed * dt;

    // Trail
    if (_trail.isEmpty || (_trail.first - position).length2 > 16) {
      _trail.insert(0, position.clone());
      if (_trail.length > _maxTrailPoints) _trail.removeLast();
    }
  }

  void _onHit() {
    if (explode) {
      _explode();
    } else {
      _target?.takeDamage(damage, source: position, type: DamageType.mothership);
      parent?.add(HitSparkEffect(
        effectCenter: position.clone(),
        direction: Vector2(math.cos(angle + math.pi), math.sin(angle + math.pi)),
        color: const Color(0xFFCE93D8),
      ));
    }
    removeFromParent();
  }

  void _explode() {
    final blastRadius = 64.0;
    final blastRadius2 = blastRadius * blastRadius;
    
    parent?.add(NovaPulseEffect(
      effectCenter: position.clone(),
      radius: blastRadius,
      color: const Color(0xFFCE93D8),
      level: level,
    ));

    for (final e in game.aliveEnemies) {
      if ((e.position - position).length2 < blastRadius2) {
        e.takeDamage(damage * 1.5, source: position, type: DamageType.mothership);
      }
    }
  }

  double _lerpAngle(double a, double b, double t) {
    var diff = (b - a) % (2 * math.pi);
    if (diff > math.pi) diff -= 2 * math.pi;
    if (diff < -math.pi) diff += 2 * math.pi;
    return a + diff * t;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Drone Shape: Small sharp triangle
    final path = Path()
      ..moveTo(6, 0)
      ..lineTo(-4, -4)
      ..lineTo(-2, 0)
      ..lineTo(-4, 4)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFCE93D8)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
}
