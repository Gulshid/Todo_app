import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todo/src/core/db/db_helpher.dart';
import 'todo_event.dart';
import 'todo_state.dart';

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final DBHelper dbHelper;

  // Active filter state
  int? _activeCategoryId;
  bool? _activeIsDone;
  bool? _activeIsStarred;
  String _searchQuery = '';

  TodoBloc(this.dbHelper) : super(TodoInitial()) {
    on<LoadTodos>(_loadTodos);
    on<SearchTodos>(_searchTodos);
    on<LoadStats>(_loadStats);
    on<AddTodo>(_addTodo);
    on<UpdateTodo>(_updateTodo);
    on<DeleteTodo>(_deleteTodo);
    on<ToggleTodoDone>(_toggleDone);
    on<ToggleStar>(_toggleStar);
    on<DeleteCompleted>(_deleteCompleted);
    on<ToggleSubtask>(_toggleSubtask);
    on<LoadCategories>(_loadCategories);
    on<AddCategory>(_addCategory);
    on<DeleteCategory>(_deleteCategory);
    on<SetFilter>(_setFilter);
  }

  Future<(List<dynamic>, List<dynamic>, Map<String, int>)> _fetchAll({
    int? categoryId,
    bool? isDone,
    bool? isStarred,
  }) async {
    final todos = await dbHelper.getTodos(
      categoryId: categoryId,
      isDone: isDone,
      isStarred: isStarred,
    );
    final categories = await dbHelper.getCategories();
    final stats = await dbHelper.getStats();
    return (todos, categories, stats);
  }

  Future<void> _loadTodos(LoadTodos event, Emitter<TodoState> emit) async {
    emit(TodoLoading());
    try {
      _activeCategoryId = event.categoryId;
      _activeIsDone = event.isDone;
      _activeIsStarred = event.isStarred;
      _searchQuery = '';

      final todos = await dbHelper.getTodos(
        categoryId: _activeCategoryId,
        isDone: _activeIsDone,
        isStarred: _activeIsStarred,
      );
      final categories = await dbHelper.getCategories();
      final stats = await dbHelper.getStats();

      emit(TodoLoaded(
        todos: todos,
        categories: categories,
        stats: stats,
        activeCategoryId: _activeCategoryId,
        activeIsDone: _activeIsDone,
        activeIsStarred: _activeIsStarred,
        searchQuery: _searchQuery,
      ));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  Future<void> _searchTodos(SearchTodos event, Emitter<TodoState> emit) async {
    _searchQuery = event.query;
    try {
      final todos = event.query.isEmpty
          ? await dbHelper.getTodos(
              categoryId: _activeCategoryId,
              isDone: _activeIsDone,
              isStarred: _activeIsStarred,
            )
          : await dbHelper.searchTodos(event.query);
      final categories = await dbHelper.getCategories();
      final stats = await dbHelper.getStats();

      emit(TodoLoaded(
        todos: todos,
        categories: categories,
        stats: stats,
        activeCategoryId: _activeCategoryId,
        activeIsDone: _activeIsDone,
        activeIsStarred: _activeIsStarred,
        searchQuery: _searchQuery,
      ));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  Future<void> _loadStats(LoadStats event, Emitter<TodoState> emit) async {
    if (state is TodoLoaded) {
      final stats = await dbHelper.getStats();
      final s = state as TodoLoaded;
      emit(s.copyWith(stats: stats));
    }
  }

  Future<void> _addTodo(AddTodo event, Emitter<TodoState> emit) async {
    await dbHelper.insertTodo(event.todo);
    add(LoadTodos(
      categoryId: _activeCategoryId,
      isDone: _activeIsDone,
      isStarred: _activeIsStarred,
    ));
  }

  Future<void> _updateTodo(UpdateTodo event, Emitter<TodoState> emit) async {
    await dbHelper.updateTodo(event.todo);
    add(LoadTodos(
      categoryId: _activeCategoryId,
      isDone: _activeIsDone,
      isStarred: _activeIsStarred,
    ));
  }

  Future<void> _deleteTodo(DeleteTodo event, Emitter<TodoState> emit) async {
    await dbHelper.deleteTodo(event.id);
    add(LoadTodos(
      categoryId: _activeCategoryId,
      isDone: _activeIsDone,
      isStarred: _activeIsStarred,
    ));
  }

  Future<void> _toggleDone(ToggleTodoDone event, Emitter<TodoState> emit) async {
    await dbHelper.toggleTodoDone(event.id, event.isDone);
    add(LoadTodos(
      categoryId: _activeCategoryId,
      isDone: _activeIsDone,
      isStarred: _activeIsStarred,
    ));
  }

  Future<void> _toggleStar(ToggleStar event, Emitter<TodoState> emit) async {
    await dbHelper.toggleStar(event.id, event.isStarred);
    add(LoadTodos(
      categoryId: _activeCategoryId,
      isDone: _activeIsDone,
      isStarred: _activeIsStarred,
    ));
  }

  Future<void> _deleteCompleted(DeleteCompleted event, Emitter<TodoState> emit) async {
    await dbHelper.deleteCompleted();
    add(LoadTodos(
      categoryId: _activeCategoryId,
      isDone: _activeIsDone,
      isStarred: _activeIsStarred,
    ));
  }

  Future<void> _toggleSubtask(ToggleSubtask event, Emitter<TodoState> emit) async {
    await dbHelper.toggleSubtask(event.subtaskId, event.isDone);
    add(LoadTodos(
      categoryId: _activeCategoryId,
      isDone: _activeIsDone,
      isStarred: _activeIsStarred,
    ));
  }

  Future<void> _loadCategories(LoadCategories event, Emitter<TodoState> emit) async {
    if (state is TodoLoaded) {
      final cats = await dbHelper.getCategories();
      emit((state as TodoLoaded).copyWith(categories: cats));
    }
  }

  Future<void> _addCategory(AddCategory event, Emitter<TodoState> emit) async {
    await dbHelper.insertCategory(event.category);
    add(LoadCategories());
  }

  Future<void> _deleteCategory(DeleteCategory event, Emitter<TodoState> emit) async {
    await dbHelper.deleteCategory(event.id);
    if (_activeCategoryId == event.id) {
      _activeCategoryId = null;
    }
    add(LoadTodos());
  }

  Future<void> _setFilter(SetFilter event, Emitter<TodoState> emit) async {
    _activeCategoryId = event.categoryId;
    _activeIsDone = event.isDone;
    _activeIsStarred = event.isStarred;
    _searchQuery = '';
    add(LoadTodos(
      categoryId: _activeCategoryId,
      isDone: _activeIsDone,
      isStarred: _activeIsStarred,
    ));
  }
}