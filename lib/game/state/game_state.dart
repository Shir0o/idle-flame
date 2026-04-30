import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'skill_catalog.dart';

class SkillChoice {
  const SkillChoice({
    required this.definition,
    required this.currentLevel,
    required this.level,
    required this.maxLevel,
    required this.description,
  });

  final SkillDefinition definition;
  final int currentLevel;
  final int level;
  final int maxLevel;
  final String description;

  bool get isNew => currentLevel == 0;

  String get tierLabel {
    return switch (level) {
      1 || 3 => 'Stat',
      2 || 4 => 'Special',
      _ => 'Ascendant',
    };
  }
}

class GameState extends ChangeNotifier {
  final Random _rng = Random();

  int gold = 0;
  int floor = 1;
  int killsOnFloor = 0;
  int lastIdleReward = 0;
  int resetGeneration = 0;
  double nexusHp = maxNexusHp;

  final Map<String, int> _skillLevels = {};
  List<String> _pendingUpgradeIds = [];

  static const double maxNexusHp = 100;
  static const int killsPerFloor = 10;
  static const double baseDamage = 7;
  static const double baseAttacksPerSec = 1;
  static const double flameNovaCooldown = 5;
  static const double firewallCooldown = 3.5;
  static const double meteorMarkCooldown = 4.5;
  static const double _enemyHpGrowth = 1.12;
  static const double _goldGrowth = 1.15;
  static const double _baseEnemyHp = 6;
  static const int _baseGoldPerKill = 1;
  static const double _idleEfficiency = 0.5;
  static const int _idleCapSeconds = 8 * 3600;
  static const int _newSkillOfferWeight = 1;
  static const int _ownedSkillOfferWeight = 4;

  double get heroDamage =>
      baseDamage * (1 + _archetypeLevel(SkillArchetype.focus) * 0.08);
  double get heroAttacksPerSec =>
      baseAttacksPerSec * (1 + _archetypeLevel(SkillArchetype.barrage) * 0.06);
  double get heroAttackRange => double.infinity;
  int get emberTargets =>
      (1 + _archetypeLevel(SkillArchetype.chain)).clamp(1, 10);
  int get barrageLevel => _archetypeLevel(SkillArchetype.barrage);
  int get focusLevel => _archetypeLevel(SkillArchetype.focus);
  int get bountyLevel => _archetypeLevel(SkillArchetype.bounty);
  int get frostLevel => _archetypeLevel(SkillArchetype.frost);
  int get ruptureLevel => _archetypeLevel(SkillArchetype.rupture);
  int get sentinelLevel => _archetypeLevel(SkillArchetype.sentinel);
  int get sentinelCount => sentinelLevel == 0 ? 0 : (1 + (sentinelLevel / 3).floor()).clamp(0, 8);
  double get sentinelDamage => heroDamage * (0.35 + sentinelLevel * 0.08);
  int get flameNovaLevel => _archetypeLevel(SkillArchetype.nova);
  double get flameNovaRadius => 90 + flameNovaLevel * 10;
  double get flameNovaDamage => heroDamage * (1 + flameNovaLevel * 0.18);
  int get firewallLevel => _archetypeLevel(SkillArchetype.firewall);
  double get firewallWidth => 150 + firewallLevel * 14;
  double get firewallDamage => heroDamage * (0.8 + firewallLevel * 0.12);
  int get meteorMarkLevel => _archetypeLevel(SkillArchetype.meteor);
  double get meteorMarkRadius => 28 + meteorMarkLevel * 5;
  double get meteorMarkDamage => heroDamage * (1.7 + meteorMarkLevel * 0.14);
  double get enemySpeedMultiplier => max(0.45, 1 - frostLevel * 0.025);
  double get executeDamageMultiplier => 1 + ruptureLevel * 0.035;
  bool get isRunOver => nexusHp <= 0;
  bool get hasPendingLevelUp => _pendingUpgradeIds.isNotEmpty;
  List<SkillChoice> get pendingChoices =>
      _pendingUpgradeIds.map(_choiceFor).nonNulls.toList(growable: false);
  double get enemyMaxHp => _baseEnemyHp * pow(_enemyHpGrowth, floor - 1);
  double get enemyBreachDamage => 4 + floor * 0.8;
  int get goldPerKill {
    final base = _baseGoldPerKill * pow(_goldGrowth, floor - 1);
    final bountyMultiplier = 1 + bountyLevel * 0.08;
    return (base * bountyMultiplier).round();
  }

