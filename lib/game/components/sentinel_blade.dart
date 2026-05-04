import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../idle_game.dart';
import 'enemy.dart';
import 'combat_effects.dart';

enum _StrikePhase { idle, windup, dashing, returning }

class SentinelBlade extends PositionComponent with HasGameReference<IdleGame> {
  SentinelBlade({required this.orbitIndex, this.level = 1})
    : super(priority: 62) {
    // Stagger initial readiness so blades don't all strike simultaneously
    // when a target appears.
    _attackTimer = orbitIndex * 0.18;
  }

  final int orbitIndex;
  final int level;
  Enemy? _target;
  double _attackTimer = 0;
  double _totalTime = 0;
  double _hitStopTimer = 0;
  double _pulseTimer = 0;
  double _pulseDuration = 0.18;

  _StrikePhase _phase = _StrikePhase.idle;
  double _phaseTimer = 0;
  double _phaseDuration = 0;

  Vector2 _dashStart = Vector2.zero();
  Vector2 _dashControl1 = Vector2.zero();
  Vector2 _dashControl2 = Vector2.zero();
  Vector2 _dashEnd = Vector2.zero();
  double _dashProgress = 0;

  Vector2 _windupAnchor = Vector2.zero();

  Vector2 _returnStart = Vector2.zero();
  Vector2 _returnControl = Vector2.zero();

  final Set<Enemy> _hitThisDash = {};
  static const double _sliceOvershoot = 56.0;

  static const double _siblingStaggerGap = 0.10;

  final List<Vector2> _trail = [];
  static const int _maxTrailPoints = 12;

  static const double _attackRange = double.infinity;
  static const double _dashSpeedRef = 600;
  static const double _windupDuration = 0.14;
  static const double _returnDuration = 0.55;

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

  final Paint _trailPaint = Paint()..style = PaintingStyle.fill;

  final Paint _handlePaint = Paint()
    ..color = const Color(0xFF6A4C93).withValues(alpha: 0.7)
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

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
        if (_target != null && _attackTimer <= 0 && _siblingsClear()) {
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
    if (_phase == _StrikePhase.dashing ||
        _phase == _StrikePhase.returning) {
      if (_trail.isEmpty || (_trail.first - position).length2 > 4) {
        _trail.insert(0, position.clone());
        if (_trail.length > _maxTrailPoints) _trail.removeLast();
      }
    } else if (_trail.isNotEmpty) {
      // Fade out by dropping a point per frame so the ribbon trails off.
      _trail.removeLast();
    }
  }

  void pulse(double duration) {
    _pulseTimer = duration;
    _pulseDuration = duration;
  }

