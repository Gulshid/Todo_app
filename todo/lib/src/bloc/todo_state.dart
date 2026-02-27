import 'package:equatable/equatable.dart';
import 'package:todo/src/core/model/category_model.dart';
import 'package:todo/src/core/model/todo_model.dart';

abstract class TodoState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TodoInitial extends TodoState {}

class TodoLoading extends TodoState {}

class TodoLoaded extends TodoState {
  final List<Todo> todos;
  final List<Category> categories;
  final Map<String, int> stats;
  final int? activeCategoryId;
  final bool? activeIsDone;
  final bool? activeIsStarred;
  final String searchQuery;

  TodoLoaded({
    required this.todos,
    required this.categories,
    required this.stats,
    this.activeCategoryId,
    this.activeIsDone,
    this.activeIsStarred,
    this.searchQuery = '',
  });

  TodoLoaded copyWith({
    List<Todo>? todos,
    List<Category>? categories,
    Map<String, int>? stats,
    int? activeCategoryId,
    bool? activeIsDone,
    bool? activeIsStarred,
    String? searchQuery,
    bool clearCategory = false,
    bool clearIsDone = false,
    bool clearIsStarred = false,
  }) {
    return TodoLoaded(
      todos: todos ?? this.todos,
      categories: categories ?? this.categories,
      stats: stats ?? this.stats,
      activeCategoryId: clearCategory ? null : (activeCategoryId ?? this.activeCategoryId),
      activeIsDone: clearIsDone ? null : (activeIsDone ?? this.activeIsDone),
      activeIsStarred: clearIsStarred ? null : (activeIsStarred ?? this.activeIsStarred),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [todos, categories, stats, activeCategoryId, activeIsDone, activeIsStarred, searchQuery];
}

class TodoError extends TodoState {
  final String message;
  TodoError(this.message);

  @override
  List<Object?> get props => [message];
}