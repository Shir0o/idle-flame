import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../audio/game_audio.dart';
import '../idle_game.dart';
import 'enemy.dart';

enum _StrikePhase { idle, windup, dashing, returning }

class SentinelBlade extends PositionComponent with HasGameReference<IdleGame> {
  SentinelBlade({required this.orbitIndex, required this.level})
    : super(size: Vector2.all(40), anchor: Anchor.center);

  final int orbitIndex;
  final int level;

  _StrikePhase _phase = _StrikePhase.idle;
  double _phaseTimer = 0;
  Enemy? _target;
  double _attackTimer = 0;
  double _totalTime = 0;
  double _pulseTimer = 0;
  double _pulseDuration = 0;
  bool _chainStrikePending = false;

  final List<Vector2> _trail = [];
  static const int _maxTrailPoints = 14;

  static const double _attackCooldown = 2.4;
  static const double _dashSpeedRef = 1000;
  static const double _windupDuration = 0.10;

  final Paint _bladePaint = Paint()
    ..color = const Color(0xFFE1F5FE)
    ..style = PaintingStyle.fill;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state.isRunOver) {
      removeFromParent();
      return;
    }
    if (game.state.hasPendingLevelUp) return;

    if (_pulseTimer > 0) {
      _pulseTimer -= dt;
      final t = (_pulseTimer / _pulseDuration).clamp(0.0, 1.0);
      scale = Vector2.all(1 + Curves.easeOutBack.transform(t) * 0.12);
      if (_pulseTimer <= 0) scale = Vector2.all(1);
    }

    _totalTime += dt;
    final heroPos = game.hero.position;
    _attackTimer = math.max(0, _attackTimer - dt);

    // Validate / drop dead target.
    if (_target != null && !_target!.isAlive) {
      _target = null;
      if (_phase == _StrikePhase.windup) {
        // Bail out of an unstarted strike if the target died mid-windup.
        _phase = _StrikePhase.idle;
      }
    }

    // Acquire target during idle.
    if (_phase == _StrikePhase.idle && _target == null) {
      _findTarget(heroPos);
    }

    switch (_phase) {
      case _StrikePhase.idle:
        if (_target != null && _attackTimer <= 0) {
          _enterWindup();
        } else {
          _orbit(heroPos, dt);
        }
        break;
      case _StrikePhase.windup:
        _tickWindup(dt);
        break;
      case _StrikePhase.dashing:
        _tickDash(dt);
        break;
      case _StrikePhase.returning:
        _tickReturn(heroPos, dt);
        break;
    }

    // Trail during the active flight (slice and return arc both).
    if (_phase == _StrikePhase.dashing || _phase == _StrikePhase.returning) {
      final tailPos = _getTailWorldPos();
      if (_trail.isEmpty || (_trail.first - tailPos).length2 > 4) {
        _trail.insert(0, tailPos);
        if (_trail.length > _maxTrailPoints) _trail.removeLast();
      }
    } else if (_trail.isNotEmpty) {
      // Fade out by dropping a point per frame so the ribbon trails off.
      _trail.removeLast();
    }
  }

  Vector2 _getTailWorldPos() {
    final sizeBase = 12.0 * (level >= 3 ? 1.3 : 1.0);
    final bladeLength = sizeBase * 2.2;
    // Tail is at the back end of the blade path: base - 3
    final tailLocalX = -bladeLength * 0.22 - 3;
    return position + Vector2(math.cos(angle), math.sin(angle)) * tailLocalX;
  }

  void pulse(double duration) {
    _pulseTimer = duration;
    _pulseDuration = duration;
  }

  void _findTarget(Vector2 heroPos) {
    final enemies = game.aliveEnemies;
    if (enemies.isEmpty) return;

    Enemy? best;
    double minDist2 = double.infinity;
    for (final e in enemies) {
      final d2 = (e.position - heroPos).length2;
      if (d2 < minDist2) {
        minDist2 = d2;
        best = e;
      }
    }
    _target = best;
  }

  // --- Formation -----------------------------------------------------------

  void _orbit(Vector2 heroPos, double dt) {
    const xBase = 52.0;
    const spacing = 16.0;

    // Row of upward-pointing blades arrayed to the hero's right.
    final xOffset = xBase + orbitIndex * spacing;

    // Lemniscate of Gerono (figure-eight) hover pattern for a "living" feel.
    final t = _totalTime * 1.2 + orbitIndex * 0.8;
    final hoverX = 4.0 * math.sin(t);
    final hoverY = 4.0 * math.sin(t) * math.cos(t);

    final targetPos = heroPos + Vector2(xOffset + hoverX, hoverY);

    // Frame-rate-stable easing toward the slot.
    final k = 1 - math.exp(-9 * dt);
    final toSlot = targetPos - position;
    if (toSlot.length2 > 0.25) {
      position += toSlot * k;
    } else {
      position = targetPos;
    }

    // Tip points north (up) with a faint hovering wobble.
    final wobble = 0.08 * math.sin(_totalTime * 1.6 + orbitIndex);
    angle = -math.pi / 2 + wobble;
  }

  // --- Strike phases -------------------------------------------------------

  void _enterWindup({bool isChain = false}) {
    _phase = _StrikePhase.windup;
    _phaseTimer = 0;
    _chainStrikePending = false;

    // Pulse effects during strike.
    game.hero.pulse(0.12);
    pulse(0.12);

    if (isChain) {
      // Chain strikes are faster since the blade is already in 'attack mode'.
      _attackTimer = 0;
    }
  }

  void _tickWindup(double dt) {
    _phaseTimer += dt;
    if (_target == null || !_target!.isAlive) {
      _phase = _StrikePhase.idle;
      return;
    }

    // Face the target during windup.
    final toTarget = _target!.position - position;
    angle = math.atan2(toTarget.y, toTarget.x);

    if (_phaseTimer >= _windupDuration) {
      _phase = _StrikePhase.dashing;
      _phaseTimer = 0;
      game.audio.playSkillDamage(SkillSound.physical);
    }
  }

  void _tickDash(double dt) {
    _phaseTimer += dt;
    if (_target == null) {
      _phase = _StrikePhase.returning;
      _phaseTimer = 0;
      return;
    }

    final toTarget = _target!.position - position;
    final dist2 = toTarget.length2;
    final dashSpeed = _dashSpeedRef * (1 + level * 0.05);

    if (dist2 < 40 * 40) {
      // Impact!
      _target!.takeDamage(
        game.state.sentinelDamage,
        source: position,
        type: DamageType.sentinel,
      );
      game.shakeCamera(intensity: 3, duration: 0.1);

      // Level 5 Ascendant: Dash to a second target immediately if possible.
      if (level >= 5 && !_chainStrikePending) {
        final otherEnemies = game.aliveEnemies.where((e) => e != _target);
        if (otherEnemies.isNotEmpty) {
          _chainStrikePending = true;
          // Find next nearest.
          Enemy? next;
          double nextDist2 = double.infinity;
          for (final e in otherEnemies) {
            final d2 = (e.position - position).length2;
            if (d2 < nextDist2) {
              nextDist2 = d2;
              next = e;
            }
          }
          _target = next;
          _enterWindup(isChain: true);
          return;
        }
      }

      _phase = _StrikePhase.returning;
      _phaseTimer = 0;
      _attackTimer = _attackCooldown * math.pow(0.92, level);
    } else {
      position += toTarget.normalized() * dashSpeed * dt;
      // Face movement direction.
      angle = math.atan2(toTarget.y, toTarget.x);
    }
  }

  void _tickReturn(Vector2 heroPos, double dt) {
    _phaseTimer += dt;
    // Arcing return path.
    final toHero = heroPos - position;
    final dist2 = toHero.length2;
    final returnSpeed = 600.0;

    if (dist2 < 10 * 10) {
      _phase = _StrikePhase.idle;
      _phaseTimer = 0;
    } else {
      position += toHero.normalized() * returnSpeed * dt;
      angle = math.atan2(toHero.y, toHero.x);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw the trailing ribbon.
    if (_trail.length >= 2) {
      _drawRibbon(canvas);
    }

    final sizeBase = 12.0 * (level >= 3 ? 1.3 : 1.0);
    final bladeLength = sizeBase * 2.2;
    final bladeWidth = sizeBase * 0.45;

    canvas.save();
    // Pivot around the anchor point.
    // Blade renders from the origin point outwards.
    final path = Path()
      ..moveTo(-bladeLength * 0.22, -bladeWidth / 2) // Guard back
      ..lineTo(bladeLength * 0.78, 0) // Tip
      ..lineTo(-bladeLength * 0.22, bladeWidth / 2) // Guard back
      ..lineTo(-bladeLength * 0.35, 0) // Pommel
      ..close();

    canvas.drawPath(path, _bladePaint);

    // Glowing edge effect.
    final edgePaint = Paint()
      ..color = const Color(0xFF64FFDA).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(path, edgePaint);

    canvas.restore();
  }

  void _drawRibbon(Canvas canvas) {
    final vertices = <Offset>[];
    final colors = <Color>[];
    final baseColor = const Color(0xFF64FFDA);

    for (var i = 0; i < _trail.length - 1; i++) {
      final p1 = _trail[i];
      final p2 = _trail[i + 1];
      final t = i / _trail.length;
      final opacity = (1.0 - t).clamp(0.0, 1.0);
      final width = 6.0 * opacity;

      final direction = (p2 - p1).normalized();
      final normal = Vector2(-direction.y, direction.x);

      final localP1 = p1 - position;

      vertices.add(
        Offset(localP1.x + normal.x * width, localP1.y + normal.y * width),
      );
      vertices.add(
        Offset(localP1.x - normal.x * width, localP1.y - normal.y * width),
      );

      final color = baseColor.withValues(alpha: 0.4 * opacity);
      colors.add(color);
      colors.add(color);
    }

    if (vertices.length < 3) return;

    final indices = <int>[];
    for (var i = 0; i < vertices.length - 2; i += 2) {
      indices.addAll([i, i + 1, i + 2]);
      indices.addAll([i + 1, i + 2, i + 3]);
    }

    final ribbonVertices = ui.Vertices(
      ui.VertexMode.triangleStrip,
      vertices,
      colors: colors,
    );

    canvas.drawVertices(ribbonVertices, BlendMode.srcOver, Paint());
  }
}