  bool _siblingsClear() {
    final p = parent;
    if (p == null) return true;
    for (final c in p.children) {
      if (c is SentinelBlade && !identical(c, this)) {
        if (c._phase == _StrikePhase.windup ||
            c._phase == _StrikePhase.dashing) {
          return false;
        }
        // Brief gap after a sibling slices so strikes sequence visibly.
        if (c._phase == _StrikePhase.returning &&
            c._phaseTimer < _siblingStaggerGap) {
          return false;
        }
      }
    }
    return true;
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

  // --- Formation -----------------------------------------------------------

  void _orbit(Vector2 heroPos, double dt) {
    const xBase = 48.0;
    const spacing = 14.0;

    // Row of upward-pointing blades arrayed to the hero's right.
    final xOffset = xBase + orbitIndex * spacing;

    // Subtle per-blade hover bob so the line breathes.
    final bob =
        2.0 * math.sin(_totalTime * 1.8 + orbitIndex * 0.7) +
        1.0 * math.sin(_totalTime * 1.1 + orbitIndex * 0.4);

    final targetPos = heroPos + Vector2(xOffset, bob);

    // Frame-rate-stable easing toward the slot.
    final k = 1 - math.exp(-9 * dt);
    final toSlot = targetPos - position;
    if (toSlot.length2 > 0.25) {
      position += toSlot * k;
    } else {
      position = targetPos;
    }

    // Tip points north (up) with a faint hovering wobble.
    final wobble = 0.06 * math.sin(_totalTime * 1.4 + orbitIndex);
    angle = -math.pi / 2 + wobble;
  }

  // --- Strike phases -------------------------------------------------------

  void _enterWindup() {
    _phase = _StrikePhase.windup;
    _phaseTimer = 0;
    _phaseDuration = _windupDuration;
    _windupAnchor = position.clone();
    game.audio.playSkillCast();
  }

  void _tickWindup(double dt) {
    final t = _target;
    if (t == null) {
      _phase = _StrikePhase.idle;
      return;
    }
    _phaseTimer += dt;

    // Hold position; just face the target while the glow charges.
    position = _windupAnchor;
    final toTarget = t.position - _windupAnchor;
    if (toTarget.length2 > 0) {
      angle = math.atan2(toTarget.y, toTarget.x);
    }

    if (_phaseTimer >= _phaseDuration) {
      _enterDash();
    }
  }

  void _enterDash() {
    final t = _target;
    if (t == null) {
      _phase = _StrikePhase.idle;
      return;
    }
    _dashStart = position.clone();

    // Each blade approaches the target from its own angle, fanning around it
    // (yujian / sword-flight feel). The angle rotates over time so successive
    // strikes from the same blade also vary.
    final count = math.max(2, game.state.sentinelCount);
    final spread = orbitIndex * (math.pi * 2 / count);
    final phase = _totalTime * 0.6;
    final approachAngle = spread + phase;
    final approachDir = Vector2(
      math.cos(approachAngle),
      math.sin(approachAngle),
    );

    // The blade enters the target along approachDir and exits past it.
    _dashEnd = t.position + approachDir * _sliceOvershoot;

    // Cubic Bézier control points create a swooping flight path:
    //  - P2 pulls the curve to enter the target along approachDir.
    //  - P1 swings the path wide off the chord on the side opposite the
    //    approach, so the blade arcs around the target before slicing through.
    final entryAnchor = t.position - approachDir * 36;

    final chord = entryAnchor - _dashStart;
    final chordLen = chord.length;
    final chordDir = chordLen > 0 ? chord / chordLen : Vector2(1, 0);
    final chordNormal = Vector2(-chordDir.y, chordDir.x);

    final dot = approachDir.dot(chordNormal);
    final swingSide = dot > 0 ? -1.0 : 1.0;
    final swingDist = math.max(28.0, chordLen * 0.45);

    _dashControl1 =
        _dashStart +
        chord * 0.35 +
        chordNormal * (swingDist * swingSide);
    _dashControl2 = entryAnchor;

    _phase = _StrikePhase.dashing;
    _phaseTimer = 0;
    final approxArcLen = chordLen + swingDist * 0.7 + _sliceOvershoot;
    _phaseDuration = math.max(
      0.26,
      math.min(0.55, approxArcLen / _dashSpeedRef),
    );
    _dashProgress = 0;
    _hitThisDash.clear();
  }

  void _tickDash(double dt) {
    _phaseTimer += dt;
    final p = (_phaseTimer / _phaseDuration).clamp(0.0, 1.0);
    // Smooth, near-constant pace through the slice (no slowdown near target).
    final eased = Curves.easeInOutSine.transform(p);
    _dashProgress = eased;

    final prev = position.clone();
    final mt = 1 - eased;
    final mt2 = mt * mt;
    final mt3 = mt2 * mt;
    final e2 = eased * eased;
    final e3 = e2 * eased;
    position = Vector2(
      mt3 * _dashStart.x +
          3 * mt2 * eased * _dashControl1.x +
          3 * mt * e2 * _dashControl2.x +
          e3 * _dashEnd.x,
      mt3 * _dashStart.y +
          3 * mt2 * eased * _dashControl1.y +
          3 * mt * e2 * _dashControl2.y +
          e3 * _dashEnd.y,
    );

    final motion = position - prev;
    if (motion.length2 > 0) {
      angle = math.atan2(motion.y, motion.x);
    }

    // Multi-hit: damage every alive enemy whose body the curve sweeps
    // through, once per strike. We do not re-target — just hit whatever
    // happens to lie along the slice path.
    const hitRadius = 16.0;
    const hitRadius2 = hitRadius * hitRadius;
    for (final e in game.aliveEnemies) {
      if (_hitThisDash.contains(e)) continue;
      if ((e.position - position).length2 < hitRadius2) {
        _applySliceDamage(motion, e);
        _hitThisDash.add(e);
      }
    }
    if (p >= 1.0) {
      final dir = motion.length2 > 0 ? motion.normalized() : Vector2(1, 0);
      _enterReturn(dir);
    }
  }

  void _applySliceDamage(Vector2 motion, Enemy t) {
    t.takeDamage(
      game.state.sentinelDamage,
      source: position,
      type: DamageType.sentinel,
    );

    parent?.add(
      HitSparkEffect(
        effectCenter: t.position.clone(),
        direction: (position - t.position).normalized(),
        color: const Color(0xFF00B0FF),
        count: 12,
      ),
    );

    // Slice arc tangent to the blade's velocity through the target.
    final dir = motion.length2 > 0
        ? motion.normalized()
        : (t.position - _dashStart).normalized();
    final arcHalf = 22.0;
    parent?.add(
      SlashArcEffect(
        from: t.position - dir * arcHalf,
        to: t.position + dir * arcHalf,
        color: const Color(0xFF00E5FF),
        widthMultiplier: 0.55,
        level: level,
      ),
    );

    // Level 5 Mastery: Shard Seekers
    if (level >= 5) {
      final secondaryTargets =
          game.aliveEnemies.where((e) => e != t).toList()..sort(
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

    if (game.state.meta.hasKeystone('twinblade') && t.isAlive) {
      t.takeDamage(
        game.state.sentinelDamage * 0.6,
        source: position,
        type: DamageType.sentinel,
      );
    }

    _attackTimer = game.state.sentinelAttackCooldown;
  }

  Vector2 _formationSlot(Vector2 heroPos) {
    const xBase = 48.0;
    const spacing = 14.0;
    final xOffset = xBase + orbitIndex * spacing;
    final bob =
        2.0 * math.sin(_totalTime * 1.8 + orbitIndex * 0.7) +
        1.0 * math.sin(_totalTime * 1.1 + orbitIndex * 0.4);
    return heroPos + Vector2(xOffset, bob);
  }

  void _enterReturn(Vector2 motionDir) {
    _phase = _StrikePhase.returning;
    _phaseTimer = 0;
    _phaseDuration = _returnDuration;
    _returnStart = position.clone();

    // Continue forward briefly so the slice exit eases into the return arc,
    // then perpendicular swing curves the path back to the formation slot.
    final heroPos = game.hero.position;
    final slot = _formationSlot(heroPos);
    final toSlot = slot - _returnStart;
    final straight = toSlot.length2 > 0
        ? toSlot.normalized()
        : Vector2(-1, 0);
    final normal = Vector2(-straight.y, straight.x);
    final side = (orbitIndex.isEven) ? -1.0 : 1.0;
    final swing = math.max(40.0, toSlot.length * 0.45);

    final continueDir = motionDir.length2 > 0
        ? motionDir.normalized()
        : straight;
    _returnControl =
        _returnStart +
        continueDir * 28 +
        normal * (swing * side);
  }

  void _tickReturn(Vector2 heroPos, double dt) {
    _phaseTimer += dt;
    final p = (_phaseTimer / _phaseDuration).clamp(0.0, 1.0);
    final eased = Curves.easeInOutCubic.transform(p);

    // End point follows the live formation slot so a moving hero is tracked.
    final slot = _formationSlot(heroPos);
    final prev = position.clone();
    final mt = 1 - eased;
    position = Vector2(
      mt * mt * _returnStart.x +
          2 * mt * eased * _returnControl.x +
          eased * eased * slot.x,
      mt * mt * _returnStart.y +
          2 * mt * eased * _returnControl.y +
          eased * eased * slot.y,
    );

    final motion = position - prev;
    if (motion.length2 > 0) {
      // Blend toward the resting (north-facing) angle as we settle.
      final flightAngle = math.atan2(motion.y, motion.x);
      final restAngle = -math.pi / 2;
      angle = _lerpAngle(flightAngle, restAngle, Curves.easeInCubic.transform(p));
    }

    if (_phaseTimer >= _phaseDuration) {
      _phase = _StrikePhase.idle;
      _target = null;
    }
  }

  double _lerpAngle(double a, double b, double t) {
    var diff = (b - a) % (2 * math.pi);
    if (diff > math.pi) diff -= 2 * math.pi;
    if (diff < -math.pi) diff += 2 * math.pi;
    return a + diff * t;
  }

  // --- Rendering -----------------------------------------------------------

  Path _swordBladePath(double length, double width) {
    final tip = length * 0.5;
    final taperStart = length * 0.32;
    final base = -length * 0.2;
    final half = width * 0.5;

    return Path()
      ..moveTo(tip, 0)
      ..lineTo(taperStart, -half)
      ..lineTo(base, -half)
      ..lineTo(base, half)
      ..lineTo(taperStart, half)
      ..close();
  }

  void _drawSword(
    Canvas canvas,
    double size,
    Paint bladePaint,
    Paint glowPaint,
  ) {
    // Lean, jian-style flying sword: long and slender.
    final bladeLength = size * 2.0;
    final bladeWidth = size * 0.24;
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

    // Subtle handle extending past the base.
    final handleStart = -bladeLength * 0.2;
    final handleEnd = handleStart - bladeLength * 0.22;
    _handlePaint.strokeWidth = bladeWidth * 0.85;
    canvas.drawLine(
      Offset(handleStart, 0),
      Offset(handleEnd, 0),
      _handlePaint,
    );
  }

  void _renderRibbon(Canvas canvas, double headHalfWidth) {
    if (_trail.length < 2) return;

    // Build a tapered ribbon polygon in world space, then translate into
    // local space by subtracting current position.
    final n = _trail.length;
    final left = <Offset>[];
    final right = <Offset>[];

    for (var i = 0; i < n; i++) {
      final p = _trail[i];
      // Direction along the curve at point i.
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

      final taper = 1 - (i / (n - 1));
      final hw = headHalfWidth * taper;

      final lx = p.x + normal.x * hw - position.x;
      final ly = p.y + normal.y * hw - position.y;
      final rx = p.x - normal.x * hw - position.x;
      final ry = p.y - normal.y * hw - position.y;
      left.add(Offset(lx, ly));
      right.add(Offset(rx, ry));
    }

    if (left.length < 2) return;

    final path = Path()..moveTo(left.first.dx, left.first.dy);
    for (var i = 1; i < left.length; i++) {
      path.lineTo(left[i].dx, left[i].dy);
    }
    for (var i = right.length - 1; i >= 0; i--) {
      path.lineTo(right[i].dx, right[i].dy);
    }
    path.close();

    _trailPaint.color = const Color(0xFF00B0FF).withValues(alpha: 0.32);
    canvas.drawPath(path, _trailPaint);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Motion ribbon (only present during strike phases).
    _renderRibbon(canvas, 2.6);

    canvas.save();

    // Idle-ready glow pulse (replaces the old constant scale shimmer).
    if (_phase == _StrikePhase.idle && _attackTimer <= 0 && _target == null) {
      final pulse = 0.4 + 0.18 * (0.5 + 0.5 * math.sin(_totalTime * 4));
      _glowPaint.color = const Color(0xFF00B0FF).withValues(alpha: pulse);
    } else if (_phase == _StrikePhase.windup) {
      // Charging glow ramps up during windup.
      final p = (_phaseTimer / _phaseDuration).clamp(0.0, 1.0);
      _glowPaint.color = const Color(
        0xFF00B0FF,
      ).withValues(alpha: 0.4 + 0.45 * p);
    } else {
      _glowPaint.color = const Color(0xFF00B0FF).withValues(alpha: 0.4);
    }

    // Slight scale stretch during dash to sell the speed.
    if (_phase == _StrikePhase.dashing) {
      final s = 1.0 + 0.15 * Curves.easeInCubic.transform(_dashProgress);
      canvas.scale(s, 1.0 / s.clamp(1.0, 2.0));
    } else if (_phase == _StrikePhase.windup) {
      final p = (_phaseTimer / _phaseDuration).clamp(0.0, 1.0);
      final s = 1.0 + 0.15 * Curves.easeOutCubic.transform(p);
      canvas.scale(s);
    }

    final sizeBase = 12.0 * (level >= 3 ? 1.3 : 1.0);

    void drawBlade(bool isShadow) {
      canvas.save();
      if (isShadow) {
        canvas.translate(-5, 5);
        canvas.scale(0.8);
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
