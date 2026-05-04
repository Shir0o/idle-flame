import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../idle_game.dart';
import 'enemy.dart';
import 'combat_effects.dart';

class SentinelBlade extends PositionComponent with HasGameReference<IdleGame> {
  SentinelBlade({required this.orbitIndex, this.level = 1})
    : super(priority: 62);

  final int orbitIndex;
  final int level;
  double _orbitAngle = 0;
  Enemy? _target;
  double _attackTimer = 0;
  double _totalTime = 0;
  double _hitStopTimer = 0;
  double _pulseTimer = 0;
  double _pulseDuration = 0.18;
  Vector2 _recoilVelocity = Vector2.zero();

  final List<Vector2> _trail = [];
  static const int _maxTrailPoints = 8;

  static const double _orbitRadius = 60;
  static const double _attackRange = double.infinity;
  static const double _dashSpeed = 650;

  final Paint _bladePaint = Paint()
    ..color = const Color(0xFFE1F5FE)
    ..style = PaintingStyle.fill;

  final Paint _glowPaint = Paint()
    ..color = const Color(0xFF00B0FF).withValues(alpha: 0.4)
    ..style = PaintingStyle.fill;

  final Paint _bladeRidgePaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.72)
    ..strokeWidth = 1.1
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  final Paint _guardPaint = Paint()
    ..color = const Color(0xFF00E5FF)
    ..strokeWidth = 2.2
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  final Paint _hiltPaint = Paint()
    ..color = const Color(0xFF6A4C93)
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  final Paint _trailPaint = Paint()..style = PaintingStyle.fill;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state.isRunOver) {
      removeFromParent();
      return;
    }
    if (game.state.hasPendingLevelUp) return;

    if (_hitStopTimer > 0) {
      _hitStopTimer -= dt;
      return;
    }

    if (_pulseTimer > 0) {
      _pulseTimer -= dt;
      final t = (_pulseTimer / _pulseDuration).clamp(0.0, 1.0);
      scale = Vector2.all(1 + Curves.easeOutBack.transform(t) * 0.12);
      if (_pulseTimer <= 0) scale = Vector2.all(1);
    }

    _totalTime += dt;
    final heroPos = game.hero.position;
    _attackTimer = math.max(0, _attackTimer - dt);

    // Apply recoil
    if (_recoilVelocity.length2 > 1) {
      position += _recoilVelocity * dt;
      _recoilVelocity *= math.pow(0.01, dt).toDouble();
    }

    // Update trail
    _trail.insert(0, position.clone());
    if (_trail.length > _maxTrailPoints) {
      _trail.removeLast();
    }

    if (_target != null &&
        (!_target!.isAlive ||
            (_target!.position - heroPos).length2 >
                _attackRange * _attackRange)) {
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

  void pulse(double duration) {
    _pulseTimer = duration;
    _pulseDuration = duration;
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
      _target!.takeDamage(
        game.state.sentinelDamage,
        source: position,
        type: DamageType.sentinel,
      );

      // Impact effect
      parent?.add(
        HitSparkEffect(
          effectCenter: _target!.position.clone(),
          direction: (position - _target!.position).normalized(),
          color: const Color(0xFF00B0FF),
          count: 12,
        ),
      );

      // Level 5 Mastery: Shard Seekers
      if (level >= 5) {
        final secondaryTargets =
            game.aliveEnemies.where((e) => e != _target).toList()..sort(
              (a, b) => (a.position - position).length2.compareTo(
                (b.position - position).length2,
              ),
            );

        final shardTargets = secondaryTargets.take(3).toList();
        for (final st in shardTargets) {
          parent?.add(
            SentinelShard(
              startPos: position.clone(),
              target: st,
              damage: game.state.sentinelDamage * 0.4,
            ),
          );
        }
      }

      if (game.state.meta.hasKeystone('twinblade') && _target!.isAlive) {
        _target!.takeDamage(
          game.state.sentinelDamage * 0.6,
          source: position,
          type: DamageType.sentinel,
        );
      }

      // Hit stop and Recoil
      _hitStopTimer = 0.05;
      final recoilDir = (position - _target!.position).normalized();
      if (recoilDir.length2 == 0) recoilDir.setValues(0, -1);
      _recoilVelocity = recoilDir * 400;

      _attackTimer = game.state.sentinelAttackCooldown;
      return;
    }

    if (_attackTimer <= 0) {
      // Launch sound
      game.audio.playSkillCast();
    }

    position += toTarget.normalized() * _dashSpeed * dt;
    angle = math.atan2(toTarget.y, toTarget.x);
  }

  void _returnToOrbit(Vector2 heroPos, double dt) {
    _orbitAngle += game.state.sentinelOrbitSpeed * dt;
    final count = math.max(1, game.state.sentinelCount);
    final offset = orbitIndex * (math.pi * 2 / count);
    // Add a slight bobbing motion to the radius
    final currentRadius =
        _orbitRadius + 4 * math.sin(_totalTime * 3 + orbitIndex);
    final targetOrbitPos =
        heroPos +
        Vector2(
          math.cos(_orbitAngle + offset) * currentRadius,
          math.sin(_orbitAngle + offset) * currentRadius,
        );

    final toOrbit = targetOrbitPos - position;
    if (toOrbit.length2 > 1) {
      position += toOrbit * 12 * dt;
    } else {
      position = targetOrbitPos;
    }

    // Point outwards from center when orbiting
    final fromHero = position - heroPos;
    angle = math.atan2(fromHero.y, fromHero.x);
  }

  Path _swordBladePath(double length, double width) {
    final tip = length * 0.5;
    final base = -length * 0.2;
    final shoulder = width * 0.5;
    final waist = width * 0.26;

    return Path()
      ..moveTo(tip, 0)
      ..lineTo(base + length * 0.12, -waist)
      ..lineTo(base, -shoulder)
      ..lineTo(base, shoulder)
      ..lineTo(base + length * 0.12, waist)
      ..close();
  }

  void _drawSword(
    Canvas canvas,
    double size,
    Paint bladePaint,
    Paint glowPaint,
  ) {
    final bladeLength = size * 1.65;
    final bladeWidth = size * 0.62;
    final bladePath = _swordBladePath(bladeLength, bladeWidth);

    canvas.save();
    canvas.scale(1.26);
    canvas.drawPath(bladePath, glowPaint);
    canvas.restore();

    canvas.drawPath(bladePath, bladePaint);
    canvas.drawLine(
      Offset(-bladeLength * 0.12, 0),
      Offset(bladeLength * 0.36, 0),
      _bladeRidgePaint,
    );
    canvas.drawLine(
      Offset(-size * 0.48, -size * 0.48),
      Offset(-size * 0.48, size * 0.48),
      _guardPaint,
    );
    canvas.drawLine(
      Offset(-size * 0.5, 0),
      Offset(-size * 0.86, 0),
      _hiltPaint,
    );
    canvas.drawCircle(Offset(-size * 0.94, 0), size * 0.12, _guardPaint);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Render trail
    for (var i = 0; i < _trail.length; i++) {
      final pos = _trail[i];
      final t = i / _maxTrailPoints;
      final alpha = (1 - t) * 0.3;
      final scale = (1 - t) * 0.8;

      _trailPaint.color = const Color(0xFF00B0FF).withValues(alpha: alpha);

      final trailOffset = pos - position;
      canvas.save();
      canvas.translate(trailOffset.x, trailOffset.y);
      canvas.rotate(angle);

      final trailSize = 10.0 * scale;
      canvas.drawPath(
        _swordBladePath(trailSize * 1.65, trailSize * 0.62),
        _trailPaint,
      );
      canvas.restore();
    }

    // Draw a compact jian-style spellblade
    canvas.save();

    // Add a scale pulse when ready to attack
    final readyPulse = (_attackTimer <= 0 && _target != null)
        ? 1.0 + 0.15 * math.sin(_totalTime * 15)
        : 1.0;
    canvas.scale(readyPulse);

    final sizeBase = 12.0 * (level >= 3 ? 1.3 : 1.0);

    void drawBlade(bool isShadow) {
      canvas.save();
      if (isShadow) {
        canvas.translate(-5, 5);
        canvas.scale(0.8);
      }

      if (isShadow) {
        final shadowGlow = Paint()
          ..color = const Color(0xFF00B0FF).withValues(alpha: 0.2)
          ..style = PaintingStyle.fill;
        final shadowBlade = Paint()
          ..color = const Color(0xFFE1F5FE).withValues(alpha: 0.4)
          ..style = PaintingStyle.fill;
        _drawSword(canvas, sizeBase, shadowBlade, shadowGlow);
      } else {
        _drawSword(canvas, sizeBase, _bladePaint, _glowPaint);
      }
      canvas.restore();
    }

    if (game.state.meta.hasKeystone('twinblade')) {
      drawBlade(true);
    }
    drawBlade(false);

    // Evolution: Mastery Level 5 - Orbiting Shards (Cloud of Steel)
    if (level >= 5) {
      final shardPaint = Paint()
        ..color = const Color(0xFFE1F5FE).withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;

      final shardGlow = Paint()
        ..color = const Color(0xFF00B0FF).withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      final pulsePaint = Paint()
        ..color = const Color(0xFF00B0FF).withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      final shardCount = 5;
      for (var i = 0; i < shardCount; i++) {
        // Varied rotation speeds and distances for shards
        final speedMult = 1.5 + (i * 0.4);
        final shardAngle =
            (_totalTime * speedMult) + (i * math.pi * 2 / shardCount);
        final distBase = 16.0 + 4 * math.sin(_totalTime * 2 + i);

        final shardPos = Offset(
          math.cos(shardAngle) * distBase,
          math.sin(shardAngle) * distBase,
        );

        // Draw energy pulse connecting to main blade
        if ((_totalTime * 2 + i) % 3 < 0.5) {
          canvas.drawLine(Offset.zero, shardPos, pulsePaint);
        }

        canvas.save();
        canvas.translate(shardPos.dx, shardPos.dy);
        canvas.rotate(shardAngle);
        _drawSword(canvas, 4, shardPaint, shardGlow);
        canvas.restore();
      }
    }

    canvas.restore();
  }
}

