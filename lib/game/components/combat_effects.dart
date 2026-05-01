import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../idle_game.dart';
import '../state/skill_catalog.dart';

class HitSparkEffect extends PositionComponent with HasGameReference<IdleGame> {
  HitSparkEffect({
    required this.effectCenter,
    required this.direction,
    this.color = const Color(0xFFFFEB3B),
    int count = 8,
    double spread = 0.95,
    double speed = 145,
  }) : _particles = _buildParticles(direction, count, spread, speed),
       super(priority: 90);

  final Vector2 effectCenter;
  final Vector2 direction;
  final Color color;
  final List<_SparkParticle> _particles;
  double _age = 0;

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
    final flash = Paint()
      ..color = Colors.white.withValues(alpha: alpha * 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final flashRadius = 6 + 13 * Curves.easeOut.transform(t);
    canvas.drawLine(
      center.translate(-flashRadius, 0),
      center.translate(flashRadius, 0),
      flash,
    );
    canvas.drawLine(
      center.translate(0, -flashRadius),
      center.translate(0, flashRadius),
      flash,
    );
    for (final particle in _particles) {
      final offset = effectCenter + (particle.velocity + gravity) * _age;
      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
      final glow = Paint()
        ..color = color.withValues(alpha: alpha * 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(offset.x, offset.y),
        particle.radius * 2.5 * (1 - t * 0.45),
        glow,
      );
      canvas.drawCircle(
        Offset(offset.x, offset.y),
        particle.radius * (1 - t * 0.55),
        paint,
      );
    }
  }
}

