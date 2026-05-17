import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'meta_catalog.dart';
import 'skill_catalog.dart';

class MetaState extends ChangeNotifier {
  int embers = 0;
  int lifetimeEmbers = 0;
  int lastEmbersEarned = 0;
  final Map<String, int> _upgradeTiers = {};
  final Set<String> _keystones = {};
  final Set<String> _discoveredIds = {};
  final Map<SkillArchetype, int> _sutras = {};
  final Map<SkillPath, bool> _awakenings = {};
  final Set<String> _f25Unlocks = {};

  // Floors v3 §5 — Daily Descent. Keyed by `YYYY-MM-DD` UTC. Records the
  // best peak floor and embers earned for each date the player attempted.
  final Map<String, ({int floor, int embers})> _dailyBests = {};

  Set<String> get discoveredIds => Set.unmodifiable(_discoveredIds);
  Set<String> get f25Unlocks => Set.unmodifiable(_f25Unlocks);
  Map<String, ({int floor, int embers})> get dailyBests =>
      Map.unmodifiable(_dailyBests);

  static String currentDailyKey() {
    final now = DateTime.now().toUtc();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void recordDailyBest(String key, int floor, int embers) {
    final existing = _dailyBests[key];
    if (existing == null ||
        floor > existing.floor ||
        (floor == existing.floor && embers > existing.embers)) {
      _dailyBests[key] = (floor: floor, embers: embers);
      notifyListeners();
      _save();
    }
  }

  static const List<String> f25UnlockPool = [
    'Nexus Skin: Obsidian',
    'Heretic Cant Slot +1',
    'Starting Reroll +1',
    'Starting Banish +1',
    'Echo-Resonance Kit',
  ];

  String? claimNextF25Unlock() {
    for (final unlock in f25UnlockPool) {
      if (!_f25Unlocks.contains(unlock)) {
        _f25Unlocks.add(unlock);
        notifyListeners();
        _save();
        return unlock;
      }
    }
    return null; // All unlocked
  }

  int sutraCount(SkillArchetype archetype) => _sutras[archetype] ?? 0;
  bool hasSutraPerk(SkillArchetype archetype, int mark) =>
      sutraCount(archetype) >= mark;
  bool isAwakened(SkillPath path) => _awakenings[path] ?? false;

  bool recordDiscovery(String id, {int reward = 5}) {
    if (!_discoveredIds.contains(id)) {
      _discoveredIds.add(id);
      embers += reward; // Reward for new discovery
      notifyListeners();
      _save();
      return true;
    }
    return false;
  }

  void incrementSutra(SkillArchetype archetype) {
    final current = sutraCount(archetype);
    if (current < 25) {
      _sutras[archetype] = current + 1;
      notifyListeners();
      _save();
    }
  }

  void awakenPath(SkillPath path) {
    if (isAwakened(path)) return;

    // Verify all archetypes in path are at Sutra 25
    bool eligible = true;
    for (final archetype in SkillArchetype.values) {
      if (archetype.path == path && sutraCount(archetype) < 25) {
        eligible = false;
        break;
      }
    }

    if (eligible) {
      _awakenings[path] = true;
      // Reset Sutras for this path
      for (final archetype in SkillArchetype.values) {
        if (archetype.path == path) {
          _sutras[archetype] = 0;
        }
      }
      notifyListeners();
      _save();
    }
  }

  int upgradeTier(String id) => _upgradeTiers[id] ?? 0;
  bool hasKeystone(String id) => _keystones.contains(id);
  bool hasKeystoneFor(SkillArchetype archetype) {
    for (final k in keystoneCatalog) {
      if (k.archetype == archetype && _keystones.contains(k.id)) return true;
    }
    return false;
  }

  bool get widerPick => upgradeTier('wider_pick') > 0;
  int get rerollsPerRun => upgradeTier('reroll');
  int get banishesPerRun => upgradeTier('banish');
  bool get lockEnabled => upgradeTier('lock') > 0;
  bool get rareCadence => upgradeTier('rare_cadence') > 0;
  bool get prePick => upgradeTier('pre_pick') > 0;

  bool canPurchaseUpgrade(MetaUpgradeDef def) {
    final tier = upgradeTier(def.id);
    if (tier >= def.maxTier) return false;
    return embers >= def.costForTier(tier + 1);
  }

  bool purchaseUpgrade(MetaUpgradeDef def) {
    final tier = upgradeTier(def.id);
    if (tier >= def.maxTier) return false;
    final cost = def.costForTier(tier + 1);
    if (embers < cost) return false;
    embers -= cost;
    _upgradeTiers[def.id] = tier + 1;
    notifyListeners();
    _save();
    return true;
  }

  bool canPurchaseKeystone(KeystoneDef def) {
    if (_keystones.contains(def.id)) return false;
    return embers >= def.cost;
  }

  bool purchaseKeystone(KeystoneDef def) {
    if (_keystones.contains(def.id)) return false;
    if (embers < def.cost) return false;
    embers -= def.cost;
    _keystones.add(def.id);
    notifyListeners();
    _save();
    return true;
  }

  void awardEmbers(int amount) {
    if (amount <= 0) return;
    embers += amount;
    lifetimeEmbers += amount;
    lastEmbersEarned = amount;
    notifyListeners();
    _save();
  }

  void devGrantEmbers(int amount) {
    embers += amount;
    lifetimeEmbers += amount;
    notifyListeners();
    _save();
  }

  void devResetEmbers() {
    embers = 0;
    notifyListeners();
    _save();
  }

  void devMaxAll() {
    for (final def in metaUpgradeCatalog) {
      _upgradeTiers[def.id] = def.maxTier;
    }
    for (final def in keystoneCatalog) {
      _keystones.add(def.id);
    }
    notifyListeners();
    _save();
  }

  void devResetAll() {
    _upgradeTiers.clear();
    _keystones.clear();
    notifyListeners();
    _save();
  }

  void clearLastEmbersEarned() {
    if (lastEmbersEarned == 0) return;
    lastEmbersEarned = 0;
    notifyListeners();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    embers = prefs.getInt(_kEmbers) ?? 0;
    lifetimeEmbers = prefs.getInt(_kLifetimeEmbers) ?? embers;
    _upgradeTiers
      ..clear()
      ..addAll(_decode(prefs.getStringList(_kUpgrades)));
    _keystones
      ..clear()
      ..addAll(prefs.getStringList(_kKeystones) ?? const []);
    _discoveredIds
      ..clear()
      ..addAll(prefs.getStringList(_kDiscovered) ?? const []);
    _sutras
      ..clear()
      ..addAll(_decodeSutras(prefs.getStringList(_kSutras)));
    _awakenings
      ..clear()
      ..addAll(_decodeAwakenings(prefs.getStringList(_kAwakenings)));
    _f25Unlocks
      ..clear()
      ..addAll(prefs.getStringList(_kF25Unlocks) ?? const []);
    _dailyBests
      ..clear()
      ..addAll(_decodeDailyBests(prefs.getStringList(_kDailyBests)));
    notifyListeners();
  }

  Map<String, ({int floor, int embers})> _decodeDailyBests(
    List<String>? encoded,
  ) {
    final map = <String, ({int floor, int embers})>{};
    for (final item in encoded ?? const <String>[]) {
      final parts = item.split('|');
      if (parts.length != 3) continue;
      final floor = int.tryParse(parts[1]);
      final embers = int.tryParse(parts[2]);
      if (floor == null || embers == null) continue;
      map[parts[0]] = (floor: floor, embers: embers);
    }
    return map;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kEmbers, embers);
    await prefs.setInt(_kLifetimeEmbers, lifetimeEmbers);
    await prefs.setStringList(
      _kUpgrades,
      _upgradeTiers.entries
          .where((e) => e.value > 0)
          .map((e) => '${e.key}:${e.value}')
          .toList(),
    );
    await prefs.setStringList(_kKeystones, _keystones.toList());
    await prefs.setStringList(_kDiscovered, _discoveredIds.toList());
    await prefs.setStringList(
      _kSutras,
      _sutras.entries.map((e) => '${e.key.name}:${e.value}').toList(),
    );
    await prefs.setStringList(
      _kAwakenings,
      _awakenings.entries.where((e) => e.value).map((e) => e.key.name).toList(),
    );
    await prefs.setStringList(_kF25Unlocks, _f25Unlocks.toList());
    await prefs.setStringList(
      _kDailyBests,
      _dailyBests.entries
          .map((e) => '${e.key}|${e.value.floor}|${e.value.embers}')
          .toList(),
    );
  }

