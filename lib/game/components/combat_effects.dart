import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../zenith_zero_game.dart';
import '../state/skill_catalog.dart';

class HitSparkEffect extends PositionComponent
    with HasGameReference<ZenithZeroGame> {
  HitSparkEffect({
    required this.effectCenter,
    required this.direction,
    this.color = const Color(0xFFFFEB3B),
    int count = 8,
    double spread = 0.95,
    double speed = 145,
  }) : _particles = _buildParticles(direction, count, spread, speed),
       super(priority: 90);

  static int _aliveCount = 0;
  static const int _maxAlive = 60;
  static bool get atCap => _aliveCount >= _maxAlive;

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

  final Vector2 effectCenter;
  final Vector2 direction;
  final Color color;
  final List<_SparkParticle> _particles;
  double _age = 0;

  final Paint _flashPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round;
  final Paint _particlePaint = Paint()..style = PaintingStyle.fill;
  final Paint _glowPaint = Paint()..style = PaintingStyle.fill;

  static final math.Random _rng = math.Random();
  static const double _duration = 0.34;

  static List<_SparkParticle> _buildParticles(
    Vector2 direction,
    int count,
    double spread,
    double speed,
  ) {
    final baseAngle = direction.length2 == 0
        ? -math.pi / 2
        : math.atan2(direction.y, direction.x);
    return List.generate(count, (index) {
      final angle = baseAngle + (_rng.nextDouble() - 0.5) * spread;
      final magnitude = speed * (0.48 + _rng.nextDouble() * 0.72);
      return _SparkParticle(
        velocity: Vector2(math.cos(angle), math.sin(angle)) * magnitude,
        radius: 1.8 + _rng.nextDouble() * 2.4,
      );
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state.hasPendingLevelUp || game.state.isRunOver) return;
    _age += dt;
    if (_age >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final t = (_age / _duration).clamp(0.0, 1.0);
    final alpha = 1 - Curves.easeInCubic.transform(t);
    final gravity = Vector2(0, 95 * t);
    final center = Offset(effectCenter.x, effectCenter.y);
    _flashPaint.color = Colors.white.withValues(alpha: alpha * 0.42);
    final flashRadius = 6 + 13 * Curves.easeOut.transform(t);
    canvas.drawLine(
      center.translate(-flashRadius, 0),
      center.translate(flashRadius, 0),
      _flashPaint,
    );
    canvas.drawLine(
      center.translate(0, -flashRadius),
      center.translate(0, flashRadius),
      _flashPaint,
    );
    _particlePaint.color = color.withValues(alpha: alpha);
    _glowPaint.color = color.withValues(alpha: alpha * 0.2);
    for (final particle in _particles) {
      final offset = effectCenter + (particle.velocity + gravity) * _age;
      canvas.drawCircle(
        Offset(offset.x, offset.y),
        particle.radius * 2.5 * (1 - t * 0.45),
        _glowPaint,
      );
      canvas.drawCircle(
        Offset(offset.x, offset.y),
        particle.radius * (1 - t * 0.55),
        _particlePaint,
      );
    }
  }
}

class DeathBurstEffect extends PositionComponent
    with HasGameReference<ZenithZeroGame> {
  DeathBurstEffect({
    required this.effectCenter,
    this.color = const Color(0xFFFF2D95),
  }) : _particles = _buildParticles(),
       super(priority: 85);

  final Vector2 effectCenter;
  final Color color;
  final List<_SparkParticle> _particles;
  double _age = 0;

  final Paint _flashPaint = Paint()..style = PaintingStyle.fill;
  final Paint _ringPaint = Paint()..style = PaintingStyle.stroke;
  final Paint _outerRingPaint = Paint()..style = PaintingStyle.stroke;
  final Paint _particlePaint = Paint()..style = PaintingStyle.fill;
  final Paint _streakPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  static final math.Random _rng = math.Random();
  static const double _duration = 0.46;

  static List<_SparkParticle> _buildParticles() {
    return List.generate(16, (index) {
      final angle = index / 16 * math.pi * 2 + (_rng.nextDouble() - 0.5) * 0.28;
      final magnitude = 92 + _rng.nextDouble() * 100;
      return _SparkParticle(
        velocity: Vector2(math.cos(angle), math.sin(angle)) * magnitude,
        radius: 2 + _rng.nextDouble() * 3.5,
      );
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state.hasPendingLevelUp || game.state.isRunOver) return;
    _age += dt;
    if (_age >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final t = (_age / _duration).clamp(0.0, 1.0);
    final alpha = 1 - t;
    final center = Offset(effectCenter.x, effectCenter.y);
    final eased = Curves.easeOutCubic.transform(t);
    _flashPaint.color = Colors.white.withValues(alpha: alpha * 0.45);
    canvas.drawCircle(center, 20 * (1 - t), _flashPaint);
    _ringPaint
      ..color = color.withValues(alpha: alpha * 0.44)
      ..strokeWidth = 4 * (1 - t);
    _outerRingPaint
      ..color = Colors.white.withValues(alpha: alpha * 0.18)
      ..strokeWidth = 1.5 * (1 - t);
    canvas.drawCircle(center, eased * 34, _ringPaint);
    canvas.drawCircle(center, eased * 52, _outerRingPaint);
    _particlePaint.color = color.withValues(alpha: alpha);
    _streakPaint.color = color.withValues(alpha: alpha * 0.42);
    for (final particle in _particles) {
      final offset = effectCenter + particle.velocity * eased * _duration;
      _streakPaint.strokeWidth = particle.radius * 0.75;
      final tail = effectCenter + (offset - effectCenter) * 0.62;
      canvas.drawLine(
        Offset(tail.x, tail.y),
        Offset(offset.x, offset.y),
        _streakPaint,
      );
      canvas.drawCircle(
        Offset(offset.x, offset.y),
        particle.radius * (1 - t * 0.35),
        _particlePaint,
      );
    }
  }
}

class CoinBurstEffect extends PositionComponent
    with HasGameReference<ZenithZeroGame> {
  CoinBurstEffect({required this.effectCenter})
    : _particles = _buildParticles(),
      super(priority: 88);

  final Vector2 effectCenter;
  final List<_SparkParticle> _particles;
  double _age = 0;

  final Paint _coinPaint = Paint()..style = PaintingStyle.fill;
  final Paint _shinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  static final math.Random _rng = math.Random();
  static const double _duration = 0.56;

  static List<_SparkParticle> _buildParticles() {
    return List.generate(10, (index) {
      final angle = -math.pi / 2 + (_rng.nextDouble() - 0.5) * 1.9;
      final magnitude = 72 + _rng.nextDouble() * 90;
      return _SparkParticle(
        velocity: Vector2(math.cos(angle), math.sin(angle)) * magnitude,
        radius: 2.4 + _rng.nextDouble() * 2.2,
      );
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state.hasPendingLevelUp || game.state.isRunOver) return;
    _age += dt;
    if (_age >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final t = (_age / _duration).clamp(0.0, 1.0);
    final alpha = 1 - Curves.easeIn.transform(t);
    _coinPaint.color = const Color(0xFFFFD54F).withValues(alpha: alpha);
    _shinePaint.color = Colors.white.withValues(alpha: alpha * 0.72);
    for (final particle in _particles) {
      final fall = Vector2(0, 160 * t * t);
      final offset = effectCenter + (particle.velocity * _age) + fall;
      canvas.drawCircle(
        Offset(offset.x, offset.y),
        particle.radius,
        _coinPaint,
      );
      canvas.drawLine(
        Offset(offset.x - particle.radius * 0.5, offset.y),
        Offset(offset.x + particle.radius * 0.5, offset.y),
        _shinePaint,
      );
    }
  }
}

class SlashArcEffect extends PositionComponent
    with HasGameReference<ZenithZeroGame> {
  SlashArcEffect({
    required this.from,
    required this.to,
    this.color = const Color(0xFF00E5FF),
    this.widthMultiplier = 1,
    this.level = 1,
  }) : super(priority: 60);

  final Vector2 from;
  final Vector2 to;
  final Color color;
  final double widthMultiplier;
  final int level;
  double _age = 0;
  static const double _duration = 0.18;

  late final Paint _wideGlow = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 28 * widthMultiplier * (level >= 3 ? 1.4 : 1.0)
    ..strokeCap = StrokeCap.round;
  late final Paint _glow = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 14 * widthMultiplier * (level >= 4 ? 1.3 : 1.0)
    ..strokeCap = StrokeCap.round;
  late final Paint _core = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.5 * widthMultiplier * (level >= 5 ? 1.5 : 1.0)
    ..strokeCap = StrokeCap.round;
  late final Paint _edge = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8 * widthMultiplier
    ..strokeCap = StrokeCap.round;
  final Paint _secondary = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state.hasPendingLevelUp || game.state.isRunOver) return;
    _age += dt;
    if (_age >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final t = (_age / _duration).clamp(0.0, 1.0);
    final alpha = (1 - t) * 0.9;
    final start = Offset(from.x, from.y);
    final end = Offset(to.x, to.y);
    final mid = Offset((from.x + to.x) / 2, (from.y + to.y) / 2);
    final direction = to - from;
    if (direction.length2 == 0) return;
    final normal = Vector2(-direction.y, direction.x)..normalize();

    // Evolution: Arcs curve more at higher levels
    final curveStrength = 48 * (level >= 3 ? 1.3 : 1.0);
    final control =
        mid + Offset(normal.x * curveStrength, normal.y * curveStrength);

    _wideGlow.color = color.withValues(alpha: alpha * 0.12);
    _glow.color = color.withValues(alpha: alpha * 0.28);
    _core.color = color.withValues(alpha: alpha);
    _edge.color = Colors.white.withValues(alpha: alpha * 0.7);

    if (level >= 2) {
      // Electric Jitter Path
      final path = Path()..moveTo(start.dx, start.dy);
      const segments = 8;
      final rng = math.Random(from.x.hashCode ^ to.x.hashCode);

      for (var i = 1; i <= segments; i++) {
        final st = i / segments;
        // Quadratic bezier interpolation
        final mt = 1 - st;
        final px =
            mt * mt * start.dx + 2 * mt * st * control.dx + st * st * end.dx;
        final py =
            mt * mt * start.dy + 2 * mt * st * control.dy + st * st * end.dy;

        if (i < segments) {
          final jitter = (level >= 5 ? 12.0 : 6.0) * (rng.nextDouble() - 0.5);
          path.lineTo(px + normal.x * jitter, py + normal.y * jitter);
        } else {
          path.lineTo(end.dx, end.dy);
        }
      }

      canvas.drawPath(path, _wideGlow);
      canvas.drawPath(path, _glow);
      canvas.drawPath(path, _core);
      canvas.drawPath(path, _edge);
    } else {
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

      canvas.drawPath(path, _wideGlow);
      canvas.drawPath(path, _glow);
      canvas.drawPath(path, _core);
      canvas.drawPath(path, _edge);
    }

    // Evolution: Level 5 Mastery - Secondary Arcs (After-images)
    if (level >= 5) {
      final secondaryPath = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(
          control.dx + normal.x * 20 * math.sin(_age * 10),
          control.dy + normal.y * 20 * math.sin(_age * 10),
          end.dx,
          end.dy,
        );
      _secondary.color = color.withValues(alpha: alpha * 0.4);
      canvas.drawPath(secondaryPath, _secondary);
    }
  }
}

class BarrageStreakEffect extends PositionComponent
    with HasGameReference<ZenithZeroGame> {
  BarrageStreakEffect({
    required this.effectCenter,
    this.color = const Color(0xFF64FFDA),
    this.level = 1,
  }) : super(priority: 58);

  final Vector2 effectCenter;
  final Color color;
  final int level;
  double _age = 0;
  static const double _duration = 0.22;

  late final Paint _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2 * (level >= 3 ? 1.4 : 1.0)
    ..strokeCap = StrokeCap.round;
  late final Paint _glowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 8 * (level >= 4 ? 1.5 : 1.0)
    ..strokeCap = StrokeCap.round;
  final Paint _whitePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round;
  final Paint _trailPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state.hasPendingLevelUp || game.state.isRunOver) return;
    _age += dt;
    if (_age >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final t = (_age / _duration).clamp(0.0, 1.0);
    final alpha = 1 - Curves.easeIn.transform(t);
    _strokePaint.color = color.withValues(alpha: alpha * 0.82);
    _glowPaint.color = color.withValues(alpha: alpha * 0.24);
    _whitePaint.color = Colors.white.withValues(alpha: alpha * 0.55);
    if (level >= 5) {
      _trailPaint.color = color.withValues(alpha: alpha * 0.15);
    }
    final eased = Curves.easeOutCubic.transform(t);

    final streakCount = level >= 5 ? 10 : (level >= 3 ? 8 : 6);
    final ySpan = level >= 4 ? 64.0 : 48.0;

    for (var i = 0; i < streakCount; i++) {
      final y = effectCenter.y - (ySpan / 2) + i * (ySpan / (streakCount - 1));
      final phase = i * 0.13;
      final start = Offset(effectCenter.x - 42 - eased * 24 + phase * 18, y);
      final end = Offset(effectCenter.x + 42 + eased * 24 + phase * 18, y - 12);

      canvas.drawLine(start, end, _glowPaint);
      canvas.drawLine(start, end, _strokePaint);
      if (i.isEven) canvas.drawLine(start.translate(9, -3), end, _whitePaint);

      if (level >= 5) {
        canvas.drawLine(
          start.translate(-15, 5),
          end.translate(-15, 5),
          _trailPaint,
        );
      }
    }
  }
}

class FocusStrikeEffect extends PositionComponent
    with HasGameReference<ZenithZeroGame> {
  FocusStrikeEffect({
    required this.from,
    required this.to,
    this.color = const Color(0xFFFFF176),
    this.level = 1,
  }) : super(priority: 64);

  final Vector2 from;
  final Vector2 to;
  final Color color;
  final int level;
  double _age = 0;
  static const double _duration = 0.16;

  late final Paint _corePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5 * (level >= 4 ? 1.5 : 1.0)
    ..strokeCap = StrokeCap.round;
  late final Paint _glowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10 * (level >= 3 ? 1.5 : 1.0)
    ..strokeCap = StrokeCap.round;
  final Paint _targetingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;
  final Paint _piercingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state.hasPendingLevelUp || game.state.isRunOver) return;
    _age += dt;
    if (_age >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final t = (_age / _duration).clamp(0.0, 1.0);
    final alpha = 1 - Curves.easeIn.transform(t);
    final direction = to - from;
    if (direction.length2 == 0) return;
    final unit = direction.normalized();
    final normal = Vector2(-unit.y, unit.x);
    final center = from + direction * Curves.easeOutCubic.transform(t);

    // Evolution: Wider beam at higher levels
    final half = 18 * (1 - t * 0.45) * (level >= 3 ? 1.4 : 1.0);

    _corePaint.color = color.withValues(alpha: alpha);
    _glowPaint.color = color.withValues(alpha: alpha * 0.2);
    _targetingPaint.color = color.withValues(alpha: alpha * 0.24);
    final start = center - normal * half;
    final end = center + normal * half;

    canvas.drawCircle(Offset(to.x, to.y), 18 * (1 - t * 0.3), _targetingPaint);
    canvas.drawLine(Offset(start.x, start.y), Offset(end.x, end.y), _glowPaint);
    canvas.drawLine(Offset(start.x, start.y), Offset(end.x, end.y), _corePaint);

    if (level >= 5) {
      _piercingPaint.color = Colors.white.withValues(alpha: alpha * 0.5);
      final pierceStart = from + direction * (t * 0.2);
      final pierceEnd = from + direction * (t * 1.5);
      canvas.drawLine(
        Offset(pierceStart.x, pierceStart.y),
        Offset(pierceEnd.x, pierceEnd.y),
        _piercingPaint,
      );
    }
  }
}

class FrostFieldEffect extends PositionComponent
    with HasGameReference<ZenithZeroGame> {
  FrostFieldEffect({
    required this.effectCenter,
    required this.fieldSize,
    this.color = const Color(0xFF80DEEA),
    this.level = 1,
  }) : super(priority: 32);

  final Vector2 effectCenter;
  final Vector2 fieldSize;
  final Color color;
  final int level;
  double _age = 0;
  static const double _duration = 0.85;

  final Paint _washPaint = Paint()..style = PaintingStyle.fill;
  late final Paint _linePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4 * (level >= 4 ? 1.5 : 1.0);
  final Paint _crackPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.1
    ..strokeCap = StrokeCap.round;
  final Paint _cyclonePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state.hasPendingLevelUp || game.state.isRunOver) return;
    _age += dt;
    if (_age >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final t = (_age / _duration).clamp(0.0, 1.0);
    final alpha = math.sin(t * math.pi).clamp(0.0, 1.0);
    final rect = Rect.fromCenter(
      center: Offset(effectCenter.x, effectCenter.y),
      width: fieldSize.x,
      height: fieldSize.y,
    );
    _washPaint.color = color.withValues(
      alpha: alpha * (level >= 3 ? 0.12 : 0.07),
    );
    _linePaint.color = color.withValues(alpha: alpha * 0.36);
    _crackPaint.color = Colors.white.withValues(alpha: alpha * 0.5);

    canvas.drawRect(rect, _washPaint);

    final lineSpacing = level >= 4 ? 24.0 : 34.0;
    for (var y = rect.top + 22; y < rect.bottom; y += lineSpacing) {
      canvas.drawLine(
        Offset(rect.left, y),
        Offset(rect.right, y - 12),
        _linePaint,
      );
    }

    final flakeCount = level >= 5 ? 15 : (level >= 3 ? 12 : 9);
    for (var i = 0; i < flakeCount; i++) {
      final x = rect.left + (i + 0.5) * rect.width / flakeCount;
      final y = rect.top + ((i * 47) % 100) / 100 * rect.height;
      final size = 12.0 + (i % 3) * 5;
      _drawSnowflake(canvas, Offset(x, y), size, _crackPaint);
    }

    if (level >= 5) {
      _cyclonePaint.color = color.withValues(alpha: alpha * 0.15);
      final center = Offset(effectCenter.x, effectCenter.y);
      for (var i = 0; i < 3; i++) {
        final radius = 100.0 + i * 80.0;
        final rotation = _age * (1.5 + i * 0.5);
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          rotation,
          math.pi * 0.5,
          false,
          _cyclonePaint,
        );
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          rotation + math.pi,
          math.pi * 0.5,
          false,
          _cyclonePaint,
        );
      }
    }
  }
}

