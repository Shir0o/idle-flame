import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'audio/game_audio.dart';
import 'components/enemy.dart';
import 'components/enemy_spawner.dart';
import 'components/hero.dart';
import 'state/game_state.dart';

enum VisualLoadTier { normal, busy, overloaded, critical }

VisualLoadTier visualLoadTierForCounts({
  required int enemyCount,
  required int componentCount,
}) {
  if (componentCount > 760 || enemyCount > 150) {
    return VisualLoadTier.critical;
  }
  if (componentCount > 620 || enemyCount > 120) {
    return VisualLoadTier.overloaded;
  }
  if (componentCount > 420 || enemyCount > 90) {
    return VisualLoadTier.busy;
  }
  return VisualLoadTier.normal;
}

class ZenithZeroGame extends FlameGame {
  ZenithZeroGame({required this.state});

  final GameState state;
  final GameAudio audio = GameAudio();
  late final HeroComponent hero;
  late final EnemySpawner spawner;
  final Set<Enemy> activeEnemies = {};
  List<Enemy> aliveEnemies = [];
  List<Enemy> targetableEnemies = [];
  final math.Random _rng = math.Random();
  double _shakeTime = 0;
  double _shakeDuration = 0;
  double _shakeIntensity = 0;
  int _seenResetGeneration = 0;
  int _seenDevKillAllRequest = 0;
  bool _lastShowPerfOverlay = false;
  late final FpsTextComponent _fpsText;
  late final _PerfStatsComponent _perfStats;
  int _damageTextsThisFrame = 0;
  int _minorEffectsThisFrame = 0;
  int _majorEffectsThisFrame = 0;
  int _basicHitSoundsThisFrame = 0;
  int _skillHitSoundsThisFrame = 0;
  Enemy? nearestEnemyToHero;
  Enemy? deepestEnemy;
  Enemy? rightmostEnemy;
  VisualLoadTier visualLoadTier = VisualLoadTier.normal;

  @override
  Color backgroundColor() => Colors.black;

