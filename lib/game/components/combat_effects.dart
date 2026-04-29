import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class SlashArcEffect extends PositionComponent {
  SlashArcEffect({
    required this.from,
    required this.to,
    this.color = const Color(0xFF00E5FF),
  }) : super(priority: 60);

  final Vector2 from;
  final Vector2 to;
  final Color color;
  double _age = 0;
  static const double _duration = 0.18;

  @override
  void update(double dt) {
    super.update(dt);
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
    final control = mid + Offset(normal.x * 38, normal.y * 38);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
    final glow = Paint()
      ..color = color.withValues(alpha: alpha * 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;
    final core = Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, glow);
    canvas.drawPath(path, core);
  }
}

class NovaPulseEffect extends PositionComponent {
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
    canvas.drawCircle(offset, radius * eased, fill);
    canvas.drawCircle(offset, radius * eased, glow);
    canvas.drawCircle(offset, radius * eased, core);
  }
}

class FirewallEffect extends PositionComponent {
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
    canvas.drawLine(rect.centerLeft, rect.centerRight, core);
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

class MeteorImpactEffect extends PositionComponent {
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
    final blade = Paint()
      ..color = Colors.white.withValues(alpha: alpha)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final trail = Paint()
      ..color = color.withValues(alpha: alpha * 0.4)
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, impact, trail);
    canvas.drawLine(start, impact, blade);
    final blast = Paint()
      ..color = color.withValues(alpha: alpha * 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9;
    canvas.drawCircle(impact, radius * Curves.easeOut.transform(t), blast);
  }
}
