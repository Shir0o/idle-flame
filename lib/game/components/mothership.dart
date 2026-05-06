import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../zenith_zero_game.dart';
import 'enemy.dart';
import 'combat_effects.dart';

enum CrewShipType {
  interceptor, // Ranged plasma
  kamikaze, // Dive explosion
  slicer, // Melee saw
  thermal, // Charge laser
}

class Mothership extends PositionComponent
    with HasGameReference<ZenithZeroGame> {
  Mothership({this.level = 1}) : super(priority: 65);

  final int level;
  double _spawnTimer = 0;
  double _totalTime = 0;
  final math.Random _rng = math.Random();

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
      _launchCrewShips();
    }
  }

  void _orbit(Vector2 heroPos, double dt) {
    const xBase = 120.0;
    final t = _totalTime * 0.8;
    final hoverX = 24.0 * math.sin(t);
    final hoverY = 16.0 * math.sin(t) * math.cos(t);

    final targetPos = heroPos + Vector2(xBase + hoverX, hoverY);
    final k = 1 - math.exp(-4 * dt);
    position += (targetPos - position) * k;

    final targetAngle = math.sin(_totalTime * 0.5) * 0.15;
    angle = _lerpAngle(angle, targetAngle, 1 - math.exp(-3 * dt));
  }

  double _lerpAngle(double a, double b, double t) {
    var diff = (b - a) % (2 * math.pi);
    if (diff > math.pi) diff -= 2 * math.pi;
    if (diff < -math.pi) diff += 2 * math.pi;
    return a + diff * t;
  }

  void _launchCrewShips() {
    final world = parent;
    if (world == null) return;

    final count = game.state.mothershipDroneCount;
    if (CrewShip.availableSlots <= 0) return;
    game.audio.playSkillCast();

    final currentLevel = game.state.mothershipLevel;
    final availableTypes = <CrewShipType>[CrewShipType.interceptor];
    if (currentLevel >= 2) availableTypes.add(CrewShipType.kamikaze);
    if (currentLevel >= 3) availableTypes.add(CrewShipType.slicer);
    if (currentLevel >= 4) availableTypes.add(CrewShipType.thermal);

    for (var i = 0; i < count; i++) {
      if (!CrewShip.reserveSpawn()) break;
      final type = availableTypes[_rng.nextInt(availableTypes.length)];
      final offset = Vector2(
        (_rng.nextDouble() - 0.5) * 30,
        (_rng.nextDouble() - 0.5) * 30,
      );
      world.add(
        CrewShip(
          startPos: position + offset,
          level: currentLevel,
          damage: game.state.mothershipDroneDamage,
          type: type,
        ),
      );
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    const s = 38.0;
    final pulse = 0.5 + 0.5 * math.sin(_totalTime * 5.0);
    final hullPath = Path()
      ..moveTo(s * 0.72, 0)
      ..lineTo(s * 0.48, -s * 0.28)
      ..lineTo(s * 0.12, -s * 0.42)
      ..lineTo(-s * 0.18, -s * 0.64)
      ..lineTo(-s * 0.62, -s * 0.42)
      ..lineTo(-s * 0.86, -s * 0.14)
      ..lineTo(-s * 0.76, 0)
      ..lineTo(-s * 0.86, s * 0.14)
      ..lineTo(-s * 0.62, s * 0.42)
      ..lineTo(-s * 0.18, s * 0.64)
      ..lineTo(s * 0.12, s * 0.42)
      ..lineTo(s * 0.48, s * 0.28)
      ..close();
    final wingPaint = Paint()
      ..color = const Color(0xFF7C4DFF).withValues(alpha: 0.78)
      ..style = PaintingStyle.fill;
    final outlinePaint = Paint()
      ..color = const Color(0xFFE1F5FE).withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;
    final bayPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.34 + pulse * 0.22)
      ..style = PaintingStyle.fill;
    final enginePaint = Paint()
      ..color = const Color(0xFFFF2D95).withValues(alpha: 0.52 + pulse * 0.34)
      ..style = PaintingStyle.fill;

    canvas.drawPath(
      hullPath,
      Paint()
        ..color = const Color(0xFFCE93D8).withValues(alpha: 0.26)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawPath(hullPath, _hullPaint);
    canvas.drawPath(hullPath, outlinePaint);

    final topPod = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(-s * 0.2, -s * 0.52),
        width: s * 0.72,
        height: s * 0.22,
      ),
      const Radius.circular(8),
    );
    final bottomPod = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(-s * 0.2, s * 0.52),
        width: s * 0.72,
        height: s * 0.22,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(topPod, wingPaint);
    canvas.drawRRect(bottomPod, wingPaint);
    canvas.drawRRect(topPod, outlinePaint);
    canvas.drawRRect(bottomPod, outlinePaint);

    final bay = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(-s * 0.1, 0),
        width: s * 0.66,
        height: s * 0.24,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(bay, bayPaint);
    canvas.drawRRect(bay, outlinePaint);

    canvas.drawCircle(Offset(s * 0.2, 0), 7, _glowPaint);
    canvas.drawCircle(Offset(s * 0.2, 0), 3.5, bayPaint);
    canvas.drawCircle(
      Offset(-s * 0.76, -s * 0.2),
      4 + pulse * 1.4,
      enginePaint,
    );
    canvas.drawCircle(Offset(-s * 0.76, s * 0.2), 4 + pulse * 1.4, enginePaint);
    canvas.drawCircle(
      Offset(-s * 0.9, 0),
      2.5 + pulse,
      Paint()..color = const Color(0xFFE1F5FE).withValues(alpha: 0.58),
    );
  }
}

