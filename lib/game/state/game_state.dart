import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/enemy.dart' show DamageType, EnemyType;
import 'mech_catalog.dart';
import 'meta_state.dart';
import 'skill_catalog.dart';
import 'triad_catalog.dart';
import 'inflection_catalog.dart';

enum FloorPhase { trickle, press, crucible }

enum FloorBoon {
  nexusHpBoost,
  rerollPlus1,
  gold25,
  randomSutra,
  revealModifier,
  halveCantCost,
  skipNextCant,
}

enum CrucibleEvent {
  pressure,
  hivebreak,
  sigilStorm,
  eclipse,
  quiet,
  fractalPack,
  lastCant,
  bossEcho,
}

enum FloorModifier {
  bandwidthBlackout,
  cinderDamp,
  stanceStutter,
  quickening,
  solarFlare,
  veilOfAsh,
  hereticTide,
  cipherStorm,
  echoTide,
  discountKit,
  manaBloom,
  glyphCache,
}

class SkillChoice {
  const SkillChoice({
    required this.definition,
    required this.currentLevel,
    required this.level,
    required this.maxLevel,
    required this.description,
    this.inflectionOptions = const [],
  });

  final SkillDefinition definition;
  final int currentLevel;
  final int level;
  final int maxLevel;
  final String description;
  final List<InflectionDefinition> inflectionOptions;

  bool get isNew => currentLevel == 0;

  String get tierLabel {
    return switch (level) {
      1 || 3 => 'Stat',
      2 || 4 => 'Special',
      _ => 'Ascendant',
    };
  }
}

class FusionChoice {
  const FusionChoice({
    required this.definition,
  });

  final FusionDefinition definition;

  String get title => definition.name;
  String get description => definition.description;
  String get tierLabel => 'FUSION';
}

class CantChoice {
  const CantChoice({
    required this.definition,
  });

  final CantDefinition definition;

  String get title => definition.name;
  String get description => definition.description;
  String get tierLabel => 'HERETIC';
}

class GameState extends ChangeNotifier {
  GameState({MetaState? meta}) : meta = meta ?? MetaState() {
    nexusHp = nexusMaxHp;
  }

  static const String devAccessKey = 'TWANGPRO';

  final math.Random _rng = math.Random();
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
  bool bossSpawned = false;
  bool isBossActive = false;
  double nexusHp = maxNexusHp;
  MechType selectedMech = MechType.standard;

  FloorPhase floorPhase = FloorPhase.trickle;
  CrucibleEvent? crucibleEvent;
  final Set<FloorModifier> activeModifiers = {};
  double floorTime = 0;

  bool get isBossFloor => floor % 5 == 0;
  bool devMode = false;
  bool devDisableUpgrades = false;
  bool godMode = false;
  bool devPauseSpawning = false;
  bool showPerfOverlay = kDebugMode;
  bool muted = true;
  double devTimeScale = 1.0;
  double devEnemyStrength = 1.0;
  int devKillAllRequest = 0;

  int edgeStance = 0;
  double daemonBandwidth = 100.0;
  double hexCinder = 0.0;

  // Boss reward toast state — read by the HUD and cleared by clearBossReward()
  String? lastBossRewardLabel;
  String? lastBossRewardSubtitle;

  // F10 Boss Reward Picker state
  bool pendingSutraReward = false;
  List<SkillArchetype> sutraRewardChoices = [];

  // Boss Telegraph state
  bool bossTelegraphPending = false;
  String? bossTelegraphName;
  String? bossTelegraphSubtitle;

  // Counter Tip state
  String? counterTipLabel;
  String? counterTipSubtitle;
  Timer? _counterTipTimer;

  // Floor Reward Room state
  bool pendingFloorReward = false;
  List<FloorBoon> floorRewardChoices = [];

  void triggerCounterTip(EnemyType type) {
    final copy = _counterTipCopy(type);
    if (copy == null) return;

    _counterTipTimer?.cancel();
    counterTipLabel = copy.label;
    counterTipSubtitle = copy.subtitle;
    notifyListeners();

    _counterTipTimer = Timer(const Duration(seconds: 4), () {
      counterTipLabel = null;
      counterTipSubtitle = null;
      notifyListeners();
    });
  }

  void clearCounterTip() {
    _counterTipTimer?.cancel();
    counterTipLabel = null;
    counterTipSubtitle = null;
    notifyListeners();
  }

  ({String label, String subtitle})? _counterTipCopy(EnemyType type) {
    return switch (type) {
      EnemyType.aegis => (
          label: 'AEGIS',
          subtitle: 'Reflects single-target damage. Bypass with AoE / chain.'
        ),
      EnemyType.wraith => (
          label: 'WRAITH',
          subtitle: 'Phases out for 1s after each hit. Use DOTs or frost.'
        ),
      EnemyType.cinderDrinker => (
          label: 'CINDER-DRINKER',
          subtitle: 'Heals from Hex damage. Finish with Edge or Daemon.'
        ),
      EnemyType.splinter => (
          label: 'SPLINTER',
          subtitle: 'Divides on death. Execute or wide AoE.'
        ),
      EnemyType.sutraBound => (
          label: 'SUTRA-BOUND',
          subtitle: 'Heals nearby enemies. Kill priority.'
        ),
      EnemyType.sigilBearer => (
          label: 'SIGIL-BEARER',
          subtitle: 'Drops a hazard glyph on death. Kill at the edges.'
        ),
      // Base types optional but recommended per §3
      EnemyType.basic => (
          label: 'BASIC',
          subtitle: 'Standard fodder. No special behaviors.'
        ),
      EnemyType.fast => (
          label: 'FAST',
          subtitle: 'High speed, low health. Priority for rapid fire.'
        ),
      EnemyType.tank => (
          label: 'TANK',
          subtitle: 'Slow with high health. Tests your DPS.'
        ),
      EnemyType.elite => (
          label: 'ELITE',
          subtitle: 'Stronger variant. Awards high gold.'
        ),
      _ => null,
    };
  }

