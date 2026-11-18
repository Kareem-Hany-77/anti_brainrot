import 'package:flutter/material.dart';

import 'app_state.dart';
import 'models.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key, required this.state});

  final AppState state;

  void _complete(BuildContext context, String id) {
    final result = state.completeTask(id);
    if (result == null) return;
    final message = result.leveledUp
        ? 'Level up! You are now level ${result.level} 🎉'
        : '+${result.points} points. Nice focus!';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final textTheme = Theme.of(context).textTheme;
        final pending = state.pendingTasks;
        final done = state.completedToday;

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _Header(state: state),
              const SizedBox(height: 16),
              _DailyGoalCard(state: state),
              const SizedBox(height: 24),
              Text('To do', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              if (pending.isEmpty)
                const _EmptyState()
              else
                for (final task in pending)
                  _DismissibleTask(
                    task: task,
                    onDelete: () => state.deleteTask(task.id),
                    onComplete: () => _complete(context, task.id),
                  ),
              if (done.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Done today', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final task in done) _TaskTile(task: task),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final info = levelInfo(state.totalEarned);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FocusUp',
                style: textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text('Level ${info.level} · ${info.title}',
                  style: textTheme.bodyMedium),
            ],
          ),
        ),
        _StatPill(
          icon: Icons.local_fire_department_rounded,
          value: '${state.streak}',
          color: Colors.deepOrange,
        ),
        const SizedBox(width: 8),
        _StatPill(
          icon: Icons.bolt_rounded,
          value: '${state.balance}',
          color: Colors.amber.shade700,
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final today = state.todayPoints;
    final reached = today >= AppState.dailyGoal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Today's goal", style: textTheme.titleMedium),
                Text('$today / ${AppState.dailyGoal} pts'),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (today / AppState.dailyGoal).clamp(0.0, 1.0).toDouble(),
              minHeight: 10,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 8),
            Text(
              reached
                  ? 'Goal reached. Your brain thanks you. 🧠'
                  : 'Do something real before you open the feed.',
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.self_improvement_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Nothing planned.\nTap + to add something meaningful instead of scrolling.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DismissibleTask extends StatelessWidget {
  const _DismissibleTask({
    required this.task,
    required this.onDelete,
    required this.onComplete,
  });

  final FocusTask task;
  final VoidCallback onDelete;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: cs.onErrorContainer),
      ),
      child: _TaskTile(task: task, onComplete: onComplete),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, this.onComplete});

  final FocusTask task;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: IconButton(
          tooltip: task.isDone ? null : 'Mark done',
          onPressed: onComplete,
          icon: Icon(
            task.isDone
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: task.isDone ? cs.primary : null,
          ),
        ),
        title: Text(
          task.title,
          style: task.isDone
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle: Text('${task.minutes} min · ${task.category.label}'),
        trailing: Text(
          '+${task.points}',
          style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary),
        ),
      ),
    );
  }
}