  double get estimatedDps {
    final directDps =
        heroDamage * heroAttacksPerSec * max(1, emberTargets * 0.65);
    final novaDps = flameNovaLevel == 0
        ? 0
        : flameNovaDamage / flameNovaCooldown;
    final firewallDps = firewallLevel == 0
        ? 0
        : firewallDamage / firewallCooldown;
    final meteorDps = meteorMarkLevel == 0
        ? 0
        : meteorMarkDamage / meteorMarkCooldown;
    return (directDps + novaDps + firewallDps + meteorDps) *
        executeDamageMultiplier;
  }

  void registerKill() {
    if (isRunOver) return;
    gold += goldPerKill;
    killsOnFloor += 1;
    if (killsOnFloor >= killsPerFloor) {
      killsOnFloor = 0;
      floor += 1;
      _rollUpgradeChoices();
    }
    notifyListeners();
    _saveSoon();
  }

  void selectUpgrade(String id) {
    if (isRunOver || !_pendingUpgradeIds.contains(id) || _isMaxed(id)) return;
    _skillLevels[id] = skillLevel(id) + 1;
    _pendingUpgradeIds = [];
    notifyListeners();
    _saveSoon();
  }

  int skillLevel(String id) => _skillLevels[id] ?? 0;

  void damageNexus(double amount) {
    if (isRunOver || amount <= 0) return;
    nexusHp = max(0, nexusHp - amount);
    if (isRunOver) {
      _pendingUpgradeIds = [];
    }
    notifyListeners();
    _saveSoon();
  }

  void clearIdleReward() {
    if (lastIdleReward == 0) return;
    lastIdleReward = 0;
    notifyListeners();
  }

  Future<void> resetProgress() async {
    _saveDebounce?.cancel();
    gold = 0;
    floor = 1;
    killsOnFloor = 0;
    lastIdleReward = 0;
    nexusHp = maxNexusHp;
    resetGeneration += 1;
    _skillLevels.clear();
    _pendingUpgradeIds = [];

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kGold);
    await prefs.remove(_kFloor);
    await prefs.remove(_kKills);
    await prefs.remove(_kNexusHp);
    await prefs.remove(_kSkillLevels);
    await prefs.remove(_kPendingUpgrades);
    await prefs.remove(_kOldEmberChainLevel);
    await prefs.remove(_kOldFlameNovaLevel);
    await prefs.remove(_kOldFirewallLevel);
    await prefs.remove(_kOldMeteorMarkLevel);
    await prefs.remove(_kOldDamageLevel);
    await _writeLastSeen(prefs);