  // Cipher Storm modifier — when active, a single damage type is immune for
  // 4-second windows and rotates through the catalog. Null means no immunity
  // active right now (either modifier off, or between rotations on entry).
  DamageType? cipherStormImmunity;
  double _cipherStormTimer = 0;
  int _cipherStormCursor = 0;

  // Tracks whether the Nexus has taken damage during the current Crucible
  // phase. A clean Crucible (no damage taken) awards a 25-gold bonus on
  // floor advance, per the Floors v1 reward structure.
  bool _crucibleCleanRun = true;

  final Map<String, int> _skillLevels = {};
  final Map<SkillArchetype, int> _evolutions = {};
  final Set<String> _ownedFusionIds = {};
  final Set<String> _activeCantIds = {};
  final Set<String> _activeTriadIds = {};
  final Map<String, List<String>> _selectedInflections = {};
  List<String> _pendingUpgradeIds = [];
  List<String> _pendingFusionIds = [];
  List<String> _pendingCantIds = [];
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
  int _bountyStreakStacks = 0;
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

  double sutraMultiplier(SkillArchetype archetype) =>
      1 + meta.sutraCount(archetype) * 0.01;

  MechDefinition get mech => mechDefinitionFor(selectedMech);
  late double _nexusMaxHp = maxNexusHp;
  double get nexusMaxHp => _nexusMaxHp;
  double get heroDamage =>
      baseDamage *
      (1 + _archetypeLevel(SkillArchetype.focus) * 0.08) *
      sutraMultiplier(SkillArchetype.focus);
  double get heroAttacksPerSec {
    double base = baseAttacksPerSec *
        (1 + _archetypeLevel(SkillArchetype.barrage) * 0.06) *
        sutraMultiplier(SkillArchetype.barrage);
    if (chromeIaido) {
      base *= (1 + mothershipDroneCount * 0.05);
    }
    return base;
  }
  double get heroAttackRange => double.infinity;
  int get chainLevel => _archetypeLevel(SkillArchetype.chain);
  int get emberTargets {
    int targets = 1 + chainLevel;
    if (monowireCascade) {
      targets += mothershipDroneCount;
    }
    return targets.clamp(1, 25);
  }
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
  double get sentinelDamage =>
      heroDamage * (0.35 + sentinelLevel * 0.08) * sutraMultiplier(SkillArchetype.sentinel);
  double get sentinelAttackCooldown => 0.8 * math.pow(0.92, sentinelLevel);
  double get sentinelOrbitSpeed => 2.4 * (1 + sentinelLevel * 0.1);

  int get mothershipLevel => _archetypeLevel(SkillArchetype.mothership);
  int get mothershipDroneCount =>
      (3 + (mothershipLevel / 4).floor()).clamp(3, 10);
  double get mothershipDroneDamage =>
      heroDamage * (0.25 + mothershipLevel * 0.1) * sutraMultiplier(SkillArchetype.mothership);
  double get mothershipSpawnInterval {
    double interval = 4.0 / (1 + (mothershipLevel - 1) * 0.15);
    if (meta.hasSutraPerk(SkillArchetype.mothership, 10)) {
      interval *= 0.66; // ~50% faster respawn (1 / 1.5 = 0.66)
    }
    return interval;
  }
  bool get mothershipDroneExplode => mothershipLevel >= 4;

  int get flameNovaLevel => _archetypeLevel(SkillArchetype.nova);
  double get flameNovaRadius => double.infinity * daemonRangeMultiplier;
  double get flameNovaDamage =>
      heroDamage * (1.2 + flameNovaLevel * 0.3) * sutraMultiplier(SkillArchetype.nova);
  int get firewallLevel => _archetypeLevel(SkillArchetype.firewall);
  double get firewallWidth => double.infinity * daemonRangeMultiplier;
  double get firewallDamage =>
      heroDamage * (1.1 + firewallLevel * 0.25) * sutraMultiplier(SkillArchetype.firewall);
  double get firewallBurnDps => firewallDamage * (0.3 + (firewallLevel / 10) * 0.2);
  int get meteorMarkLevel => _archetypeLevel(SkillArchetype.meteor);
  double get meteorMarkRadius => double.infinity * daemonRangeMultiplier;
  double get meteorMarkDamage =>
      heroDamage * (2.2 + meteorMarkLevel * 0.35) * sutraMultiplier(SkillArchetype.meteor);

  int get snakeLevel => _archetypeLevel(SkillArchetype.snake);
  double get snakeDamage =>
      heroDamage * (1.0 + snakeLevel * 0.4) * sutraMultiplier(SkillArchetype.snake);
  double get snakeSpeed => 190.0 * (1 + snakeLevel * 0.15);
  double get snakeTrailDuration => 0.8 + snakeLevel * 0.3;

