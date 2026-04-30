import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../idle_game.dart';
import '../state/game_state.dart';
import 'combat_effects.dart';
import 'enemy.dart';

class HeroComponent extends RectangleComponent with HasGameReference<IdleGame> {
  HeroComponent()
    : super(
        size: Vector2(48, 48),
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFF00E5FF),
      );

  double _attackTimer = 0;
  double _novaTimer = 0;
  double _firewallTimer = 0;
  double _meteorTimer = 0;
  double _frostFieldTimer = 0;
  double _pulseTimer = 0;
  double _pulseDuration = 0.18;

  @override
  void onMount() {
    super.onMount();
    _placeAtBottom(game.size);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _placeAtBottom(size);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_pulseTimer > 0) {
      _pulseTimer -= dt;
      final t = (_pulseTimer / _pulseDuration).clamp(0.0, 1.0);
      scale = Vector2.all(1 + Curves.easeOutBack.transform(t) * 0.1);
      if (_pulseTimer <= 0) scale = Vector2.all(1);
    }
    if (game.state.hasPendingLevelUp || game.state.isRunOver) return;

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
    _frostFieldTimer += dt;
    if (game.state.frostLevel > 0 && _frostFieldTimer >= 2.1) {
      _frostFieldTimer = 0;
      parent?.add(
        FrostFieldEffect(
          effectCenter: game.size / 2,
          fieldSize: Vector2(game.size.x, game.size.y),
        ),
      );
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
    scale = Vector2.all(1);
    _placeAtBottom(game.size);
  }

  void _tryAttack() {
    final targets = _enemiesInRange(game.state.heroAttackRange)
      ..sort((a, b) {
        final aDist = (a.position - position).length2;
        final bDist = (b.position - position).length2;
        return aDist.compareTo(bDist);
      });
    for (final enemy in targets.take(game.state.emberTargets)) {
      final focusLevel = game.state.focusLevel;
      final barrageLevel = game.state.barrageLevel;
      final slashColor = focusLevel > 0
          ? const Color(0xFFFFF176)
          : const Color(0xFF00E5FF);
      parent?.add(
        SlashArcEffect(
          from: position.clone(),
          to: enemy.position.clone(),
          color: slashColor,
          widthMultiplier: 1 + focusLevel * 0.04,
        ),
      );
      if (focusLevel > 0) {
        parent?.add(
          FocusStrikeEffect(from: position.clone(), to: enemy.position.clone()),
        );
      }
      enemy.takeDamage(
        game.state.heroDamage,
        source: position.clone(),
        type: DamageType.basic,
      );
      if (barrageLevel > 0) {
        parent?.add(BarrageStreakEffect(effectCenter: position.clone()));
      }
    }
    if (targets.isNotEmpty) _pulse(0.14);
  }

  void _castFlameNova() {
    _pulse(0.2);
    game.audio.playSkillCast();
    game.shakeCamera(intensity: 3.5, duration: 0.16);
    parent?.add(
      NovaPulseEffect(
        effectCenter: position.clone(),
        radius: game.state.flameNovaRadius,
      ),
    );
    for (final enemy in _enemiesInRange(game.state.flameNovaRadius)) {
      enemy.takeDamage(
        game.state.flameNovaDamage,
        source: position.clone(),
        type: DamageType.nova,
      );
    }
  }

  void _castFirewall() {
    _pulse(0.16);
    game.audio.playSkillCast();
    final wallY = position.y - 165;
    final halfWidth = game.state.firewallWidth / 2;
    final wallCenter = Vector2(position.x, wallY);
    parent?.add(
      FirewallEffect(
        effectCenter: wallCenter,
        effectWidth: game.state.firewallWidth,
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
  }

  void _castMeteorMark() {
    final enemies = _aliveEnemies();
    if (enemies.isEmpty) return;
    game.audio.playSkillCast();
    enemies.sort((a, b) => b.position.y.compareTo(a.position.y));
    final target = enemies.first;
    final blastRadius = game.state.meteorMarkRadius;
    final blastRadiusSquared = blastRadius * blastRadius;
    parent?.add(
      MeteorImpactEffect(target: target.position.clone(), radius: blastRadius),
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
  }

  List<Enemy> _enemiesInRange(double range) {
    final rangeSquared = range * range;
    return _aliveEnemies()
        .where((enemy) => (enemy.position - position).length2 <= rangeSquared)
        .toList();
  }

  List<Enemy> _aliveEnemies() {
    final siblings = parent?.children ?? const Iterable.empty();
    return siblings.whereType<Enemy>().where((enemy) => enemy.isAlive).toList();
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
