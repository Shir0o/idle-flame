import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../zenith_zero_game.dart';
import '../state/skill_catalog.dart';
import 'enemy.dart';
import 'combat_effects.dart';

enum _StrikePhase { idle, windup, dashing, returning }

class SentinelBlade extends PositionComponent
    with HasGameReference<ZenithZeroGame> {
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

  double _startAngle = 0;

  final Set<Enemy> _hitThisDash = {};
  static const double _sliceOvershoot = 84.0;

  final List<Vector2> _trail = [];
  final List<_Stardust> _stardust = [];
  static const int _maxTrailPoints = 48;
  static final math.Random _rng = math.Random();

  static const double _attackRange = double.infinity;
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

    // Stardust update loop
    for (var i = _stardust.length - 1; i >= 0; i--) {
      final s = _stardust[i];
      s.position += s.velocity * dt;
      s.age += dt;
      if (s.age >= s.life) {
        _stardust.removeAt(i);
      }
    }

    // Trail during the active flight (slice and return arc both).
    if (_phase == _StrikePhase.dashing || _phase == _StrikePhase.returning) {
      final tailPos = _getTailWorldPos();
      if (_trail.isEmpty || (_trail.first - tailPos).length2 > 4) {
        _trail.insert(0, tailPos);
        if (_trail.length > _maxTrailPoints) _trail.removeLast();
      }

      // Spawn stardust
      if (_stardust.length < 24 && _rng.nextDouble() < 0.35) {
        final dir = Vector2(
          math.cos(angle + math.pi),
          math.sin(angle + math.pi),
        );
        _stardust.add(
          _Stardust(
            position:
                tailPos +
                Vector2(_rng.nextDouble() - 0.5, _rng.nextDouble() - 0.5) * 4,
            velocity:
                dir * (20 + _rng.nextDouble() * 40) +
                Vector2(_rng.nextDouble() - 0.5, _rng.nextDouble() - 0.5) * 25,
            life: 0.3 + _rng.nextDouble() * 0.5,
            size: 0.8 + _rng.nextDouble() * 1.6,
          ),
        );
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

  void _findTarget(Vector2 refPos, {bool useNearest = false}) {
    final enemies = game.targetableEnemies;
    if (enemies.isEmpty) return;

    Enemy? best;
    if (useNearest) {
      double minDist2 = double.infinity;
      for (final e in enemies) {
        final d2 = (e.position - refPos).length2;
        if (d2 < minDist2) {
          minDist2 = d2;
          best = e;
        }
      }
    } else {
      double maxDist2 = -1;
      for (final e in enemies) {
        final d2 = (e.position - refPos).length2;
        if (d2 < _attackRange * _attackRange && d2 > maxDist2) {
          maxDist2 = d2;
          best = e;
        }
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

    // Smoothly blend toward pointing North (idle).
    const restAngle = -math.pi / 2;
    final wobble = 0.08 * math.sin(_totalTime * 1.6 + orbitIndex);
    angle = _lerpAngle(angle, restAngle + wobble, 1 - math.exp(-6 * dt));
  }

  // --- Strike phases -------------------------------------------------------

  void _enterWindup({bool isChain = false}) {
    _phase = _StrikePhase.windup;
    _phaseTimer = 0;
    // Chain strikes are faster since the blade is already in 'attack mode'.
    _phaseDuration = isChain ? _windupDuration * 0.6 : _windupDuration;
    _windupAnchor = position.clone();
    _startAngle = angle;
    _trail.clear();
    game.audio.playSkillCast();
  }

  void _tickWindup(double dt) {
    final t = _target;
    if (t == null) {
      _phase = _StrikePhase.idle;
      return;
    }
    _phaseTimer += dt;
    final p = (_phaseTimer / _phaseDuration).clamp(0.0, 1.0);

    final toTarget = t.position - _windupAnchor;
    final dir = toTarget.normalized();

    // Pull back slightly like a coiled spring, then face the target.
    final pullBack = 6.0 * Curves.easeInOutCubic.transform(p);
    position = _windupAnchor - dir * pullBack;

    if (toTarget.length2 > 0) {
      final targetAngle = math.atan2(toTarget.y, toTarget.x);
      // Subtle "readying" tilt.
      final tilt = 0.25 * math.sin(p * math.pi);

      // Smoothly rotate from the angle we had when we entered windup
      // to the angle needed to face the target.
      angle = _lerpAngle(_startAngle, targetAngle + tilt, p);
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

    // Aggressive waypoint logic: find the closest enemy that is NOT the target.
    Enemy? waypoint;
    double minWayDist2 = double.infinity;
    for (final e in game.targetableEnemies) {
      if (e == t) continue;
      final d2 = (e.position - _dashStart).length2;
      if (d2 < minWayDist2) {
        minWayDist2 = d2;
        waypoint = e;
      }
    }

    final entryAnchor = t.position - approachDir * 36;
    final chord = entryAnchor - _dashStart;
    final chordLen = chord.length;

    if (waypoint != null) {
      // Pull P1 aggressively through/past the waypoint.
      final toWaypoint = waypoint.position - _dashStart;
      final dist = toWaypoint.length;
      if (dist > 0) {
        final dir = toWaypoint / dist;
        // Pushing P1 ~80% past the waypoint (capped at 100px) pulls the curve
        // belly much closer to the enemy.
        final pullDist = dist + math.min(dist * 0.8, 100.0);
        _dashControl1 = _dashStart + dir * pullDist;
      } else {
        _dashControl1 = _dashStart;
      }
      _dashControl2 = entryAnchor;
    } else {
      // Fallback to original swooping logic if no secondary targets exist.
      final chordDir = chordLen > 0 ? chord / chordLen : Vector2(1, 0);
      final chordNormal = Vector2(-chordDir.y, chordDir.x);
      final dot = approachDir.dot(chordNormal);
      final swingSide = dot > 0 ? -1.0 : 1.0;
      final swingDist = math.max(28.0, chordLen * 0.45);

      _dashControl1 =
          _dashStart + chord * 0.35 + chordNormal * (swingDist * swingSide);
      _dashControl2 = entryAnchor;
    }

    _phase = _StrikePhase.dashing;
    _phaseTimer = 0;
    // Recalculate duration based on the actual control point distance.
    final approxArcLen = (_dashControl1 - _dashStart).length +
        (_dashControl2 - _dashControl1).length +
        (_dashEnd - _dashControl2).length;

    final dashEvo = game.state.getEvolution(SkillArchetype.sentinel);
    double actualSpeed = _dashSpeedRef;
    if (dashEvo == 2) actualSpeed *= 2.0;

    _phaseDuration = math.max(
      0.08,
      math.min(0.65, approxArcLen / actualSpeed),
    );
    _dashProgress = 0;
    _hitThisDash.clear();
  }

  void _tickDash(double dt) {
    _phaseTimer += dt;
    final p = (_phaseTimer / _phaseDuration).clamp(0.0, 1.0);
    // Smooth acceleration into the slice. No slowing down at the end;
    // the dash momentum carries straight into the return arc.
    final eased = Curves.easeInSine.transform(p);
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
      final targetA = math.atan2(motion.y, motion.x);
      // We still follow the path direction, but with a tiny bit of
      // damping to prevent micro-jitters in the Bezier math.
      angle = _lerpAngle(angle, targetA, 1 - math.exp(-25 * dt));
    }

    // Multi-hit: damage every alive enemy whose body the curve sweeps
    // through, once per strike. We do not re-target — just hit whatever
    // happens to lie along the slice path.
    const hitRadius = 16.0;
    const hitRadius2 = hitRadius * hitRadius;
    for (final e in game.targetableEnemies) {
      if (_hitThisDash.contains(e)) continue;
      if ((e.position - position).length2 < hitRadius2) {
        _applySliceDamage(motion, e);
        _hitThisDash.add(e);
      }
    }
    if (p >= 1.0) {
      final dir = motion.length2 > 0 ? motion.normalized() : Vector2(1, 0);

      // Look for a new target to continue the chain.
      // We prioritize targets roughly in front of the blade to avoid 180-degree snaps.
      _findTargetDirectional(position, dir);

      if (_target != null) {
        // Continue the sweep with a shorter windup.
        _enterWindup(isChain: true);
      } else {
        _enterReturn(dir);
      }
    }
  }

  void _findTargetDirectional(Vector2 refPos, Vector2 currentDir) {
    final enemies = game.targetableEnemies;
    if (enemies.isEmpty) {
      _target = null;
      return;
    }

    Enemy? best;
    double bestScore = -double.infinity;

    for (final e in enemies) {
      final toEnemy = e.position - refPos;
      final dist2 = toEnemy.length2;
      if (dist2 > 300 * 300) continue; // Range limit for chain logic

      final dirToEnemy = toEnemy.normalized();
      final alignment = currentDir.dot(
        dirToEnemy,
      ); // 1.0 = same dir, -1.0 = opposite

      // Score: high alignment (forward) and low distance.
      // We penalize targets behind the blade heavily.
      if (alignment < -0.2) continue;

      final score = alignment * 1000 - math.sqrt(dist2);
      if (score > bestScore) {
        bestScore = score;
        best = e;
      }
    }
    _target = best;
  }

  void _applySliceDamage(Vector2 motion, Enemy t) {
    t.takeDamage(
      game.state.sentinelDamage,
      source: position,
      type: DamageType.sentinel,
    );

    if (!HitSparkEffect.atCap && game.canSpawnMinorEffect(lowPriority: true)) {
      parent?.add(
        HitSparkEffect(
          effectCenter: t.position.clone(),
          direction: (position - t.position).normalized(),
          color: const Color(0xFF00B0FF),
          count: 12,
        ),
      );
    }

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
      final world = parent;
      if (world != null) {
        for (final st in _nearestShardTargets(t)) {
          if (!SentinelShard.reserveSpawn()) break;
          world.add(
            SentinelShard(
              startPos: position.clone(),
              target: st,
              damage: game.state.sentinelDamage * 0.4,
            ),
          );
        }
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
    if (game.state.hasSentinelBarrageSynergy) {
      _attackTimer /= (1 + game.state.barrageLevel * 0.06);
    }
  }

  List<Enemy> _nearestShardTargets(Enemy primary) {
    final selected = <Enemy>[];
    final distances = <double>[];
    for (final enemy in game.targetableEnemies) {
      if (enemy == primary) continue;
      final distance = (enemy.position - position).length2;
      var insertAt = 0;
      while (insertAt < distances.length && distances[insertAt] <= distance) {
        insertAt++;
      }
      if (insertAt >= 3) continue;
      selected.insert(insertAt, enemy);
      distances.insert(insertAt, distance);
      if (selected.length > 3) {
        selected.removeLast();
        distances.removeLast();
      }
    }
    return selected;
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
    _returnStart = position.clone();

    // Continue forward briefly so the slice exit eases into the return arc,
    // then perpendicular swing curves the path back to the formation slot.
    final heroPos = game.hero.position;
    final slot = _formationSlot(heroPos);
    final toSlot = slot - _returnStart;
    final toSlotLen = toSlot.length;

    final straight = toSlotLen > 0 ? toSlot / toSlotLen : Vector2(-1, 0);
    final normal = Vector2(-straight.y, straight.x);
    final side = (orbitIndex.isEven) ? -1.0 : 1.0;
    final swing = math.max(40.0, toSlotLen * 0.45);

    final continueDir = motionDir.length2 > 0
        ? motionDir.normalized()
        : straight;
    _returnControl = _returnStart + continueDir * 28 + normal * (swing * side);

    // Dynamic duration ensures the return flight feels consistent with the dash speed.
    final approxReturnLen = toSlotLen + swing * 0.6;
    _phaseDuration = math.max(0.22, approxReturnLen / (_dashSpeedRef * 0.8));
  }

  void _tickReturn(Vector2 heroPos, double dt) {
    _phaseTimer += dt;
    final p = (_phaseTimer / _phaseDuration).clamp(0.0, 1.0);
    // Start at high velocity (continuation of dash) and ease back into the slot.
    final eased = Curves.easeOutSine.transform(p);

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
      angle = _lerpAngle(
        flightAngle,
        restAngle,
        Curves.easeInCubic.transform(p),
      );
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
    final tip = length * 0.52;
    final shoulder = length * 0.28;
    final base = -length * 0.22;
    final half = width * 0.5;

    // Classic Jian shape: defined shoulders and a slender waist.
    return Path()
      ..moveTo(tip, 0)
      ..lineTo(shoulder, -half) // Taper from tip to shoulder
      ..lineTo(base, -half * 0.75) // Gentle waist taper to base
      ..lineTo(base - 3, 0) // Elegant rounded base point
      ..lineTo(base, half * 0.75)
      ..lineTo(shoulder, half)
      ..close();
  }

  void _drawSword(Canvas canvas, double size, Paint bladePaint) {
    // Celestial Jian: balanced, slender, and noble.
    final bladeLength = size * 2.2;
    final bladeWidth = size * 0.20; // More defined than the needle
    final bladePath = _swordBladePath(bladeLength, bladeWidth);

    // Subtle outer shimmer (ethereal edge)
    final shimmerPaint = Paint()
      ..color = const Color(0xFFB2EBF2).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.save();
    canvas.scale(1.18, 1.28);
    canvas.drawPath(bladePath, shimmerPaint);
    canvas.restore();

    // Main blade body
    canvas.drawPath(bladePath, bladePaint);

    // Integrated Spirit Core (soft central light)
    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    final corePath = _swordBladePath(bladeLength * 0.8, bladeWidth * 0.4);
    canvas.drawPath(corePath, corePaint);

    // Central Ridge / Spirit Spine
    final spinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(-bladeLength * 0.15, 0),
      Offset(bladeLength * 0.42, 0),
      spinePaint,
    );

    // Ornament: Minimalist Guard (spirit line)
    final guardPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // A tiny horizontal line to suggest a guard without adding bulk
    canvas.drawLine(
      Offset(-bladeLength * 0.12, -bladeWidth * 0.58),
      Offset(-bladeLength * 0.12, bladeWidth * 0.58),
      guardPaint,
    );
  }

  void _renderRibbon(
    Canvas canvas,
    double headHalfWidth,
    Color startColor,
    Color endColor, {
    double widthPulse = 0,
    double opacityMultiplier = 1.0,
  }) {
    if (_trail.length < 2) return;

    final n = _trail.length;
    final vertices = <Offset>[];
    final colors = <Color>[];

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

      // Smoother taper for the tail
      final progress = i / (n - 1);
      final taper = Curves.easeOutQuad.transform(1.0 - progress);

      // Subtle living wave
      final wave = widthPulse > 0
          ? math.sin(progress * 12 - _totalTime * 18) * widthPulse
          : 0.0;
      final hw = (headHalfWidth + wave) * taper;

      // Color fades along the length.
      final color = Color.lerp(
        startColor,
        endColor,
        progress,
      )!.withValues(alpha: startColor.a * (1.0 - progress) * opacityMultiplier);

      // Add two vertices (left and right) for each point in the trail.
      // We are rendering in world space, so we use the coordinates directly.
      final lx = p.x + normal.x * hw;
      final ly = p.y + normal.y * hw;
      final rx = p.x - normal.x * hw;
      final ry = p.y - normal.y * hw;

      vertices.add(Offset(lx, ly));
      vertices.add(Offset(rx, ry));
      colors.add(color);
      colors.add(color);
    }

    if (vertices.length < 4) return;

    // Use drawVertices with a Triangle Strip for smooth gradients.
    final ribbonVertices = ui.Vertices(
      ui.VertexMode.triangleStrip,
      vertices,
      colors: colors,
    );

    canvas.drawVertices(ribbonVertices, BlendMode.srcOver, Paint());
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Motion ribbon (only present during strike phases).
    // The trail points are in world space, so we temporarily undo the component's
    // internal translation/rotation/scale to draw it correctly.
    canvas.save();
    final m = transform.transformMatrix.clone();
    m.invert();
    canvas.transform(Float64List.fromList(m.storage));

    // Pass 1: Outer Glow (Wide & Faint)
    _renderRibbon(
      canvas,
      10.0,
      const Color(0xFF00E5FF).withValues(alpha: 0.15),
      const Color(0xFFB2EBF2).withValues(alpha: 0.0),
      widthPulse: 1.5,
    );

    // Pass 2: Main Energy Ribbon
    _renderRibbon(
      canvas,
      5.5,
      const Color(0xFF00E5FF).withValues(alpha: 0.55),
      const Color(0xFFB2EBF2).withValues(alpha: 0.0),
      widthPulse: 0.8,
    );

    // Pass 3: Inner Sharp Core
    _renderRibbon(
      canvas,
      1.8,
      Colors.white.withValues(alpha: 0.85),
      const Color(0xFF00E5FF).withValues(alpha: 0.0),
    );

    // Render Stardust
    final stardustPaint = Paint()..style = PaintingStyle.fill;
    for (final s in _stardust) {
      final t = (s.age / s.life).clamp(0.0, 1.0);
      final alpha = 1.0 - Curves.easeIn.transform(t);
      stardustPaint.color = Colors.white.withValues(alpha: alpha * 0.8);
      canvas.drawCircle(
        Offset(s.position.x, s.position.y),
        s.size * (1.0 - t * 0.5),
        stardustPaint,
      );
    }

    canvas.restore();

    canvas.save();

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
        final shadowBlade = Paint()
          ..color = const Color(0xFFE1F5FE).withValues(alpha: 0.4)
          ..style = PaintingStyle.fill;
        _drawSword(canvas, sizeBase, shadowBlade);
      } else {
        _drawSword(canvas, sizeBase, _bladePaint);
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

class SentinelShard extends PositionComponent
    with HasGameReference<ZenithZeroGame> {
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
  static int _reservedOrAliveCount = 0;
  static const int _maxAlive = 36;

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

class _Stardust {
  Vector2 position;
  Vector2 velocity;
  double life;
  double age = 0;
  double size;
  _Stardust({
    required this.position,
    required this.velocity,
    required this.life,
    required this.size,
  });
}