  int get summonLevel => _archetypeLevel(SkillArchetype.summon);
  double get summonDamage =>
      heroDamage * (1.4 + summonLevel * 0.45) * sutraMultiplier(SkillArchetype.summon);

  double get enemySpeedMultiplier {
    double mult = math.max(0.45, 1 - frostLevel * 0.025);
    if (activeModifiers.contains(FloorModifier.quickening)) {
      mult *= 1.25;
    }
    return mult;
  }
  
  double get daemonCostMultiplier => 
      activeModifiers.contains(FloorModifier.bandwidthBlackout) ? 2.0 : 1.0;
  
  bool get enemiesShielded => activeModifiers.contains(FloorModifier.solarFlare);
  bool get echoTideActive => activeModifiers.contains(FloorModifier.echoTide) && killsOnFloor < 5;
  bool get veilOfAshActive => activeModifiers.contains(FloorModifier.veilOfAsh);
  double get executeDamageMultiplier => 1 + ruptureLevel * 0.035;

  bool get hasFrostRuptureSynergy => frostLevel >= 1 && ruptureLevel >= 1;
  bool get hasChainNovaSynergy => chainLevel >= 1 && flameNovaLevel >= 1;
  bool get hasMeteorFirewallSynergy => meteorMarkLevel >= 1 && firewallLevel >= 1;
  bool get hasSentinelBarrageSynergy => sentinelLevel >= 1 && barrageLevel >= 1;
  bool get hasBountyExecuteSynergy => bountyLevel >= 1 && (ruptureLevel >= 1 || mothershipLevel >= 1 || snakeLevel >= 1);
  bool get hasMothershipSummonSynergy => mothershipLevel >= 1 && summonLevel >= 1;

  bool hasFusion(String id) => _ownedFusionIds.contains(id);
  bool hasCant(String id) => _activeCantIds.contains(id);
  bool hasTriad(String id) => _activeTriadIds.contains(id);
  Set<String> get activeTriadIds => Set.unmodifiable(_activeTriadIds);

  List<String> getInflectionsFor(String skillId) {
    return List.unmodifiable(_selectedInflections[skillId] ?? []);
  }

  bool hasInflection(String id) {
    return _selectedInflections.values.any((list) => list.contains(id));
  }

  void _checkTriads() {
    for (final triad in triadCatalog) {
      if (_activeTriadIds.contains(triad.id)) continue;

      bool eligible = true;
      for (final archetype in triad.archetypes) {
        if (_archetypeLevel(archetype) < 1) {
          eligible = false;
          break;
        }
      }

      if (eligible) {
        _activeTriadIds.add(triad.id);
        meta.recordDiscovery('triad:${triad.id}');
      }
    }
  }

  bool get monowireCascade => hasFusion('monowire_cascade');
  bool get chromeIaido => hasFusion('chrome_iaido');
  bool get killcodeEdge => hasFusion('killcode_edge');
  bool get glyphbladeCant => hasFusion('glyphblade_cant');
  bool get phantomFrost => hasFusion('phantom_frost');
  bool get hexcutMantra => hasFusion('hexcut_mantra');
  bool get sigilReactor => hasFusion('sigil_reactor');
  bool get hexnetDrones => hasFusion('hexnet_drones');
  bool get bountysoulLedger => hasFusion('bountysoul_ledger');

  bool get bloodprice => hasCant('bloodprice');
  bool get devotion => hasCant('devotion');
  bool get diaspora => hasCant('diaspora');
  bool get greedglyph => hasCant('greedglyph');
  bool get hereticBargain => hasCant('heretic_bargain');

  int pathLevels(SkillPath path) {
    int total = 0;
    for (final archetype in SkillArchetype.values) {
      if (archetype.path == path) {
        total += _archetypeLevel(archetype);
      }
    }
    // Devotion: Tier-up twice as fast
    if (devotion) {
      final dominant = dominantPath;
      if (dominant != null && path == dominant) {
        total *= 2;
      }
    }
    return total;
  }

  int get edgeLevel => pathLevels(SkillPath.edge);
  int get daemonLevel => pathLevels(SkillPath.daemon);
  int get hexLevel => pathLevels(SkillPath.hex);

  bool useBandwidth(double amount) {
    final cost = amount * daemonCostMultiplier;
    if (daemonBandwidth >= cost) {
      daemonBandwidth -= cost;
      notifyListeners();
      return true;
    }
    return false;
  }

  bool useCinder() {
    if (hexCinder >= 100.0) {
      hexCinder = 0.0;
      notifyListeners();
      return true;
    }
    return false;
  }

  PathTier getTier(SkillPath path) {

    final levels = pathLevels(path);
    if (levels >= PathTier.apex.requiredLevels) return PathTier.apex;
    if (levels >= PathTier.master.requiredLevels) return PathTier.master;
    if (levels >= PathTier.adept.requiredLevels) return PathTier.adept;
    if (levels >= PathTier.initiate.requiredLevels) return PathTier.initiate;
    return PathTier.none;
  }

  PathTier get edgeTier => getTier(SkillPath.edge);
  PathTier get daemonTier => getTier(SkillPath.daemon);
  PathTier get hexTier => getTier(SkillPath.hex);