  @override
  Future<void> onLoad() async {
    await audio.load();
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.position = Vector2.zero();

    hero = HeroComponent(mechType: state.selectedMech);
    spawner = EnemySpawner();
    _seenResetGeneration = state.resetGeneration;
    world.add(hero);
    world.add(spawner);

    _fpsText = FpsTextComponent(
      position: Vector2(8, 8),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF80FF80),
          fontSize: 12,
          fontFamily: 'monospace',
        ),
      ),
    );
    _perfStats = _PerfStatsComponent(this);
    _lastShowPerfOverlay = state.showPerfOverlay;
    if (_lastShowPerfOverlay) {
      camera.viewport.add(_fpsText);
      camera.viewport.add(_perfStats);
    }
  }

  @override
  void onRemove() {
    unawaited(audio.dispose());
    super.onRemove();
  }

  @override
  void update(double dt) {
    final scaledDt = dt * state.devTimeScale;
    _refreshCombatSummary();
    _resetVisualBudget();

    if (_lastShowPerfOverlay != state.showPerfOverlay) {
      _lastShowPerfOverlay = state.showPerfOverlay;
      if (_lastShowPerfOverlay) {
        camera.viewport.add(_fpsText);
        camera.viewport.add(_perfStats);
      } else {
        _fpsText.removeFromParent();
        _perfStats.removeFromParent();
      }
    }

    super.update(scaledDt);
    if (state.hasPendingLevelUp || state.isRunOver) return;

    audio.update(scaledDt);
    if (_seenResetGeneration != state.resetGeneration) {
      _seenResetGeneration = state.resetGeneration;
      _resetWorldForNewRun();
    }
    if (_seenDevKillAllRequest != state.devKillAllRequest) {
      _seenDevKillAllRequest = state.devKillAllRequest;
      _devKillAllEnemies();
    }
    if (hero.mechType != state.selectedMech) {
      hero.setMechType(state.selectedMech);
    }
    if (audio.muted != state.muted) {
      audio.muted = state.muted;
    }
    if (_shakeTime > 0) {
      _shakeTime -= scaledDt;
      final t = (_shakeTime / _shakeDuration).clamp(0.0, 1.0);
      final intensity = _shakeIntensity * Curves.easeOut.transform(t);
      camera.viewfinder.position = Vector2(
        (_rng.nextDouble() - 0.5) * intensity,
        (_rng.nextDouble() - 0.5) * intensity,
      );
      if (_shakeTime <= 0) {
        camera.viewfinder.position = Vector2.zero();
      }
    }
  }

  void shakeCamera({required double intensity, required double duration}) {
    if (duration <= 0 || intensity <= 0) return;
    if (intensity < _shakeIntensity && _shakeTime > 0) return;
    _shakeTime = duration;
    _shakeDuration = duration;
    _shakeIntensity = intensity;
  }

  List<Enemy> selectNearestEnemies(
    Vector2 origin,
    int limit, {
    double range = double.infinity,
  }) {
    if (limit <= 0 || targetableEnemies.isEmpty) return const <Enemy>[];

    final selected = <Enemy>[];
    final distances = <double>[];
    final rangeSquared = range * range;

    for (final enemy in targetableEnemies) {
      final distance = (enemy.position - origin).length2;
      if (distance > rangeSquared) continue;

      var insertAt = 0;
      while (insertAt < distances.length && distances[insertAt] <= distance) {
        insertAt++;
      }
      if (insertAt >= limit) continue;

      selected.insert(insertAt, enemy);
      distances.insert(insertAt, distance);
      if (selected.length > limit) {
        selected.removeLast();
        distances.removeLast();
      }
    }

    return selected;
  }

  bool hasEnemyWithin(Vector2 origin, double range) {
    if (targetableEnemies.isEmpty) return false;
    final rangeSquared = range * range;
    for (final enemy in targetableEnemies) {
      if ((enemy.position - origin).length2 <= rangeSquared) return true;
    }
    return false;
  }

  bool canSpawnDamageText({bool lowPriority = false}) {
    if (world.children.length > 700) return false;
    final tier = visualLoadTier;
    if (lowPriority && tier != VisualLoadTier.normal) return false;
    final maxPerFrame = switch (tier) {
      VisualLoadTier.normal => 16,
      VisualLoadTier.busy => 8,
      VisualLoadTier.overloaded => 4,
      VisualLoadTier.critical => 0,
    };
    if (_damageTextsThisFrame >= maxPerFrame) return false;
    _damageTextsThisFrame++;
    return true;
  }

  bool canSpawnMinorEffect({bool lowPriority = false}) {
    final componentCount = world.children.length;
    if (componentCount > 700) return false;
    final tier = visualLoadTier;
    if (lowPriority && tier != VisualLoadTier.normal) return false;
    final maxPerFrame = switch (tier) {
      VisualLoadTier.normal => 14,
      VisualLoadTier.busy => 5,
      VisualLoadTier.overloaded => 2,
      VisualLoadTier.critical => 0,
    };
    if (_minorEffectsThisFrame >= maxPerFrame) return false;
    _minorEffectsThisFrame++;
    return true;
  }

  bool canSpawnMajorEffect() {
    final componentCount = world.children.length;
    if (componentCount > 760) return false;
    final maxPerFrame = switch (visualLoadTier) {
      VisualLoadTier.normal => 6,
      VisualLoadTier.busy => 2,
      VisualLoadTier.overloaded => 1,
      VisualLoadTier.critical => 0,
    };
    if (_majorEffectsThisFrame >= maxPerFrame) return false;
    _majorEffectsThisFrame++;
    return true;
  }

  bool canPlayBasicHitSound({bool lowPriority = false}) {
    final maxPerFrame = switch (visualLoadTier) {
      VisualLoadTier.normal => lowPriority ? 2 : 4,
      VisualLoadTier.busy => lowPriority ? 1 : 2,
      VisualLoadTier.overloaded => lowPriority ? 0 : 1,
      VisualLoadTier.critical => 0,
    };
    if (_basicHitSoundsThisFrame >= maxPerFrame) return false;
    _basicHitSoundsThisFrame++;
    return true;
  }

  bool canPlaySkillHitSound({bool lowPriority = false}) {
    final maxPerFrame = switch (visualLoadTier) {
      VisualLoadTier.normal => lowPriority ? 2 : 4,
      VisualLoadTier.busy => lowPriority ? 1 : 2,
      VisualLoadTier.overloaded => lowPriority ? 0 : 1,
      VisualLoadTier.critical => 0,
    };
    if (_skillHitSoundsThisFrame >= maxPerFrame) return false;
    _skillHitSoundsThisFrame++;
    return true;
  }

  bool get effectsConstrained => visualLoadTier != VisualLoadTier.normal;

  void _resetVisualBudget() {
    _damageTextsThisFrame = 0;
    _minorEffectsThisFrame = 0;
    _majorEffectsThisFrame = 0;
    _basicHitSoundsThisFrame = 0;
    _skillHitSoundsThisFrame = 0;
  }

  void _refreshCombatSummary() {
    aliveEnemies.clear();
    targetableEnemies.clear();
    nearestEnemyToHero = null;
    deepestEnemy = null;
    rightmostEnemy = null;

    var nearestDistance = double.infinity;
    var deepestY = -double.infinity;
    var rightmostX = -double.infinity;
    final heroPos = hero.position;

    for (final enemy in activeEnemies) {
      if (!enemy.isAlive) continue;
      aliveEnemies.add(enemy);

      // Only target enemies in the bottom 2/3 of the screen above the hero.
      // This gives the player time to see enemies before they are engaged.
      if (enemy.position.y < hero.position.y / 3) continue;

      targetableEnemies.add(enemy);

      final distance = (enemy.position - heroPos).length2;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestEnemyToHero = enemy;
      }

      if (enemy.position.y > deepestY) {
        deepestY = enemy.position.y;
        deepestEnemy = enemy;
      }

      if (enemy.position.x > rightmostX) {
        rightmostX = enemy.position.x;
        rightmostEnemy = enemy;
      }
    }

    visualLoadTier = visualLoadTierForCounts(
      enemyCount: targetableEnemies.length,
      componentCount: world.children.length,
    );
  }

  void _devKillAllEnemies() {
    for (final enemy in activeEnemies.toList()) {
      if (enemy.isAlive) {
        enemy.takeDamage(enemy.hp + 1);
      }
    }
  }

  void _resetWorldForNewRun() {
    activeEnemies.clear();
    for (final component in world.children.toList()) {
      if (component == hero || component == spawner) continue;
      component.removeFromParent();
    }
    hero.resetForNewRun();
    spawner.resetForNewRun();
    _shakeTime = 0;
    _shakeDuration = 0;
    _shakeIntensity = 0;
    camera.viewfinder.position = Vector2.zero();
  }
}

class _PerfStatsComponent extends TextComponent {
  _PerfStatsComponent(this._game)
    : super(
        position: Vector2(8, 24),
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Color(0xFF80FF80),
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
      );

  final ZenithZeroGame _game;
  double _accum = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _accum += dt;
    if (_accum >= 0.5) {
      _accum = 0;
      final enemies = _game.aliveEnemies.length;
      final components = _game.world.children.length;
      text = 'enemies: $enemies  comps: $components';
    }
  }
}
