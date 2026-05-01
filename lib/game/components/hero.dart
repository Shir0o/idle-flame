import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../idle_game.dart';
import '../state/game_state.dart';
import '../state/mech_catalog.dart';
import 'combat_effects.dart';
import 'enemy.dart';
import 'sentinel_blade.dart';

class HeroComponent extends PositionComponent with HasGameReference<IdleGame> {
  HeroComponent({this.mechType = MechType.standard})
    : super(
        size: Vector2.all(mechDefinitionFor(mechType).spriteSize),
        anchor: Anchor.center,
      );

  MechType mechType;

  double _attackTimer = 0;
  double _novaTimer = 0;
  double _firewallTimer = 0;
  double _meteorTimer = 0;
  double _frostFieldTimer = 0;
  double _pulseTimer = 0;
  double _pulseDuration = 0.18;
  double _aftershockTimer = -1;
  double _backdraftTimer = -1;
  double _attackFlashTimer = 0;
  double _idlePhase = 0;
  int _twinShotCounter = 0;
  final math.Random _critRng = math.Random();
  final List<SentinelBlade> _sentinelBlades = [];

  void setMechType(MechType nextMechType) {
    if (mechType == nextMechType) return;
    mechType = nextMechType;
    size = Vector2.all(mechDefinitionFor(mechType).spriteSize);
    _placeAtBottom(game.size);
  }

  @override
  void onMount() {
    super.onMount();
    _placeAtBottom(game.size);
    parent?.add(HeroAuraEffect(effectCenter: position));
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _placeAtBottom(size);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final visual = mechDefinitionFor(mechType).visual;
    final w = size.x;
    final h = size.y;
    final cx = w / 2;
    final cy = h / 2;
    final attacking = _attackFlashTimer > 0;
    final bob = math.sin(_idlePhase * 2.4) * 1.2;

    _drawHeroShape(canvas, visual, cx, cy, w, h, bob, attacking);
  }

  void _drawHeroShape(
    Canvas canvas,
    MechVisual visual,
    double cx,
    double cy,
    double w,
    double h,
    double bob,
    bool attacking,
  ) {
    final center = Offset(cx, cy + bob);
    final radius = w * 0.15;
    final fill = attacking
        ? Color.lerp(visual.body, visual.accent, 0.35)!
        : visual.body;
    final outline = attacking ? Colors.white : visual.outline;

    final fillPaint = Paint()..color = fill;
    final outlinePaint = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = attacking ? 3 : 2;

    canvas.drawCircle(center, radius, fillPaint);
    canvas.drawCircle(center, radius, outlinePaint);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _idlePhase += dt;
    if (_attackFlashTimer > 0) _attackFlashTimer -= dt;

    if (_pulseTimer > 0) {
      _pulseTimer -= dt;
      final t = (_pulseTimer / _pulseDuration).clamp(0.0, 1.0);
      scale = Vector2.all(1 + Curves.easeOutBack.transform(t) * 0.1);
      if (_pulseTimer <= 0) scale = Vector2.all(1);
    }
    if (game.state.hasPendingLevelUp || game.state.isRunOver) return;

    _updateSentinelBlades();

    final period = 1.0 / game.state.heroAttacksPerSec;
    _attackTimer += dt;
    if (_attackTimer >= period) {
      _attackTimer = 0;
      _tryAttack();
    }
    _novaTimer += dt;
    if (game.state.flameNovaLevel > 0 &&
        _novaTimer >= GameState.flameNovaCooldown) {
      _novaTimer = 0;
      _castFlameNova();
    }
    _firewallTimer += dt;
    if (game.state.firewallLevel > 0 &&
        _firewallTimer >= GameState.firewallCooldown) {
      _firewallTimer = 0;
      _castFirewall();
    }
    _meteorTimer += dt;
    if (game.state.meteorMarkLevel > 0 &&
        _meteorTimer >= GameState.meteorMarkCooldown) {
      _meteorTimer = 0;
      _castMeteorMark();
    }
    if (_aftershockTimer > 0) {
      _aftershockTimer -= dt;
      if (_aftershockTimer <= 0) {
        _aftershockTimer = -1;
        _castFlameNova(damageScale: 0.5, isAftershock: true);
      }
    }
    if (_backdraftTimer > 0) {
      _backdraftTimer -= dt;
      if (_backdraftTimer <= 0) {
        _backdraftTimer = -1;
        _castFirewall(isBackdraft: true);
      }
    }
    _frostFieldTimer += dt;
    if (game.state.frostLevel > 0 && _frostFieldTimer >= 2.1) {
      _frostFieldTimer = 0;
      parent?.add(
        FrostFieldEffect(
          effectCenter: game.size / 2,
          fieldSize: Vector2(game.size.x, game.size.y),
          level: game.state.frostLevel,
        ),
      );
    }
  }

