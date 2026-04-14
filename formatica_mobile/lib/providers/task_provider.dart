import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/task_status.dart';

class TaskProvider with ChangeNotifier {
  final List<Task> _tasks = [];
  final Map<String, Future<void> Function()> _cancelHooks = {};

  UnmodifiableListView<Task> get tasks => UnmodifiableListView(_tasks);

  int get runningCount => _tasks.where((t) => t.status == TaskStatus.running).length;

  List<Task> get activeTasks => _tasks
      .where((t) => t.status == TaskStatus.queued || t.status == TaskStatus.running)
      .toList();

  List<Task> get completedTasks => _tasks
      .where((t) =>
          t.status == TaskStatus.success ||
          t.status == TaskStatus.failed ||
          t.status == TaskStatus.cancelled)
      .toList()
      .reversed
      .toList();

  String addTask(String label, String featureType, {String? subtext}) {
    final String id = DateTime.now().millisecondsSinceEpoch.toString();
    final task = Task(
      id: id,
      label: label,
      featureType: featureType,
      createdAt: DateTime.now(),
      subtext: subtext,
    );
    _tasks.add(task);
    notifyListeners();
    return id;
  }

  void updateProgress(String id, double progress) {
    final int index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final current = _tasks[index];
      _tasks[index] = current.copyWith(
        status: TaskStatus.running,
        progress: progress,
        startTime: current.startTime ?? DateTime.now(),
      );
      notifyListeners();
    }
  }

  Future<void> completeTask(String id, String outputPath) async {
    _cancelHooks.remove(id);
    final int index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      if (_tasks[index].status == TaskStatus.cancelled) return;
      
      double? size;
      try {
        final file = File(outputPath);
        if (await file.exists()) {
          size = (await file.length()).toDouble();
        }
      } catch (e) {
        debugPrint('TaskProvider: Error fetching file size: $e');
      }

      _tasks[index] = _tasks[index].copyWith(
        status: TaskStatus.success,
        progress: 1.0,
        outputPath: outputPath,
        fileSize: size,
      );
      notifyListeners();
    }
  }

  void failTask(String id, String errorMessage, {String? subtext}) {
    _cancelHooks.remove(id);
    final int index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      if (_tasks[index].status == TaskStatus.cancelled) return;
      _tasks[index] = _tasks[index].copyWith(
        status: TaskStatus.failed,
        errorMessage: errorMessage,
        subtext: subtext ?? _tasks[index].subtext,
      );
      notifyListeners();
    }
  }

  void setCancelHook(String id, Future<void> Function() hook) {
    _cancelHooks[id] = hook;
  }

  Future<void> cancelTask(String id) async {
    final hook = _cancelHooks.remove(id);
    if (hook != null) {
      try {
        await hook();
      } catch (e) {
        debugPrint('TaskProvider: Error during cancel hook execution: $e');
      }
    }

    final int index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        status: TaskStatus.cancelled,
      );
      notifyListeners();
    }
  }

  void clearCompleted() {
    _tasks.removeWhere((t) =>
        t.status == TaskStatus.success ||
        t.status == TaskStatus.failed ||
        t.status == TaskStatus.cancelled);
    notifyListeners();
  }
}








