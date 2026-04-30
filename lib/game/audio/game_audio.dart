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
  double _hitCooldown = 0;
  double _deathCooldown = 0;
  double _skillDamageCooldown = 0;

  static const _hit = 'hit.mp3';
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

  Future<void> load() {
    return FlameAudio.audioCache.loadAll([
      _hit,
      _skill,
      _enemyDeath,
      ..._skillFiles.values,
    ]);
  }

  void update(double dt) {
    _hitCooldown = math.max(0, _hitCooldown - dt);
    _deathCooldown = math.max(0, _deathCooldown - dt);
    _skillDamageCooldown = math.max(0, _skillDamageCooldown - dt);
  }

  void playHit() {
    if (_hitCooldown > 0) return;
    _hitCooldown = 0.045;
    FlameAudio.play(_hit, volume: 0.35);
  }

  void playSkillCast() {
    FlameAudio.play(_skill, volume: 0.5);
  }

  void playSkillDamage(SkillSound sound) {
    if (_skillDamageCooldown > 0) return;
    _skillDamageCooldown = 0.08;
    FlameAudio.play(_skillFiles[sound]!, volume: 0.45);
  }

  void playRandomSkillDamage() {
    final sounds = SkillSound.values;
    playSkillDamage(sounds[_rng.nextInt(sounds.length)]);
  }

  void playEnemyDeath() {
    if (_deathCooldown > 0) return;
    _deathCooldown = 0.06;
    FlameAudio.play(_enemyDeath, volume: 0.45);
  }
}
