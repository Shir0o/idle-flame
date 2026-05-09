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

  static const String devAccessKey = 'TWANGPRO';

  final Random _rng = Random();
  final MetaState meta;

  int gold = 0;
  int floor = 1;
  int killsOnFloor = 0;
  int runKills = 0;
  int lifetimeKills = 0;
  int totalRuns = 0;
  int lastVoidReward = 0;
  int resetGeneration = 0;
  bool sessionWelcomeShown = false;
  double nexusHp = maxNexusHp;
  MechType selectedMech = MechType.standard;
  bool devMode = false;
  bool devDisableUpgrades = false;
  bool godMode = false;
  bool devPauseSpawning = false;
  bool showPerfOverlay = kDebugMode;
  bool muted = true;
  double devTimeScale = 1.0;
  double devEnemyStrength = 1.0;
  int devKillAllRequest = 0;

  final Map<String, int> _skillLevels = {};
  final Map<SkillArchetype, int> _evolutions = {};
  List<String> _pendingUpgradeIds = [];
  int? autoSelectSecondsRemaining;
  SkillArchetype? pendingEvolutionArchetype;

  int rerollsRemaining = 0;
  int banishesRemaining = 0;
  final Set<String> _bannedIds = {};
  final Set<String> _recentlyOfferedIds = {};
  String? lockedUpgradeId;

  static const _starterArchetypes = {
    SkillArchetype.chain,
    SkillArchetype.nova,
    SkillArchetype.barrage,
    SkillArchetype.focus,
  };

  static const _specialistArchetypes = {
    SkillArchetype.frost,
    SkillArchetype.rupture,
    SkillArchetype.sentinel,
    SkillArchetype.firewall,
    SkillArchetype.bounty,
  };

  static const _capstoneArchetypes = {
    SkillArchetype.meteor,
    SkillArchetype.mothership,
    SkillArchetype.snake,
    SkillArchetype.summon,
  };

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
  static const double snakeCooldown = 6.0;
  static const double summonCooldown = 8.0;
  static const double _enemyHpGrowth = 1.09;
  static const double _goldGrowth = 1.15;
  static const double _baseEnemyHp = 5.0;
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

  int getEvolution(SkillArchetype archetype) => _evolutions[archetype] ?? 0;

  int get sentinelCount =>
      sentinelLevel.clamp(0, 8) +
      (getEvolution(SkillArchetype.sentinel) == 1 ? 2 : 0);
  double get sentinelDamage => heroDamage * (0.35 + sentinelLevel * 0.08);
  double get sentinelAttackCooldown => 0.8 * pow(0.92, sentinelLevel);
  double get sentinelOrbitSpeed => 2.4 * (1 + sentinelLevel * 0.1);

  int get mothershipLevel => _archetypeLevel(SkillArchetype.mothership);
  int get mothershipDroneCount =>
      (3 + (mothershipLevel / 4).floor()).clamp(3, 10);
  double get mothershipDroneDamage =>
      heroDamage * (0.25 + mothershipLevel * 0.1);
  double get mothershipSpawnInterval => 4.0 / (1 + (mothershipLevel - 1) * 0.15);
  bool get mothershipDroneExplode => mothershipLevel >= 4;

  int get flameNovaLevel => _archetypeLevel(SkillArchetype.nova);
  double get flameNovaRadius => double.infinity;
  double get flameNovaDamage => heroDamage * (1.2 + flameNovaLevel * 0.3);
  int get firewallLevel => _archetypeLevel(SkillArchetype.firewall);
  double get firewallWidth => double.infinity;
  double get firewallDamage => heroDamage * (1.1 + firewallLevel * 0.25);
  double get firewallBurnDps => firewallDamage * (0.3 + (firewallLevel / 10) * 0.2);
  int get meteorMarkLevel => _archetypeLevel(SkillArchetype.meteor);
  double get meteorMarkRadius => double.infinity;
  double get meteorMarkDamage => heroDamage * (2.2 + meteorMarkLevel * 0.35);

  int get snakeLevel => _archetypeLevel(SkillArchetype.snake);
  double get snakeDamage => heroDamage * (1.0 + snakeLevel * 0.4);
  double get snakeSpeed => 190.0 * (1 + snakeLevel * 0.15);
  double get snakeTrailDuration => 0.8 + snakeLevel * 0.3;

  int get summonLevel => _archetypeLevel(SkillArchetype.summon);
  double get summonDamage => heroDamage * (1.4 + summonLevel * 0.45);

  double get enemySpeedMultiplier => max(0.45, 1 - frostLevel * 0.025);
  double get executeDamageMultiplier => 1 + ruptureLevel * 0.035;

  bool get hasFrostRuptureSynergy => frostLevel >= 1 && ruptureLevel >= 1;
  bool get hasChainNovaSynergy => chainLevel >= 1 && flameNovaLevel >= 1;
  bool get hasMeteorFirewallSynergy => meteorMarkLevel >= 1 && firewallLevel >= 1;
  bool get hasSentinelBarrageSynergy => sentinelLevel >= 1 && barrageLevel >= 1;
  bool get hasBountyExecuteSynergy => bountyLevel >= 1 && (ruptureLevel >= 1 || mothershipLevel >= 1 || snakeLevel >= 1);
  bool get hasMothershipSummonSynergy => mothershipLevel >= 1 && summonLevel >= 1;

  bool get isRunOver => nexusHp <= 0;
  bool get hasPendingLevelUp => _pendingUpgradeIds.isNotEmpty;
  List<SkillChoice> get pendingChoices =>
      _pendingUpgradeIds.map(_choiceFor).nonNulls.toList(growable: false);
  double get enemyMaxHp =>
      _baseEnemyHp * pow(_enemyHpGrowth, floor - 1) * devEnemyStrength;
  double get enemyBreachDamage => (3 + floor * 0.5) * devEnemyStrength;
  int get goldPerKill {
    final base = _baseGoldPerKill * pow(_goldGrowth, floor - 1);
    final bountyEvo = getEvolution(SkillArchetype.bounty);
    final bountyMultiplier =
        (1 + bountyLevel * 0.08) * (bountyEvo == 1 ? 1.5 : 1.0);
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
    final mothershipDps = mothershipLevel == 0
        ? 0
        : (mothershipDroneDamage * mothershipDroneCount) /
            mothershipSpawnInterval;
    return (directDps + novaDps + firewallDps + meteorDps + mothershipDps) *
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
    runKills += 1;
    lifetimeKills += 1;
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
    final nextLevel = skillLevel(id) + 1;
    _skillLevels[id] = nextLevel;
    levelUpCount += 1;

    if (nextLevel == 5) {
      final definition = _skillById(id);
      if (definition != null) {
        pendingEvolutionArchetype = definition.archetype;
      }
    }

    if (lockedUpgradeId == id) lockedUpgradeId = null;
    _clearPending();
    notifyListeners();
    _saveSoon();
  }

  void selectEvolution(int path) {
    if (pendingEvolutionArchetype == null) return;
    _evolutions[pendingEvolutionArchetype!] = path;
    pendingEvolutionArchetype = null;
    notifyListeners();
    _saveSoon();
  }

  void devGrantSkill(String id) {
    if (_skillById(id) == null) return;
    final current = skillLevel(id);
    if (current >= SkillDefinition.maxLevel) {
      _skillLevels[id] = 0;
    } else {
      _skillLevels[id] = current + 1;
    }
    notifyListeners();
    _saveSoon();
  }

  void devSetSkillLevel(String id, int level) {
    if (_skillById(id) == null) return;
    final clamped = level.clamp(0, SkillDefinition.maxLevel);
    if (clamped == 0) {
      _skillLevels.remove(id);
    } else {
      _skillLevels[id] = clamped;
    }
    notifyListeners();
    _saveSoon();
  }

  void devGrantGold(int amount) {
    gold += amount;
    notifyListeners();
    _saveSoon();
  }

  void devJumpFloor(int floors) {
    floor = max(1, floor + floors);
    killsOnFloor = 0;
    notifyListeners();
    _saveSoon();
  }

  void devMaxAllSkills() {
    for (final def in skillCatalog) {
      _skillLevels[def.id] = SkillDefinition.maxLevel;
    }
    notifyListeners();
    _saveSoon();
  }

  void devResetAllSkills() {
    _skillLevels.clear();
    _evolutions.clear();
    pendingEvolutionArchetype = null;
    notifyListeners();
    _saveSoon();
  }

  void devMaxArchetypeSkills(SkillArchetype archetype) {
    for (final def in skillCatalog) {
      if (def.archetype == archetype) {
        _skillLevels[def.id] = SkillDefinition.maxLevel;
      }
    }
    notifyListeners();
    _saveSoon();
  }

  void devResetArchetypeSkills(SkillArchetype archetype) {
    for (final def in skillCatalog) {
      if (def.archetype == archetype) {
        _skillLevels.remove(def.id);
      }
    }
    notifyListeners();
    _saveSoon();
  }

  void devForceLevelUp() {
    _rollUpgradeChoices();
    notifyListeners();
  }

  void toggleDevMode() {
    devMode = !devMode;
    notifyListeners();
    _saveSoon();
  }

  bool unlockDevMode(String key) {
    if (key.trim().toUpperCase() == devAccessKey) {
      devMode = !devMode;
      notifyListeners();
      _saveSoon();
      return true;
    }
    return false;
  }

  void toggleDevDisableUpgrades() {
    devDisableUpgrades = !devDisableUpgrades;
    notifyListeners();
    _saveSoon();
  }

  void toggleGodMode() {
    godMode = !godMode;
    notifyListeners();
    _saveSoon();
  }

  void toggleDevPauseSpawning() {
    devPauseSpawning = !devPauseSpawning;
    notifyListeners();
  }

  void toggleMuted() {
    muted = !muted;
    notifyListeners();
    _saveSoon();
  }

  void togglePerfOverlay() {
    showPerfOverlay = !showPerfOverlay;
    notifyListeners();
    _saveSoon();
  }

  void cycleGameSpeed() {
    if (devTimeScale == 1.0) {
      devTimeScale = 2.0;
    } else if (devTimeScale == 2.0) {
      devTimeScale = 5.0;
    } else if (devTimeScale == 5.0) {
      devTimeScale = 0.0;
    } else {
      devTimeScale = 1.0;
    }
    notifyListeners();
    _saveSoon();
  }

  void cycleEnemyStrength() {
    if (devEnemyStrength == 1.0) {
      devEnemyStrength = 2.0;
    } else if (devEnemyStrength == 2.0) {
      devEnemyStrength = 5.0;
    } else if (devEnemyStrength == 5.0) {
      devEnemyStrength = 10.0;
    } else {
      devEnemyStrength = 1.0;
    }
    notifyListeners();
    _saveSoon();
  }

  void devHealNexus() {
    nexusHp = nexusMaxHp;
    notifyListeners();
    _saveSoon();
  }

  void devResetCurrency() {
    gold = 0;
    notifyListeners();
    _saveSoon();
  }

  void devResetFloor() {
    floor = 1;
    killsOnFloor = 0;
    notifyListeners();
    _saveSoon();
  }

  void devResetEngine() {
    devTimeScale = 1.0;
    devEnemyStrength = 1.0;
    devPauseSpawning = false;
    godMode = false;
    devDisableUpgrades = false;
    notifyListeners();
    _saveSoon();
  }

  void requestDevKillAll() {
    devKillAllRequest += 1;
    notifyListeners();
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
    selectedMech = mechType;
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
    if (isRunOver || amount <= 0 || godMode) return;
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
    final earned = floor * 5 + runKills;
    if (earned > 0) meta.awardEmbers(earned);
  }

  void clearVoidReward() {
    if (lastVoidReward == 0) return;
    lastVoidReward = 0;
    notifyListeners();
  }

  void dismissWelcome() {
    if (sessionWelcomeShown && lastVoidReward == 0) return;
    sessionWelcomeShown = true;
    lastVoidReward = 0;
    notifyListeners();
  }

  Future<void> resetProgress() async {
    _saveDebounce?.cancel();
    totalRuns += 1;
    gold = 0;
    floor = 1;
    killsOnFloor = 0;
    runKills = 0;
    lastVoidReward = 0;
    nexusHp = nexusMaxHp;
    resetGeneration += 1;
    _skillLevels.clear();
    _clearPending();
    _resetPerRunMeta();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kGold);
    await prefs.remove(_kFloor);
    await prefs.remove(_kKills);
    await prefs.remove(_kRunKills);
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
    _recentlyOfferedIds.clear();
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
    runKills = prefs.getInt(_kRunKills) ?? 0;
    lifetimeKills = prefs.getInt(_kLifetimeKills) ?? 0;
    totalRuns = prefs.getInt(_kTotalRuns) ?? 1;
    selectedMech = mechTypeFromId(prefs.getString(_kSelectedMech));
    devMode = prefs.getBool(_kDevMode) ?? false;
    devDisableUpgrades = prefs.getBool(_kDevDisableUpgrades) ?? false;
    godMode = prefs.getBool(_kGodMode) ?? false;
    showPerfOverlay = prefs.getBool(_kShowPerfOverlay) ?? kDebugMode;
    muted = prefs.getBool(_kMuted) ?? true;
    devTimeScale = prefs.getDouble(_kDevTimeScale) ?? 1.0;
    devEnemyStrength = prefs.getDouble(_kDevEnemyStrength) ?? 1.0;
    nexusHp = (prefs.getDouble(_kNexusHp) ?? nexusMaxHp).clamp(0, nexusMaxHp);
    _resetPerRunMeta();
    _skillLevels
      ..clear()
      ..addAll(_decodeSkillLevels(prefs.getStringList(_kSkillLevels)));
    _evolutions
      ..clear()
      ..addAll(_decodeEvolutions(prefs.getStringList(_kEvolutions)));
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
      final reward = _computeVoidReward(
        DateTime.fromMillisecondsSinceEpoch(lastSeen),
      );
      if (reward > 0) {
        gold += reward;
        lastVoidReward = reward;
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
    await prefs.setInt(_kRunKills, runKills);
    await prefs.setInt(_kLifetimeKills, lifetimeKills);
    await prefs.setInt(_kTotalRuns, totalRuns);
    await prefs.setDouble(_kNexusHp, nexusHp);
    await prefs.setString(_kSelectedMech, selectedMech.name);
    await prefs.setBool(_kDevMode, devMode);
    await prefs.setBool(_kDevDisableUpgrades, devDisableUpgrades);
    await prefs.setBool(_kGodMode, godMode);
    await prefs.setBool(_kShowPerfOverlay, showPerfOverlay);
    await prefs.setBool(_kMuted, muted);
    await prefs.setDouble(_kDevTimeScale, devTimeScale);
    await prefs.setDouble(_kDevEnemyStrength, devEnemyStrength);
    await prefs.setStringList(_kSkillLevels, _encodeSkillLevels());
    await prefs.setStringList(_kEvolutions, _encodeEvolutions());
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

    // Determine unlocked archetypes based on tiers
    final unlockedArchetypes = <SkillArchetype>{..._starterArchetypes};

    // Specialist unlock: any archetype >= 5
    bool specialistUnlocked = false;
    for (final a in SkillArchetype.values) {
      if (_archetypeLevel(a) >= 5) {
        specialistUnlocked = true;
        break;
      }
    }
    if (specialistUnlocked) {
      unlockedArchetypes.addAll(_specialistArchetypes);
    }

    // Capstone unlock: any specialist >= 5
    bool capstoneUnlocked = false;
    for (final a in _specialistArchetypes) {
      if (_archetypeLevel(a) >= 5) {
        capstoneUnlocked = true;
        break;
      }
    }
    if (capstoneUnlocked) {
      unlockedArchetypes.addAll(_capstoneArchetypes);
    }

    final available = skillCatalog
        .where((d) =>
            unlockedArchetypes.contains(d.archetype) &&
            !_isMaxed(d.id) &&
            !_bannedIds.contains(d.id))
        .toList();

    final ids = <String>[];
    final lockId = forceLockedId ?? lockedUpgradeId;
    if (lockId != null && available.any((d) => d.id == lockId)) {
      ids.add(lockId);
    }

    // New skill guarantee: improves with rareCadence meta-upgrade
    final cadence = meta.rareCadence ? 3 : 5;
    final guaranteeNew = (levelUpCount + 1) % cadence == 0;
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

    // Refresh recently offered tracking
    _recentlyOfferedIds.clear();
    _recentlyOfferedIds.addAll(ids);

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
      final totalWeight = pool.fold<double>(
        0.0,
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

  double _offerWeight(String id) {
    final level = skillLevel(id);
    // Peaks around level 2 (commitment reward), then decays.
    // 1.0 floor ensures everything stays in the pool.
    double weight = 1.0 + 5.0 * level * exp(-level / 1.5);

    // Cooldown on recently offered
    if (_recentlyOfferedIds.contains(id)) {
      weight *= 0.5;
    }

    return weight;
  }

  bool _isMaxed(String id) => skillLevel(id) >= SkillDefinition.maxLevel;

  int _archetypeLevel(SkillArchetype archetype) {
    return _skillLevels[archetype.name] ?? 0;
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

  SkillDefinition? _skillById(String id) => findSkillById(id);

  List<String> _encodeSkillLevels() {
    return _skillLevels.entries
        .where((entry) => entry.value > 0)
        .map((entry) => '${entry.key}:${entry.value}')
        .toList();
  }

  List<String> _encodeEvolutions() {
    return _evolutions.entries
        .map((entry) => '${entry.key.name}:${entry.value}')
        .toList();
  }

  Map<String, int> _decodeSkillLevels(List<String>? encoded) {
    final levels = <String, int>{};
    for (final item in encoded ?? const <String>[]) {
      final separator = item.lastIndexOf(':');
      if (separator <= 0) continue;
      final id = item.substring(0, separator);
      final level = int.tryParse(item.substring(separator + 1));
      if (level == null || level <= 0) continue;
      levels[id] = level.clamp(0, SkillDefinition.maxLevel);
    }
    return levels;
  }

  Map<SkillArchetype, int> _decodeEvolutions(List<String>? encoded) {
    final evos = <SkillArchetype, int>{};
    for (final item in encoded ?? const <String>[]) {
      final separator = item.lastIndexOf(':');
      if (separator <= 0) continue;
      final name = item.substring(0, separator);
      final path = int.tryParse(item.substring(separator + 1));
      if (path == null) continue;
      try {
        final archetype = SkillArchetype.values.byName(name);
        evos[archetype] = path;
      } catch (_) {}
    }
    return evos;
  }

  void _migrateOldSkillLevels(SharedPreferences prefs) {
    _migrateSkill(prefs, _kOldEmberChainLevel, 'chain');
    _migrateSkill(prefs, _kOldFlameNovaLevel, 'nova');
    _migrateSkill(prefs, _kOldFirewallLevel, 'firewall');
    _migrateSkill(prefs, _kOldMeteorMarkLevel, 'meteor');
    _migrateSkill(prefs, _kOldDamageLevel, 'focus');

    // Migrate from the cosmetic slugs to the new archetype IDs
    final oldSlugs = {
      'neon_katana_chain': 'chain',
      'mana_reactor_nova': 'nova',
      'rune_firewall': 'firewall',
      'orbital_spellblade': 'meteor',
      'void_edge_focus': 'focus',
      'overclocked_iaido': 'barrage',
      'soulcoin_brand': 'bounty',
      'cryo_hex_ash': 'frost',
      'rupture_hex': 'rupture',
      'ghost_blade_sentinel': 'sentinel',
      'tactical_mothership': 'mothership',
      'fire_snake_ignite': 'snake',
      'fire_wolf_spirit': 'summon',
    };

    for (final entry in oldSlugs.entries) {
      if (_skillLevels.containsKey(entry.key)) {
        final level = _skillLevels.remove(entry.key)!;
        _skillLevels[entry.value] = max(_skillLevels[entry.value] ?? 0, level);
      }
    }
  }

  void _migrateSkill(SharedPreferences prefs, String oldKey, String newId) {
    if (_skillLevels.containsKey(newId)) return;
    final oldLevel = prefs.getInt(oldKey);
    if (oldLevel == null || oldLevel <= 0) return;
    _skillLevels[newId] = oldLevel.clamp(1, SkillDefinition.maxLevel);
  }

  int _computeVoidReward(DateTime lastSeen) {
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
  static const _kRunKills = 'runKills';
  static const _kLifetimeKills = 'lifetimeKills';
  static const _kTotalRuns = 'totalRuns';
  static const _kNexusHp = 'nexusHp';
  static const _kSelectedMech = 'selectedMech';
  static const _kDevMode = 'devMode';
  static const _kDevDisableUpgrades = 'devDisableUpgrades';
  static const _kGodMode = 'godMode';
  static const _kShowPerfOverlay = 'showPerfOverlay';
  static const _kMuted = 'muted';
  static const _kDevTimeScale = 'devTimeScale';
  static const _kDevEnemyStrength = 'devEnemyStrength';
  static const _kSkillLevels = 'skillLevels';
  static const _kEvolutions = 'skillEvolutions';
  static const _kPendingUpgrades = 'pendingUpgrades';
  static const _kOldEmberChainLevel = 'emberChainLevel';
  static const _kOldFlameNovaLevel = 'flameNovaLevel';
  static const _kOldFirewallLevel = 'firewallLevel';
  static const _kOldMeteorMarkLevel = 'meteorMarkLevel';
  static const _kOldDamageLevel = 'damageLevel';
  static const _kLastSeen = 'lastSeenAt';
}