class SentinelShard extends PositionComponent with HasGameReference<IdleGame> {
  SentinelShard({
    required Vector2 startPos,
    required this.target,
    required this.damage,
  }) : super(position: startPos, size: Vector2.all(4), priority: 63);

  final Enemy target;
  final double damage;
  double _age = 0;
  static const double _speed = 850;
  static const double _maxLife = 1.2;

  final Paint _paint = Paint()
    ..color = const Color(0xFFE1F5FE)
    ..style = PaintingStyle.fill;

  final Paint _glow = Paint()
    ..color = const Color(0xFF00B0FF).withValues(alpha: 0.4)
    ..style = PaintingStyle.fill;

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= _maxLife || game.state.isRunOver) {
      removeFromParent();
      return;
    }

    if (!target.isAlive) {
      removeFromParent();
      return;
    }

    final toTarget = target.position - position;
    if (toTarget.length < 10) {
      target.takeDamage(damage, source: position, type: DamageType.sentinel);
      removeFromParent();
      return;
    }

    position += toTarget.normalized() * _speed * dt;
    angle = math.atan2(toTarget.y, toTarget.x);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.save();
    final blade = Path()
      ..moveTo(6, 0)
      ..lineTo(-1, -1.6)
      ..lineTo(-2.2, -2.5)
      ..lineTo(-2.2, 2.5)
      ..lineTo(-1, 1.6)
      ..close();
    canvas.scale(1.35);
    canvas.drawPath(blade, _glow);
    canvas.scale(1 / 1.35);
    canvas.drawPath(blade, _paint);
    canvas.drawLine(const Offset(-2.6, -2.4), const Offset(-2.6, 2.4), _glow);
    canvas.restore();
  }
}
