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

class ZenithZeroGame extends FlameGame {
  ZenithZeroGame({required this.state});

  final GameState state;
  final GameAudio audio = GameAudio();
  late final HeroComponent hero;
  late final EnemySpawner spawner;
  final Set<Enemy> activeEnemies = {};
  List<Enemy> aliveEnemies = [];
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
    aliveEnemies.clear();
    for (final enemy in activeEnemies) {
      if (enemy.isAlive) aliveEnemies.add(enemy);
    }
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

  bool canSpawnDamageText() {
    if (world.children.length > 700) return false;
    final maxPerFrame = aliveEnemies.length > 80 ? 8 : 16;
    if (_damageTextsThisFrame >= maxPerFrame) return false;
    _damageTextsThisFrame++;
    return true;
  }

  bool canSpawnMinorEffect() {
    final componentCount = world.children.length;
    if (componentCount > 700) return false;
    final maxPerFrame = componentCount > 420 || aliveEnemies.length > 90
        ? 5
        : 14;
    if (_minorEffectsThisFrame >= maxPerFrame) return false;
    _minorEffectsThisFrame++;
    return true;
  }

  bool canSpawnMajorEffect() {
    final componentCount = world.children.length;
    if (componentCount > 760) return false;
    final maxPerFrame = componentCount > 420 || aliveEnemies.length > 90
        ? 2
        : 6;
    if (_majorEffectsThisFrame >= maxPerFrame) return false;
    _majorEffectsThisFrame++;
    return true;
  }

  bool get effectsConstrained =>
      world.children.length > 420 || aliveEnemies.length > 90;

  void _resetVisualBudget() {
    _damageTextsThisFrame = 0;
    _minorEffectsThisFrame = 0;
    _majorEffectsThisFrame = 0;
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