class RuptureMarkEffect extends PositionComponent
    with HasGameReference<ZenithZeroGame> {
  RuptureMarkEffect({required this.effectCenter, this.level = 1})
    : super(priority: 92);

  final Vector2 effectCenter;
  final int level;
  double _age = 0;
  static const double _duration = 0.28;

  late final Paint _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3 * (level >= 4 ? 1.5 : 1.0)
    ..strokeCap = StrokeCap.round;
  late final Paint _glowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10 * (level >= 3 ? 1.4 : 1.0)
    ..strokeCap = StrokeCap.round;
  final Paint _crackPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state.hasPendingLevelUp || game.state.isRunOver) return;
    _age += dt;
    if (_age >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final t = (_age / _duration).clamp(0.0, 1.0);
    final alpha = 1 - t;
    _strokePaint.color = const Color(0xFFFF5252).withValues(alpha: alpha);
    _glowPaint.color = const Color(0xFFFF5252).withValues(alpha: alpha * 0.24);

    final radius =
        (16 + Curves.easeOutBack.transform(t) * 8) * (level >= 3 ? 1.3 : 1.0);
    final center = Offset(effectCenter.x, effectCenter.y);

    canvas.drawCircle(center, radius, _glowPaint);
    canvas.drawCircle(center, radius * 0.6, _glowPaint);

    canvas.drawLine(
      Offset(center.dx - radius, center.dy - radius),
      Offset(center.dx + radius, center.dy + radius),
      _strokePaint,
    );
    canvas.drawLine(
      Offset(center.dx + radius, center.dy - radius),
      Offset(center.dx - radius, center.dy + radius),
      _strokePaint,
    );

    final radialCount = level >= 4 ? 9 : 6;
    for (var i = 0; i < radialCount; i++) {
      final angle = i / radialCount * math.pi * 2 + t * 0.7;
      final start = center.translate(
        math.cos(angle) * radius * 0.35,
        math.sin(angle) * radius * 0.35,
      );
      final end = center.translate(
        math.cos(angle) * radius * 1.25,
        math.sin(angle) * radius * 1.25,
      );
      canvas.drawLine(start, end, _glowPaint);
    }

    if (level >= 5) {
      _crackPaint.color = Colors.white.withValues(alpha: alpha * 0.6);

      for (var i = 0; i < 4; i++) {
        final angle = i * math.pi / 2 + math.pi / 4;
        final start = center.translate(
          math.cos(angle) * radius,
          math.sin(angle) * radius,
        );
        final crackPath = Path()..moveTo(start.dx, start.dy);

        var current = start;
        for (var j = 0; j < 3; j++) {
          final next = current.translate(
            math.cos(
                  angle + (math.Random(i * 5 + j).nextDouble() - 0.5) * 0.5,
                ) *
                30,
            math.sin(
                  angle + (math.Random(i * 5 + j).nextDouble() - 0.5) * 0.5,
                ) *
                30,
          );
          crackPath.lineTo(next.dx, next.dy);
          current = next;
        }
        canvas.drawPath(crackPath, _crackPaint);
      }
    }
  }
}

