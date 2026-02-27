import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/todo_model.dart';
import '../model/category_model.dart';

class DBHelper {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'taskmaster.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        colorValue INTEGER NOT NULL,
        iconCodePoint INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE todos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        isDone INTEGER DEFAULT 0,
        priority INTEGER DEFAULT 0,
        categoryId INTEGER,
        dueDate TEXT,
        isStarred INTEGER DEFAULT 0,
        tags TEXT DEFAULT '',
        createdAt TEXT NOT NULL,
        FOREIGN KEY (categoryId) REFERENCES categories(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE subtasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        todoId INTEGER NOT NULL,
        title TEXT NOT NULL,
        isDone INTEGER DEFAULT 0,
        FOREIGN KEY (todoId) REFERENCES todos(id) ON DELETE CASCADE
      )
    ''');

    // Insert default categories
    for (final cat in defaultCategories) {
      await db.insert('categories', cat.toMap()..remove('id'));
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migrate from v1
      try {
        await db.execute('ALTER TABLE todos ADD COLUMN description TEXT');
        await db.execute('ALTER TABLE todos ADD COLUMN priority INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE todos ADD COLUMN categoryId INTEGER');
        await db.execute('ALTER TABLE todos ADD COLUMN dueDate TEXT');
        await db.execute('ALTER TABLE todos ADD COLUMN isStarred INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE todos ADD COLUMN tags TEXT DEFAULT ""');
        await db.execute('ALTER TABLE todos ADD COLUMN createdAt TEXT');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS categories(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            colorValue INTEGER NOT NULL,
            iconCodePoint INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS subtasks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            todoId INTEGER NOT NULL,
            title TEXT NOT NULL,
            isDone INTEGER DEFAULT 0
          )
        ''');
        for (final cat in defaultCategories) {
          await db.insert('categories', cat.toMap()..remove('id'));
        }
      } catch (_) {}
    }
  }

  // ── CATEGORIES ─────────────────────────────────────────────────────────────

  Future<List<Category>> getCategories() async {
    final db = await database;
    final res = await db.query('categories', orderBy: 'name ASC');
    return res.map((e) => Category.fromMap(e)).toList();
  }

  Future<int> insertCategory(Category cat) async {
    final db = await database;
    return db.insert('categories', cat.toMap()..remove('id'));
  }

  Future<void> updateCategory(Category cat) async {
    final db = await database;
    await db.update('categories', cat.toMap(),
        where: 'id = ?', whereArgs: [cat.id]);
  }

  Future<void> deleteCategory(int id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ── TODOS ───────────────────────────────────────────────────────────────────

  Future<List<Todo>> getTodos({int? categoryId, bool? isDone, bool? isStarred}) async {
    final db = await database;

    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (categoryId != null) {
      whereClauses.add('t.categoryId = ?');
      whereArgs.add(categoryId);
    }
    if (isDone != null) {
      whereClauses.add('t.isDone = ?');
      whereArgs.add(isDone ? 1 : 0);
    }
    if (isStarred != null && isStarred) {
      whereClauses.add('t.isStarred = 1');
    }

    final whereString =
        whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';

    final res = await db.rawQuery(
        'SELECT t.* FROM todos t $whereString ORDER BY t.isStarred DESC, t.priority DESC, t.createdAt DESC',
        whereArgs.isNotEmpty ? whereArgs : null);

    final todos = <Todo>[];
    for (final row in res) {
      final todo = Todo.fromMap(row);
      final subs = await _getSubtasks(todo.id!);
      todos.add(todo.copyWith(subtasks: subs));
    }
    return todos;
  }

  Future<List<Todo>> searchTodos(String query) async {
    final db = await database;
    final res = await db.query(
      'todos',
      where: 'title LIKE ? OR description LIKE ? OR tags LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );
    final todos = <Todo>[];
    for (final row in res) {
      final todo = Todo.fromMap(row);
      final subs = await _getSubtasks(todo.id!);
      todos.add(todo.copyWith(subtasks: subs));
    }
    return todos;
  }

  Future<Map<String, int>> getStats() async {
    final db = await database;
    final total = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM todos')) ??
        0;
    final done = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM todos WHERE isDone = 1')) ??
        0;
    final overdue = Sqflite.firstIntValue(await db.rawQuery(
            "SELECT COUNT(*) FROM todos WHERE isDone = 0 AND dueDate IS NOT NULL AND dueDate < ?",
            [DateTime.now().toIso8601String()])) ??
        0;
    final today = Sqflite.firstIntValue(await db.rawQuery(
            "SELECT COUNT(*) FROM todos WHERE isDone = 0 AND dueDate LIKE ?",
            ['${DateTime.now().toIso8601String().substring(0, 10)}%'])) ??
        0;
    return {
      'total': total,
      'done': done,
      'pending': total - done,
      'overdue': overdue,
      'today': today,
    };
  }

  Future<int> insertTodo(Todo todo) async {
    final db = await database;
    final id = await db.insert('todos', todo.toMap()..remove('id'));
    for (final sub in todo.subtasks) {
      await db.insert('subtasks', sub.copyWith(todoId: id).toMap()..remove('id'));
    }
    return id;
  }

  Future<void> updateTodo(Todo todo) async {
    final db = await database;
    await db.update('todos', todo.toMap(),
        where: 'id = ?', whereArgs: [todo.id]);
    // Refresh subtasks
    await db.delete('subtasks', where: 'todoId = ?', whereArgs: [todo.id]);
    for (final sub in todo.subtasks) {
      await db.insert(
          'subtasks', sub.copyWith(todoId: todo.id).toMap()..remove('id'));
    }
  }

  Future<void> deleteTodo(int id) async {
    final db = await database;
    await db.delete('todos', where: 'id = ?', whereArgs: [id]);
    await db.delete('subtasks', where: 'todoId = ?', whereArgs: [id]);
  }

  Future<void> toggleTodoDone(int id, bool isDone) async {
    final db = await database;
    await db.update('todos', {'isDone': isDone ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> toggleStar(int id, bool isStarred) async {
    final db = await database;
    await db.update('todos', {'isStarred': isStarred ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteCompleted() async {
    final db = await database;
    await db.delete('todos', where: 'isDone = 1');
  }

  // ── SUBTASKS ────────────────────────────────────────────────────────────────

  Future<List<SubTask>> _getSubtasks(int todoId) async {
    final db = await database;
    final res = await db.query('subtasks',
        where: 'todoId = ?', whereArgs: [todoId]);
    return res.map((e) => SubTask.fromMap(e)).toList();
  }

  Future<void> toggleSubtask(int subtaskId, bool isDone) async {
    final db = await database;
    await db.update('subtasks', {'isDone': isDone ? 1 : 0},
        where: 'id = ?', whereArgs: [subtaskId]);
  }
}