class CrewShip extends PositionComponent with HasGameReference<ZenithZeroGame> {
  CrewShip({
    required Vector2 startPos,
    required this.level,
    required this.damage,
    required this.type,
  }) : super(position: startPos, size: Vector2.all(12), priority: 64);

  final int level;
  final double damage;
  final CrewShipType type;

  Enemy? _target;
  double _age = 0;
  double _actionTimer = 0;
  double _retargetCooldown = 0;
  final double _maxLife = 6.0;
  double _speed = 400;
  double _rotationSpeed = 0;
  final Paint _shipFillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _shipStrokePaint = Paint()..style = PaintingStyle.stroke;
  final Paint _shipAccentPaint = Paint()..style = PaintingStyle.fill;
  static int _reservedOrAliveCount = 0;
  static const int _maxAlive = 24;
  static const double _noTargetRetargetInterval = 0.2;
  static int get availableSlots =>
      math.max(0, _maxAlive - _reservedOrAliveCount);

  static final Path _interceptorPath = Path()
    ..moveTo(10, 0)
    ..lineTo(1, -4)
    ..lineTo(-8, -8)
    ..lineTo(-4, 0)
    ..lineTo(-8, 8)
    ..lineTo(1, 4)
    ..close();
  static final Path _kamikazePath = Path()
    ..moveTo(11, 0)
    ..lineTo(1, -5)
    ..lineTo(-9, -4)
    ..lineTo(-5, 0)
    ..lineTo(-9, 4)
    ..lineTo(1, 5)
    ..close();
  static final Path _thermalPath = Path()
    ..moveTo(12, 0)
    ..lineTo(3, -5)
    ..lineTo(-5, -9)
    ..lineTo(-10, -5)
    ..lineTo(-8, 5)
    ..lineTo(-5, 9)
    ..lineTo(3, 5)
    ..close();
  static final List<Path> _slicerBladePaths = List.unmodifiable(
    List.generate(6, (i) {
      final a = i * math.pi / 3;
      return Path()
        ..moveTo(math.cos(a - 0.18) * 4, math.sin(a - 0.18) * 4)
        ..lineTo(math.cos(a) * 12, math.sin(a) * 12)
        ..lineTo(math.cos(a + 0.32) * 5, math.sin(a + 0.32) * 5)
        ..close();
    }),
  );