  void _updateSentinelBlades() {
    final targetCount = game.state.sentinelCount;
    while (_sentinelBlades.length < targetCount) {
      final blade = SentinelBlade(
        orbitIndex: _sentinelBlades.length,
        level: game.state.sentinelLevel,
      );
      blade.position = position.clone();
      _sentinelBlades.add(blade);
      parent?.add(blade);
    }
    while (_sentinelBlades.length > targetCount) {
      final blade = _sentinelBlades.removeLast();
      blade.removeFromParent();
    }
  }

  void resetForNewRun() {
    _attackTimer = 0;
    _novaTimer = 0;
    _firewallTimer = 0;
    _meteorTimer = 0;
    _frostFieldTimer = 0;
    _pulseTimer = 0;
    _pulseDuration = 0.18;
    _aftershockTimer = -1;
    _backdraftTimer = -1;
    _attackFlashTimer = 0;
    _twinShotCounter = 0;
    scale = Vector2.all(1);
    for (final blade in _sentinelBlades) {
      blade.removeFromParent();
    }
    _sentinelBlades.clear();
    _placeAtBottom(game.size);
  }

  void _tryAttack() {
    final targets = _enemiesInRange(game.state.heroAttackRange)
      ..sort((a, b) {
        final aDist = (a.position - position).length2;
        final bDist = (b.position - position).length2;
        return aDist.compareTo(bDist);
      });

    if (targets.isNotEmpty) {
      game.audio.playBasicAttack();
      _attackFlashTimer = 0.18;
    }

    final meta = game.state.meta;
    final critRoll = meta.hasKeystone('crit') && _critRng.nextDouble() < 0.08;
    final critMul = critRoll ? 3.0 : 1.0;
    final twinShot =
        meta.hasKeystone('twin_shot') && (++_twinShotCounter % 4 == 0);

    if (critRoll && targets.isNotEmpty) {
      game.shakeCamera(intensity: 5, duration: 0.12);
      // Small hit-stop effect
      _idlePhase -= 0.05;
    }

    for (var i = 0; i < targets.take(game.state.emberTargets).length; i++) {
      final enemy = targets[i];
      final focusLevel = game.state.focusLevel;
      final barrageLevel = game.state.barrageLevel;
      final slashColor = critRoll
          ? const Color(0xFFFF6B35)
          : (focusLevel > 0
                ? const Color(0xFFFFF176)
                : const Color(0xFF00E5FF));
      parent?.add(
        SlashArcEffect(
          from: position.clone(),
          to: enemy.position.clone(),
          color: slashColor,
          widthMultiplier: 1 + focusLevel * 0.04,
          level: game.state.chainLevel,
        ),
      );
      if (focusLevel > 0) {
        parent?.add(
          FocusStrikeEffect(
            from: position.clone(),
            to: enemy.position.clone(),
            level: focusLevel,
          ),
        );
      }
      enemy.takeDamage(
        game.state.heroDamage * critMul,
        source: position.clone(),
        type: DamageType.basic,
      );
      // Whiplash: primary target hit twice
      if (i == 0 && meta.hasKeystone('whiplash')) {
        enemy.takeDamage(
          game.state.heroDamage * critMul * 0.6,
          source: position.clone(),
          type: DamageType.basic,
        );
      }
      // Twin Shot: every 4th attack hits each target twice
      if (twinShot) {
        enemy.takeDamage(
          game.state.heroDamage * critMul,
          source: position.clone(),
          type: DamageType.basic,
        );
      }
      if (barrageLevel > 0) {
        parent?.add(
          BarrageStreakEffect(
            effectCenter: position.clone(),
            level: barrageLevel,
          ),
        );
      }
    }
    if (targets.isNotEmpty) _pulse(0.14);
  }