  // DAEMON Operator (Tier 2) range bonus
  double get daemonRangeMultiplier =>
      daemonTier.index >= PathTier.adept.index ? 1.2 : 1.0;

  // Iaido Draw (EDGE Apex)
  double _iaidoTimer = 0;
  bool get canIaidoDraw =>
      edgeTier == PathTier.apex && _iaidoTimer >= 30.0;
  
  void triggerIaidoDraw() {
    _iaidoTimer = 0;
    notifyListeners();
  }

  // Network Crash (DAEMON Apex)
  bool _networkCrashUsedThisFloor = false;
  bool get canNetworkCrash =>
      daemonTier == PathTier.apex && !_networkCrashUsedThisFloor;

  void triggerNetworkCrash() {
    _networkCrashUsedThisFloor = true;
    notifyListeners();
  }

  // Satellite Uplink (DAEMON Master)
  double _satelliteTimer = 0;
  bool get canSatelliteUplink =>
      daemonTier.index >= PathTier.master.index && _satelliteTimer >= 3.0;

  void triggerSatelliteUplink() {
    _satelliteTimer = 0;
    notifyListeners();
  }

  double _goldBoostTimer = 0;
  void triggerGoldBoost(double duration) {
    _goldBoostTimer = math.max(_goldBoostTimer, duration);
    notifyListeners();
  }

  void update(double dt) {
    if (isRunOver) return;

    if (_goldBoostTimer > 0) {
      _goldBoostTimer -= dt;
    }

    if (edgeTier == PathTier.apex) {
      _iaidoTimer += dt;
    }
    if (daemonTier.index >= PathTier.master.index) {
      _satelliteTimer += dt;
    }

    if (activeModifiers.contains(FloorModifier.cipherStorm)) {
      _cipherStormTimer += dt;
      if (cipherStormImmunity == null || _cipherStormTimer >= 4.0) {
        _cipherStormTimer = 0;
        // Rotate through the offensive damage types only — basic stays
        // damage-able so the auto-attack never freezes out completely.
        const rotation = [
          DamageType.nova,
          DamageType.firewall,
          DamageType.meteor,
          DamageType.sentinel,
          DamageType.mothership,
          DamageType.rupture,
          DamageType.hex,
          DamageType.daemon,
        ];
        cipherStormImmunity = rotation[_cipherStormCursor % rotation.length];
        _cipherStormCursor++;
        notifyListeners();
      }
    } else if (cipherStormImmunity != null) {
      cipherStormImmunity = null;
      _cipherStormTimer = 0;
      notifyListeners();
    }

    if (!hasPendingLevelUp && !devPauseSpawning) {
      _updateFloorPhases(dt);
    }
  }

  void _updateFloorPhases(double dt) {
    floorTime += dt;

    if (isBossFloor) {
      if (floorPhase != FloorPhase.crucible && floorTime >= 22.0) {
        floorPhase = FloorPhase.crucible;
        notifyListeners();
      }
      return;
    }

    if (floorPhase == FloorPhase.trickle && floorTime >= 10.0) {
      floorPhase = FloorPhase.press;
      notifyListeners();
    } else if (floorPhase == FloorPhase.press && floorTime >= 22.0) {
      floorPhase = FloorPhase.crucible;
      crucibleEvent ??= CrucibleEvent.values[_rng.nextInt(CrucibleEvent.values.length)];
      _crucibleCleanRun = true;
      notifyListeners();
    } else if (floorPhase == FloorPhase.crucible && floorTime >= 32.0) {
      if (_crucibleCleanRun && !isBossFloor) {
        gold += 25;
      }
      _advanceFloor();
    }
  }

  void _advanceFloor() {
    killsOnFloor = 0;
    floor += 1;
    bossSpawned = false;
    floorTime = 0;
    floorPhase = FloorPhase.trickle;
    crucibleEvent = null;
    _networkCrashUsedThisFloor = false; // Reset for new floor
    cipherStormImmunity = null;
    _cipherStormTimer = 0;
    _cipherStormCursor = 0;

    activeModifiers.clear();
    if (!isBossFloor) {
      final count = _rng.nextInt(3); // 0 to 2 modifiers
      if (count > 0) {
        final pool = FloorModifier.values.toList()..shuffle(_rng);
        activeModifiers.addAll(pool.take(count));
      }
    }

    if (activeModifiers.contains(FloorModifier.manaBloom)) {
      hexCinder = 50.0;
    }

    if (!devDisableUpgrades) {
      _rollUpgradeChoices();
    }
    notifyListeners();
    _saveSoon();
  }

  SkillPath? get dominantPath {
    final pathScores = <SkillPath, int>{};
    for (final archetype in SkillArchetype.values) {
      final level = _archetypeLevel(archetype);
      if (level > 0) {
        pathScores[archetype.path] = (pathScores[archetype.path] ?? 0) + level;
      }
    }

    if (pathScores.isEmpty) return null;

    SkillPath? dominant;
    int maxScore = -1;
    for (final entry in pathScores.entries) {
      if (entry.value > maxScore) {
        maxScore = entry.value;
        dominant = entry.key;
      }
    }
    return dominant;
  }

  Color get nexusCoreColor {
    final path = dominantPath;
    return path?.color ?? const Color(0xFF00E5FF); // Default cyan
  }

