import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../audio/game_audio.dart';
import '../zenith_zero_game.dart';
import 'combat_effects.dart';
import 'damage_text.dart';

enum DamageType { basic, nova, firewall, meteor, sentinel, mothership }

enum EnemyType { basic, fast, tank, elite }

class Enemy extends PositionComponent with HasGameReference<ZenithZeroGame> {
  Enemy({
    required Vector2 position,
    required double baseMaxHp,
    this.type = EnemyType.basic,
  }) : maxHp = baseMaxHp * _typeData[type]!.hpMult,
       hp = baseMaxHp * _typeData[type]!.hpMult,
       super(
         position: position,
         size: _typeData[type]!.size,
         anchor: Anchor.center,
       );

  final EnemyType type;
  final double maxHp;
  double hp;
  late Color _color = _typeData[type]!.baseColor;
  late final Paint _fillPaint = Paint()..color = _typeData[type]!.baseColor;
  late final Paint _strokePaint = Paint()
    ..color = _typeData[type]!.outlineColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;
  late final Paint _detailPaint = Paint()
    ..color = _typeData[type]!.outlineColor.withValues(alpha: 0.72)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  late final Paint _glowPaint = Paint()
    ..color = _typeData[type]!.baseColor.withValues(alpha: 0.2)
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);

  double _flashTimer = 0;
  double _hitPopTimer = 0;
  double _breachTimer = 0;
  double _walkPhase = 0;
  Vector2 _knockbackVelocity = Vector2.zero();
  bool _dying = false;
  bool _lastDamageWasExecute = false;
  bool get isAlive => !_dying;

  static const double _stopRadius = 50;
  static const double _breachInterval = 1.0;

  static final Map<EnemyType, _EnemyTypeData> _typeData = {
    EnemyType.basic: _EnemyTypeData(
      baseColor: const Color(0xFFFF2D95),
      outlineColor: const Color(0xFFFFB3DC),
      speed: 60,
      hpMult: 1.0,
      size: Vector2(64, 64),
    ),
    EnemyType.fast: _EnemyTypeData(
      baseColor: const Color(0xFF00E5FF),
      outlineColor: const Color(0xFFB2F7FF),
      speed: 100,
      hpMult: 0.6,
      size: Vector2(48, 48),
    ),
    EnemyType.tank: _EnemyTypeData(
      baseColor: const Color(0xFF7C4DFF),
      outlineColor: const Color(0xFFD1C4E9),
      speed: 40,
      hpMult: 2.8,
      size: Vector2(80, 80),
    ),
    EnemyType.elite: _EnemyTypeData(
      baseColor: const Color(0xFFFFD166),
      outlineColor: const Color(0xFFFFF4D6),
      speed: 50,
      hpMult: 6.0,
      size: Vector2(96, 96),
    ),
  };

  @override
  void onMount() {
    super.onMount();
    game.activeEnemies.add(this);
  }

  @override
  void onRemove() {
    game.activeEnemies.remove(this);
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final w = size.x;
    final h = size.y;
    final cx = w / 2;
    final cy = h / 2;
    final bob = math.sin(_walkPhase * 7.2) * 2.4;

    final path = _getPathForType(type, w, h, cx, cy, bob);

    _fillPaint.color = _color;
    _glowPaint.color = _color.withValues(
      alpha: type == EnemyType.elite ? 0.3 : 0.18,
    );
    canvas.drawPath(path, _fillPaint);
    canvas.drawPath(path, _glowPaint);
    canvas.drawPath(path, _fillPaint);
    canvas.drawPath(path, _strokePaint);
    _drawDetailsForType(canvas, type, w, h, cx, cy, bob);
  }

  Path _getPathForType(
    EnemyType type,
    double w,
    double h,
    double cx,
    double cy,
    double bob,
  ) {
    switch (type) {
      case EnemyType.basic:
        return Path()
          ..moveTo(cx, h * 0.08 + bob)
          ..lineTo(w * 0.78, h * 0.34 + bob)
          ..lineTo(w * 0.92, h * 0.58 + bob)
          ..lineTo(w * 0.58, h * 0.52 + bob)
          ..lineTo(cx, h * 0.9 + bob)
          ..lineTo(w * 0.42, h * 0.52 + bob)
          ..lineTo(w * 0.08, h * 0.58 + bob)
          ..lineTo(w * 0.22, h * 0.34 + bob)
          ..close();
      case EnemyType.fast:
        return Path()
          ..moveTo(cx, h * 0.02 + bob)
          ..lineTo(w * 0.62, h * 0.54 + bob)
          ..lineTo(w * 0.96, h * 0.92 + bob)
          ..lineTo(cx, h * 0.72 + bob)
          ..lineTo(w * 0.04, h * 0.92 + bob)
          ..lineTo(w * 0.38, h * 0.54 + bob)
          ..close();
      case EnemyType.tank:
        return Path()
          ..moveTo(w * 0.24, h * 0.1 + bob)
          ..lineTo(w * 0.76, h * 0.1 + bob)
          ..lineTo(w * 0.94, h * 0.3 + bob)
          ..lineTo(w * 0.94, h * 0.72 + bob)
          ..lineTo(w * 0.72, h * 0.92 + bob)
          ..lineTo(w * 0.28, h * 0.92 + bob)
          ..lineTo(w * 0.06, h * 0.72 + bob)
          ..lineTo(w * 0.06, h * 0.3 + bob)
          ..close();
      case EnemyType.elite:
        return Path()
          ..moveTo(cx, h * 0.02 + bob)
          ..lineTo(w * 0.62, h * 0.16 + bob)
          ..lineTo(w * 0.86, h * 0.14 + bob)
          ..lineTo(w * 0.78, h * 0.38 + bob)
          ..lineTo(w * 0.96, h * 0.56 + bob)
          ..lineTo(w * 0.72, h * 0.86 + bob)
          ..lineTo(cx, h * 0.98 + bob)
          ..lineTo(w * 0.28, h * 0.86 + bob)
          ..lineTo(w * 0.04, h * 0.56 + bob)
          ..lineTo(w * 0.22, h * 0.38 + bob)
          ..lineTo(w * 0.14, h * 0.14 + bob)
          ..lineTo(w * 0.38, h * 0.16 + bob)
          ..close();
    }
  }

  void _drawDetailsForType(
    Canvas canvas,
    EnemyType type,
    double w,
    double h,
    double cx,
    double cy,
    double bob,
  ) {
    final corePaint = Paint()
      ..color = _typeData[type]!.outlineColor.withValues(alpha: 0.86)
      ..style = PaintingStyle.fill;
    final darkCutPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    switch (type) {
      case EnemyType.basic:
        canvas.drawLine(
          Offset(cx, h * 0.18 + bob),
          Offset(cx, h * 0.78 + bob),
          _detailPaint,
        );
        canvas.drawLine(
          Offset(w * 0.28, h * 0.42 + bob),
          Offset(w * 0.72, h * 0.42 + bob),
          darkCutPaint,
        );
        canvas.drawCircle(Offset(cx, cy + bob), w * 0.08, corePaint);
        break;
      case EnemyType.fast:
        canvas.drawLine(
          Offset(cx, h * 0.14 + bob),
          Offset(cx, h * 0.7 + bob),
          _detailPaint,
        );
        canvas.drawLine(
          Offset(w * 0.22, h * 0.82 + bob),
          Offset(w * 0.42, h * 0.58 + bob),
          darkCutPaint,
        );
        canvas.drawLine(
          Offset(w * 0.78, h * 0.82 + bob),
          Offset(w * 0.58, h * 0.58 + bob),
          darkCutPaint,
        );
        canvas.drawCircle(Offset(cx, h * 0.2 + bob), w * 0.06, corePaint);
        break;
      case EnemyType.tank:
        final plate = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, cy + bob),
            width: w * 0.5,
            height: h * 0.42,
          ),
          const Radius.circular(4),
        );
        canvas.drawRRect(
          plate,
          Paint()
            ..color = Colors.black.withValues(alpha: 0.2)
            ..style = PaintingStyle.fill,
        );
        canvas.drawRRect(plate, _detailPaint);
        canvas.drawLine(
          Offset(w * 0.16, h * 0.32 + bob),
          Offset(w * 0.84, h * 0.32 + bob),
          darkCutPaint,
        );
        canvas.drawLine(
          Offset(w * 0.16, h * 0.7 + bob),
          Offset(w * 0.84, h * 0.7 + bob),
          darkCutPaint,
        );
        canvas.drawCircle(Offset(cx, cy + bob), w * 0.08, corePaint);
        break;
      case EnemyType.elite:
        final crown = Path()
          ..moveTo(w * 0.28, h * 0.24 + bob)
          ..lineTo(cx, h * 0.08 + bob)
          ..lineTo(w * 0.72, h * 0.24 + bob);
        canvas.drawPath(crown, _detailPaint);
        canvas.drawLine(
          Offset(cx, h * 0.24 + bob),
          Offset(cx, h * 0.82 + bob),
          _detailPaint,
        );
        canvas.drawLine(
          Offset(w * 0.25, h * 0.48 + bob),
          Offset(w * 0.75, h * 0.48 + bob),
          darkCutPaint,
        );
        canvas.drawCircle(Offset(cx, cy + bob), w * 0.12, corePaint);
        canvas.drawCircle(
          Offset(cx, cy + bob),
          w * 0.19,
          Paint()
            ..color = _typeData[type]!.outlineColor.withValues(alpha: 0.34)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
        break;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_flashTimer > 0) {
      _flashTimer -= dt;
      if (_flashTimer <= 0) _color = _typeData[type]!.baseColor;
    }
    if (_hitPopTimer > 0 && !_dying) {
      _hitPopTimer -= dt;
      final t = (_hitPopTimer / 0.16).clamp(0.0, 1.0);
      scale = Vector2.all(1 + Curves.easeOutBack.transform(t) * 0.16);
      if (_hitPopTimer <= 0) scale = Vector2.all(1);
    }
    if (_knockbackVelocity.length2 > 1 && !_dying) {
      position += _knockbackVelocity * dt;
      _knockbackVelocity *= math.pow(0.06, dt).toDouble();
    }
    if (game.state.hasPendingLevelUp || game.state.isRunOver) return;
    if (_dying) return;
    final hero = game.hero;
    final toHero = hero.position - position;
    final dist = toHero.length;
    if (dist > _stopRadius) {
      _walkPhase += dt;
      position +=
          toHero.normalized() *
          _typeData[type]!.speed *
          game.state.enemySpeedMultiplier *
          dt;
      _breachTimer = 0;
      return;
    }
    _breachTimer += dt;
    if (_breachTimer >= _breachInterval) {
      _breachTimer = 0;
      game.state.damageNexus(game.state.enemyBreachDamage);
      game.shakeCamera(intensity: 5, duration: 0.18);
      if (!HitSparkEffect.atCap && game.canSpawnMinorEffect()) {
        parent?.add(
          HitSparkEffect(
            effectCenter: game.hero.position.clone(),
            direction: Vector2(0, -1),
            color: const Color(0xFFFF5252),
            count: 10,
            spread: 2.2,
            speed: 130,
          ),
        );
      }
    }
  }

  void takeDamage(
    double amount, {
    Vector2? source,
    DamageType type = DamageType.basic,
  }) {
    if (_dying || game.state.isRunOver) return;
    final executeBonus = hp / maxHp <= 0.5
        ? game.state.executeDamageMultiplier
        : 1.0;
    final finalAmount = amount * executeBonus;
    final isExecute = executeBonus > 1;
    _lastDamageWasExecute = isExecute;
    final visual = _visualFor(type, isExecute);
    final incoming = source == null ? Vector2(0, -1) : position - source;
    final pushDirection = incoming.length2 == 0
        ? Vector2(0, -1)
        : incoming.normalized();
    _knockbackVelocity += pushDirection * visual.knockback;
    _hitPopTimer = 0.16;
    hp -= finalAmount;
    if (!DamageText.atCap && game.canSpawnDamageText()) {
      parent?.add(
        DamageText(
          position: position + Vector2(0, -size.y / 2),
          amount: finalAmount.round(),
          color: visual.textColor,
          scale: visual.textScale,
        ),
      );
    }
    if (!HitSparkEffect.atCap && game.canSpawnMinorEffect()) {
      parent?.add(
        HitSparkEffect(
          effectCenter: position.clone(),
          direction: pushDirection,
          color: visual.sparkColor,
          count: visual.sparkCount,
          spread: visual.sparkSpread,
          speed: visual.sparkSpeed,
        ),
      );
    }
    if (type == DamageType.basic) {
      game.audio.playHit();
    } else if (type == DamageType.sentinel || type == DamageType.mothership) {
      game.audio.playSkillDamage(SkillSound.arcane);
    } else {
      game.audio.playRandomSkillDamage();
    }
    if (isExecute && game.state.ruptureLevel > 0) {
      parent?.add(
        RuptureMarkEffect(
          effectCenter: position.clone(),
          level: game.state.ruptureLevel,
        ),
      );
    }
    _color = visual.flashColor;
    _flashTimer = visual.flashDuration;
    if (hp <= 0) _die();
  }

  Iterable<Enemy> _otherAliveEnemies() {
    return game.aliveEnemies.where((e) => e != this);
  }

  void _die() {
    _dying = true;
    game.audio.playEnemyDeath();
    if (game.state.bountyLevel > 0 && !game.effectsConstrained) {
      parent?.add(CoinBurstEffect(effectCenter: position.clone()));
    }
    final meta = game.state.meta;
    // Shatter: frost-slowed enemies explode for AoE on death
    if (meta.hasKeystone('shatter') && game.state.frostLevel > 0) {
      final blastRadiusSq = 110.0 * 110.0;
      final dmg = game.state.heroDamage * 0.8;
      if (game.canSpawnMajorEffect()) {
        parent?.add(
          NovaPulseEffect(
            effectCenter: position.clone(),
            radius: 110,
            level: game.state.flameNovaLevel,
          ),
        );
      }
      for (final other in _otherAliveEnemies()) {
        if ((other.position - position).length2 <= blastRadiusSq) {
          other.takeDamage(
            dmg,
            source: position.clone(),
            type: DamageType.nova,
          );
        }
      }
    }
    // Spread: execute kills propagate to nearest enemy
    if (meta.hasKeystone('spread') && _lastDamageWasExecute) {
      Enemy? nearest;
      double best = double.infinity;
      for (final other in _otherAliveEnemies()) {
        final d2 = (other.position - position).length2;
        if (d2 < best) {
          best = d2;
          nearest = other;
        }
      }
      if (nearest != null) {
        parent?.add(
          RuptureMarkEffect(
            effectCenter: nearest.position.clone(),
            level: game.state.ruptureLevel,
          ),
        );
        nearest.takeDamage(
          game.state.heroDamage * 1.5,
          source: position.clone(),
          type: DamageType.basic,
        );
      }
    }
    game.state.registerKill();
    if (game.canSpawnMajorEffect()) {
      parent?.add(DeathBurstEffect(effectCenter: position.clone()));
    }
    add(
      ScaleEffect.to(
        Vector2.zero(),
        EffectController(duration: 0.18, curve: Curves.easeIn),
        onComplete: removeFromParent,
      ),
    );
  }

  _DamageVisual _visualFor(DamageType type, bool isExecute) {
    if (isExecute) {
      return const _DamageVisual(
        textColor: Color(0xFFFF6B35),
        sparkColor: Color(0xFFFF2D2D),
        flashColor: Color(0xFFFFF1E8),
        textScale: 1.2,
        flashDuration: 0.1,
        knockback: 58,
        sparkCount: 12,
        sparkSpread: 1.35,
        sparkSpeed: 180,
      );
    }
    return switch (type) {
      DamageType.basic => const _DamageVisual(
        textColor: Color(0xFFFFEB3B),
        sparkColor: Color(0xFF00E5FF),
        flashColor: Colors.white,
        textScale: 1,
        flashDuration: 0.08,
        knockback: 120,
        sparkCount: 7,
        sparkSpread: 0.95,
        sparkSpeed: 160,
      ),
      DamageType.sentinel => _DamageVisual(
        textColor: const Color(0xFFE1F5FE),
        sparkColor: const Color(0xFF00B0FF),
        flashColor: Colors.white,
        textScale: 1.05,
        flashDuration: 0.1,
        // Level 4 Special: Increased impact force
        knockback: game.state.sentinelLevel >= 4 ? 240.0 : 150.0,
        sparkCount: 10,
        sparkSpread: 1.2,
        sparkSpeed: 180,
      ),
      DamageType.nova => const _DamageVisual(
        textColor: Color(0xFFFF77C8),
        sparkColor: Color(0xFFFF2D95),
        flashColor: Color(0xFFFFD8F0),
        textScale: 1.08,
        flashDuration: 0.1,
        knockback: 52,
        sparkCount: 11,
        sparkSpread: 2.6,
        sparkSpeed: 150,
      ),
      DamageType.firewall => const _DamageVisual(
        textColor: Color(0xFFFFD166),
        sparkColor: Color(0xFFFF8A00),
        flashColor: Color(0xFFFFF4D6),
        textScale: 0.96,
        flashDuration: 0.07,
        knockback: 24,
        sparkCount: 8,
        sparkSpread: 1.8,
        sparkSpeed: 125,
      ),
      DamageType.meteor => const _DamageVisual(
        textColor: Color(0xFFD8C7FF),
        sparkColor: Color(0xFF7C4DFF),
        flashColor: Color(0xFFF0EBFF),
        textScale: 1.28,
        flashDuration: 0.12,
        knockback: 76,
        sparkCount: 15,
        sparkSpread: 3.4,
        sparkSpeed: 210,
      ),
      DamageType.mothership => const _DamageVisual(
        textColor: Color(0xFFCE93D8),
        sparkColor: Color(0xFFCE93D8),
        flashColor: Colors.white,
        textScale: 1.12,
        flashDuration: 0.08,
        knockback: 120,
        sparkCount: 12,
        sparkSpread: 1.4,
        sparkSpeed: 190,
      ),
    };
  }
}

