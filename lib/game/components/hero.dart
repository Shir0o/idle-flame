import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../zenith_zero_game.dart';
import '../state/game_state.dart';
import '../state/mech_catalog.dart';
import 'combat_effects.dart';
import 'enemy.dart';
import 'sentinel_blade.dart';
import 'mothership.dart';
import 'fire_snake.dart';
import 'fire_summons.dart';

class HeroComponent extends PositionComponent
    with HasGameReference<ZenithZeroGame> {
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
  double _snakeTimer = 0;
  double _summonTimer = 0;
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
  Mothership? _mothership;

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

    // Sentinel Aura (Sync Aura)
    if (_sentinelBlades.length >= 4) {
      final pulse = 0.5 + 0.5 * math.sin(_idlePhase * 4);
      final radius = w * 0.15;
      final auraPaint = Paint()
        ..color = const Color(0xFF00B0FF).withValues(alpha: 0.1 + 0.1 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 + 1.0 * pulse;

      canvas.drawCircle(
        Offset(cx, cy + bob),
        radius * (2.0 + 0.2 * pulse),
        auraPaint,
      );

      // Outer faint ring
      auraPaint.color = const Color(
        0xFF00B0FF,
      ).withValues(alpha: 0.05 * (1 - pulse));
      canvas.drawCircle(Offset(cx, cy + bob), radius * 3.0, auraPaint);
    }
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

    if (game.state.godMode) {
      _drawGodModeShield(canvas, center, radius);
    }
  }

  void _drawGodModeShield(Canvas canvas, Offset center, double radius) {
    final t = _idlePhase * 2.0;
    final shieldRadius = radius * 2.5;
    final shieldPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(
        0xFF64FFDA,
      ).withValues(alpha: 0.3 + 0.1 * math.sin(t));

    // Draw a pulsating hexagonal/circular shield
    canvas.drawCircle(center, shieldRadius, shieldPaint);

    // Draw tech-themed hex grid pattern inside shield
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = const Color(
        0xFF64FFDA,
      ).withValues(alpha: 0.1 * (0.3 + 0.1 * math.sin(t)));

    final hexPath = Path();
    const hexSize = 6.0;
    final h = hexSize * math.sqrt(3);
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final x = hexSize * math.cos(angle);
      final y = hexSize * math.sin(angle);
      if (i == 0) {
        hexPath.moveTo(x, y);
      } else {
        hexPath.lineTo(x, y);
      }
    }
    hexPath.close();

    for (
      double y = center.dy - shieldRadius;
      y <= center.dy + shieldRadius;
      y += hexSize * 1.5
    ) {
      final isOffset =
          ((y - center.dy + shieldRadius) / (hexSize * 1.5)).round() % 2 == 1;
      final xStart = center.dx - shieldRadius + (isOffset ? h / 2 : 0);
      for (double x = xStart; x <= center.dx + shieldRadius; x += h) {
        if ((Offset(x, y) - center).distance < shieldRadius - 2) {
          canvas.save();
          canvas.translate(x, y);
          canvas.drawPath(hexPath, gridPaint);
          canvas.restore();
        }
      }
    }

    // Add some orbiting particles or segments
    final segments = 6;
    for (var i = 0; i < segments; i++) {
      final angle = t + (i * 2 * math.pi / segments);
      final x = center.dx + math.cos(angle) * (shieldRadius + 4);
      final y = center.dy + math.sin(angle) * (shieldRadius + 4);
      canvas.drawCircle(
        Offset(x, y),
        2,
        Paint()..color = const Color(0xFF64FFDA).withValues(alpha: 0.6),
      );
    }
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
    _updateMothership();

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
    _snakeTimer += dt;
    if (game.state.snakeLevel > 0 && _snakeTimer >= GameState.snakeCooldown) {
      _snakeTimer = 0;
      _castSnake();
    }
    _summonTimer += dt;
    if (game.state.summonLevel > 0 && _summonTimer >= GameState.summonCooldown) {
      _summonTimer = 0;
      _castSummon();
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

  void _updateMothership() {
    final level = game.state.mothershipLevel;
    if (level > 0 && _mothership == null) {
      _mothership = Mothership(level: level);
      _mothership!.position = position.clone();
      parent?.add(_mothership!);
    } else if (level == 0 && _mothership != null) {
      _mothership!.removeFromParent();
      _mothership = null;
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
    _mothership?.removeFromParent();
    _mothership = null;
    _placeAtBottom(game.size);
  }

  void _tryAttack() {
    final emberTargets = game.state.emberTargets;
    final targets = game.selectNearestEnemies(
      position,
      emberTargets,
      range: game.state.heroAttackRange,
    );

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

    final focusLevel = game.state.focusLevel;
    final chainLevel = game.state.chainLevel;
    final barrageLevel = game.state.barrageLevel;
    final slashColor = critRoll
        ? const Color(0xFFFF6B35)
        : (focusLevel > 0 ? const Color(0xFFFFF176) : const Color(0xFF00E5FF));
    final jumpInterval = chainLevel >= 4 ? 0.04 : 0.08;

    for (var i = 0; i < targets.length; i++) {
      final enemy = targets[i];
      final delay = i * jumpInterval;

      final prevTargetPos = i == 0
          ? position.clone()
          : targets[i - 1].position.clone();

      if (delay == 0) {
        _applyChainHit(
          enemy,
          prevTargetPos,
          slashColor,
          focusLevel,
          chainLevel,
          critMul,
          twinShot,
          i == 0,
        );
      } else {
        parent?.add(
          TimerComponent(
            period: delay,
            removeOnFinish: true,
            onTick: () {
              if (game.state.isRunOver || !enemy.isAlive) return;
              _applyChainHit(
                enemy,
                prevTargetPos,
                slashColor,
                focusLevel,
                chainLevel,
                critMul,
                false,
                false,
              );
            },
          ),
        );
      }

      if (barrageLevel > 0 && _canSpawnAttackEffect(lowPriority: i > 0)) {
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

  void _applyChainHit(
    Enemy enemy,
    Vector2 fromPos,
    Color slashColor,
    int focusLevel,
    int chainLevel,
    double critMul,
    bool twinShot,
    bool isPrimary,
  ) {
    if (_canSpawnAttackEffect(lowPriority: !isPrimary)) {
      parent?.add(
        SlashArcEffect(
          from: fromPos,
          to: enemy.position.clone(),
          color: slashColor,
          widthMultiplier: 1 + focusLevel * 0.04,
          level: chainLevel,
        ),
      );
    }
    if (focusLevel > 0 && _canSpawnAttackEffect(lowPriority: true)) {
      parent?.add(
        FocusStrikeEffect(
          from: fromPos,
          to: enemy.position.clone(),
          level: focusLevel,
        ),
      );
    }
    enemy.takeDamage(
      game.state.heroDamage * critMul,
      source: fromPos,
      type: DamageType.basic,
    );
    // Whiplash: primary target hit twice
    if (isPrimary && game.state.meta.hasKeystone('whiplash')) {
      enemy.takeDamage(
        game.state.heroDamage * critMul * 0.6,
        source: fromPos,
        type: DamageType.basic,
      );
    }
    // Twin Shot: every 4th attack hits each target twice
    if (twinShot) {
      enemy.takeDamage(
        game.state.heroDamage * critMul,
        source: fromPos,
        type: DamageType.basic,
      );
    }
  }

  void _castFlameNova({double damageScale = 1.0, bool isAftershock = false}) {
    final novaLevel = game.state.flameNovaLevel;
    final radius = game.state.flameNovaRadius;
    final targets = _enemiesInRange(radius);

    // Level 4 Special: Reactor Surge (under pressure)
    // "Pressure" is defined as having enemies within 150 units of the nexus
    final isUnderPressure =
        novaLevel >= 4 && game.hasEnemyWithin(position, 150);

    final finalDamageScale = damageScale * (isUnderPressure ? 1.5 : 1.0);
    final finalShake =
        (isAftershock ? 2.0 : 3.5) * (isUnderPressure ? 1.4 : 1.0);

    if (!isAftershock) _pulse(isUnderPressure ? 0.28 : 0.2);
    game.audio.playSkillCast();
    game.shakeCamera(intensity: finalShake, duration: 0.16);

    final effectRadius = radius.isFinite ? radius : game.size.length;
    if (game.canSpawnMajorEffect()) {
      parent?.add(
        NovaPulseEffect(
          effectCenter: position.clone(),
          radius: effectRadius * (isAftershock ? 0.7 : 1.0),
          level: novaLevel,
        ),
      );
    }
    for (final enemy in targets) {
      enemy.takeDamage(
        game.state.flameNovaDamage * finalDamageScale,
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

    final firewallLevel = game.state.firewallLevel;
    Vector2 targetPos;

    // Level 2+ Special: Adaptive Targeting (spawns on deepest enemy if exists)
    if (firewallLevel >= 2 && game.deepestEnemy != null) {
      targetPos = game.deepestEnemy!.position.clone();
    } else {
      targetPos = Vector2(position.x, position.y - 165);
    }

    final wallY = targetPos.y;
    final wallX = targetPos.x;
    final width = game.state.firewallWidth;
    final effectWidth = width.isFinite ? width : game.size.x;
    final halfWidth = effectWidth / 2;
    final wallCenter = Vector2(wallX, wallY);

    if (game.canSpawnMajorEffect()) {
      parent?.add(
        FirewallEffect(
          effectCenter: wallCenter,
          effectWidth: effectWidth,
          level: firewallLevel,
        ),
      );
    }
    final enemies = _aliveEnemies().where((enemy) {
      final insideWidth = (enemy.position.x - wallX).abs() <= halfWidth;
      final nearWall = (enemy.position.y - wallY).abs() <= 28;
      return insideWidth && nearWall;
    }).toList();

    for (final enemy in enemies) {
      enemy.takeDamage(
        game.state.firewallDamage,
        source: wallCenter,
        type: DamageType.firewall,
      );
    }

    // Level 4 Special: Ward Refresh
    if (firewallLevel >= 4 && enemies.length >= 4) {
      _firewallTimer = GameState.firewallCooldown * 0.4;
    }

    if (!isBackdraft && game.state.meta.hasKeystone('backdraft')) {
      _backdraftTimer = 0.4;
    }
  }

  void _castSnake() {
    _pulse(0.12);
    game.audio.playSkillCast();
    parent?.add(
      FireSnake(
        startPos: position.clone(),
        level: game.state.snakeLevel,
        damage: game.state.snakeDamage,
        speed: game.state.snakeSpeed,
        trailDuration: game.state.snakeTrailDuration,
      ),
    );
  }

  void _castSummon() {
    _pulse(0.18);
    game.audio.playSkillCast();
    final level = game.state.summonLevel;

    // Wolf at L1
    parent?.add(
      FireSummon(
        startPos: position.clone(),
        type: SummonType.wolf,
        level: level,
        damage: game.state.summonDamage,
      ),
    );

    // Salamander at L2
    if (level >= 2) {
      parent?.add(
        FireSummon(
          startPos: position.clone(),
          type: SummonType.salamander,
          level: level,
          damage: game.state.summonDamage,
        ),
      );
    }

    // Phoenix at L4
    if (level >= 4) {
      parent?.add(
        FireSummon(
          startPos: position.clone(),
          type: SummonType.phoenix,
          level: level,
          damage: game.state.summonDamage,
        ),
      );
    }
  }

  void _castMeteorMark() {
    final target = game.deepestEnemy;
    if (target == null) return;

    final meteorLevel = game.state.meteorMarkLevel;
    final radius = game.state.meteorMarkRadius;
    final blastRadius = radius.isFinite ? radius : game.size.length;
    final blastRadiusSquared = blastRadius * blastRadius;

    // Level 4 Special: Faster lock-on
    final lockDuration = meteorLevel >= 4 ? 0.35 : 0.7;

    // Add targeting sigil
    parent?.add(
      MeteorTargetingEffect(
        target: target.position.clone(),
        radius: blastRadius,
        duration: lockDuration,
      ),
    );

    // Staggered Impact
    parent?.add(
      TimerComponent(
        period: lockDuration,
        removeOnFinish: true,
        onTick: () {
          if (game.state.isRunOver) return;
          _applyMeteorImpact(
            target.position.clone(),
            blastRadius,
            blastRadiusSquared,
          );

          // Level 5 Mastery: Rain of Chrome Comets
          if (meteorLevel >= 5) {
            final others = _aliveEnemies().where((e) => e != target).toList();
            others.shuffle(_critRng);
            final extraCount = 3;
            for (var i = 0; i < extraCount && i < others.length; i++) {
              final extraTarget = others[i];
              final delay = (i + 1) * 0.15;
              parent?.add(
                TimerComponent(
                  period: delay,
                  removeOnFinish: true,
                  onTick: () {
                    if (game.state.isRunOver) return;
                    _applyMeteorImpact(
                      extraTarget.position.clone(),
                      blastRadius * 0.7,
                      blastRadiusSquared * 0.49,
                    );
                  },
                ),
              );
            }
          }
        },
      ),
    );

    if (game.state.meta.hasKeystone('cluster')) {
      for (var i = 1; i <= 2; i++) {
        final delay = lockDuration + 0.18 * i;
        final offset = Vector2(
          (_critRng.nextDouble() - 0.5) * 80,
          (_critRng.nextDouble() - 0.5) * 80,
        );
        final clusterPos = target.position + offset;
        parent?.add(
          TimerComponent(
            period: delay,
            removeOnFinish: true,
            onTick: () {
              if (game.state.isRunOver) return;
              _applyMeteorImpact(
                clusterPos,
                blastRadius * 0.6,
                blastRadiusSquared * 0.36,
                damageScale: 0.5,
              );
            },
          ),
        );
      }
    }
  }

  void _applyMeteorImpact(
    Vector2 impactPos,
    double radius,
    double radiusSq, {
    double damageScale = 1.0,
  }) {
    if (game.canSpawnMajorEffect()) {
      parent?.add(
        MeteorImpactEffect(
          target: impactPos,
          radius: radius,
          level: game.state.meteorMarkLevel,
        ),
      );
    }
    _pulse(0.24);
    game.shakeCamera(intensity: 7, duration: 0.22);
    game.audio.playSkillCast(); // Using cast sound for impact 'thud'

    for (final enemy in _aliveEnemies()) {
      if ((enemy.position - impactPos).length2 <= radiusSq) {
        enemy.takeDamage(
          game.state.meteorMarkDamage * damageScale,
          source: impactPos,
          type: DamageType.meteor,
        );
      }
    }
  }

  List<Enemy> _enemiesInRange(double range) {
    if (!range.isFinite) return _aliveEnemies();
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
    for (final blade in _sentinelBlades) {
      blade.pulse(duration);
    }
  }

  bool _canSpawnAttackEffect({bool lowPriority = false}) {
    return game.visualLoadTier == VisualLoadTier.normal ||
        game.canSpawnMinorEffect(lowPriority: lowPriority);
  }
}