  static bool reserveSpawn() {
    if (_reservedOrAliveCount >= _maxAlive) return false;
    _reservedOrAliveCount++;
    return true;
  }

  @override
  void onRemove() {
    _reservedOrAliveCount = math.max(0, _reservedOrAliveCount - 1);
    super.onRemove();
  }

  @override
  void onMount() {
    super.onMount();
    _speed = type == CrewShipType.kamikaze ? 600 : 400;
    if (!_findTarget()) {
      _retargetCooldown = _noTargetRetargetInterval;
    }
  }

  bool _findTarget() {
    final best = type == CrewShipType.kamikaze
        ? game.nearestEnemyToHero
        : game.rightmostEnemy;
    _target = best != null && best.isAlive ? best : null;
    return _target != null;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    _actionTimer += dt;
    _retargetCooldown = math.max(0, _retargetCooldown - dt);

    if (_age >= _maxLife || game.state.isRunOver) {
      removeFromParent();
      return;
    }

    if (_target != null && !_target!.isAlive) {
      _target = null;
    }

    if (_target == null) {
      if (_retargetCooldown <= 0) {
        if (!_findTarget()) {
          _retargetCooldown = _noTargetRetargetInterval;
        }
      }
      if (_target == null) {
        position += Vector2(math.cos(angle), math.sin(angle)) * _speed * dt;
        return;
      }
    }

    final toTarget = _target!.position - position;
    final dist = toTarget.length;

    switch (type) {
      case CrewShipType.interceptor:
        _updateInterceptor(toTarget, dist, dt);
        break;
      case CrewShipType.kamikaze:
        _updateKamikaze(dt, toTarget, dist);
        break;
      case CrewShipType.slicer:
        _updateSlicer(dt, toTarget, dist);
        break;
      case CrewShipType.thermal:
        _updateThermal(dt, toTarget, dist);
        break;
    }
  }

  void _updateInterceptor(Vector2 toTarget, double dist, double dt) {
    const idealDist = 140.0;
    final targetAngle = math.atan2(toTarget.y, toTarget.x);
    angle = _lerpAngle(angle, targetAngle, 1 - math.exp(-6 * dt));

    if (dist > idealDist + 20) {
      position += Vector2(math.cos(angle), math.sin(angle)) * _speed * dt;
    } else if (dist < idealDist - 20) {
      position -= Vector2(math.cos(angle), math.sin(angle)) * _speed * 0.5 * dt;
    } else {
      // Strafe
      final strafeDir = Vector2(-toTarget.y, toTarget.x).normalized();
      position += strafeDir * _speed * 0.3 * dt;
    }

    if (_actionTimer >= 0.8) {
      _actionTimer = 0;
      _firePlasma();
    }
  }

  void _firePlasma() {
    final target = _target;
    if (target == null || !CrewShipProjectile.reserveSpawn()) return;
    parent?.add(
      CrewShipProjectile(
        startPos: position.clone(),
        target: target,
        damage: damage * 0.8,
        color: const Color(0xFFCE93D8),
      ),
    );
  }

  void _updateKamikaze(double dt, Vector2 toTarget, double dist) {
    final targetAngle = math.atan2(toTarget.y, toTarget.x);
    angle = _lerpAngle(angle, targetAngle, 1 - math.exp(-10 * dt));
    position += Vector2(math.cos(angle), math.sin(angle)) * _speed * dt;

    if (dist < 16) {
      _explode();
      removeFromParent();
    }
  }

