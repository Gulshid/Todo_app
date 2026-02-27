import 'package:flutter/foundation.dart' hide Category;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:sqflite/sqflite.dart' show getDatabasesPath;
import '../model/category_model.dart';
import '../model/todo_model.dart';

class DBHelper {
  static Database? _db;

  // ── Stores (like tables) ─────────────────────────────────────────────────
  final _todoStore    = intMapStoreFactory.store('todos');
  final _categoryStore = intMapStoreFactory.store('categories');
  final _subtaskStore  = intMapStoreFactory.store('subtasks');

  // ── Open DB ──────────────────────────────────────────────────────────────
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _openDb();
    await _seedCategories(_db!);
    return _db!;
  }

  Future<Database> _openDb() async {
    if (kIsWeb) {
      return databaseFactoryWeb.openDatabase('taskmaster.db');
    }
    // Mobile & Desktop — use file path
    late String dir;
    try {
      dir = await getDatabasesPath();
    } catch (_) {
      final appDir = await getApplicationDocumentsDirectory();
      dir = appDir.path;
    }
    return databaseFactoryIo.openDatabase(join(dir, 'taskmaster.db'));
  }

  Future<void> _seedCategories(Database db) async {
    final count = await _categoryStore.count(db);
    if (count == 0) {
      for (final cat in defaultCategories) {
        await _categoryStore.add(db, {
          'name': cat.name,
          'colorValue': cat.colorValue,
          'iconCodePoint': cat.iconCodePoint,
        });
      }
    }
  }

  // ── CATEGORIES ────────────────────────────────────────────────────────────

  Future<List<Category>> getCategories() async {
    final db = await database;
    final records = await _categoryStore.find(db,
        finder: Finder(sortOrders: [SortOrder('name')]));
    return records
        .map((r) => Category.fromMap({...r.value, 'id': r.key}))
        .toList();
  }

  Future<int> insertCategory(Category cat) async {
    final db = await database;
    return _categoryStore.add(db, {
      'name': cat.name,
      'colorValue': cat.colorValue,
      'iconCodePoint': cat.iconCodePoint,
    });
  }

  Future<void> updateCategory(Category cat) async {
    final db = await database;
    await _categoryStore.record(cat.id!).update(db, {
      'name': cat.name,
      'colorValue': cat.colorValue,
      'iconCodePoint': cat.iconCodePoint,
    });
  }

  Future<void> deleteCategory(int id) async {
    final db = await database;
    await _categoryStore.record(id).delete(db);
    // Clear categoryId on todos that used this category
    final todos = await _todoStore.find(db,
        finder: Finder(filter: Filter.equals('categoryId', id)));
    for (final t in todos) {
      await _todoStore.record(t.key).update(db, {'categoryId': null});
    }
  }

  // ── TODOS ─────────────────────────────────────────────────────────────────

  Future<List<Todo>> getTodos({
    int? categoryId,
    bool? isDone,
    bool? isStarred,
  }) async {
    final db = await database;

    final filters = <Filter>[];
    if (categoryId != null) filters.add(Filter.equals('categoryId', categoryId));
    if (isDone != null)     filters.add(Filter.equals('isDone', isDone));
    if (isStarred == true)  filters.add(Filter.equals('isStarred', true));

    final finder = Finder(
      filter: filters.isEmpty ? null : Filter.and(filters),
      sortOrders: [
        SortOrder('isStarred', false),
        SortOrder('priority', false),
        SortOrder('createdAt', false),
      ],
    );

    final records = await _todoStore.find(db, finder: finder);
    final todos = <Todo>[];
    for (final r in records) {
      final subs = await _getSubtasks(db, r.key);
      todos.add(Todo.fromMap({...r.value, 'id': r.key})
          .copyWith(subtasks: subs));
    }
    return todos;
  }

  Future<List<Todo>> searchTodos(String query) async {
    final db = await database;
    final q = query.toLowerCase();
    final records = await _todoStore.find(db,
        finder: Finder(sortOrders: [SortOrder('createdAt', false)]));
    final todos = <Todo>[];
    for (final r in records) {
      final map = {...r.value, 'id': r.key};
      if ((map['title'] as String? ?? '').toLowerCase().contains(q) ||
          (map['description'] as String? ?? '').toLowerCase().contains(q) ||
          (map['tags'] as String? ?? '').toLowerCase().contains(q)) {
        final subs = await _getSubtasks(db, r.key);
        todos.add(Todo.fromMap(map).copyWith(subtasks: subs));
      }
    }
    return todos;
  }

  Future<Map<String, int>> getStats() async {
    final db = await database;
    final all    = await _todoStore.count(db);
    final done   = await _todoStore.count(db,
        filter: Filter.equals('isDone', true));
    final nowStr = DateTime.now().toIso8601String();
    final todayPrefix = nowStr.substring(0, 10);

    // overdue: not done + dueDate < today
    final allRecords = await _todoStore.find(db);
    int overdue = 0, today = 0;
    for (final r in allRecords) {
      if (r.value['isDone'] == true) continue;
      final due = r.value['dueDate'] as String?;
      if (due == null) continue;
      if (due.compareTo(nowStr) < 0 && !due.startsWith(todayPrefix)) overdue++;
      if (due.startsWith(todayPrefix)) today++;
    }

    return {
      'total':   all,
      'done':    done,
      'pending': all - done,
      'overdue': overdue,
      'today':   today,
    };
  }

  Future<int> insertTodo(Todo todo) async {
    final db = await database;
    final id = await _todoStore.add(db, _todoToMap(todo));
    for (final sub in todo.subtasks) {
      await _subtaskStore.add(db, {
        'todoId': id,
        'title': sub.title,
        'isDone': sub.isDone,
      });
    }
    return id;
  }

  Future<void> updateTodo(Todo todo) async {
    final db = await database;
    await _todoStore.record(todo.id!).update(db, _todoToMap(todo));
    // Refresh subtasks
    final old = await _subtaskStore.find(db,
        finder: Finder(filter: Filter.equals('todoId', todo.id)));
    for (final s in old) await _subtaskStore.record(s.key).delete(db);
    for (final sub in todo.subtasks) {
      await _subtaskStore.add(db, {
        'todoId': todo.id,
        'title':  sub.title,
        'isDone': sub.isDone,
      });
    }
  }

  Future<void> deleteTodo(int id) async {
    final db = await database;
    await _todoStore.record(id).delete(db);
    final subs = await _subtaskStore.find(db,
        finder: Finder(filter: Filter.equals('todoId', id)));
    for (final s in subs) await _subtaskStore.record(s.key).delete(db);
  }

  Future<void> toggleTodoDone(int id, bool isDone) async {
    final db = await database;
    await _todoStore.record(id).update(db, {'isDone': isDone});
  }

  Future<void> toggleStar(int id, bool isStarred) async {
    final db = await database;
    await _todoStore.record(id).update(db, {'isStarred': isStarred});
  }

  Future<void> deleteCompleted() async {
    final db = await database;
    final done = await _todoStore.find(db,
        finder: Finder(filter: Filter.equals('isDone', true)));
    for (final r in done) {
      await _todoStore.record(r.key).delete(db);
      final subs = await _subtaskStore.find(db,
          finder: Finder(filter: Filter.equals('todoId', r.key)));
      for (final s in subs) await _subtaskStore.record(s.key).delete(db);
    }
  }

  // ── SUBTASKS ──────────────────────────────────────────────────────────────

  Future<List<SubTask>> _getSubtasks(Database db, int todoId) async {
    final records = await _subtaskStore.find(db,
        finder: Finder(filter: Filter.equals('todoId', todoId)));
    return records
        .map((r) => SubTask.fromMap({...r.value, 'id': r.key, 'todoId': todoId}))
        .toList();
  }

  Future<void> toggleSubtask(int subtaskId, bool isDone) async {
    final db = await database;
    await _subtaskStore.record(subtaskId).update(db, {'isDone': isDone});
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _todoToMap(Todo todo) => {
        'title':       todo.title,
        'description': todo.description,
        'isDone':      todo.isDone,
        'priority':    todo.priority.value,
        'categoryId':  todo.categoryId,
        'dueDate':     todo.dueDate?.toIso8601String(),
        'isStarred':   todo.isStarred,
        'tags':        todo.tags,
        'createdAt':   todo.createdAt.toIso8601String(),
      };
}