import 'dart:async';
import 'dart:math' as math;

import 'package:flame_audio/flame_audio.dart';

enum SkillSound {
  fire,
  ice,
  lightning,
  poison,
  shadow,
  holy,
  earth,
  wind,
  arcane,
  physical,
}

class GameAudio {
  GameAudio();

  final math.Random _rng = math.Random();
  final Map<String, AudioPool> _pools = {};
  final Map<SkillSound, AudioPool> _skillPools = {};
  final Map<AudioPool, int> _activePlayers = {};
  bool _enabled = true;
  bool muted = false;
  double _hitCooldown = 0;
  double _deathCooldown = 0;
  double _skillDamageCooldown = 0;
  double _attackCooldown = 0;

  static const _hit = 'hit.mp3';
  static const _basicAttack = 'basic_attack_v2.mp3';
  static const _skill = 'skill.mp3';
  static const _enemyDeath = 'enemy_death.mp3';
  static const _skillFiles = <SkillSound, String>{
    SkillSound.fire: 'skill_fire.mp3',
    SkillSound.ice: 'skill_ice.mp3',
    SkillSound.lightning: 'skill_lightning.mp3',
    SkillSound.poison: 'skill_poison.mp3',
    SkillSound.shadow: 'skill_shadow.mp3',
    SkillSound.holy: 'skill_holy.mp3',
    SkillSound.earth: 'skill_earth.mp3',
    SkillSound.wind: 'skill_wind.mp3',
    SkillSound.arcane: 'skill_arcane.mp3',
    SkillSound.physical: 'skill_physical.mp3',
  };

  Future<void> load() async {
    try {
      await FlameAudio.audioCache.loadAll([
        _hit,
        _basicAttack,
        _skill,
        _enemyDeath,
        ..._skillFiles.values,
      ]);

      _pools[_hit] = await FlameAudio.createPool(
        _hit,
        minPlayers: 0,
        maxPlayers: 4,
      );
      _pools[_basicAttack] = await FlameAudio.createPool(
        _basicAttack,
        minPlayers: 0,
        maxPlayers: 6,
      );
      _pools[_skill] = await FlameAudio.createPool(
        _skill,
        minPlayers: 0,
        maxPlayers: 3,
      );
      _pools[_enemyDeath] = await FlameAudio.createPool(
        _enemyDeath,
        minPlayers: 0,
        maxPlayers: 3,
      );

      for (final entry in _skillFiles.entries) {
        _skillPools[entry.key] = await FlameAudio.createPool(
          entry.value,
          minPlayers: 0,
          maxPlayers: 2,
        );
      }
    } catch (_) {
      _enabled = false;
      _pools.clear();
      _skillPools.clear();
    }
  }

  void update(double dt) {
    _hitCooldown = math.max(0, _hitCooldown - dt);
    _deathCooldown = math.max(0, _deathCooldown - dt);
    _skillDamageCooldown = math.max(0, _skillDamageCooldown - dt);
    _attackCooldown = math.max(0, _attackCooldown - dt);
  }

  void playHit() {
    if (_hitCooldown > 0) return;
    _hitCooldown = 0.045;
    _playPool(_pools[_hit], volume: 0.35);
  }

  void playBasicAttack() {
    if (_attackCooldown > 0) return;
    _attackCooldown = 0.1;
    _playPool(_pools[_basicAttack], volume: 0.65);
  }

  void playSkillCast() {
    _playPool(_pools[_skill], volume: 0.5);
  }

  void playSkillDamage(SkillSound sound) {
    if (_skillDamageCooldown > 0) return;
    _skillDamageCooldown = 0.08;
    _playPool(_skillPools[sound], volume: 0.45);
  }

  void playRandomSkillDamage() {
    final sounds = SkillSound.values;
    playSkillDamage(sounds[_rng.nextInt(sounds.length)]);
  }

  void playEnemyDeath() {
    if (_deathCooldown > 0) return;
    _deathCooldown = 0.06;
    _playPool(_pools[_enemyDeath], volume: 0.45);
  }

  Future<void> dispose() async {
    await Future.wait([
      ..._pools.values.map((pool) => pool.dispose()),
      ..._skillPools.values.map((pool) => pool.dispose()),
    ]);
    _activePlayers.clear();
    _pools.clear();
    _skillPools.clear();
  }

  void _playPool(AudioPool? pool, {required double volume}) {
    if (!_enabled || muted) return;
    if (pool == null || (_activePlayers[pool] ?? 0) >= pool.maxPlayers) return;
    _activePlayers[pool] = (_activePlayers[pool] ?? 0) + 1;
    unawaited(_startPooledSound(pool, volume: volume));
  }

  Future<void> _startPooledSound(
    AudioPool pool, {
    required double volume,
  }) async {
    try {
      await pool.start(volume: volume);
      Timer(const Duration(milliseconds: 600), () => _releasePoolSlot(pool));
    } catch (_) {
      _releasePoolSlot(pool);
    }
  }

  void _releasePoolSlot(AudioPool pool) {
    final active = _activePlayers[pool];
    if (active == null) return;
    if (active <= 1) {
      _activePlayers.remove(pool);
      return;
    }
    _activePlayers[pool] = active - 1;
  }
}
