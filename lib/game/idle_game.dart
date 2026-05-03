import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'audio/game_audio.dart';
import 'components/enemy.dart';
import 'components/enemy_spawner.dart';
import 'components/hero.dart';
import 'state/game_state.dart';

const bool _showPerfOverlay = kDebugMode;

class IdleGame extends FlameGame {
  IdleGame({required this.state});

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

    if (_showPerfOverlay) {
      camera.viewport.add(
        FpsTextComponent(
          position: Vector2(8, 8),
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Color(0xFF80FF80),
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ),
      );
      camera.viewport.add(_PerfStatsComponent(this));
    }
  }

  @override
  void onRemove() {
    unawaited(audio.dispose());
    super.onRemove();
  }

  @override
  void update(double dt) {
    aliveEnemies = activeEnemies.where((e) => e.isAlive).toList();
    super.update(dt);
    if (state.hasPendingLevelUp || state.isRunOver) return;

    audio.update(dt);
    if (_seenResetGeneration != state.resetGeneration) {
      _seenResetGeneration = state.resetGeneration;
      _resetWorldForNewRun();
    }
    if (hero.mechType != state.selectedMech) {
      hero.setMechType(state.selectedMech);
    }
    if (_shakeTime > 0) {
      _shakeTime -= dt;
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

  final IdleGame _game;
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
