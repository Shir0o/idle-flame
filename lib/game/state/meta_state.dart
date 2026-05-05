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
    notifyListeners();
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
  }

  Future<void> wipe() async {
    embers = 0;
    lastEmbersEarned = 0;
    _upgradeTiers.clear();
    _keystones.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kEmbers);
    await prefs.remove(_kUpgrades);
    await prefs.remove(_kKeystones);
    notifyListeners();
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
}
