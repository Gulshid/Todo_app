import 'package:equatable/equatable.dart';
import 'package:todo/src/core/model/category_model.dart';
import 'package:todo/src/core/model/todo_model.dart';

abstract class TodoEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// ── LOAD / FILTER ────────────────────────────────────────────────────────────
class LoadTodos extends TodoEvent {
  final int? categoryId;
  final bool? isDone;
  final bool? isStarred;

  LoadTodos({this.categoryId, this.isDone, this.isStarred});

  @override
  List<Object?> get props => [categoryId, isDone, isStarred];
}

class SearchTodos extends TodoEvent {
  final String query;
  SearchTodos(this.query);

  @override
  List<Object?> get props => [query];
}

class LoadStats extends TodoEvent {}

// ── CRUD TODOS ───────────────────────────────────────────────────────────────
class AddTodo extends TodoEvent {
  final Todo todo;
  AddTodo(this.todo);

  @override
  List<Object?> get props => [todo];
}

class UpdateTodo extends TodoEvent {
  final Todo todo;
  UpdateTodo(this.todo);

  @override
  List<Object?> get props => [todo];
}

class DeleteTodo extends TodoEvent {
  final int id;
  DeleteTodo(this.id);

  @override
  List<Object?> get props => [id];
}

class ToggleTodoDone extends TodoEvent {
  final int id;
  final bool isDone;
  ToggleTodoDone(this.id, this.isDone);

  @override
  List<Object?> get props => [id, isDone];
}

class ToggleStar extends TodoEvent {
  final int id;
  final bool isStarred;
  ToggleStar(this.id, this.isStarred);

  @override
  List<Object?> get props => [id, isStarred];
}

class DeleteCompleted extends TodoEvent {}

class ToggleSubtask extends TodoEvent {
  final int subtaskId;
  final bool isDone;
  final int parentTodoId;
  ToggleSubtask(this.subtaskId, this.isDone, this.parentTodoId);

  @override
  List<Object?> get props => [subtaskId, isDone, parentTodoId];
}

// ── CATEGORIES ───────────────────────────────────────────────────────────────
class LoadCategories extends TodoEvent {}

class AddCategory extends TodoEvent {
  final Category category;
  AddCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class DeleteCategory extends TodoEvent {
  final int id;
  DeleteCategory(this.id);

  @override
  List<Object?> get props => [id];
}

// ── UI STATE ─────────────────────────────────────────────────────────────────
class SetFilter extends TodoEvent {
  final int? categoryId;
  final bool? isDone;
  final bool? isStarred;

  SetFilter({this.categoryId, this.isDone, this.isStarred});

  @override
  List<Object?> get props => [categoryId, isDone, isStarred];
}