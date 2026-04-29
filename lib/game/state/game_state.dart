import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameState extends ChangeNotifier {
  int gold = 0;
  int floor = 1;
  int killsOnFloor = 0;
  int damageLevel = 1;
  int attackSpeedLevel = 1;
  int lastIdleReward = 0;

  static const int killsPerFloor = 10;
  static const double _baseDamage = 5;
  static const double _damagePerLevel = 2;
  static const double _baseAttacksPerSec = 1;
  static const double _attackSpeedPerLevel = 0.1;
  static const int _baseDamageCost = 10;
  static const int _baseAttackSpeedCost = 15;
  static const double _upgradeCostGrowth = 1.5;
  static const double _enemyHpGrowth = 1.25;
  static const double _goldGrowth = 1.15;
  static const double _baseEnemyHp = 10;
  static const int _baseGoldPerKill = 1;
  static const double _idleEfficiency = 0.5;
  static const int _idleCapSeconds = 8 * 3600;

  double get heroDamage => _baseDamage + _damagePerLevel * (damageLevel - 1);
  double get heroAttacksPerSec =>
      _baseAttacksPerSec + _attackSpeedPerLevel * (attackSpeedLevel - 1);
  double get enemyMaxHp => _baseEnemyHp * pow(_enemyHpGrowth, floor - 1);
  int get goldPerKill =>
      (_baseGoldPerKill * pow(_goldGrowth, floor - 1)).round();
  int get damageUpgradeCost =>
      (_baseDamageCost * pow(_upgradeCostGrowth, damageLevel - 1)).round();
  int get attackSpeedUpgradeCost =>
      (_baseAttackSpeedCost * pow(_upgradeCostGrowth, attackSpeedLevel - 1))
          .round();

  void registerKill() {
    gold += goldPerKill;
    killsOnFloor += 1;
    if (killsOnFloor >= killsPerFloor) {
      killsOnFloor = 0;
      floor += 1;
    }
    notifyListeners();
    _saveSoon();
  }

  bool buyDamage() {
    if (gold < damageUpgradeCost) return false;
    gold -= damageUpgradeCost;
    damageLevel += 1;
    notifyListeners();
    _saveSoon();
    return true;
  }

  bool buyAttackSpeed() {
    if (gold < attackSpeedUpgradeCost) return false;
    gold -= attackSpeedUpgradeCost;
    attackSpeedLevel += 1;
    notifyListeners();
    _saveSoon();
    return true;
  }

  void clearIdleReward() {
    if (lastIdleReward == 0) return;
    lastIdleReward = 0;
    notifyListeners();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    gold = prefs.getInt(_kGold) ?? 0;
    floor = prefs.getInt(_kFloor) ?? 1;
    killsOnFloor = prefs.getInt(_kKills) ?? 0;
    damageLevel = prefs.getInt(_kDamageLevel) ?? 1;
    attackSpeedLevel = prefs.getInt(_kAtkSpeedLevel) ?? 1;
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
    await prefs.setInt(_kDamageLevel, damageLevel);
    await prefs.setInt(_kAtkSpeedLevel, attackSpeedLevel);
    await _writeLastSeen(prefs);
  }

  int _computeIdleReward(DateTime lastSeen) {
    final seconds =
        DateTime.now().difference(lastSeen).inSeconds.clamp(0, _idleCapSeconds);
    if (seconds <= 0) return 0;
    final timeToKill = enemyMaxHp / (heroDamage * heroAttacksPerSec);
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
  static const _kDamageLevel = 'damageLevel';
  static const _kAtkSpeedLevel = 'attackSpeedLevel';
  static const _kLastSeen = 'lastSeenAt';
}