class _SparkParticle {
  const _SparkParticle({required this.velocity, required this.radius});

  final Vector2 velocity;
  final double radius;
}

class NovaPulseEffect extends PositionComponent
    with HasGameReference<ZenithZeroGame> {
  NovaPulseEffect({
    required this.effectCenter,
    required this.radius,
    this.color = const Color(0xFFFF2D95),
    this.level = 1,
  }) : super(priority: 55);

  final Vector2 effectCenter;
  final double radius;
  final Color color;
  final int level;
  double _age = 0;
  static const double _duration = 0.42;

  late final Paint _warmPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 18 * (level >= 3 ? 1.4 : 1.0);
  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  late final Paint _glowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 12 * (level >= 3 ? 1.5 : 1.0);
  late final Paint _corePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2 * (level >= 4 ? 1.5 : 1.0);
  final Paint _lightningPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8;
  final Paint _shockwavePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state.hasPendingLevelUp || game.state.isRunOver) return;
    _age += dt;
    if (_age >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final t = (_age / _duration).clamp(0.0, 1.0);
    final eased = Curves.easeOutCubic.transform(t);
    final alpha = 1 - t;
    final offset = Offset(effectCenter.x, effectCenter.y);

    _warmPaint.color = const Color(0xFFFFD166).withValues(alpha: alpha * 0.15);
    _fillPaint.color = color.withValues(alpha: alpha * 0.12);
    _glowPaint.color = color.withValues(alpha: alpha * 0.45);
    _corePaint.color = Colors.white.withValues(alpha: alpha * 0.85);

    // Inner Bloom Ring
    canvas.drawCircle(offset, radius * eased * 0.5, _fillPaint);

    // Main Expanding Ring
    canvas.drawCircle(offset, radius * eased, _glowPaint);
    canvas.drawCircle(offset, radius * eased, _corePaint);

    // Evolution: Level 3+ - Concentric filaments and petals
    final petalCount = level >= 5 ? 28 : (level >= 3 ? 18 : 0);
    if (petalCount > 0) {
      final rotationSpeed = level >= 5 ? 3.8 : 2.4;
      for (var i = 0; i < petalCount; i++) {
        final angle = i / petalCount * math.pi * 2 + t * rotationSpeed;
        final petalLength = radius * eased * (0.8 + (i.isEven ? 0.25 : 0));
        final petal = Path()
          ..moveTo(offset.dx, offset.dy)
          ..quadraticBezierTo(
            offset.dx + math.cos(angle + 0.2) * petalLength * 0.6,
            offset.dy + math.sin(angle + 0.2) * petalLength * 0.6,
            offset.dx + math.cos(angle) * petalLength,
            offset.dy + math.sin(angle) * petalLength,
          );
        canvas.drawPath(petal, _warmPaint);
      }
    }

    // Evolution: Level 5 Mastery - City-Block Shockwave
    if (level >= 5) {
      _lightningPaint.color = Colors.white.withValues(alpha: alpha * 0.7);
      _shockwavePaint.color = color.withValues(alpha: alpha * 0.25);

      // Huge slow-expanding outer ring
      final shockT = Curves.easeOutQuart.transform(t);
      _shockwavePaint.strokeWidth = 6.0 * (1 - t);
      canvas.drawCircle(offset, radius * 2.5 * shockT, _shockwavePaint);

      // Secondary core flash
      canvas.drawCircle(offset, radius * 0.3 * (1 - t), _corePaint);

      // Lightning Filaments
      for (var i = 0; i < 12; i++) {
        final angle = i / 12 * math.pi * 2 + _age * 6;
        final startDist = radius * 0.3 * eased;
        final endDist = radius * 1.8 * eased;

        var currentPoint = offset.translate(
          math.cos(angle) * startDist,
          math.sin(angle) * startDist,
        );

        final path = Path()..moveTo(currentPoint.dx, currentPoint.dy);
        for (var j = 1; j <= 4; j++) {
          final stepDist = startDist + (endDist - startDist) * (j / 4);
          final jitter = (math.Random(i * 13 + j).nextDouble() - 0.5) * 60 * t;
          final nextPoint = offset.translate(
            math.cos(angle) * stepDist + jitter,
            math.sin(angle) * stepDist + jitter,
          );
          path.lineTo(nextPoint.dx, nextPoint.dy);
        }
        canvas.drawPath(path, _lightningPaint);
      }
    }
  }
}

