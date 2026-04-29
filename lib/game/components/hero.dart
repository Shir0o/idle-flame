import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../idle_game.dart';
import '../state/game_state.dart';
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
    if (game.state.hasPendingLevelUp) return;

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
  }

  void _tryAttack() {
    final targets = _enemiesInRange(game.state.heroAttackRange)
      ..sort((a, b) {
        final aDist = (a.position - position).length2;
        final bDist = (b.position - position).length2;
        return aDist.compareTo(bDist);
      });
    for (final enemy in targets.take(game.state.emberTargets)) {
      enemy.takeDamage(game.state.heroDamage);
    }
  }

  void _castFlameNova() {
    for (final enemy in _enemiesInRange(game.state.flameNovaRadius)) {
      enemy.takeDamage(game.state.flameNovaDamage);
    }
  }

  void _castFirewall() {
    final wallY = position.y - 165;
    final halfWidth = game.state.firewallWidth / 2;
    final enemies = _aliveEnemies().where((enemy) {
      final insideWidth = (enemy.position.x - position.x).abs() <= halfWidth;
      final nearWall = (enemy.position.y - wallY).abs() <= 28;
      return insideWidth && nearWall;
    });
    for (final enemy in enemies) {
      enemy.takeDamage(game.state.firewallDamage);
    }
  }

  void _castMeteorMark() {
    final enemies = _aliveEnemies();
    if (enemies.isEmpty) return;
    enemies.sort((a, b) => b.position.y.compareTo(a.position.y));
    final target = enemies.first;
    final blastRadius = game.state.meteorMarkRadius;
    final blastRadiusSquared = blastRadius * blastRadius;
    for (final enemy in enemies) {
      final inBlast =
          (enemy.position - target.position).length2 <= blastRadiusSquared;
      if (inBlast) enemy.takeDamage(game.state.meteorMarkDamage);
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
}