  bool get isRunOver => nexusHp <= 0;

  bool get hasPendingLevelUp =>
      _pendingUpgradeIds.isNotEmpty ||
      _pendingFusionIds.isNotEmpty ||
      _pendingCantIds.isNotEmpty;
  List<SkillChoice> get pendingChoices =>
      _pendingUpgradeIds.map(_choiceFor).nonNulls.toList(growable: false);
  List<FusionChoice> get pendingFusionChoices => _pendingFusionIds
      .map((id) =>
          fusionCatalog.firstWhereOrNull((f) => f.id == id))
      .nonNulls
      .map((f) => FusionChoice(definition: f))
      .toList(growable: false);
  List<CantChoice> get pendingCantChoices => _pendingCantIds
      .map((id) =>
          hereticCantCatalog.firstWhereOrNull((c) => c.id == id))
      .nonNulls
      .map((c) => CantChoice(definition: c))
      .toList(growable: false);
  double get enemyMaxHp =>
      _baseEnemyHp * math.pow(_enemyHpGrowth, floor - 1) * devEnemyStrength;
  double get enemyBreachDamage {
    double dmg = (3 + floor * 0.5) * devEnemyStrength;
    if (bloodprice) dmg *= 1.5;
    return dmg;
  }
  int get goldPerKill {
    final base = _baseGoldPerKill * math.pow(_goldGrowth, floor - 1);
    final bountyEvo = getEvolution(SkillArchetype.bounty);
    final bountyMultiplier =
        (1 + bountyLevel * 0.08) * (bountyEvo == 1 ? 1.5 : 1.0);
    final streakMultiplier = 1 + _streakStacks * 0.1;
    final boostMultiplier = _goldBoostTimer > 0 ? 2.0 : 1.0;
    
    double cantMultiplier = 1.0;
    if (bloodprice) cantMultiplier *= 1.5;
    if (greedglyph) cantMultiplier *= 2.0;

    // Floors v1 §2: accepting a hard floor modifier (restriction or pressure)
    // boosts this floor's gold drop by 50%. Flat — doesn't stack with itself.
    final modifierMultiplier = hasHardFloorModifier ? 1.5 : 1.0;

    return (base * bountyMultiplier * streakMultiplier * boostMultiplier * cantMultiplier * modifierMultiplier).round();
  }

  // Restriction + pressure modifiers — anything that makes the floor harder.
  // Boons (echoTide, discountKit, manaBloom, glyphCache) are excluded.
  // Centralized here so adding a new modifier only requires updating one
  // place to opt it into the gold-bonus rule.
  static const Set<FloorModifier> _hardFloorModifiers = {
    FloorModifier.bandwidthBlackout,
    FloorModifier.cinderDamp,
    FloorModifier.stanceStutter,
    FloorModifier.quickening,
    FloorModifier.solarFlare,
    FloorModifier.veilOfAsh,
    FloorModifier.hereticTide,
    FloorModifier.cipherStorm,
  };

  // True when at least one "hard" floor modifier (restriction or pressure)
  // is active.
  bool get hasHardFloorModifier =>
      activeModifiers.any(_hardFloorModifiers.contains);

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
        heroDamage * heroAttacksPerSec * math.max(1, emberTargets * 0.65);
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

  void registerKill({bool isBoss = false}) {
    if (isRunOver) return;
    final now = DateTime.now();

    if (meta.hasKeystone('streak')) {
      if (_lastKillAt != null &&
          now.difference(_lastKillAt!).inMilliseconds <= 1000) {
        _streakStacks = (_streakStacks + 1).clamp(0, 5);
      } else {
        _streakStacks = 0;
      }
    }

    double multiplier = 1.0;
    if (meta.hasSutraPerk(SkillArchetype.bounty, 25)) {
      if (_lastKillAt != null &&
          now.difference(_lastKillAt!).inMilliseconds <= 2000) {
        _bountyStreakStacks++;
      } else {
        _bountyStreakStacks = 0;
      }
      multiplier += _bountyStreakStacks * 0.05;
    }
    _lastKillAt = now;

    // Path Signature Resources
    if (daemonLevel > 0) {
      daemonBandwidth = (daemonBandwidth + 5.0).clamp(0.0, 100.0);
    }
    if (hexLevel > 0) {
      final cinderAmount = activeModifiers.contains(FloorModifier.cinderDamp) ? 2.0 : 4.0;
      hexCinder = (hexCinder + cinderAmount).clamp(0.0, 100.0);
    }

    gold += (goldPerKill * multiplier).round();
    killsOnFloor += 1;
    runKills += 1;
    lifetimeKills += 1;

    if (isBossFloor && isBoss) {
      isBossActive = false;
      _grantBossReward(floor);

      if (floor == 10 || floor == 20) {
        pendingFloorReward = true;
        floorRewardChoices = _rollFloorBoonChoices();
      } else {
        _advanceFloor();
      }
    }

    notifyListeners();
    _saveSoon();
  }