class FirewallEffect extends PositionComponent
    with HasGameReference<ZenithZeroGame> {
  FirewallEffect({
    required this.effectCenter,
    required this.effectWidth,
    this.color = const Color(0xFFFFD166),
    this.level = 1,
  }) : super(priority: 50);

  final Vector2 effectCenter;
  final double effectWidth;
  final Color color;
  final int level;
  double _age = 0;
  static const double _duration = 0.5;

  final Paint _glowPaint = Paint()..style = PaintingStyle.fill;
  final Paint _heatPaint = Paint()..style = PaintingStyle.fill;
  late final Paint _corePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3 * (level >= 4 ? 1.4 : 1.0);
  final Paint _runePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  final Paint _flamePaint = Paint()..style = PaintingStyle.fill;
  final Paint _whiteHotPaint = Paint()..style = PaintingStyle.fill;
  final Paint _beamPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state.hasPendingLevelUp || game.state.isRunOver) return;
    _age += dt;
    if (_age >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final t = (_age / _duration).clamp(0.0, 1.0);
    final alpha = math.sin(t * math.pi).clamp(0.0, 1.0);

    final wallHeight = 42 * (level >= 3 ? 1.4 : 1.0);
    final rect = Rect.fromCenter(
      center: Offset(effectCenter.x, effectCenter.y),
      width: effectWidth,
      height: wallHeight,
    );

    _glowPaint.color = color.withValues(alpha: alpha * 0.32);
    _heatPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withValues(alpha: 0),
        color.withValues(alpha: alpha * 0.45),
        const Color(0xFFFF4D00).withValues(alpha: alpha * 0.28),
        color.withValues(alpha: 0),
      ],
    ).createShader(rect);
    _corePaint.color = color.withValues(alpha: alpha * 0.95);
    _runePaint.color = Colors.white.withValues(alpha: alpha * 0.85);

    // Heat Haze
    canvas.drawRect(rect.inflate(level >= 5 ? 28 : 12), _heatPaint);

    // Core Ward Line
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      _glowPaint,
    );
    canvas.drawLine(rect.centerLeft, rect.centerRight, _corePaint);

    _flamePaint.color = const Color(0xFFFF8A00).withValues(alpha: alpha * 0.82);
    _whiteHotPaint.color = Colors.white.withValues(alpha: alpha * 0.6);

    // Evolution: Pyre Columns (Vertical Flames)
    final columnCount = (effectWidth / (level >= 3 ? 14 : 20)).floor();
    for (var i = 0; i < columnCount; i++) {
      final x = rect.left + (i * (effectWidth / columnCount)) + 6;
      final phase = math.sin(x * 0.08 + _age * 22);
      final height = (level >= 4 ? 34.0 : 22.0) + phase * 10;

      final flamePath = Path()
        ..moveTo(x - 6, rect.center.dy + 15)
        ..quadraticBezierTo(
          x - 9,
          rect.center.dy - height * 0.3,
          x,
          rect.center.dy - height,
        )
        ..quadraticBezierTo(
          x + 10,
          rect.center.dy - height * 0.2,
          x + 6,
          rect.center.dy + 15,
        )
        ..close();
      canvas.drawPath(flamePath, _flamePaint);

      if (i % 3 == 0) {
        canvas.drawCircle(
          Offset(x, rect.center.dy - height * 0.5),
          2.5,
          _whiteHotPaint,
        );
      }
    }

    // Evolution: Level 5 Mastery - Ward Gate Beams
    if (level >= 5) {
      _beamPaint.color = Colors.white.withValues(alpha: alpha * 0.5);
      _beamPaint.strokeWidth = 2.5;

      final beamCount = 6;
      final beamProgress = (_age * 4).clamp(0.0, 1.0);
      for (var i = 0; i < beamCount; i++) {
        final bx = rect.left + (i + 0.5) * (effectWidth / beamCount);
        final by1 = rect.center.dy - 20;
        final by2 = by1 - 60 * beamProgress;
        canvas.drawLine(Offset(bx, by1), Offset(bx, by2), _beamPaint);

        // Beam head glow
        canvas.drawCircle(Offset(bx, by2), 4 * (1 - t), _beamPaint);
      }
    }

    // Floating Ancient Runes
    final runeSpacing = level >= 5 ? 28.0 : 42.0;
    for (var x = rect.left + 20; x < rect.right; x += runeSpacing) {
      final drift = math.sin(_age * 5 + x) * 4;
      final rx = x;
      final ry = rect.center.dy + drift;

      canvas.drawCircle(Offset(rx, ry), 6, _runePaint);
      canvas.drawLine(
        Offset(rx - 8, ry - 10),
        Offset(rx + 8, ry + 10),
        _runePaint,
      );

      if (level >= 3) {
        canvas.drawLine(
          Offset(rx + 8, ry - 10),
          Offset(rx - 8, ry + 10),
          _runePaint,
        );
      }
    }
  }
}

