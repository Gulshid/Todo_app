import 'package:equatable/equatable.dart';

enum Priority { low, medium, high, urgent }

extension PriorityExtension on Priority {
  String get label {
    switch (this) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
      case Priority.urgent:
        return 'Urgent';
    }
  }

  int get value {
    switch (this) {
      case Priority.low:
        return 0;
      case Priority.medium:
        return 1;
      case Priority.high:
        return 2;
      case Priority.urgent:
        return 3;
    }
  }

  static Priority fromValue(int v) {
    switch (v) {
      case 1:
        return Priority.medium;
      case 2:
        return Priority.high;
      case 3:
        return Priority.urgent;
      default:
        return Priority.low;
    }
  }
}

class SubTask extends Equatable {
  final int? id;
  final int? todoId;
  final String title;
  final bool isDone;

  const SubTask({
    this.id,
    this.todoId,
    required this.title,
    this.isDone = false,
  });

  SubTask copyWith({int? id, int? todoId, String? title, bool? isDone}) {
    return SubTask(
      id: id ?? this.id,
      todoId: todoId ?? this.todoId,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'todoId': todoId,
        'title': title,
        'isDone': isDone ? 1 : 0,
      };

  factory SubTask.fromMap(Map<String, dynamic> map) => SubTask(
        id: map['id'],
        todoId: map['todoId'],
        title: map['title'],
        isDone: map['isDone'] == 1,
      );

  @override
  List<Object?> get props => [id, todoId, title, isDone];
}

class Todo extends Equatable {
  final int? id;
  final String title;
  final String? description;
  final bool isDone;
  final Priority priority;
  final int? categoryId;
  final DateTime? dueDate;
  final bool isStarred;
  final String tags; // comma-separated
  final DateTime createdAt;
  final List<SubTask> subtasks;

  const Todo({
    this.id,
    required this.title,
    this.description,
    this.isDone = false,
    this.priority = Priority.low,
    this.categoryId,
    this.dueDate,
    this.isStarred = false,
    this.tags = '',
    required this.createdAt,
    this.subtasks = const [],
  });

  List<String> get tagList =>
      tags.isEmpty ? [] : tags.split(',').map((e) => e.trim()).toList();

  bool get isOverdue =>
      dueDate != null &&
      !isDone &&
      dueDate!.isBefore(DateTime.now().copyWith(
          hour: 0, minute: 0, second: 0, microsecond: 0, millisecond: 0));

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  int get completedSubtasks => subtasks.where((s) => s.isDone).length;
  double get subtaskProgress =>
      subtasks.isEmpty ? 0 : completedSubtasks / subtasks.length;

  Todo copyWith({
    int? id,
    String? title,
    String? description,
    bool? isDone,
    Priority? priority,
    int? categoryId,
    DateTime? dueDate,
    bool? isStarred,
    String? tags,
    DateTime? createdAt,
    List<SubTask>? subtasks,
    bool clearCategory = false,
    bool clearDueDate = false,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isDone: isDone ?? this.isDone,
      priority: priority ?? this.priority,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      isStarred: isStarred ?? this.isStarred,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      subtasks: subtasks ?? this.subtasks,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'isDone': isDone ? 1 : 0,
        'priority': priority.value,
        'categoryId': categoryId,
        'dueDate': dueDate?.toIso8601String(),
        'isStarred': isStarred ? 1 : 0,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Todo.fromMap(Map<String, dynamic> map) => Todo(
        id: map['id'],
        title: map['title'] ?? '',
        description: map['description'],
        isDone: map['isDone'] == 1,
        priority: PriorityExtension.fromValue(map['priority'] ?? 0),
        categoryId: map['categoryId'],
        dueDate:
            map['dueDate'] != null ? DateTime.tryParse(map['dueDate']) : null,
        isStarred: map['isStarred'] == 1,
        tags: map['tags'] ?? '',
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
            : DateTime.now(),
        subtasks: const [],
      );

  @override
  List<Object?> get props =>
      [id, title, description, isDone, priority, categoryId, dueDate, isStarred, tags, createdAt, subtasks];
}