  void _castFlameNova({double damageScale = 1.0, bool isAftershock = false}) {
    if (!isAftershock) _pulse(0.2);
    game.audio.playSkillCast();
    game.shakeCamera(intensity: isAftershock ? 2 : 3.5, duration: 0.16);
    final radius = game.state.flameNovaRadius;
    final effectRadius = radius.isFinite ? radius : game.size.length;
    parent?.add(
      NovaPulseEffect(
        effectCenter: position.clone(),
        radius: effectRadius * (isAftershock ? 0.7 : 1.0),
        level: game.state.flameNovaLevel,
      ),
    );
    for (final enemy in _enemiesInRange(radius)) {
      enemy.takeDamage(
        game.state.flameNovaDamage * damageScale,
        source: position.clone(),
        type: DamageType.nova,
      );
    }
    if (!isAftershock && game.state.meta.hasKeystone('aftershock')) {
      _aftershockTimer = 0.5;
    }
  }

  void _castFirewall({bool isBackdraft = false}) {
    if (!isBackdraft) _pulse(0.16);
    game.audio.playSkillCast();
    final wallY = position.y - 165;
    final width = game.state.firewallWidth;
    final effectWidth = width.isFinite ? width : game.size.x;
    final halfWidth = effectWidth / 2;
    final wallCenter = Vector2(position.x, wallY);
    parent?.add(
      FirewallEffect(
        effectCenter: wallCenter,
        effectWidth: effectWidth,
        level: game.state.firewallLevel,
      ),
    );
    final enemies = _aliveEnemies().where((enemy) {
      final insideWidth = (enemy.position.x - position.x).abs() <= halfWidth;
      final nearWall = (enemy.position.y - wallY).abs() <= 28;
      return insideWidth && nearWall;
    });
    for (final enemy in enemies) {
      enemy.takeDamage(
        game.state.firewallDamage,
        source: wallCenter,
        type: DamageType.firewall,
      );
    }
    if (!isBackdraft && game.state.meta.hasKeystone('backdraft')) {
      _backdraftTimer = 0.4;
    }
  }

  void _castMeteorMark() {
    final enemies = _aliveEnemies();
    if (enemies.isEmpty) return;
    game.audio.playSkillCast();
    enemies.sort((a, b) => b.position.y.compareTo(a.position.y));
    final target = enemies.first;
    final radius = game.state.meteorMarkRadius;
    final blastRadius = radius.isFinite ? radius : game.size.length;
    final blastRadiusSquared = radius * radius;
    parent?.add(
      MeteorImpactEffect(
        target: target.position.clone(),
        radius: blastRadius,
        level: game.state.meteorMarkLevel,
      ),
    );
    _pulse(0.24);
    game.shakeCamera(intensity: 7, duration: 0.22);
    for (final enemy in enemies) {
      final inBlast =
          (enemy.position - target.position).length2 <= blastRadiusSquared;
      if (inBlast) {
        enemy.takeDamage(
          game.state.meteorMarkDamage,
          source: target.position.clone(),
          type: DamageType.meteor,
        );
      }
    }
    if (game.state.meta.hasKeystone('cluster')) {
      for (var i = 1; i <= 2; i++) {
        final delay = 0.18 * i;
        final offset = Vector2(
          (_critRng.nextDouble() - 0.5) * 80,
          (_critRng.nextDouble() - 0.5) * 80,
        );
        final clusterPos = target.position + offset;
        Future.delayed(Duration(milliseconds: (delay * 1000).round()), () {
          if (game.state.isRunOver) return;
          parent?.add(
            MeteorImpactEffect(
              target: clusterPos,
              radius: blastRadius * 0.6,
              level: game.state.meteorMarkLevel,
            ),
          );
          for (final enemy in _aliveEnemies()) {
            if ((enemy.position - clusterPos).length2 <=
                blastRadiusSquared * 0.36) {
              enemy.takeDamage(
                game.state.meteorMarkDamage * 0.5,
                source: clusterPos,
                type: DamageType.meteor,
              );
            }
          }
        });
      }
    }
  }

  List<Enemy> _enemiesInRange(double range) {
    final rangeSquared = range * range;
    return _aliveEnemies()
        .where((enemy) => (enemy.position - position).length2 <= rangeSquared)
        .toList();
  }

  List<Enemy> _aliveEnemies() {
    return game.aliveEnemies;
  }

  void _placeAtBottom(Vector2 size) {
    final y = size.y < 300 ? size.y * 0.72 : size.y - 120;
    position = Vector2(size.x / 2, y);
  }

  void _pulse(double duration) {
    _pulseTimer = duration;
    _pulseDuration = duration;
  }
}