class MeteorImpactEffect extends PositionComponent
    with HasGameReference<ZenithZeroGame> {
  MeteorImpactEffect({
    required this.target,
    required this.radius,
    this.color = const Color(0xFF7C4DFF),
    this.level = 1,
  }) : super(priority: 65);

  final Vector2 target;
  final double radius;
  final Color color;
  final int level;
  double _age = 0;
  static const double _duration = 0.45;

  late final Paint _skyGlowPaint = Paint()
    ..strokeWidth = 26 * (level >= 3 ? 1.5 : 1.0)
    ..strokeCap = StrokeCap.round;
  late final Paint _bladePaint = Paint()
    ..strokeWidth = 4 * (level >= 4 ? 1.6 : 1.0)
    ..strokeCap = StrokeCap.round;
  late final Paint _trailPaint = Paint()
    ..strokeWidth = 13 * (level >= 3 ? 1.4 : 1.0)
    ..strokeCap = StrokeCap.round;
  late final Paint _blastPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 9 * (level >= 3 ? 1.3 : 1.0);
  final Paint _firePaint = Paint()..style = PaintingStyle.fill;
  final Paint _craterPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4;
  final Paint _shockwavePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state.hasPendingLevelUp || game.state.isRunOver) return;
    _age += dt;
    if (_age >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final t = (_age / _duration).clamp(0.0, 1.0);
    final alpha = 1 - t;
    final impact = Offset(target.x, target.y);

    // Blade entry phase (top to bottom)
    final bladeT = Curves.easeIn.transform(t);
    final start = Offset(target.x - 40, target.y - 450);
    final currentPos = Offset.lerp(start, impact, bladeT)!;

    _skyGlowPaint.color = color.withValues(alpha: alpha * 0.22);
    _bladePaint.color = Colors.white.withValues(alpha: alpha);
    _trailPaint.color = color.withValues(alpha: alpha * 0.45);

    // Entry Trail
    canvas.drawLine(start, currentPos, _skyGlowPaint);
    canvas.drawLine(start, currentPos, _trailPaint);

    // Falling Blade
    final bladeVec = (impact - start);
    final bladeAngle = math.atan2(bladeVec.dy, bladeVec.dx);
    canvas.save();
    canvas.translate(currentPos.dx, currentPos.dy);
    canvas.rotate(bladeAngle + math.pi / 2);
    final bladeRect = Rect.fromCenter(
      center: Offset.zero,
      width: 8 * (level >= 4 ? 1.5 : 1.0),
      height: 80,
    );
    canvas.drawRect(bladeRect.inflate(4), _trailPaint);
    canvas.drawRect(bladeRect, _bladePaint);
    canvas.restore();

    // Impact Ground Effects
    _blastPaint.color = color.withValues(alpha: alpha * 0.35);
    _firePaint.color = const Color(0xFFFFD166).withValues(alpha: alpha * 0.4);
    _craterPaint.color = Colors.white.withValues(alpha: alpha * 0.5);

    final blastRadius = radius * Curves.easeOutQuart.transform(t);
    canvas.drawCircle(impact, blastRadius * 0.5, _firePaint);
    canvas.drawCircle(impact, blastRadius, _blastPaint);

    // Impact Flash
    if (t < 0.2) {
      canvas.drawCircle(impact, blastRadius * 1.5, _bladePaint);
    }

    // Ground Cracks
    final lineCount = level >= 5 ? 24 : (level >= 3 ? 16 : 10);
    for (var i = 0; i < lineCount; i++) {
      final angle = i / lineCount * math.pi * 2 + (i % 2 == 0 ? t : -t) * 0.2;
      final length = blastRadius * (0.6 + (i % 3) * 0.2);
      final end = impact.translate(
        math.cos(angle) * length,
        math.sin(angle) * length,
      );
      canvas.drawLine(impact, end, _craterPaint);
    }

    if (level >= 5) {
      _shockwavePaint.color = color.withValues(alpha: alpha * 0.2);
      final shockRadius = blastRadius * 1.8 * Curves.easeOutExpo.transform(t);
      _shockwavePaint.strokeWidth = 4.0 * (1 - t);
      canvas.drawCircle(impact, shockRadius, _shockwavePaint);
    }
  }
}