  void _explode() {
    final blastRadius = 72.0;
    final blastRadius2 = blastRadius * blastRadius;

    if (game.canSpawnMajorEffect()) {
      parent?.add(
        NovaPulseEffect(
          effectCenter: position.clone(),
          radius: blastRadius,
          color: const Color(0xFFFF5252),
          level: level,
        ),
      );
    }

    for (final e in game.aliveEnemies) {
      if ((e.position - position).length2 < blastRadius2) {
        e.takeDamage(
          damage * 2.5,
          source: position,
          type: DamageType.mothership,
        );
      }
    }
  }

  void _updateSlicer(double dt, Vector2 toTarget, double dist) {
    _rotationSpeed += dt * 20;
    final targetAngle = math.atan2(toTarget.y, toTarget.x);
    angle = _lerpAngle(angle, targetAngle, 1 - math.exp(-4 * dt));

    // Slicers just dive through enemies
    position += Vector2(math.cos(angle), math.sin(angle)) * _speed * dt;

    if (_actionTimer >= 0.2) {
      _actionTimer = 0;
      _meleeAoe();
    }
  }

  void _meleeAoe() {
    const range = 42.0;
    const range2 = range * range;
    for (final e in game.aliveEnemies) {
      if ((e.position - position).length2 < range2) {
        e.takeDamage(
          damage * 0.4,
          source: position,
          type: DamageType.mothership,
        );
        if (!HitSparkEffect.atCap &&
            game.canSpawnMinorEffect(lowPriority: true)) {
          parent?.add(
            HitSparkEffect(
              effectCenter: e.position.clone(),
              direction: (e.position - position).normalized(),
              color: const Color(0xFFCE93D8),
              count: 3,
            ),
          );
        }
      }
    }
  }

  void _updateThermal(double dt, Vector2 toTarget, double dist) {
    const chargeDist = 180.0;
    final targetAngle = math.atan2(toTarget.y, toTarget.x);
    angle = _lerpAngle(angle, targetAngle, 1 - math.exp(-3 * dt));

    if (dist > chargeDist) {
      position += Vector2(math.cos(angle), math.sin(angle)) * _speed * dt;
    }

    if (_actionTimer >= 3.0) {
      _actionTimer = 0;
      _fireLaser();
    }
  }

  void _fireLaser() {
    if (_target == null) return;
    if (game.visualLoadTier == VisualLoadTier.normal ||
        game.canSpawnMajorEffect()) {
      parent?.add(
        LaserBeamEffect(
          from: position.clone(),
          to: _target!.position.clone(),
          color: const Color(0xFFFF2D95),
          duration: 1.0,
          width: 6,
        ),
      );
    }
    _target?.takeDamage(
      damage * 4.0,
      source: position,
      type: DamageType.mothership,
    );
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

    switch (type) {
      case CrewShipType.interceptor:
        _drawInterceptor(canvas);
        break;
      case CrewShipType.kamikaze:
        _drawKamikaze(canvas);
        break;
      case CrewShipType.slicer:
        _drawSlicer(canvas);
        break;
      case CrewShipType.thermal:
        _drawThermal(canvas);
        break;
    }
  }

