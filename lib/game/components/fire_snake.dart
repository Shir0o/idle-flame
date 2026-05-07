import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../zenith_zero_game.dart';
import 'enemy.dart';

class FireSnake extends PositionComponent with HasGameReference<ZenithZeroGame> {
  FireSnake({
    required Vector2 startPos,
    required this.level,
    required this.damage,
    required this.speed,
    required this.trailDuration,
  }) : super(position: startPos, priority: 60);

  final int level;
  final double damage;
  final double speed;
  final double trailDuration;

  final List<Vector2> _trail = [];
  final List<double> _trailAges = [];
  static const double _pointSpacing = 8.0;
  
  Enemy? _target;
  double _totalTime = 0;
  double _lifeTime = 0;
  static const double _maxLife = 6.0;

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
      _target = null;
    }

    // Target acquisition
    if (_lifeTime < _maxLife && (_target == null || !_target!.isAlive)) {
      final targets = game.selectNearestEnemies(position, 1);
      if (targets.isNotEmpty) {
        _target = targets.first;
      }
    }

    // Movement
    final dir = Vector2(0, -1);
    if (_target != null) {
      final toTarget = _target!.position - position;
      if (toTarget.length2 > 0) {
        dir.setFrom(toTarget.normalized());
      }
    }

    // Slither motion
    final slither = math.sin(_totalTime * 10) * 0.4;
    final moveDir = Vector2(
      dir.x * math.cos(slither) - dir.y * math.sin(slither),
      dir.x * math.sin(slither) + dir.y * math.cos(slither),
    );

    position += moveDir * speed * dt;
    angle = math.atan2(moveDir.y, moveDir.x);

    // Trail management
    if (_lifeTime < _maxLife && (_trail.isEmpty || (_trail.first - position).length > _pointSpacing)) {
      _trail.insert(0, position.clone());
      _trailAges.insert(0, 0);
    }

    for (var i = _trailAges.length - 1; i >= 0; i--) {
      _trailAges[i] += dt;
      if (_trailAges[i] > trailDuration) {
        _trail.removeAt(i);
        _trailAges.removeAt(i);
      }
    }

    if (_trail.isEmpty && (_target == null || _lifeTime >= _maxLife)) {
      removeFromParent();
      return;
    }

    // Damage logic
    const hitRadius = 24.0;
    const hitRadius2 = hitRadius * hitRadius;
    for (final enemy in game.targetableEnemies) {
      bool hit = false;
      // Check head
      if ((enemy.position - position).length2 < hitRadius2) {
        hit = true;
      } else {
        // Check trail segments (optimized: only every few points)
        for (var i = 0; i < _trail.length; i += 2) {
          if ((enemy.position - _trail[i]).length2 < hitRadius2) {
            hit = true;
            break;
          }
        }
      }

      if (hit) {
        enemy.takeDamage(
          damage * dt, // Continuous damage
          source: position,
          type: DamageType.firewall,
        );
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (_trail.length < 2) return;

    final lifeT = (_lifeTime / _maxLife).clamp(0.0, 1.0);
    final globalAlpha = 1.0 - math.pow(lifeT, 4).toDouble();

    // Undo component transform to draw trail in world space
    canvas.save();
    final m = transform.transformMatrix.clone();
    m.invert();
    canvas.transform(Float64List.fromList(m.storage));

    final n = _trail.length;
    final vertices = <Offset>[];
    final colors = <Color>[];

    for (var i = 0; i < n; i++) {
      final p = _trail[i];
      final age = _trailAges[i];
      final lifeFactor = 1.0 - (age / trailDuration).clamp(0.0, 1.0);
      
      final Vector2 tangent;
      if (i == 0) {
        tangent = (p - _trail[i + 1]);
      } else if (i == n - 1) {
        tangent = (_trail[i - 1] - p);
      } else {
        tangent = (_trail[i - 1] - _trail[i + 1]);
      }

      if (tangent.length2 == 0) continue;
      final t = tangent.normalized();
      final normal = Vector2(-t.y, t.x);

      final width = (12.0 + math.sin(i * 0.5 - _totalTime * 5) * 4.0) * lifeFactor;
      
      final color = Color.lerp(
        const Color(0xFFFFAB40), // Orange
        const Color(0xFFFF3D00), // Deep Red-Orange
        i / n,
      )!.withValues(alpha: 0.8 * lifeFactor * globalAlpha);

      vertices.add(Offset(p.x + normal.x * width, p.y + normal.y * width));
      vertices.add(Offset(p.x - normal.x * width, p.y - normal.y * width));
      colors.add(color);
      colors.add(color);
    }

    if (vertices.length >= 4) {
      final ribbon = ui.Vertices(
        ui.VertexMode.triangleStrip,
        vertices,
        colors: colors,
      );
      canvas.drawVertices(ribbon, BlendMode.srcOver, Paint());

      // Glow pass
      final glowPaint = Paint()
        ..color = const Color(0xFFFFD166).withValues(alpha: 0.2 * globalAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      
      final glowPath = Path();
      glowPath.moveTo(vertices.first.dx, vertices.first.dy);
      for(var i = 2; i < vertices.length; i += 2) {
        glowPath.lineTo(vertices[i].dx, vertices[i].dy);
      }
      for(var i = vertices.length - 1; i >= 1; i -= 2) {
        glowPath.lineTo(vertices[i].dx, vertices[i].dy);
      }
      glowPath.close();
      canvas.drawPath(glowPath, glowPaint);
    }

    // Render head
    if (_lifeTime < _maxLife) {
      final headPos = _trail.first;
      final headPaint = Paint()
        ..color = Colors.white.withValues(alpha: globalAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(headPos.x, headPos.y), 6, headPaint);
    }

    canvas.restore();
  }
}
