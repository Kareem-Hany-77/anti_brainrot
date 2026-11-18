import 'package:flutter_test/flutter_test.dart';
import 'package:foucs_up/app_state.dart';
import 'package:foucs_up/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('level thresholds', () {
    expect(levelInfo(0).level, 1);
    expect(levelInfo(49).level, 1);
    expect(levelInfo(50).level, 2);
    expect(levelInfo(200).level, 3);
    expect(levelInfo(450).level, 4);
  });

  test('points are weighted by category', () {
    expect(pointsFor(30, TaskCategory.reading), 30);
    expect(pointsFor(60, TaskCategory.exercise), 72);
  });

  test('first launch seeds starter tasks', () async {
    final state = AppState(await SharedPreferences.getInstance());
    expect(state.pendingTasks.length, 3);
    expect(state.balance, 0);
    expect(state.streak, 0);
  });

  test('completing a task awards points once and starts a streak', () async {
    final state = AppState(await SharedPreferences.getInstance());
    final task = state.pendingTasks.first;

    final result = state.completeTask(task.id);
    expect(result, isNotNull);
    expect(result!.points, task.points);
    expect(state.balance, task.points);
    expect(state.streak, 1);
    expect(state.todayPoints, task.points);

    // Completing again does nothing.
    expect(state.completeTask(task.id), isNull);
    expect(state.balance, task.points);
  });

  test('redeeming needs enough points and spends them', () async {
    final state = AppState(await SharedPreferences.getInstance());
    final reward = defaultRewards.first;
    expect(state.redeem(reward), isFalse);

    final task = state.addTask('Gym', TaskCategory.exercise, 60);
    state.completeTask(task.id);
    expect(state.redeem(reward), isTrue);
    expect(state.balance, task.points - reward.cost);
    expect(state.redemptions.length, 1);
  });

  test('data survives a restart', () async {
    final prefs = await SharedPreferences.getInstance();
    final first = AppState(prefs);
    final task = first.pendingTasks.first;
    first.completeTask(task.id);

    final second = AppState(prefs);
    expect(second.balance, task.points);
    expect(second.tasksDone, 1);
  });
}