  // Tiered boss-floor rewards. Called once per boss kill, before the floor
  // advances. Sets lastBossRewardLabel for the HUD toast and dispatches the
  // actual rewards (embers, sutras, fusion guarantees) into meta state.
  void _grantBossReward(int floorBeingCleared) {
    switch (floorBeingCleared) {
      case 5:
        meta.awardEmbers(50);
        lastBossRewardLabel = 'WATCHER DEFEATED';
        lastBossRewardSubtitle = '+50 embers';
      case 10:
        // F10 Reward: +1 Sutra mark of player's choice
        pendingSutraReward = true;
        sutraRewardChoices = _rollSutraChoices();
        lastBossRewardLabel = 'SOVEREIGN DEFEATED';
        lastBossRewardSubtitle = 'Choose +1 Sutra Mark';
      case 15:
        // F15 Reward: +1 Codex peek (reveal one undiscovered Inflection or Triad)
        final undiscovered = <String>[];
        for (final inf in inflectionCatalog) {
          if (!meta.discoveredIds.contains(inf.id)) undiscovered.add(inf.id);
        }
        for (final triad in triadCatalog) {
          if (!meta.discoveredIds.contains(triad.id)) undiscovered.add(triad.id);
        }

        if (undiscovered.isNotEmpty) {
          final targetId = undiscovered[_rng.nextInt(undiscovered.length)];
          meta.recordDiscovery(targetId);
          
          String name = 'Unknown';
          final infMatch = inflectionCatalog.firstWhereOrNull((i) => i.id == targetId);
          if (infMatch != null) {
            name = infMatch.name;
          } else {
            final triadMatch = triadCatalog.firstWhereOrNull((t) => t.id == targetId);
            if (triadMatch != null) name = triadMatch.name;
          }

          lastBossRewardLabel = 'HIVEFATHER DEFEATED';
          lastBossRewardSubtitle = 'Codex Peek: Revealed $name';
        } else {
          // Fallback if everything is already discovered
          meta.awardEmbers(100);
          lastBossRewardLabel = 'HIVEFATHER DEFEATED';
          lastBossRewardSubtitle = '+100 embers';
        }
      case 20:
        // F20 Reward: Free Fusion offer at next level-up
        _forceFusionNext = true;
        lastBossRewardLabel = 'CIPHER TWIN DEFEATED';
        lastBossRewardSubtitle = 'Fusion offer guaranteed at next level-up';
      case 25:
        // F25 Reward: Permanent meta unlock
        final unlock = meta.claimNextF25Unlock();
        if (unlock != null) {
          lastBossRewardLabel = 'ARCHITECT DEFEATED';
          lastBossRewardSubtitle = 'PERMANENT UNLOCK: $unlock';
        } else {
          // Fallback if all permanent rewards are already unlocked
          meta.awardEmbers(500);
          lastBossRewardLabel = 'ARCHITECT DEFEATED';
          lastBossRewardSubtitle = '+500 embers';
        }
      default:
        // Architect respawns on floors 30+. Scale a smaller ember reward so
        // late-game grinding still pays out without dwarfing the F25 trophy.
        final reward = 50 + floorBeingCleared * 5;
        meta.awardEmbers(reward);
        lastBossRewardLabel = 'BOSS DEFEATED';
        lastBossRewardSubtitle = '+$reward embers';
    }
  }

  List<SkillArchetype> _rollSutraChoices() {
    // 3 archetypes the player owns, or all if none/few owned
    final owned = <SkillArchetype>[];
    for (final archetype in SkillArchetype.values) {
      if (_archetypeLevel(archetype) > 0 && meta.sutraCount(archetype) < 25) {
        owned.add(archetype);
      }
    }

    if (owned.length <= 3) {
      if (owned.isEmpty) {
        // If none owned (rare at F10), show some random ones
        return (SkillArchetype.values.toList()..shuffle(_rng)).take(3).toList();
      }
      return owned;
    }

    owned.shuffle(_rng);
    return owned.take(3).toList();
  }

  void resolveSutraReward(SkillArchetype archetype) {
    meta.incrementSutra(archetype);
    pendingSutraReward = false;
    sutraRewardChoices = [];
    notifyListeners();
  }

  List<FloorBoon> _rollFloorBoonChoices() {
    final pool = FloorBoon.values.toList()..shuffle(_rng);
    return pool.take(3).toList();
  }

  void resolveFloorReward(FloorBoon boon) {
    _applyFloorBoon(boon);
    pendingFloorReward = false;
    floorRewardChoices = [];
    _advanceFloor();
    notifyListeners();
  }

  void _applyFloorBoon(FloorBoon boon) {
    switch (boon) {
      case FloorBoon.nexusHpBoost:
        _nexusMaxHp *= 1.05;
        nexusHp = math.min(nexusMaxHp, nexusHp + nexusMaxHp * 0.05);
      case FloorBoon.rerollPlus1:
        rerollsRemaining += 1;
      case FloorBoon.gold25:
        gold += 25;
      case FloorBoon.randomSutra:
        final archetype = _randomOwnedArchetype();
        meta.incrementSutra(archetype);
      case FloorBoon.revealModifier:
        _revealNextModifier = true;
      case FloorBoon.halveCantCost:
        _halveNextCantCost = true;
      case FloorBoon.skipNextCant:
        _skipNextCant = true;
    }
  }

  SkillArchetype _randomOwnedArchetype() {
    final owned = SkillArchetype.values.where((a) => _archetypeLevel(a) > 0).toList();
    if (owned.isEmpty) return SkillArchetype.values[_rng.nextInt(SkillArchetype.values.length)];
    return owned[_rng.nextInt(owned.length)];
  }

