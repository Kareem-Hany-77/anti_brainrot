import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'add_task_sheet.dart';
import 'app_state.dart';
import 'progress_page.dart';
import 'rewards_page.dart';
import 'today_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(FocusUpApp(state: AppState(prefs)));
}

class FocusUpApp extends StatelessWidget {
  const FocusUpApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF4F46E5);
    return MaterialApp(
      title: 'FocusUp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: HomeShell(state: state),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.state});

  final AppState state;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      TodayPage(state: widget.state),
      RewardsPage(state: widget.state),
      ProgressPage(state: widget.state),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: () => showAddTaskSheet(context, widget.state),
              icon: const Icon(Icons.add),
              label: const Text('New task'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.checklist_rounded),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard_rounded),
            label: 'Rewards',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_rounded),
            label: 'Progress',
          ),
        ],
      ),
    );
  }
}
