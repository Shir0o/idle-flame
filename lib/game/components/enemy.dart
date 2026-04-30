import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../idle_game.dart';
import 'combat_effects.dart';
import 'damage_text.dart';

enum DamageType { basic, nova, firewall, meteor }

class Enemy extends RectangleComponent with HasGameReference<IdleGame> {
  Enemy({required Vector2 position, required this.maxHp})
    : hp = maxHp,
      super(
        position: position,
        size: Vector2(84, 84),
        anchor: Anchor.center,
        paint: Paint()..color = _baseColor,
      );

  final double maxHp;
  double hp;
  Sprite? _sprite;
  List<Sprite> _walkFrames = const [];
  double _animationTimer = 0;
  int _animationFrame = 0;
  double _flashTimer = 0;
  double _hitPopTimer = 0;
  double _breachTimer = 0;
  Vector2 _knockbackVelocity = Vector2.zero();
  bool _dying = false;
  bool get isAlive => !_dying;

  static const double _speed = 60;
  static const double _stopRadius = 70;
  static const double _breachInterval = 1;
  static const Color _baseColor = Color(0xFFFF2D95);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      _sprite = await game.loadSprite('characters/cyber_grunt/south.png');
      _walkFrames = await Future.wait([
        for (var i = 0; i < 6; i++)
          game.loadSprite(
            'characters/cyber_grunt/walk_south/frame_${i.toString().padLeft(3, '0')}.png',
          ),
      ]);
    } catch (_) {
      _sprite = null;
      _walkFrames = const [];
    }
  }

  @override
  void render(Canvas canvas) {
    final sprite = _currentSprite;
    if (sprite == null) {
      super.render(canvas);
      return;
    }
    sprite.render(
      canvas,
      size: size,
      overridePaint: _flashTimer > 0 ? paint : null,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _advanceAnimation(dt);
    if (_flashTimer > 0) {
      _flashTimer -= dt;
      if (_flashTimer <= 0) paint.color = _baseColor;
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

  Sprite? get _currentSprite {
    if (_walkFrames.isEmpty) return _sprite;
    return _walkFrames[_animationFrame % _walkFrames.length];
  }

  void _advanceAnimation(double dt) {
    if (_walkFrames.length <= 1 || _dying) return;
    if (game.state.hasPendingLevelUp || game.state.isRunOver) return;
    _animationTimer += dt;
    while (_animationTimer >= 0.12) {
      _animationTimer -= 0.12;
      _animationFrame = (_animationFrame + 1) % _walkFrames.length;
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
      parent?.add(RuptureMarkEffect(effectCenter: position.clone()));
    }
    paint.color = visual.flashColor;
    _flashTimer = visual.flashDuration;
    if (hp <= 0) _die();
  }

  void _die() {
    _dying = true;
    game.audio.playEnemyDeath();
    if (game.state.bountyLevel > 0) {
      parent?.add(CoinBurstEffect(effectCenter: position.clone()));
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