  void clearBossReward() {
    if (lastBossRewardLabel == null) return;
    lastBossRewardLabel = null;
    lastBossRewardSubtitle = null;
    notifyListeners();
  }

  SkillPath? _lastPathPicked;

  void selectUpgrade(String id, {String? inflectionId}) {
    if (isRunOver || !_pendingUpgradeIds.contains(id) || _isMaxed(id)) return;
    meta.recordDiscovery(id);
    if (inflectionId != null) {
      meta.recordDiscovery('inflection:$inflectionId');
      _selectedInflections.putIfAbsent(id, () => []).add(inflectionId);
    }
    final nextLevel = skillLevel(id) + 1;
    _skillLevels[id] = nextLevel;
    levelUpCount += 1;

    final definition = _skillById(id);
    if (definition != null) {
      _lastPathPicked = definition.archetype.path;
      if (nextLevel == 5) {
        pendingEvolutionArchetype = definition.archetype;
      }
    }

    if (lockedUpgradeId == id) lockedUpgradeId = null;
    _checkTriads();
    _clearPending();
    notifyListeners();
    _saveSoon();
  }

  void selectEvolution(int path) {
    if (pendingEvolutionArchetype == null) return;
    meta.recordDiscovery('${pendingEvolutionArchetype!.name}:$path');
    _evolutions[pendingEvolutionArchetype!] = path;
    pendingEvolutionArchetype = null;
    _checkTriads();
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
    _checkTriads();
    notifyListeners();
    _saveSoon();
  }