  Future<void> wipe() async {
    embers = 0;
    lastEmbersEarned = 0;
    _upgradeTiers.clear();
    _keystones.clear();
    _discoveredIds.clear();
    _sutras.clear();
    _awakenings.clear();
    _f25Unlocks.clear();
    _dailyBests.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kEmbers);
    await prefs.remove(_kUpgrades);
    await prefs.remove(_kKeystones);
    await prefs.remove(_kDiscovered);
    await prefs.remove(_kSutras);
    await prefs.remove(_kAwakenings);
    await prefs.remove(_kF25Unlocks);
    await prefs.remove(_kDailyBests);
    notifyListeners();
  }

  Map<SkillArchetype, int> _decodeSutras(List<String>? encoded) {
    final map = <SkillArchetype, int>{};
    for (final item in encoded ?? const <String>[]) {
      final i = item.lastIndexOf(':');
      if (i <= 0) continue;
      final name = item.substring(0, i);
      final count = int.tryParse(item.substring(i + 1));
      if (count == null) continue;
      final archetype = SkillArchetype.values.firstWhereOrNull(
        (a) => a.name == name,
      );
      if (archetype != null) map[archetype] = count;
    }
    return map;
  }

  Map<SkillPath, bool> _decodeAwakenings(List<String>? encoded) {
    final map = <SkillPath, bool>{};
    for (final name in encoded ?? const <String>[]) {
      final path = SkillPath.values.firstWhereOrNull((p) => p.name == name);
      if (path != null) map[path] = true;
    }
    return map;
  }

  Map<String, int> _decode(List<String>? encoded) {
    final map = <String, int>{};
    for (final item in encoded ?? const <String>[]) {
      final i = item.lastIndexOf(':');
      if (i <= 0) continue;
      final id = item.substring(0, i);
      final tier = int.tryParse(item.substring(i + 1));
      if (tier == null || tier <= 0) continue;
      map[id] = tier;
    }
    return map;
  }

  static const _kEmbers = 'meta_embers';
  static const _kLifetimeEmbers = 'meta_lifetime_embers';
  static const _kUpgrades = 'meta_upgrades';
  static const _kKeystones = 'meta_keystones';
  static const _kDiscovered = 'meta_discovered';
  static const _kSutras = 'meta_sutras';
  static const _kAwakenings = 'meta_awakenings';
  static const _kF25Unlocks = 'meta_f25_unlocks';
  static const _kDailyBests = 'meta_daily_bests';
}