class MeteorTargetingEffect extends PositionComponent
    with HasGameReference<ZenithZeroGame> {
  MeteorTargetingEffect({
    required Vector2 target,
    required this.radius,
    required this.duration,
    this.color = const Color(0xFF7C4DFF),
  }) : super(position: target, priority: 64);

  final double radius;
  final double duration;
  final Color color;
  double _age = 0;

  final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  final Paint _fill = Paint()..style = PaintingStyle.fill;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state.hasPendingLevelUp || game.state.isRunOver) return;
    _age += dt;
    if (_age >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final t = (_age / duration).clamp(0.0, 1.0);
    final alpha = (1 - t) * 0.8;
    final eased = Curves.easeIn.transform(t);

    _paint.color = color.withValues(alpha: alpha);
    _fill.color = color.withValues(alpha: alpha * 0.15);

    final currentRadius = radius * (1.5 - 0.5 * eased);
    canvas.drawCircle(Offset.zero, currentRadius, _fill);
    canvas.drawCircle(Offset.zero, currentRadius, _paint);

    // Crosshair
    final inner = currentRadius * 0.3;
    canvas.drawLine(Offset(-currentRadius, 0), Offset(-inner, 0), _paint);
    canvas.drawLine(Offset(currentRadius, 0), Offset(inner, 0), _paint);
    canvas.drawLine(Offset(0, -currentRadius), Offset(0, -inner), _paint);
    canvas.drawLine(Offset(0, currentRadius), Offset(0, inner), _paint);

    // Ancient Sigil Dots
    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 + t * 4;
      canvas.drawCircle(
        Offset(
          math.cos(angle) * currentRadius,
          math.sin(angle) * currentRadius,
        ),
        3,
        _paint,
      );
    }
  }
}

