import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class CompletionResult {
  const CompletionResult({
    required this.points,
    required this.leveledUp,
    required this.level,
  });

  final int points;
  final bool leveledUp;
  final int level;
}

/// Holds all app data, saves it locally, and notifies the UI on change.
class AppState extends ChangeNotifier {
  AppState(this._prefs) {
    _load();
  }

  static const _storageKey = 'focusup_v1';

  /// Points per day that count as a "good day".
  static const dailyGoal = 100;

  final SharedPreferences _prefs;
  final List<FocusTask> _tasks = [];
  final List<Redemption> _redemptions = [];
  int _totalEarned = 0;
  int _spent = 0;
  int _streak = 0;
  int _bestStreak = 0;
  String? _lastActiveDay;

  // ---- Read access -------------------------------------------------------

  int get totalEarned => _totalEarned;

  /// Points available to spend on rewards.
  int get balance => _totalEarned - _spent;

  int get bestStreak => _bestStreak;

  /// Current streak; resets to 0 if you missed yesterday and haven't done
  /// anything yet today.
  int get streak {
    final last = _lastActiveDay;
    if (last == null) return 0;
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    if (last == dayKey(now) || last == dayKey(yesterday)) return _streak;
    return 0;
  }

  List<FocusTask> get pendingTasks =>
      _tasks.where((t) => !t.isDone).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  List<FocusTask> get completedToday {
    final today = dayKey(DateTime.now());
    return _tasks
        .where((t) => t.isDone && dayKey(t.completedAt!) == today)
        .toList()
      ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
  }

  int get todayPoints => completedToday.fold<int>(0, (s, t) => s + t.points);

  int get tasksDone => _tasks.where((t) => t.isDone).length;

  int get minutesFocused =>
      _tasks.where((t) => t.isDone).fold<int>(0, (s, t) => s + t.minutes);

  List<Redemption> get redemptions => List.unmodifiable(_redemptions);

  /// The last [n] calendar days, oldest first, ending today.
  List<DateTime> lastDates(int n) {
    final now = DateTime.now();
    return List.generate(
      n,
      (i) => DateTime(now.year, now.month, now.day - (n - 1 - i)),
    );
  }

  /// Points earned on each of the last [n] days, oldest first.
  List<int> pointsLastDays(int n) {
    return lastDates(n).map((d) {
      final key = dayKey(d);
      return _tasks
          .where((t) => t.isDone && dayKey(t.completedAt!) == key)
          .fold<int>(0, (s, t) => s + t.points);
    }).toList();
  }

  // ---- Actions -----------------------------------------------------------

  FocusTask addTask(String title, TaskCategory category, int minutes) {
    final now = DateTime.now();
    final task = FocusTask(
      id: now.microsecondsSinceEpoch.toString(),
      title: title.trim(),
      category: category,
      minutes: minutes,
      points: pointsFor(minutes, category),
      createdAt: now,
    );
    _tasks.add(task);
    _commit();
    return task;
  }

  /// Only unfinished tasks can be deleted, so points can't be farmed or
  /// erased after the fact.
  void deleteTask(String id) {
    _tasks.removeWhere((t) => t.id == id && !t.isDone);
    _commit();
  }

  CompletionResult? completeTask(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1 || _tasks[index].isDone) return null;

    final task = _tasks[index];
    final levelBefore = levelInfo(_totalEarned).level;
    final now = DateTime.now();

    task.completedAt = now;
    _totalEarned += task.points;
    _updateStreak(now);

    final levelAfter = levelInfo(_totalEarned).level;
    _commit();
    return CompletionResult(
      points: task.points,
      leveledUp: levelAfter > levelBefore,
      level: levelAfter,
    );
  }

  /// Returns false if there aren't enough points.
  bool redeem(Reward reward) {
    if (balance < reward.cost) return false;
    _spent += reward.cost;
    _redemptions.add(
      Redemption(title: reward.title, cost: reward.cost, at: DateTime.now()),
    );
    _commit();
    return true;
  }

  // ---- Internals ---------------------------------------------------------

  void _updateStreak(DateTime now) {
    final today = dayKey(now);
    if (_lastActiveDay == today) return;
    final yesterday = dayKey(DateTime(now.year, now.month, now.day - 1));
    _streak = _lastActiveDay == yesterday ? _streak + 1 : 1;
    _lastActiveDay = today;
    if (_streak > _bestStreak) _bestStreak = _streak;
  }

  void _commit() {
    _save();
    notifyListeners();
  }

  void _save() {
    final data = {
      'tasks': _tasks.map((t) => t.toJson()).toList(),
      'redemptions': _redemptions.map((r) => r.toJson()).toList(),
      'totalEarned': _totalEarned,
      'spent': _spent,
      'streak': _streak,
      'bestStreak': _bestStreak,
      'lastActiveDay': _lastActiveDay,
    };
    _prefs.setString(_storageKey, jsonEncode(data));
  }

  void _load() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null) {
      _seed();
      return;
    }
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _tasks.addAll(
        (data['tasks'] as List)
            .map((e) => FocusTask.fromJson(e as Map<String, dynamic>)),
      );
      _redemptions.addAll(
        (data['redemptions'] as List)
            .map((e) => Redemption.fromJson(e as Map<String, dynamic>)),
      );
      _totalEarned = data['totalEarned'] as int;
      _spent = data['spent'] as int;
      _streak = data['streak'] as int;
      _bestStreak = data['bestStreak'] as int;
      _lastActiveDay = data['lastActiveDay'] as String?;
    } catch (_) {
      // Corrupt data: start fresh rather than crash.
      _tasks.clear();
      _redemptions.clear();
      _totalEarned = 0;
      _spent = 0;
      _streak = 0;
      _bestStreak = 0;
      _lastActiveDay = null;
      _seed();
    }
  }

  /// A few starter tasks so the first launch isn't an empty screen.
  void _seed() {
    final now = DateTime.now();
    final starters = [
      ('Read 10 pages of a book', TaskCategory.reading, 15),
      ('20-minute walk or workout', TaskCategory.exercise, 20),
      ('Learn something new for 30 min', TaskCategory.skill, 30),
    ];
    for (var i = 0; i < starters.length; i++) {
      final (title, category, minutes) = starters[i];
      _tasks.add(
        FocusTask(
          id: '${now.microsecondsSinceEpoch}$i',
          title: title,
          category: category,
          minutes: minutes,
          points: pointsFor(minutes, category),
          createdAt: now.add(Duration(milliseconds: i)),
        ),
      );
    }
    _save();
  }
}
