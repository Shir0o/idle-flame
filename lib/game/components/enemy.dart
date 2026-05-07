import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../audio/game_audio.dart';
import '../zenith_zero_game.dart';
import 'combat_effects.dart';
import 'damage_text.dart';

enum DamageType { basic, nova, firewall, meteor, sentinel, mothership, rupture }

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
       ) {
    _bodyPath = _buildPathForType(type, size.x, size.y, size.x / 2, size.y / 2);
  }

  final EnemyType type;
  final double maxHp;
  double hp;
  late final Path _bodyPath;
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
  late final Paint _corePaint = Paint()
    ..color = _typeData[type]!.outlineColor.withValues(alpha: 0.86)
    ..style = PaintingStyle.fill;
  late final Paint _eliteRingPaint = Paint()
    ..color = _typeData[type]!.outlineColor.withValues(alpha: 0.34)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  double _flashTimer = 0;
  double _hitPopTimer = 0;
  double _breachTimer = 0;
  double _walkPhase = 0;
  double _burnTimer = 0;
  double _burnDps = 0;
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
      hpMult: 4.5,
      size: Vector2(96, 96),
    ),
  };

  static final Paint _darkCutPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.26)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  static final Paint _plateFillPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.2)
    ..style = PaintingStyle.fill;
  static final Paint _burnPaint = Paint()
    ..color = const Color(0xFFFF8A00).withValues(alpha: 0.4)
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

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

    _fillPaint.color = _color;
    _glowPaint.color = _color.withValues(
      alpha: type == EnemyType.elite ? 0.3 : 0.18,
    );
    canvas.save();
    canvas.translate(0, bob);

    if (_burnTimer > 0) {
      canvas.drawPath(_bodyPath, _burnPaint);
    }

    canvas.drawPath(_bodyPath, _fillPaint);
    canvas.drawPath(_bodyPath, _glowPaint);
    canvas.drawPath(_bodyPath, _fillPaint);
    canvas.drawPath(_bodyPath, _strokePaint);
    _drawDetailsForType(canvas, type, w, h, cx, cy);
    canvas.restore();
  }

  static Path _buildPathForType(
    EnemyType type,
    double w,
    double h,
    double cx,
    double cy,
  ) {
    switch (type) {
      case EnemyType.basic:
        return Path()
          ..moveTo(cx, h * 0.08)
          ..lineTo(w * 0.78, h * 0.34)
          ..lineTo(w * 0.92, h * 0.58)
          ..lineTo(w * 0.58, h * 0.52)
          ..lineTo(cx, h * 0.9)
          ..lineTo(w * 0.42, h * 0.52)
          ..lineTo(w * 0.08, h * 0.58)
          ..lineTo(w * 0.22, h * 0.34)
          ..close();
      case EnemyType.fast:
        return Path()
          ..moveTo(cx, h * 0.02)
          ..lineTo(w * 0.62, h * 0.54)
          ..lineTo(w * 0.96, h * 0.92)
          ..lineTo(cx, h * 0.72)
          ..lineTo(w * 0.04, h * 0.92)
          ..lineTo(w * 0.38, h * 0.54)
          ..close();
      case EnemyType.tank:
        return Path()
          ..moveTo(w * 0.24, h * 0.1)
          ..lineTo(w * 0.76, h * 0.1)
          ..lineTo(w * 0.94, h * 0.3)
          ..lineTo(w * 0.94, h * 0.72)
          ..lineTo(w * 0.72, h * 0.92)
          ..lineTo(w * 0.28, h * 0.92)
          ..lineTo(w * 0.06, h * 0.72)
          ..lineTo(w * 0.06, h * 0.3)
          ..close();
      case EnemyType.elite:
        return Path()
          ..moveTo(cx, h * 0.02)
          ..lineTo(w * 0.62, h * 0.16)
          ..lineTo(w * 0.86, h * 0.14)
          ..lineTo(w * 0.78, h * 0.38)
          ..lineTo(w * 0.96, h * 0.56)
          ..lineTo(w * 0.72, h * 0.86)
          ..lineTo(cx, h * 0.98)
          ..lineTo(w * 0.28, h * 0.86)
          ..lineTo(w * 0.04, h * 0.56)
          ..lineTo(w * 0.22, h * 0.38)
          ..lineTo(w * 0.14, h * 0.14)
          ..lineTo(w * 0.38, h * 0.16)
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
  ) {
    switch (type) {
      case EnemyType.basic:
        canvas.drawLine(
          Offset(cx, h * 0.18),
          Offset(cx, h * 0.78),
          _detailPaint,
        );
        canvas.drawLine(
          Offset(w * 0.28, h * 0.42),
          Offset(w * 0.72, h * 0.42),
          _darkCutPaint,
        );
        canvas.drawCircle(Offset(cx, cy), w * 0.08, _corePaint);
        break;
      case EnemyType.fast:
        canvas.drawLine(
          Offset(cx, h * 0.14),
          Offset(cx, h * 0.7),
          _detailPaint,
        );
        canvas.drawLine(
          Offset(w * 0.22, h * 0.82),
          Offset(w * 0.42, h * 0.58),
          _darkCutPaint,
        );
        canvas.drawLine(
          Offset(w * 0.78, h * 0.82),
          Offset(w * 0.58, h * 0.58),
          _darkCutPaint,
        );
        canvas.drawCircle(Offset(cx, h * 0.2), w * 0.06, _corePaint);
        break;
      case EnemyType.tank:
        final plate = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, cy),
            width: w * 0.5,
            height: h * 0.42,
          ),
          const Radius.circular(4),
        );
        canvas.drawRRect(plate, _plateFillPaint);
        canvas.drawRRect(plate, _detailPaint);
        canvas.drawLine(
          Offset(w * 0.16, h * 0.32),
          Offset(w * 0.84, h * 0.32),
          _darkCutPaint,
        );
        canvas.drawLine(
          Offset(w * 0.16, h * 0.7),
          Offset(w * 0.84, h * 0.7),
          _darkCutPaint,
        );
        canvas.drawCircle(Offset(cx, cy), w * 0.08, _corePaint);
        break;
      case EnemyType.elite:
        final crown = Path()
          ..moveTo(w * 0.28, h * 0.24)
          ..lineTo(cx, h * 0.08)
          ..lineTo(w * 0.72, h * 0.24);
        canvas.drawPath(crown, _detailPaint);
        canvas.drawLine(
          Offset(cx, h * 0.24),
          Offset(cx, h * 0.82),
          _detailPaint,
        );
        canvas.drawLine(
          Offset(w * 0.25, h * 0.48),
          Offset(w * 0.75, h * 0.48),
          _darkCutPaint,
        );
        canvas.drawCircle(Offset(cx, cy), w * 0.12, _corePaint);
        canvas.drawCircle(Offset(cx, cy), w * 0.19, _eliteRingPaint);
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

    if (_burnTimer > 0 && !_dying) {
      _burnTimer -= dt;
      hp -= _burnDps * dt;
      if (hp <= 0) {
        _die();
        return;
      }
    }

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

    if (type == DamageType.firewall && game.state.firewallLevel >= 3) {
      _applyBurn(
        duration: 3.0,
        dps: game.state.firewallBurnDps,
      );
    }

    final lowPriorityFeedback =
        type == DamageType.sentinel || type == DamageType.mothership;
    if (!DamageText.atCap &&
        game.canSpawnDamageText(lowPriority: lowPriorityFeedback)) {
      parent?.add(
        DamageText(
          position: position + Vector2(0, -size.y / 2),
          amount: finalAmount.round(),
          color: visual.textColor,
          scale: visual.textScale,
        ),
      );
    }
    if (!HitSparkEffect.atCap &&
        game.canSpawnMinorEffect(lowPriority: lowPriorityFeedback)) {
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
      if (game.canPlayBasicHitSound()) game.audio.playHit();
    } else if (type == DamageType.sentinel || type == DamageType.mothership) {
      if (game.canPlaySkillHitSound(lowPriority: true)) {
        game.audio.playSkillDamage(SkillSound.arcane);
      }
    } else {
      if (game.canPlaySkillHitSound()) game.audio.playRandomSkillDamage();
    }
    if (isExecute &&
        game.state.ruptureLevel > 0 &&
        game.canSpawnMinorEffect(lowPriority: lowPriorityFeedback)) {
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

  void _applyBurn({required double duration, required double dps}) {
    _burnTimer = math.max(_burnTimer, duration);
    _burnDps = math.max(_burnDps, dps);
  }

  Iterable<Enemy> _otherAliveEnemies() {
    return game.targetableEnemies.where((e) => e != this);
  }

  void _die() {
    _dying = true;
    game.state.registerKill();
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
        nearest.takeDamage(
          game.state.heroDamage * 1.5,
          source: position.clone(),
          type: DamageType.rupture,
        );
      }
    }
    removeFromParent();
  }

  _DamageVisual _visualFor(DamageType type, bool isExecute) {
    if (isExecute) {
      return const _DamageVisual(
        textColor: Color(0xFFFF5252),
        textScale: 1.4,
        sparkColor: Color(0xFFFF5252),
        sparkCount: 15,
        sparkSpread: 2.5,
        sparkSpeed: 180,
        flashColor: Colors.white,
        flashDuration: 0.15,
        knockback: 65,
      );
    }
    return switch (type) {
      DamageType.basic => const _DamageVisual(
        textColor: Colors.white,
        textScale: 1.0,
        sparkColor: Colors.white,
        sparkCount: 5,
        sparkSpread: 1.2,
        sparkSpeed: 100,
        flashColor: Color(0x60FFFFFF),
        flashDuration: 0.08,
        knockback: 15,
      ),
      DamageType.nova => const _DamageVisual(
        textColor: Color(0xFFFF2D95),
        textScale: 1.2,
        sparkColor: Color(0xFFFF2D95),
        sparkCount: 12,
        sparkSpread: 2.0,
        sparkSpeed: 140,
        flashColor: Color(0xFFFFB3DC),
        flashDuration: 0.12,
        knockback: 35,
      ),
      DamageType.firewall => const _DamageVisual(
        textColor: Color(0xFFFFD166),
        textScale: 1.1,
        sparkColor: Color(0xFFFFD166),
        sparkCount: 8,
        sparkSpread: 1.5,
        sparkSpeed: 120,
        flashColor: Color(0xFFFFF4D6),
        flashDuration: 0.1,
        knockback: 5,
      ),
      DamageType.meteor => const _DamageVisual(
        textColor: Color(0xFF7C4DFF),
        textScale: 1.5,
        sparkColor: Color(0xFF7C4DFF),
        sparkCount: 20,
        sparkSpread: 3.0,
        sparkSpeed: 220,
        flashColor: Color(0xFFD1C4E9),
        flashDuration: 0.2,
        knockback: 120,
      ),
      DamageType.sentinel => const _DamageVisual(
        textColor: Color(0xFFE1F5FE),
        textScale: 0.9,
        sparkColor: Color(0xFFE1F5FE),
        sparkCount: 4,
        sparkSpread: 1.0,
        sparkSpeed: 90,
        flashColor: Color(0x40E1F5FE),
        flashDuration: 0.05,
        knockback: 8,
      ),
      DamageType.mothership => const _DamageVisual(
        textColor: Color(0xFFCE93D8),
        textScale: 0.95,
        sparkColor: Color(0xFFCE93D8),
        sparkCount: 6,
        sparkSpread: 1.3,
        sparkSpeed: 110,
        flashColor: Color(0x40CE93D8),
        flashDuration: 0.06,
        knockback: 12,
      ),
      DamageType.rupture => const _DamageVisual(
        textColor: Color(0xFFFF5252),
        textScale: 1.3,
        sparkColor: Color(0xFFFF5252),
        sparkCount: 10,
        sparkSpread: 1.8,
        sparkSpeed: 150,
        flashColor: Color(0xFFFF8A80),
        flashDuration: 0.12,
        knockback: 45,
      ),
    };
  }
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
}

class _DamageVisual {
  const _DamageVisual({
    required this.textColor,
    required this.textScale,
    required this.sparkColor,
    required this.sparkCount,
    required this.sparkSpread,
    required this.sparkSpeed,
    required this.flashColor,
    required this.flashDuration,
    required this.knockback,
  });

  final Color textColor;
  final double textScale;
  final Color sparkColor;
  final int sparkCount;
  final double sparkSpread;
  final double sparkSpeed;
  final Color flashColor;
  final double flashDuration;
  final double knockback;
}
