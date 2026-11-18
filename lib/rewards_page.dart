import 'package:flutter/material.dart';

import 'app_state.dart';
import 'models.dart';

class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key, required this.state});

  final AppState state;

  void _redeem(BuildContext context, Reward reward) {
    final ok = state.redeem(reward);
    final message = ok
        ? 'Enjoy it. Set a timer so it stays guilt-free ⏱️'
        : 'Not enough points yet. Complete a task first!';
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
        final cs = Theme.of(context).colorScheme;
        final history = state.redemptions.reversed.take(5).toList();

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Rewards',
                style: textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Card(
                color: cs.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.bolt_rounded,
                          size: 40, color: cs.onPrimaryContainer),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${state.balance}',
                            style: textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            'points to spend',
                            style: TextStyle(color: cs.onPrimaryContainer),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Spend your points', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final reward in defaultRewards)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(reward.icon, color: cs.primary),
                    title: Text(reward.title),
                    subtitle: Text('${reward.cost} pts'),
                    trailing: FilledButton.tonal(
                      onPressed: state.balance >= reward.cost
                          ? () => _redeem(context, reward)
                          : null,
                      child: const Text('Redeem'),
                    ),
                  ),
                ),
              if (history.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Recently redeemed', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final r in history)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history_rounded),
                    title: Text(r.title),
                    subtitle: Text(dayKey(r.at)),
                    trailing: Text('-${r.cost}'),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}