class DeathBurstEffect extends PositionComponent
    with HasGameReference<IdleGame> {
  DeathBurstEffect({
    required this.effectCenter,
    this.color = const Color(0xFFFF2D95),
  }) : _particles = _buildParticles(),
       super(priority: 85);

  final Vector2 effectCenter;
  final Color color;
  final List<_SparkParticle> _particles;
  double _age = 0;

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
    final flash = Paint()
      ..color = Colors.white.withValues(alpha: alpha * 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 20 * (1 - t), flash);
    final ring = Paint()
      ..color = color.withValues(alpha: alpha * 0.44)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * (1 - t);
    final outerRing = Paint()
      ..color = Colors.white.withValues(alpha: alpha * 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * (1 - t);
    canvas.drawCircle(center, eased * 34, ring);
    canvas.drawCircle(center, eased * 52, outerRing);
    for (final particle in _particles) {
      final offset = effectCenter + particle.velocity * eased * _duration;
      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
      final streak = Paint()
        ..color = color.withValues(alpha: alpha * 0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = particle.radius * 0.75
        ..strokeCap = StrokeCap.round;
      final tail = effectCenter + (offset - effectCenter) * 0.62;
      canvas.drawLine(
        Offset(tail.x, tail.y),
        Offset(offset.x, offset.y),
        streak,
      );
      canvas.drawCircle(
        Offset(offset.x, offset.y),
        particle.radius * (1 - t * 0.35),
        paint,
      );
    }
  }
}

class CoinBurstEffect extends PositionComponent
    with HasGameReference<IdleGame> {
  CoinBurstEffect({required this.effectCenter})
    : _particles = _buildParticles(),
      super(priority: 88);

  final Vector2 effectCenter;
  final List<_SparkParticle> _particles;
  double _age = 0;

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
    for (final particle in _particles) {
      final fall = Vector2(0, 160 * t * t);
      final offset = effectCenter + (particle.velocity * _age) + fall;
      final coin = Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
      final shine = Paint()
        ..color = Colors.white.withValues(alpha: alpha * 0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(Offset(offset.x, offset.y), particle.radius, coin);
      canvas.drawLine(
        Offset(offset.x - particle.radius * 0.5, offset.y),
        Offset(offset.x + particle.radius * 0.5, offset.y),
        shine,
      );
    }
  }
}

class SlashArcEffect extends PositionComponent with HasGameReference<IdleGame> {
  SlashArcEffect({
    required this.from,
    required this.to,
    this.color = const Color(0xFF00E5FF),
    this.widthMultiplier = 1,
  }) : super(priority: 60);

  final Vector2 from;
  final Vector2 to;
  final Color color;
  final double widthMultiplier;
  double _age = 0;
  static const double _duration = 0.18;

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
    final control = mid + Offset(normal.x * 48, normal.y * 48);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
    final wideGlow = Paint()
      ..color = color.withValues(alpha: alpha * 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28 * widthMultiplier
      ..strokeCap = StrokeCap.round;
    final glow = Paint()
      ..color = color.withValues(alpha: alpha * 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14 * widthMultiplier
      ..strokeCap = StrokeCap.round;
    final core = Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5 * widthMultiplier
      ..strokeCap = StrokeCap.round;
    final edge = Paint()
      ..color = Colors.white.withValues(alpha: alpha * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * widthMultiplier
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, wideGlow);
    canvas.drawPath(path, glow);
    canvas.drawPath(path, core);
    canvas.drawPath(path, edge);
  }
}

class BarrageStreakEffect extends PositionComponent
    with HasGameReference<IdleGame> {
  BarrageStreakEffect({
    required this.effectCenter,
    this.color = const Color(0xFF64FFDA),
  }) : super(priority: 58);

  final Vector2 effectCenter;
  final Color color;
  double _age = 0;
  static const double _duration = 0.22;

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
    final paint = Paint()
      ..color = color.withValues(alpha: alpha * 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final glow = Paint()
      ..color = color.withValues(alpha: alpha * 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final white = Paint()
      ..color = Colors.white.withValues(alpha: alpha * 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final eased = Curves.easeOutCubic.transform(t);
    for (var i = 0; i < 6; i++) {
      final y = effectCenter.y - 24 + i * 14;
      final phase = i * 0.13;
      final start = Offset(effectCenter.x - 42 - eased * 24 + phase * 18, y);
      final end = Offset(effectCenter.x + 42 + eased * 24 + phase * 18, y - 12);
      canvas.drawLine(start, end, glow);
      canvas.drawLine(start, end, paint);
      if (i.isEven) canvas.drawLine(start.translate(9, -3), end, white);
    }
  }
}

class FocusStrikeEffect extends PositionComponent
    with HasGameReference<IdleGame> {
  FocusStrikeEffect({
    required this.from,
    required this.to,
    this.color = const Color(0xFFFFF176),
  }) : super(priority: 64);

  final Vector2 from;
  final Vector2 to;
  final Color color;
  double _age = 0;
  static const double _duration = 0.16;

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
    final half = 18 * (1 - t * 0.45);
    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final glow = Paint()
      ..color = color.withValues(alpha: alpha * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final start = center - normal * half;
    final end = center + normal * half;
    final targeting = Paint()
      ..color = color.withValues(alpha: alpha * 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(Offset(to.x, to.y), 18 * (1 - t * 0.3), targeting);
    canvas.drawLine(Offset(start.x, start.y), Offset(end.x, end.y), glow);
    canvas.drawLine(Offset(start.x, start.y), Offset(end.x, end.y), paint);
  }
}

class FrostFieldEffect extends PositionComponent
    with HasGameReference<IdleGame> {
  FrostFieldEffect({
    required this.effectCenter,
    required this.fieldSize,
    this.color = const Color(0xFF80DEEA),
  }) : super(priority: 32);

  final Vector2 effectCenter;
  final Vector2 fieldSize;
  final Color color;
  double _age = 0;
  static const double _duration = 0.85;

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
    final wash = Paint()
      ..color = color.withValues(alpha: alpha * 0.07)
      ..style = PaintingStyle.fill;
    final line = Paint()
      ..color = color.withValues(alpha: alpha * 0.36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final crack = Paint()
      ..color = Colors.white.withValues(alpha: alpha * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    canvas.drawRect(rect, wash);
    for (var y = rect.top + 22; y < rect.bottom; y += 34) {
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y - 12), line);
    }
    for (var i = 0; i < 9; i++) {
      final x = rect.left + (i + 0.5) * rect.width / 9;
      final y = rect.top + ((i * 47) % 100) / 100 * rect.height;
      final size = 12.0 + (i % 3) * 5;
      _drawSnowflake(canvas, Offset(x, y), size, crack);
    }
  }
}

class RuptureMarkEffect extends PositionComponent
    with HasGameReference<IdleGame> {
  RuptureMarkEffect({required this.effectCenter}) : super(priority: 92);

  final Vector2 effectCenter;
  double _age = 0;
  static const double _duration = 0.28;

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
    final paint = Paint()
      ..color = const Color(0xFFFF5252).withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final glow = Paint()
      ..color = const Color(0xFFFF5252).withValues(alpha: alpha * 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final radius = 16 + Curves.easeOutBack.transform(t) * 8;
    final center = Offset(effectCenter.x, effectCenter.y);
    canvas.drawCircle(center, radius, glow);
    canvas.drawCircle(center, radius * 0.6, glow);
    canvas.drawLine(
      Offset(center.dx - radius, center.dy - radius),
      Offset(center.dx + radius, center.dy + radius),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + radius, center.dy - radius),
      Offset(center.dx - radius, center.dy + radius),
      paint,
    );
    for (var i = 0; i < 6; i++) {
      final angle = i / 6 * math.pi * 2 + t * 0.7;
      final start = center.translate(
        math.cos(angle) * radius * 0.35,
        math.sin(angle) * radius * 0.35,
      );
      final end = center.translate(
        math.cos(angle) * radius * 1.25,
        math.sin(angle) * radius * 1.25,
      );
      canvas.drawLine(start, end, glow);
    }
  }
}

class _SparkParticle {
  const _SparkParticle({required this.velocity, required this.radius});

  final Vector2 velocity;
  final double radius;
}

class NovaPulseEffect extends PositionComponent
    with HasGameReference<IdleGame> {
  NovaPulseEffect({
    required this.effectCenter,
    required this.radius,
    this.color = const Color(0xFFFF2D95),
  }) : super(priority: 55);

  final Vector2 effectCenter;
  final double radius;
  final Color color;
  double _age = 0;
  static const double _duration = 0.42;

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
    final warm = Paint()
      ..color = const Color(0xFFFFD166).withValues(alpha: alpha * 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18;
    final fill = Paint()
      ..color = color.withValues(alpha: alpha * 0.08)
      ..style = PaintingStyle.fill;
    final glow = Paint()
      ..color = color.withValues(alpha: alpha * 0.36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    final core = Paint()
      ..color = Colors.white.withValues(alpha: alpha * 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < 14; i++) {
      final angle = i / 14 * math.pi * 2 + t * 1.8;
      final petalLength = radius * eased * (0.72 + (i.isEven ? 0.18 : 0));
      final petal = Path()
        ..moveTo(offset.dx, offset.dy)
        ..quadraticBezierTo(
          offset.dx + math.cos(angle + 0.18) * petalLength * 0.55,
          offset.dy + math.sin(angle + 0.18) * petalLength * 0.55,
          offset.dx + math.cos(angle) * petalLength,
          offset.dy + math.sin(angle) * petalLength,
        );
      canvas.drawPath(petal, warm);
    }
    canvas.drawCircle(offset, radius * eased, fill);
    canvas.drawCircle(offset, radius * eased, glow);
    canvas.drawCircle(offset, radius * eased, core);
  }
}

class FirewallEffect extends PositionComponent with HasGameReference<IdleGame> {
  FirewallEffect({
    required this.effectCenter,
    required this.effectWidth,
    this.color = const Color(0xFFFFD166),
  }) : super(priority: 50);

  final Vector2 effectCenter;
  final double effectWidth;
  final Color color;
  double _age = 0;
  static const double _duration = 0.5;

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
      width: effectWidth,
      height: 42,
    );
    final glow = Paint()
      ..color = color.withValues(alpha: alpha * 0.28)
      ..style = PaintingStyle.fill;
    final heat = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0),
          color.withValues(alpha: alpha * 0.38),
          const Color(0xFFFF4D00).withValues(alpha: alpha * 0.22),
          color.withValues(alpha: 0),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    final core = Paint()
      ..color = color.withValues(alpha: alpha * 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final rune = Paint()
      ..color = Colors.white.withValues(alpha: alpha * 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      glow,
    );
    canvas.drawRect(rect.inflate(10), heat);
    canvas.drawLine(rect.centerLeft, rect.centerRight, core);
    final flame = Paint()
      ..color = const Color(0xFFFF8A00).withValues(alpha: alpha * 0.78)
      ..style = PaintingStyle.fill;
    final whiteHot = Paint()
      ..color = Colors.white.withValues(alpha: alpha * 0.54)
      ..style = PaintingStyle.fill;
    for (var x = rect.left + 10; x < rect.right; x += 16) {
      final phase = math.sin(x * 0.05 + _age * 18);
      final height = 20 + phase * 8;
      final flamePath = Path()
        ..moveTo(x - 7, rect.center.dy + 12)
        ..quadraticBezierTo(
          x - 10,
          rect.center.dy - height * 0.2,
          x,
          rect.center.dy - height,
        )
        ..quadraticBezierTo(
          x + 11,
          rect.center.dy - height * 0.15,
          x + 7,
          rect.center.dy + 12,
        )
        ..close();
      canvas.drawPath(flamePath, flame);
      if ((x / 16).round().isEven) {
        canvas.drawCircle(
          Offset(x, rect.center.dy - height * 0.45),
          2.2,
          whiteHot,
        );
      }
    }
    for (var x = rect.left + 18; x < rect.right; x += 34) {
      canvas.drawCircle(Offset(x, rect.center.dy), 7, rune);
      canvas.drawLine(
        Offset(x - 9, rect.center.dy - 12),
        Offset(x + 9, rect.center.dy + 12),
        rune,
      );
    }
  }
}

class MeteorImpactEffect extends PositionComponent
    with HasGameReference<IdleGame> {
  MeteorImpactEffect({
    required this.target,
    required this.radius,
    this.color = const Color(0xFF7C4DFF),
  }) : super(priority: 65);

  final Vector2 target;
  final double radius;
  final Color color;
  double _age = 0;
  static const double _duration = 0.45;

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
    final start = Offset(target.x - 34, target.y - 190 + 120 * t);
    final skyGlow = Paint()
      ..color = color.withValues(alpha: alpha * 0.18)
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round;
    final blade = Paint()
      ..color = Colors.white.withValues(alpha: alpha)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final trail = Paint()
      ..color = color.withValues(alpha: alpha * 0.4)
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start.translate(-10, -12), impact, skyGlow);
    canvas.drawLine(start, impact, trail);
    canvas.drawLine(start, impact, blade);
    final blast = Paint()
      ..color = color.withValues(alpha: alpha * 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9;
    final fire = Paint()
      ..color = const Color(0xFFFFD166).withValues(alpha: alpha * 0.34)
      ..style = PaintingStyle.fill;
    final crater = Paint()
      ..color = Colors.white.withValues(alpha: alpha * 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final blastRadius = radius * Curves.easeOut.transform(t);
    canvas.drawCircle(impact, blastRadius * 0.45, fire);
    canvas.drawCircle(impact, blastRadius, blast);
    canvas.drawCircle(impact, blastRadius * 0.65, crater);
    for (var i = 0; i < 12; i++) {
      final angle = i / 12 * math.pi * 2;
      final length = blastRadius * (0.45 + (i % 3) * 0.12);
      final end = impact.translate(
        math.cos(angle) * length,
        math.sin(angle) * length,
      );
      canvas.drawLine(impact, end, crater);
    }
  }
}

class HeroAuraEffect extends PositionComponent with HasGameReference<IdleGame> {
  HeroAuraEffect({required this.effectCenter}) : super(priority: 45);

  final Vector2 effectCenter;
  double _age = 0;
  final math.Random _rng = math.Random();
  final List<_AuraParticle> _particles = [];

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;

    if (_particles.length < 20 && _rng.nextDouble() < 0.3) {
      _particles.add(_AuraParticle(
        offset: Vector2((_rng.nextDouble() - 0.5) * 20, (_rng.nextDouble() - 0.5) * 20),
        velocity: Vector2((_rng.nextDouble() - 0.5) * 15, -20 - _rng.nextDouble() * 30),
        life: 0.6 + _rng.nextDouble() * 0.4,
      ));
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
    
    final paint = Paint()
      ..color = color.withValues(alpha: 0.15 + 0.1 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    
    canvas.drawCircle(Offset(effectCenter.x, effectCenter.y), 24 + 4 * pulse, paint);

    for (final p in _particles) {
      final t = p.age / p.life;
      final alpha = (1 - t) * 0.6;
      final pPaint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(effectCenter.x + p.offset.x, effectCenter.y + p.offset.y),
        1.5 * (1 - t),
        pPaint,
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
    };
  }
}

class _AuraParticle {
  _AuraParticle({required this.offset, required this.velocity, required this.life});
  Vector2 offset;
  Vector2 velocity;
  double life;
  double age = 0;
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