class HeroAuraEffect extends PositionComponent
    with HasGameReference<ZenithZeroGame> {
  HeroAuraEffect({required this.effectCenter}) : super(priority: 45);

  final Vector2 effectCenter;
  double _age = 0;
  final math.Random _rng = math.Random();
  final List<_AuraParticle> _particles = [];

  final Paint _aurPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  final Paint _particlePaint = Paint()..style = PaintingStyle.fill;

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;

    if (_particles.length < 20 && _rng.nextDouble() < 0.3) {
      _particles.add(
        _AuraParticle(
          offset: Vector2(
            (_rng.nextDouble() - 0.5) * 20,
            (_rng.nextDouble() - 0.5) * 20,
          ),
          velocity: Vector2(
            (_rng.nextDouble() - 0.5) * 15,
            -20 - _rng.nextDouble() * 30,
          ),
          life: 0.6 + _rng.nextDouble() * 0.4,
        ),
      );
    }

    for (var i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.offset += p.velocity * dt;
      p.age += dt;
      if (p.age >= p.life) {
        _particles.removeAt(i);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final color = _getAuraColor();
    final pulse = 0.5 + 0.5 * math.sin(_age * 4);

    _aurPaint.color = color.withValues(alpha: 0.15 + 0.1 * pulse);
    canvas.drawCircle(
      Offset(effectCenter.x, effectCenter.y),
      24 + 4 * pulse,
      _aurPaint,
    );

    for (final p in _particles) {
      final t = p.age / p.life;
      final alpha = (1 - t) * 0.6;
      _particlePaint.color = color.withValues(alpha: alpha);
      canvas.drawCircle(
        Offset(effectCenter.x + p.offset.x, effectCenter.y + p.offset.y),
        1.5 * (1 - t),
        _particlePaint,
      );
    }
  }

  Color _getAuraColor() {
    final state = game.state;
    final archetypes = {
      SkillArchetype.chain: state.chainLevel,
      SkillArchetype.nova: state.flameNovaLevel,
      SkillArchetype.firewall: state.firewallLevel,
      SkillArchetype.meteor: state.meteorMarkLevel,
      SkillArchetype.barrage: state.barrageLevel,
      SkillArchetype.focus: state.focusLevel,
      SkillArchetype.frost: state.frostLevel,
      SkillArchetype.rupture: state.ruptureLevel,
      SkillArchetype.sentinel: state.sentinelLevel,
    };

    var maxLevel = 0;
    var topType = SkillArchetype.chain;
    archetypes.forEach((type, level) {
      if (level > maxLevel) {
        maxLevel = level;
        topType = type;
      }
    });

    if (maxLevel == 0) return const Color(0xFF00E5FF);

    return switch (topType) {
      SkillArchetype.chain => const Color(0xFF00E5FF),
      SkillArchetype.nova => const Color(0xFFFF2D95),
      SkillArchetype.firewall => const Color(0xFFFFD166),
      SkillArchetype.meteor => const Color(0xFF7C4DFF),
      SkillArchetype.barrage => const Color(0xFF64FFDA),
      SkillArchetype.focus => const Color(0xFFFFF176),
      SkillArchetype.bounty => const Color(0xFFFFD54F),
      SkillArchetype.frost => const Color(0xFF80DEEA),
      SkillArchetype.rupture => const Color(0xFFFF5252),
      SkillArchetype.sentinel => const Color(0xFFE1F5FE),
      SkillArchetype.mothership => const Color(0xFFCE93D8),
    };
  }
}

class _AuraParticle {
  _AuraParticle({
    required this.offset,
    required this.velocity,
    required this.life,
  });
  Vector2 offset;
  Vector2 velocity;
  double life;
  double age = 0;
}

class LaserBeamEffect extends PositionComponent
    with HasGameReference<ZenithZeroGame> {
  LaserBeamEffect({
    required this.from,
    required this.to,
    this.color = const Color(0xFFFF5252),
    this.width = 4.0,
    this.duration = 0.5,
  }) : super(priority: 58);

  final Vector2 from;
  final Vector2 to;
  final Color color;
  @override
  final double width;
  final double duration;
  double _age = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / duration).clamp(0.0, 1.0);
    // Beams usually flicker or pulse
    final pulse = 0.8 + 0.2 * math.sin(_age * 40);
    final alpha = 1.0 - Curves.easeIn.transform(t);

    final beamPaint = Paint()
      ..color = color.withValues(alpha: alpha * pulse)
      ..strokeWidth = width * pulse
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: alpha * 0.3)
      ..strokeWidth = width * 3.0 * pulse
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: alpha)
      ..strokeWidth = width * 0.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final start = Offset(from.x, from.y);
    final end = Offset(to.x, to.y);

    canvas.drawLine(start, end, glowPaint);
    canvas.drawLine(start, end, beamPaint);
    canvas.drawLine(start, end, corePaint);
  }
}

void _drawSnowflake(Canvas canvas, Offset center, double radius, Paint paint) {
  for (var i = 0; i < 6; i++) {
    final angle = i / 6 * math.pi * 2;
    final end = center.translate(
      math.cos(angle) * radius,
      math.sin(angle) * radius,
    );
    canvas.drawLine(center, end, paint);
    final branchAngle = angle + math.pi * 0.72;
    final branch = end.translate(
      math.cos(branchAngle) * radius * 0.28,
      math.sin(branchAngle) * radius * 0.28,
    );
    canvas.drawLine(end, branch, paint);
  }
}