    notifyListeners();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    gold = prefs.getInt(_kGold) ?? 0;
    floor = prefs.getInt(_kFloor) ?? 1;
    killsOnFloor = prefs.getInt(_kKills) ?? 0;
    nexusHp = (prefs.getDouble(_kNexusHp) ?? maxNexusHp).clamp(0, maxNexusHp);
    _skillLevels
      ..clear()
      ..addAll(_decodeSkillLevels(prefs.getStringList(_kSkillLevels)));
    _migrateOldSkillLevels(prefs);
    _pendingUpgradeIds =
        prefs
            .getStringList(_kPendingUpgrades)
            ?.where((id) => _skillById(id) != null && !_isMaxed(id))
            .toList() ??
        [];
    final lastSeen = prefs.getInt(_kLastSeen);
    if (lastSeen != null) {
      final reward = _computeIdleReward(
        DateTime.fromMillisecondsSinceEpoch(lastSeen),
      );
      if (reward > 0) {
        gold += reward;
        lastIdleReward = reward;
      }
    }
    await _writeLastSeen(prefs);
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kGold, gold);
    await prefs.setInt(_kFloor, floor);
    await prefs.setInt(_kKills, killsOnFloor);
    await prefs.setDouble(_kNexusHp, nexusHp);
    await prefs.setStringList(_kSkillLevels, _encodeSkillLevels());
    await prefs.setStringList(_kPendingUpgrades, _pendingUpgradeIds);
    await _writeLastSeen(prefs);
  }

  void _rollUpgradeChoices() {
    final available = skillCatalog
        .where((definition) => !_isMaxed(definition.id))
        .toList();
    _pendingUpgradeIds = _weightedUpgradeIds(available, 3);
  }

  List<String> _weightedUpgradeIds(List<SkillDefinition> available, int count) {
    final pool = available.toList();
    final selected = <String>[];
    while (pool.isNotEmpty && selected.length < count) {
      final totalWeight = pool.fold<int>(
        0,
        (total, definition) => total + _offerWeight(definition.id),
      );
      if (totalWeight <= 0) break;

      var roll = _rng.nextDouble() * totalWeight;
      for (var i = 0; i < pool.length; i++) {
        roll -= _offerWeight(pool[i].id);
        if (roll > 0) continue;
        selected.add(pool.removeAt(i).id);
        break;
      }
    }
    return selected;
  }

  int _offerWeight(String id) {
    return skillLevel(id) > 0 ? _ownedSkillOfferWeight : _newSkillOfferWeight;
  }

  bool _isMaxed(String id) => skillLevel(id) >= SkillDefinition.maxLevel;

  int _archetypeLevel(SkillArchetype archetype) {
    var total = 0;
    for (final entry in _skillLevels.entries) {
      final definition = _skillById(entry.key);
      if (definition?.archetype == archetype) total += entry.value;
    }
    return total;
  }

  SkillChoice? _choiceFor(String id) {
    final definition = _skillById(id);
    if (definition == null) return null;
    final currentLevel = skillLevel(id);
    final nextLevel = currentLevel + 1;
    return SkillChoice(
      definition: definition,
      currentLevel: currentLevel,
      level: nextLevel,
      maxLevel: SkillDefinition.maxLevel,
      description: definition.descriptionForLevel(nextLevel),
    );
  }

  SkillDefinition? _skillById(String id) {
    for (final definition in skillCatalog) {
      if (definition.id == id) return definition;
    }
    return null;
  }

  List<String> _encodeSkillLevels() {
    return _skillLevels.entries
        .where((entry) => entry.value > 0)
        .map((entry) => '${entry.key}:${entry.value}')
        .toList();
  }

  Map<String, int> _decodeSkillLevels(List<String>? encoded) {
    final levels = <String, int>{};
    for (final item in encoded ?? const <String>[]) {
      final separator = item.lastIndexOf(':');
      if (separator <= 0) continue;
      final id = item.substring(0, separator);
      final level = int.tryParse(item.substring(separator + 1));
      if (level == null || level <= 0 || _skillById(id) == null) continue;
      levels[id] = level.clamp(0, SkillDefinition.maxLevel);
    }
    return levels;
  }

  void _migrateOldSkillLevels(SharedPreferences prefs) {
    _migrateSkill(prefs, _kOldEmberChainLevel, 'neon_katana_chain');
    _migrateSkill(prefs, _kOldFlameNovaLevel, 'mana_reactor_nova');
    _migrateSkill(prefs, _kOldFirewallLevel, 'rune_firewall');
    _migrateSkill(prefs, _kOldMeteorMarkLevel, 'orbital_spellblade');
    _migrateSkill(prefs, _kOldDamageLevel, 'void_edge_focus');
  }

  void _migrateSkill(SharedPreferences prefs, String oldKey, String newId) {
    if (_skillLevels.containsKey(newId)) return;
    final oldLevel = prefs.getInt(oldKey);
    if (oldLevel == null || oldLevel <= 0) return;
    _skillLevels[newId] = oldLevel.clamp(1, SkillDefinition.maxLevel);
  }

  int _computeIdleReward(DateTime lastSeen) {
    if (isRunOver) return 0;
    final seconds = DateTime.now()
        .difference(lastSeen)
        .inSeconds
        .clamp(0, _idleCapSeconds);
    if (seconds <= 0) return 0;
    final timeToKill = enemyMaxHp / estimatedDps;
    final goldPerSec = goldPerKill / timeToKill;
    return (goldPerSec * seconds * _idleEfficiency).round();
  }

  Future<void> _writeLastSeen(SharedPreferences prefs) {
    return prefs.setInt(_kLastSeen, DateTime.now().millisecondsSinceEpoch);
  }

  Timer? _saveDebounce;
  void _saveSoon() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), save);
  }

  static const _kGold = 'gold';
  static const _kFloor = 'floor';
  static const _kKills = 'killsOnFloor';
  static const _kNexusHp = 'nexusHp';
  static const _kSkillLevels = 'skillLevels';
  static const _kPendingUpgrades = 'pendingUpgrades';
  static const _kOldEmberChainLevel = 'emberChainLevel';
  static const _kOldFlameNovaLevel = 'flameNovaLevel';
  static const _kOldFirewallLevel = 'firewallLevel';
  static const _kOldMeteorMarkLevel = 'meteorMarkLevel';
  static const _kOldDamageLevel = 'damageLevel';
  static const _kLastSeen = 'lastSeenAt';
}
