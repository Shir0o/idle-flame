import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../idle_game.dart';
import 'combat_effects.dart';
import 'damage_text.dart';

enum DamageType { basic, nova, firewall, meteor }

class Enemy extends PositionComponent with HasGameReference<IdleGame> {
  Enemy({required Vector2 position, required this.maxHp})
    : hp = maxHp,
      super(position: position, size: Vector2(64, 64), anchor: Anchor.center);

  final double maxHp;
  double hp;
  Color _color = _baseColor;
  double _flashTimer = 0;
  double _hitPopTimer = 0;
  double _breachTimer = 0;
  double _walkPhase = 0;
  Vector2 _knockbackVelocity = Vector2.zero();
  bool _dying = false;
  bool _lastDamageWasExecute = false;
  bool get isAlive => !_dying;

  static const double _speed = 60;
  static const double _stopRadius = 50;
  static const double _breachInterval = 1.0;
  static const Color _baseColor = Color(0xFFFF2D95);
  static const Color _outlineColor = Color(0xFFFFB3DC);

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

    final path = Path()
      ..moveTo(cx, bob)
      ..lineTo(w, cy + bob)
      ..lineTo(cx, h + bob)
      ..lineTo(0, cy + bob)
      ..close();

    canvas.drawPath(path, Paint()..color = _color);
    canvas.drawPath(
      path,
      Paint()
        ..color = _outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_flashTimer > 0) {
      _flashTimer -= dt;
      if (_flashTimer <= 0) _color = _baseColor;
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
          toHero.normalized() * _speed * game.state.enemySpeedMultiplier * dt;
      _breachTimer = 0;
      return;
    }
    _breachTimer += dt;
    if (_breachTimer >= _breachInterval) {
      _breachTimer = 0;
      game.state.damageNexus(game.state.enemyBreachDamage);
      game.shakeCamera(intensity: 5, duration: 0.18);
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
    parent?.add(
      DamageText(
        position: position + Vector2(0, -size.y / 2),
        amount: finalAmount.round(),
        color: visual.textColor,
        scale: visual.textScale,
      ),
    );
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
    if (type == DamageType.basic) {
      game.audio.playHit();
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
    return game.activeEnemies.where((e) => e.isAlive && e != this);
  }

  void _die() {
    _dying = true;
    game.audio.playEnemyDeath();
    if (game.state.bountyLevel > 0) {
      parent?.add(CoinBurstEffect(effectCenter: position.clone()));
    }
    final meta = game.state.meta;
    // Shatter: frost-slowed enemies explode for AoE on death
    if (meta.hasKeystone('shatter') && game.state.frostLevel > 0) {
      final blastRadiusSq = 110.0 * 110.0;
      final dmg = game.state.heroDamage * 0.8;
      parent?.add(
        NovaPulseEffect(
          effectCenter: position.clone(),
          radius: 110,
          level: game.state.flameNovaLevel,
        ),
      );
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
    parent?.add(DeathBurstEffect(effectCenter: position.clone()));
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