  void _drawInterceptor(Canvas canvas) {
    _shipFillPaint
      ..color = const Color(0xFFCE93D8)
      ..style = PaintingStyle.fill;
    _shipStrokePaint
      ..color = const Color(0xFFE1F5FE).withValues(alpha: 0.76)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(_interceptorPath, _shipFillPaint);
    canvas.drawPath(_interceptorPath, _shipStrokePaint);
    _shipAccentPaint
      ..color = const Color(0xFFE1F5FE).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawLine(const Offset(-2, 0), const Offset(8, 0), _shipAccentPaint);
    _shipAccentPaint
      ..color = const Color(0xFFE1F5FE)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(-6, 0), 2, _shipAccentPaint);
  }

  void _drawKamikaze(Canvas canvas) {
    _shipFillPaint
      ..color = const Color(0xFFFF5252)
      ..style = PaintingStyle.fill;
    _shipStrokePaint
      ..color = Colors.white.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawPath(_kamikazePath, _shipFillPaint);
    canvas.drawPath(_kamikazePath, _shipStrokePaint);
    final pulse = 0.7 + 0.3 * math.sin(_age * 15);
    _shipAccentPaint
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(3, 0), 3 * pulse, _shipAccentPaint);
    _shipAccentPaint.color = const Color(0xFFFFD166).withValues(alpha: 0.72);
    canvas.drawCircle(const Offset(-7, 0), 2.2 + pulse, _shipAccentPaint);
  }

  void _drawSlicer(Canvas canvas) {
    canvas.save();
    canvas.rotate(_rotationSpeed);
    _shipFillPaint
      ..color = const Color(0xFFCE93D8)
      ..style = PaintingStyle.fill;
    _shipStrokePaint
      ..color = Colors.white.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final blade in _slicerBladePaths) {
      canvas.drawPath(blade, _shipFillPaint);
      canvas.drawPath(blade, _shipStrokePaint);
    }
    _shipAccentPaint
      ..color = const Color(0xFF7C4DFF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 5, _shipAccentPaint);
    _shipAccentPaint.color = Colors.white.withValues(alpha: 0.8);
    canvas.drawCircle(Offset.zero, 2.5, _shipAccentPaint);
    canvas.restore();
  }

  void _drawThermal(Canvas canvas) {
    _shipFillPaint
      ..color = const Color(0xFFCE93D8)
      ..style = PaintingStyle.fill;
    _shipStrokePaint
      ..color = const Color(0xFFE1F5FE).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawPath(_thermalPath, _shipFillPaint);
    canvas.drawPath(_thermalPath, _shipStrokePaint);
    _shipAccentPaint
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;
    canvas.drawRect(const Rect.fromLTWH(-5, -3, 10, 6), _shipAccentPaint);
    _shipAccentPaint.color = const Color(0xFFFF2D95).withValues(alpha: 0.68);
    canvas.drawCircle(const Offset(10, 0), 2.5, _shipAccentPaint);
    if (_actionTimer > 2.0) {
      final p = (_actionTimer - 2.0).clamp(0.0, 1.0);
      _shipAccentPaint.color = const Color(0xFFFF2D95).withValues(alpha: 0.8);
      canvas.drawCircle(const Offset(14, 0), 5 * p, _shipAccentPaint);
      _shipStrokePaint
        ..color = const Color(0xFFFF2D95).withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      canvas.drawCircle(const Offset(14, 0), 8 * p, _shipStrokePaint);
    }
  }
}

class CrewShipProjectile extends PositionComponent
    with HasGameReference<ZenithZeroGame> {
  CrewShipProjectile({
    required Vector2 startPos,
    required this.target,
    required this.damage,
    required this.color,
  }) : super(position: startPos, size: Vector2.all(4), priority: 66) {
    _paint = Paint()..color = color;
    _glowPaint = Paint()..color = color.withValues(alpha: 0.3);
  }

  final Enemy target;
  final double damage;
  final Color color;
  late final Paint _paint;
  late final Paint _glowPaint;
  double _age = 0;
  static const double _speed = 700;
  static const double _maxLife = 2.0;
  static int _reservedOrAliveCount = 0;
  static const int _maxAlive = 48;

  static bool reserveSpawn() {
    if (_reservedOrAliveCount >= _maxAlive) return false;
    _reservedOrAliveCount++;
    return true;
  }

  @override
  void onRemove() {
    _reservedOrAliveCount = math.max(0, _reservedOrAliveCount - 1);
    super.onRemove();
  }

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
      target.takeDamage(damage, source: position, type: DamageType.mothership);
      removeFromParent();
      return;
    }

    position += toTarget.normalized() * _speed * dt;
    angle = math.atan2(toTarget.y, toTarget.x);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset.zero, 3, _paint);
    canvas.drawCircle(Offset.zero, 5, _glowPaint);
  }
}