class _DamageVisual {
  const _DamageVisual({
    required this.textColor,
    required this.sparkColor,
    required this.flashColor,
    required this.textScale,
    required this.flashDuration,
    required this.knockback,
    required this.sparkCount,
    required this.sparkSpread,
    required this.sparkSpeed,
  });

  final Color textColor;
  final Color sparkColor;
  final Color flashColor;
  final double textScale;
  final double flashDuration;
  final double knockback;
  final int sparkCount;
  final double sparkSpread;
  final double sparkSpeed;
}

class _EnemyTypeData {
  const _EnemyTypeData({
    required this.baseColor,
    required this.outlineColor,
    required this.speed,
    required this.hpMult,
    required this.size,
  });

  final Color baseColor;
  final Color outlineColor;
  final double speed;
  final double hpMult;
  final Vector2 size;

  _EnemyTypeData copyWith({
    Color? baseColor,
    Color? outlineColor,
    double? speed,
    double? hpMult,
    Vector2? size,
  }) {
    return _EnemyTypeData(
      baseColor: baseColor ?? this.baseColor,
      outlineColor: outlineColor ?? this.outlineColor,
      speed: speed ?? this.speed,
      hpMult: hpMult ?? this.hpMult,
      size: size ?? this.size,
    );
  }
}
