import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_state.dart';
import 'models.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final textTheme = Theme.of(context).textTheme;
        final info = levelInfo(state.totalEarned);

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Progress',
                style: textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Level ${info.level}', style: textTheme.titleLarge),
                      Text(info.title, style: textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: info.progress(state.totalEarned),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${info.remaining(state.totalEarned)} pts to level ${info.level + 1}',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.stars_rounded,
                      label: 'Total points',
                      value: '${state.totalEarned}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.task_alt_rounded,
                      label: 'Tasks done',
                      value: '${state.tasksDone}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.timer_rounded,
                      label: 'Minutes focused',
                      value: '${state.minutesFocused}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.local_fire_department_rounded,
                      label: 'Best streak',
                      value: '${state.bestStreak} d',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Last 7 days', style: textTheme.titleMedium),
              const SizedBox(height: 12),
              _WeekChart(state: state),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(label, style: textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.state});

  static const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _chartHeight = 110.0;

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dates = state.lastDates(7);
    final values = state.pointsLastDays(7);
    final maxValue = math.max(values.reduce(math.max), AppState.dailyGoal);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < dates.length; i++)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${values[i]}',
                        style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 4),
                    Container(
                      height: math.max(
                          4.0, _chartHeight * values[i] / maxValue),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: values[i] >= AppState.dailyGoal
                            ? cs.primary
                            : cs.primary.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(_weekdayLetters[dates[i].weekday - 1]),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
