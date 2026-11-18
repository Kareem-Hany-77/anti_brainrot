import 'package:flutter/material.dart';

import 'app_state.dart';
import 'models.dart';

Future<void> showAddTaskSheet(BuildContext context, AppState state) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => AddTaskSheet(state: state),
  );
}

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key, required this.state});

  final AppState state;

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  static const _durations = [10, 15, 30, 45, 60];

  final _controller = TextEditingController();
  TaskCategory _category = TaskCategory.reading;
  int _minutes = 30;

  bool get _canAdd => _controller.text.trim().isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_canAdd) return;
    widget.state.addTask(_controller.text, _category, _minutes);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final points = pointsFor(_minutes, _category);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New task', style: textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'What will you do instead of scrolling?',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            Text('Category', style: textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in TaskCategory.values)
                  ChoiceChip(
                    avatar: Icon(c.icon, size: 18),
                    label: Text(c.label),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text('How long?', style: textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in _durations)
                  ChoiceChip(
                    label: Text('$m min'),
                    selected: _minutes == m,
                    onSelected: (_) => setState(() => _minutes = m),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _canAdd ? _submit : null,
                icon: const Icon(Icons.add),
                label: Text('Add task  •  +$points pts'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
