import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mech_catalog.dart';
import 'meta_state.dart';
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
  GameState({MetaState? meta}) : meta = meta ?? MetaState() {
    nexusHp = nexusMaxHp;
  }

  final Random _rng = Random();
  final MetaState meta;

  int gold = 0;
  int floor = 1;
  int killsOnFloor = 0;
  int totalKills = 0;
  int lastIdleReward = 0;
  int resetGeneration = 0;
  double nexusHp = maxNexusHp;
  MechType selectedMech = MechType.standard;
  bool devMode = false;
  bool devDisableUpgrades = false;

  final Map<String, int> _skillLevels = {};
  List<String> _pendingUpgradeIds = [];
  int? autoSelectSecondsRemaining;

  int rerollsRemaining = 0;
  int banishesRemaining = 0;
  final Set<String> _bannedIds = {};
  String? lockedUpgradeId;
  int levelUpCount = 0;
  int _streakStacks = 0;
  DateTime? _lastKillAt;
  bool _embersAwardedThisRun = false;

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
  static const int autoSelectDuration = 60;

  MechDefinition get mech => mechDefinitionFor(selectedMech);
  double get nexusMaxHp => maxNexusHp;
  double get heroDamage =>
      baseDamage * (1 + _archetypeLevel(SkillArchetype.focus) * 0.08);
  double get heroAttacksPerSec =>
      baseAttacksPerSec * (1 + _archetypeLevel(SkillArchetype.barrage) * 0.06);
  double get heroAttackRange => double.infinity;
  int get chainLevel => _archetypeLevel(SkillArchetype.chain);
  int get emberTargets => (1 + chainLevel).clamp(1, 10);
  int get barrageLevel => _archetypeLevel(SkillArchetype.barrage);
  int get focusLevel => _archetypeLevel(SkillArchetype.focus);
  int get bountyLevel => _archetypeLevel(SkillArchetype.bounty);
  int get frostLevel => _archetypeLevel(SkillArchetype.frost);
  int get ruptureLevel => _archetypeLevel(SkillArchetype.rupture);
  int get sentinelLevel => _archetypeLevel(SkillArchetype.sentinel);
  int get sentinelCount => sentinelLevel.clamp(0, 8);
  double get sentinelDamage => heroDamage * (0.35 + sentinelLevel * 0.08);
  double get sentinelAttackCooldown => 0.8 * pow(0.92, sentinelLevel);
  double get sentinelOrbitSpeed => 2.4 * (1 + sentinelLevel * 0.1);
  int get flameNovaLevel => _archetypeLevel(SkillArchetype.nova);
  double get flameNovaRadius => double.infinity;
  double get flameNovaDamage => heroDamage * (1 + flameNovaLevel * 0.18);
  int get firewallLevel => _archetypeLevel(SkillArchetype.firewall);
  double get firewallWidth => double.infinity;
  double get firewallDamage => heroDamage * (0.8 + firewallLevel * 0.12);
  int get meteorMarkLevel => _archetypeLevel(SkillArchetype.meteor);
  double get meteorMarkRadius => double.infinity;
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
    final streakMultiplier = 1 + _streakStacks * 0.1;
    return (base * bountyMultiplier * streakMultiplier).round();
  }

  double get estimatedTimeToKill =>
      estimatedDps <= 0 ? double.infinity : enemyMaxHp / estimatedDps;
  double get estimatedGoldPerSecond =>
      estimatedTimeToKill.isFinite && estimatedTimeToKill > 0
      ? goldPerKill / estimatedTimeToKill
      : 0;
  Map<String, int> get skillLevels =>
      Map.unmodifiable(Map<String, int>.from(_skillLevels));

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
    if (meta.hasKeystone('streak')) {
      final now = DateTime.now();
      if (_lastKillAt != null &&
          now.difference(_lastKillAt!).inMilliseconds <= 1000) {
        _streakStacks = (_streakStacks + 1).clamp(0, 5);
      } else {
        _streakStacks = 0;
      }
      _lastKillAt = now;
    }
    gold += goldPerKill;
    killsOnFloor += 1;
    totalKills += 1;
    if (killsOnFloor >= killsPerFloor) {
      killsOnFloor = 0;
      floor += 1;
      if (!devDisableUpgrades) {
        _rollUpgradeChoices();
      }
    }
    notifyListeners();
    _saveSoon();
  }

  void selectUpgrade(String id) {
    if (isRunOver || !_pendingUpgradeIds.contains(id) || _isMaxed(id)) return;
    _skillLevels[id] = skillLevel(id) + 1;
    levelUpCount += 1;
    if (lockedUpgradeId == id) lockedUpgradeId = null;
    _clearPending();
    notifyListeners();
    _saveSoon();
  }

  void devGrantSkill(String id) {
    if (_skillById(id) == null || _isMaxed(id)) return;
    _skillLevels[id] = skillLevel(id) + 1;
    notifyListeners();
    _saveSoon();
  }

  void toggleDevMode() {
    devMode = !devMode;
    notifyListeners();
    _saveSoon();
  }

  void toggleDevDisableUpgrades() {
    devDisableUpgrades = !devDisableUpgrades;
    notifyListeners();
    _saveSoon();
  }

  void rerollChoices() {
    if (isRunOver || !hasPendingLevelUp) return;
    if (rerollsRemaining <= 0) return;
    rerollsRemaining -= 1;
    final preserveLocked = lockedUpgradeId;
    _autoSelectTimer?.cancel();
    _countdownTimer?.cancel();
    autoSelectSecondsRemaining = null;
    _pendingUpgradeIds = [];
    _rollUpgradeChoices(forceLockedId: preserveLocked);
    notifyListeners();
  }

  void banishChoice(String id) {
    if (isRunOver || !_pendingUpgradeIds.contains(id)) return;
    if (banishesRemaining <= 0) return;
    banishesRemaining -= 1;
    _bannedIds.add(id);
    if (lockedUpgradeId == id) lockedUpgradeId = null;
    _pendingUpgradeIds.remove(id);
    if (_pendingUpgradeIds.isEmpty) {
      _autoSelectTimer?.cancel();
      _countdownTimer?.cancel();
      autoSelectSecondsRemaining = null;
      _rollUpgradeChoices();
    }
    notifyListeners();
  }

  void toggleLock(String id) {
    if (isRunOver || !meta.lockEnabled) return;
    if (!_pendingUpgradeIds.contains(id)) return;
    lockedUpgradeId = lockedUpgradeId == id ? null : id;
    notifyListeners();
  }

  void selectMech(MechType mechType) {
    selectedMech = MechType.standard;
  }

  void _clearPending() {
    _pendingUpgradeIds = [];
    autoSelectSecondsRemaining = null;
    _autoSelectTimer?.cancel();
    _autoSelectTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  int skillLevel(String id) => _skillLevels[id] ?? 0;

  void damageNexus(double amount) {
    if (isRunOver || amount <= 0) return;
    nexusHp = max(0, min(nexusMaxHp, nexusHp) - amount);
    if (isRunOver) {
      _clearPending();
      _awardEmbersForRun();
    }
    notifyListeners();
    _saveSoon();
  }

  void _awardEmbersForRun() {
    if (_embersAwardedThisRun) return;
    _embersAwardedThisRun = true;
    final earned = floor * 5 + totalKills;
    if (earned > 0) meta.awardEmbers(earned);
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
    totalKills = 0;
    lastIdleReward = 0;
    nexusHp = nexusMaxHp;
    resetGeneration += 1;
    _skillLevels.clear();
    _clearPending();
    _resetPerRunMeta();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kGold);
    await prefs.remove(_kFloor);
    await prefs.remove(_kKills);
    await prefs.remove(_kTotalKills);
    await prefs.remove(_kNexusHp);
    await prefs.remove(_kSkillLevels);
    await prefs.remove(_kPendingUpgrades);
    await prefs.remove(_kOldEmberChainLevel);
    await prefs.remove(_kOldFlameNovaLevel);
    await prefs.remove(_kOldFirewallLevel);
    await prefs.remove(_kOldMeteorMarkLevel);
    await prefs.remove(_kOldDamageLevel);
    await _writeLastSeen(prefs);

    if (meta.prePick) _rollUpgradeChoices();
    notifyListeners();
  }

  void _resetPerRunMeta() {
    rerollsRemaining = meta.rerollsPerRun;
    banishesRemaining = meta.banishesPerRun;
    _bannedIds.clear();
    lockedUpgradeId = null;
    levelUpCount = 0;
    _streakStacks = 0;
    _lastKillAt = null;
    _embersAwardedThisRun = false;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    gold = prefs.getInt(_kGold) ?? 0;
    floor = prefs.getInt(_kFloor) ?? 1;
    killsOnFloor = prefs.getInt(_kKills) ?? 0;
    totalKills = prefs.getInt(_kTotalKills) ?? 0;
    selectedMech = mechTypeFromId(prefs.getString(_kSelectedMech));
    devMode = prefs.getBool(_kDevMode) ?? false;
    nexusHp = (prefs.getDouble(_kNexusHp) ?? nexusMaxHp).clamp(0, nexusMaxHp);
    _resetPerRunMeta();
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

    if (hasPendingLevelUp) {
      _startAutoSelectTimer();
    }

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
    await prefs.setInt(_kTotalKills, totalKills);
    await prefs.setDouble(_kNexusHp, nexusHp);
    await prefs.setString(_kSelectedMech, selectedMech.name);
    await prefs.setBool(_kDevMode, devMode);
    await prefs.setStringList(_kSkillLevels, _encodeSkillLevels());
    await prefs.setStringList(_kPendingUpgrades, _pendingUpgradeIds);
    await _writeLastSeen(prefs);
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _autoSelectTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _rollUpgradeChoices({String? forceLockedId}) {
    final offerCount = meta.widerPick ? 4 : 3;
    final available = skillCatalog
        .where((d) => !_isMaxed(d.id) && !_bannedIds.contains(d.id))
        .toList();

    final ids = <String>[];
    final lockId = forceLockedId ?? lockedUpgradeId;
    if (lockId != null && available.any((d) => d.id == lockId)) {
      ids.add(lockId);
    }

    final guaranteeNew =
        meta.rareCadence && levelUpCount > 0 && (levelUpCount + 1) % 5 == 0;
    if (guaranteeNew) {
      final fresh = available
          .where((d) => skillLevel(d.id) == 0 && !ids.contains(d.id))
          .toList();
      if (fresh.isNotEmpty) {
        ids.add(fresh[_rng.nextInt(fresh.length)].id);
      }
    }

    final remaining = available.where((d) => !ids.contains(d.id)).toList();
    final extra = _weightedUpgradeIds(remaining, offerCount - ids.length);
    ids.addAll(extra);

    _pendingUpgradeIds = ids;
    lockedUpgradeId = null;
    if (hasPendingLevelUp) {
      _startAutoSelectTimer();
    }
  }

  Timer? _autoSelectTimer;
  Timer? _countdownTimer;

  void _startAutoSelectTimer() {
    _autoSelectTimer?.cancel();
    _countdownTimer?.cancel();

    autoSelectSecondsRemaining = autoSelectDuration;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (autoSelectSecondsRemaining != null &&
          autoSelectSecondsRemaining! > 0) {
        autoSelectSecondsRemaining = autoSelectSecondsRemaining! - 1;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });

    _autoSelectTimer = Timer(const Duration(seconds: autoSelectDuration), () {
      if (hasPendingLevelUp) {
        selectUpgrade(_pendingUpgradeIds.first);
      }
    });
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
    return (estimatedGoldPerSecond * seconds * _idleEfficiency).round();
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
  static const _kTotalKills = 'totalKills';
  static const _kNexusHp = 'nexusHp';
  static const _kSelectedMech = 'selectedMech';
  static const _kDevMode = 'devMode';
  static const _kSkillLevels = 'skillLevels';
  static const _kPendingUpgrades = 'pendingUpgrades';
  static const _kOldEmberChainLevel = 'emberChainLevel';
  static const _kOldFlameNovaLevel = 'flameNovaLevel';
  static const _kOldFirewallLevel = 'firewallLevel';
  static const _kOldMeteorMarkLevel = 'meteorMarkLevel';
  static const _kOldDamageLevel = 'damageLevel';
  static const _kLastSeen = 'lastSeenAt';
}