  void devGrantRandomInflection(String skillId) {
    final def = _skillById(skillId);
    if (def == null) return;
    
    final owned = _selectedInflections[skillId] ?? [];
    final pool = inflectionCatalog
        .where((inf) => inf.archetype == def.archetype && !owned.contains(inf.id))
        .toList();
        
    if (pool.isEmpty) return;
    final inf = pool[_rng.nextInt(pool.length)];
    _selectedInflections.putIfAbsent(skillId, () => []).add(inf.id);
    meta.recordDiscovery('inflection:${inf.id}');
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
    floor = math.max(1, floor + floors);
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

  void forceCantOffer() {
    if (_pendingCantIds.isEmpty && !hasCant('greedglyph')) {
      final pool = hereticCantCatalog.where((c) => !_activeCantIds.contains(c.id)).toList();
      pool.shuffle(_rng);
      _pendingCantIds = pool.take(3).map((c) => c.id).toList();
      _pendingUpgradeIds = [];
      _pendingFusionIds = [];
      if (hasPendingLevelUp) {
        _startAutoSelectTimer();
      } else {
        notifyListeners();
      }
    }
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

  void selectFusion(String id) {
    if (isRunOver || !_pendingFusionIds.contains(id)) return;
    meta.recordDiscovery(id);
    _ownedFusionIds.add(id);
    _clearPending();
    notifyListeners();
    _saveSoon();
  }

  bool _forceFusionNext = false;
  bool _revealNextModifier = false;
  bool _halveNextCantCost = false;
  bool _skipNextCant = false;

  void selectCant(String id) {
    if (isRunOver || !_pendingCantIds.contains(id)) return;
    _activeCantIds.add(id);

    if (id == 'heretic_bargain' && !activeModifiers.contains(FloorModifier.discountKit)) {
      nexusHp = math.max(0, nexusHp - nexusMaxHp * 0.2);
      _forceFusionNext = true;
    } else if (id == 'heretic_bargain') {
      _forceFusionNext = true;
    }

    _clearPending();
    notifyListeners();
    _saveSoon();
  }

  void _clearPending() {
    _pendingUpgradeIds = [];
    _pendingFusionIds = [];
    _pendingCantIds = [];
    autoSelectSecondsRemaining = null;
    _autoSelectTimer?.cancel();
    _autoSelectTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  int skillLevel(String id) => _skillLevels[id] ?? 0;

  void damageNexus(double amount) {
    if (isRunOver || amount <= 0 || godMode) return;
    nexusHp = math.max(0, math.min(nexusMaxHp, nexusHp) - amount);
    if (floorPhase == FloorPhase.crucible) {
      _crucibleCleanRun = false;
    }
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

    // Award Sutra marks for all evolved archetypes in this run
    for (final archetype in _evolutions.keys) {
      meta.incrementSutra(archetype);
    }

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
    _iaidoTimer = 0;
    _satelliteTimer = 0;
    _networkCrashUsedThisFloor = false;
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
    // Every 5 floors (or if Heretic Tide is active), offer Heretic Cants instead of normal upgrades
    bool offerCants = (floor % 5 == 0 || activeModifiers.contains(FloorModifier.hereticTide));
    if (offerCants && _pendingCantIds.isEmpty && !hasCant('greedglyph')) {
      final pool = hereticCantCatalog.where((c) => !_activeCantIds.contains(c.id)).toList();
      pool.shuffle(_rng);
      _pendingCantIds = pool.take(3).map((c) => c.id).toList();
      _pendingUpgradeIds = [];
      _pendingFusionIds = [];
      if (hasPendingLevelUp) {
        _startAutoSelectTimer();
      }
      return;
    }

    _pendingCantIds = [];
    final offerCount = meta.widerPick ? 4 : 3;

    // Check for Fusion eligibility
    final evolvedPaths = <SkillPath>{};
    for (final archetype in SkillArchetype.values) {
      if (skillLevel(archetype.name) >= 5 && getEvolution(archetype) > 0) {
        evolvedPaths.add(archetype.path);
      }
    }

    final eligibleFusions = fusionCatalog.where((f) =>
        !_ownedFusionIds.contains(f.id) &&
        f.paths.every((p) => evolvedPaths.contains(p))).toList();

    // 15% base chance for a Fusion offer if eligible, or forced by Bargain
    if (eligibleFusions.isNotEmpty && (_rng.nextDouble() < 0.15 || _forceFusionNext)) {
      _forceFusionNext = false;
      _pendingFusionIds = [eligibleFusions[_rng.nextInt(eligibleFusions.length)].id];
      _pendingUpgradeIds = [];
      if (hasPendingLevelUp) {
        _startAutoSelectTimer();
      }
      return;
    }

    _pendingFusionIds = [];

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

    // Capstone unlock: tier Master (12) in that path
    if (edgeTier.index >= PathTier.master.index) unlockedArchetypes.add(SkillArchetype.rupture);
    if (daemonTier.index >= PathTier.master.index) unlockedArchetypes.add(SkillArchetype.bounty);
    if (hexTier.index >= PathTier.master.index) unlockedArchetypes.add(SkillArchetype.summon);

    // Devotion: Restricted to dominant path if it exists
    if (devotion) {
      final dominant = dominantPath;
      if (dominant != null) {
        unlockedArchetypes.removeWhere((a) => a.path != dominant);
      }
    }

    // Diaspora: Exclude last path picked if multiple paths available
    if (diaspora && _lastPathPicked != null) {
      final otherPaths = unlockedArchetypes.map((a) => a.path).toSet();
      if (otherPaths.length > 1) {
        unlockedArchetypes.removeWhere((a) => a.path == _lastPathPicked);
      }
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

    if (activeModifiers.contains(FloorModifier.glyphCache)) {
      // Find a skill that can be upgraded with an inflection and hasn't been yet
      final ownedKeys = _skillLevels.keys.where((k) => _skillLevels[k]! >= 1 && _skillLevels[k]! < 5).toList();
      if (ownedKeys.isNotEmpty) {
        final skillId = ownedKeys[_rng.nextInt(ownedKeys.length)];
        final def = _skillById(skillId);
        if (def != null) {
          final owned = _selectedInflections[skillId] ?? [];
          final pool = inflectionCatalog
              .where((inf) => inf.archetype == def.archetype && !owned.contains(inf.id))
              .toList();
          if (pool.isNotEmpty) {
            final inf = pool[_rng.nextInt(pool.length)];
            _selectedInflections.putIfAbsent(skillId, () => []).add(inf.id);
            meta.recordDiscovery('inflection:${inf.id}');
          }
        }
      }
    }

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
    final definition = findSkillById(id);
    
    // Peaks around level 2 (commitment reward), then decays.
    // 1.0 floor ensures everything stays in the pool.
    double weight = 1.0 + 5.0 * level * math.exp(-level / 1.5);

    // Near-orbit nudge: multiply weight if picking this completes a synergy
    if (level == 0 && definition != null) {
      if (_completesSynergyIfPicked(definition.archetype)) {
        weight *= 1.5;
      }
    }

    // Cooldown on recently offered
    if (_recentlyOfferedIds.contains(id)) {
      weight *= 0.5;
    }

    return weight;
  }

  bool _completesSynergyIfPicked(SkillArchetype archetype) {
    // Check if any synergy partner is already owned
    final partners = switch (archetype) {
      SkillArchetype.frost => [SkillArchetype.rupture],
      SkillArchetype.rupture => [SkillArchetype.frost, SkillArchetype.bounty],
      SkillArchetype.chain => [SkillArchetype.nova],
      SkillArchetype.nova => [SkillArchetype.chain],
      SkillArchetype.meteor => [SkillArchetype.firewall],
      SkillArchetype.firewall => [SkillArchetype.meteor],
      SkillArchetype.sentinel => [SkillArchetype.barrage],
      SkillArchetype.barrage => [SkillArchetype.sentinel],
      SkillArchetype.bounty => [
        SkillArchetype.rupture,
        SkillArchetype.mothership,
        SkillArchetype.snake
      ],
      SkillArchetype.mothership => [SkillArchetype.bounty, SkillArchetype.summon],
      SkillArchetype.summon => [SkillArchetype.mothership],
      SkillArchetype.snake => [SkillArchetype.bounty],
      _ => <SkillArchetype>[],
    };

    return partners.any((p) => _archetypeLevel(p) >= 1);
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

    List<InflectionDefinition> options = [];
    if (currentLevel >= 1) {
      final pool = inflectionCatalog
          .where((inf) => inf.archetype == definition.archetype)
          .toList();
      pool.shuffle(_rng);
      options = pool.take(2).toList();
    }

    return SkillChoice(
      definition: definition,
      currentLevel: currentLevel,
      level: nextLevel,
      maxLevel: SkillDefinition.maxLevel,
      description: definition.descriptionForLevel(nextLevel),
      inflectionOptions: options,
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
        _skillLevels[entry.value] = math.max(_skillLevels[entry.value] ?? 0, level);
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
