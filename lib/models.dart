import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Kinds of meaningful activity that replace scrolling time.
enum TaskCategory {
  reading('Reading', Icons.menu_book_rounded, 1.0),
  study('Study', Icons.school_rounded, 1.2),
  exercise('Exercise', Icons.fitness_center_rounded, 1.2),
  skill('New skill', Icons.lightbulb_rounded, 1.1),
  mindful('Mindfulness', Icons.self_improvement_rounded, 1.0);

  const TaskCategory(this.label, this.icon, this.weight);

  final String label;
  final IconData icon;

  /// Points multiplier per minute of effort.
  final double weight;
}

/// Points a task is worth: roughly one point per minute, weighted by category.
int pointsFor(int minutes, TaskCategory category) =>
    (minutes * category.weight).round();

/// yyyy-MM-dd key for a calendar day.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

class FocusTask {
  FocusTask({
    required this.id,
    required this.title,
    required this.category,
    required this.minutes,
    required this.points,
    required this.createdAt,
    this.completedAt,
  });

  final String id;
  final String title;
  final TaskCategory category;
  final int minutes;
  final int points;
  final DateTime createdAt;
  DateTime? completedAt;

  bool get isDone => completedAt != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category.name,
        'minutes': minutes,
        'points': points,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory FocusTask.fromJson(Map<String, dynamic> json) => FocusTask(
        id: json['id'] as String,
        title: json['title'] as String,
        category: TaskCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => TaskCategory.reading,
        ),
        minutes: json['minutes'] as int,
        points: json['points'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        completedAt: json['completedAt'] == null
            ? null
            : DateTime.parse(json['completedAt'] as String),
      );
}

class Reward {
  const Reward({
    required this.id,
    required this.title,
    required this.cost,
    required this.icon,
  });

  final String id;
  final String title;
  final int cost;
  final IconData icon;
}

/// Time-boxed treats you can buy with points you earned.
const defaultRewards = <Reward>[
  Reward(
    id: 'scroll15',
    title: 'Guilt-free scroll (15 min)',
    cost: 60,
    icon: Icons.phone_android_rounded,
  ),
  Reward(
    id: 'coffee',
    title: 'Coffee or favorite snack',
    cost: 80,
    icon: Icons.coffee_rounded,
  ),
  Reward(
    id: 'gaming30',
    title: 'Gaming session (30 min)',
    cost: 100,
    icon: Icons.sports_esports_rounded,
  ),
  Reward(
    id: 'episode',
    title: 'One episode of a show',
    cost: 120,
    icon: Icons.movie_rounded,
  ),
  Reward(
    id: 'lazy',
    title: 'Lazy hour, zero guilt',
    cost: 150,
    icon: Icons.bedtime_rounded,
  ),
];

class Redemption {
  const Redemption({required this.title, required this.cost, required this.at});

  final String title;
  final int cost;
  final DateTime at;

  Map<String, dynamic> toJson() => {
        'title': title,
        'cost': cost,
        'at': at.toIso8601String(),
      };

  factory Redemption.fromJson(Map<String, dynamic> json) => Redemption(
        title: json['title'] as String,
        cost: json['cost'] as int,
        at: DateTime.parse(json['at'] as String),
      );
}

const levelTitles = <String>[
  'Doomscroller',
  'Waking Up',
  'Getting Focused',
  'Habit Builder',
  'Deep Worker',
  'Mind Sharpener',
  'Focus Pro',
  'Flow Master',
  'Brain Titan',
  'Legend',
];

class LevelInfo {
  const LevelInfo({
    required this.level,
    required this.title,
    required this.start,
    required this.next,
  });

  final int level;
  final String title;

  /// Total points where this level begins.
  final int start;

  /// Total points where the next level begins.
  final int next;

  double progress(int totalEarned) =>
      ((totalEarned - start) / (next - start)).clamp(0.0, 1.0).toDouble();

  int remaining(int totalEarned) => next - totalEarned;
}

/// Level L begins at 50 * (L - 1)^2 total points earned.
LevelInfo levelInfo(int totalEarned) {
  final level = 1 + math.sqrt(totalEarned / 50).floor();
  final title = levelTitles[math.min(level - 1, levelTitles.length - 1)];
  return LevelInfo(
    level: level,
    title: title,
    start: 50 * (level - 1) * (level - 1),
    next: 50 * level * level,
  );
}
