import 'dart:math';

import 'package:flame/components.dart';

import '../zenith_zero_game.dart';
import '../state/game_state.dart';
import 'enemy.dart';

class EnemySpawner extends Component with HasGameReference<ZenithZeroGame> {
  final Random _rng = Random();
  double _timer = 0;

  static const double _spawnInterval = 1.8;
  static const double _offscreenPad = 40;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state.hasPendingLevelUp ||
        game.state.isRunOver ||
        game.state.devPauseSpawning) {
      return;
    }

    final phase = game.state.floorPhase;
    
    if (game.state.isBossFloor) {
      if (phase == FloorPhase.crucible && !game.state.bossSpawned) {
         _spawnBoss();
      }
      if (game.state.bossSpawned) return; // Only spawn adds if the boss itself handles it
    }

    double interval = _spawnInterval;
    if (phase == FloorPhase.trickle) {
      interval = 2.5;
    } else if (phase == FloorPhase.press) {
      interval = 1.2;
    } else if (phase == FloorPhase.crucible) {
      if (game.state.crucibleEvent == CrucibleEvent.hivebreak) {
        interval = 0.5;
      } else if (game.state.crucibleEvent == CrucibleEvent.quiet) {
        return; // No spawning
      } else if (game.state.crucibleEvent == CrucibleEvent.eclipse) {
        interval = 1.5;
      } else {
        return; // Other crucibles handle their own spawning via events
      }
    }

    _timer += dt;
    if (_timer >= interval) {
      _timer = 0;
      _spawn();
    }

    _handleCrucibleStart();
  }

  CrucibleEvent? _lastEvent;

  void _handleCrucibleStart() {
    final event = game.state.crucibleEvent;
    if (event == null || event == _lastEvent) return;
    _lastEvent = event;

    switch (event) {
      case CrucibleEvent.pressure:
        _spawnSpecific(EnemyType.tank);
        for (var i = 0; i < 5; i++) {
          _spawnSpecific(EnemyType.basic);
        }
        break;
      case CrucibleEvent.sigilStorm:
        for (var i = 0; i < 4; i++) {
          _spawnSpecific(EnemyType.sigilBearer);
        }
        break;
      case CrucibleEvent.fractalPack:
        for (var i = 0; i < 2; i++) {
          _spawnSpecific(EnemyType.splinter);
        }
        break;
      case CrucibleEvent.eclipse:
        _triggerEclipse();
        break;
      case CrucibleEvent.quiet:
        _quietStartingHp = game.state.nexusHp;
        parent?.add(
          TimerComponent(
            period: 10.0,
            removeOnFinish: true,
            onTick: () {
              if (!game.state.isRunOver && game.state.nexusHp >= _quietStartingHp) {
                game.state.gold += 25; // Bonus gold
                // TODO: Spawn a coin burst at nexus?
              }
            },
          ),
        );
        break;
      case CrucibleEvent.lastCant:
        game.state.forceCantOffer();
        break;
      case CrucibleEvent.bossEcho:
        final nextBoss = _bossForFloor(((game.state.floor / 5).floor() + 1) * 5);
        _spawnSpecific(nextBoss, hpScale: 0.2); // Mini version
        break;
      default:
        break;
    }
  }

  double _quietStartingHp = 0;

  void _triggerEclipse() {
    for (final enemy in game.aliveEnemies) {
      enemy.applyChill(duration: 2.0); // Freeze
      // After 2s, make them sprint by adding a custom component to them
      enemy.add(
        TimerComponent(
          period: 2.0,
          removeOnFinish: true,
          onTick: () {
            if (enemy.isAlive) enemy.applySprint(duration: 5.0, multiplier: 2.0);
          },
        ),
      );
    }
  }

  void resetForNewRun() {
    _timer = 0;
    _lastEvent = null;
  }

  void _spawn() {
    final size = game.size;
    final pos = Vector2(_rng.nextDouble() * size.x, -_offscreenPad);

    final floor = game.state.floor;
    final phase = game.state.floorPhase;
    
    final roll = _rng.nextDouble();
    EnemyType type;

    if (phase == FloorPhase.crucible && game.state.crucibleEvent == CrucibleEvent.hivebreak) {
      type = EnemyType.fast;
    } else {
      // Normal mix
      if (floor >= 6 && roll < 0.05) {
        type = EnemyType.aegis;
      } else if (floor >= 6 && roll < 0.10) {
        type = EnemyType.wraith;
      } else if (floor >= 6 && roll < 0.15) {
        type = EnemyType.cinderDrinker;
      } else if (floor >= 6 && roll < 0.20) {
        type = EnemyType.sutraBound;
      } else if (floor >= 8 && roll < 0.25) {
        type = EnemyType.splinter;
      } else if (floor >= 8 && roll < 0.30) {
        type = EnemyType.sigilBearer;
      } else if (floor >= 8 && roll < 0.35) {
        type = EnemyType.elite;
      } else if (floor >= 5 && roll < 0.45) {
        type = EnemyType.tank;
      } else if (floor >= 3 && roll < 0.60) {
        type = EnemyType.fast;
      } else {
        type = EnemyType.basic;
      }
    }

    parent?.add(Enemy(
      position: pos,
      baseMaxHp: game.state.enemyMaxHp,
      type: type,
    ));
  }

  void _spawnBoss() {
    game.state.bossSpawned = true;
    final bossType = _bossForFloor(game.state.floor);
    final bossPos = Vector2(game.size.x / 2, game.size.y * 0.15);
    parent?.add(Enemy(
      position: bossPos,
      baseMaxHp: game.state.enemyMaxHp,
      type: bossType,
    ));
  }

  void _spawnSpecific(EnemyType type, {double hpScale = 1.0}) {
    final size = game.size;
    final pos = Vector2(_rng.nextDouble() * size.x, -_offscreenPad);
    parent?.add(Enemy(
      position: pos,
      baseMaxHp: game.state.enemyMaxHp * hpScale,
      type: type,
    ));
  }

  EnemyType _bossForFloor(int floor) {
    return switch (floor) {
      5 => EnemyType.watcher,
      10 => EnemyType.glassSovereign,
      15 => EnemyType.hivefather,
      20 => EnemyType.cipherTwin,
      _ => EnemyType.architect,
    };
  }
}
