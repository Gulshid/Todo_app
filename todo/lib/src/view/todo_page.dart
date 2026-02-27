import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:todo/src/bloc/theme_bloc.dart';
import 'package:todo/src/bloc/todo_bloc.dart';
import 'package:todo/src/bloc/todo_event.dart';
import 'package:todo/src/bloc/todo_state.dart';
import 'package:todo/src/core/model/category_model.dart';
import 'package:todo/src/widgets/add_todo_sheet.dart';
import 'package:todo/src/widgets/todo_item.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fabAnimController;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    context.read<TodoBloc>().add(LoadTodos());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimController.dispose();
    super.dispose();
  }

  void _openAddTodo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<TodoBloc>(),
        child: const AddEditTodoSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: _buildDrawer(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, isDark),
            Expanded(
              child: BlocBuilder<TodoBloc, TodoState>(
                builder: (context, state) {
                  if (state is TodoLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6366F1),
                        strokeWidth: 2.5,
                      ),
                    );
                  }

                  if (state is TodoError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
                          const SizedBox(height: 12),
                          Text(state.message, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    );
                  }

                  if (state is TodoLoaded) {
                    return _buildMainContent(context, state, isDark);
                  }

                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: _fabAnimController, curve: Curves.elasticOut),
        ),
        child: FloatingActionButton.extended(
          onPressed: _openAddTodo,
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Task', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _isSearching
          ? _buildSearchBar(context)
          : Container(
              key: const ValueKey('topbar'),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                children: [
                  Builder(
                    builder: (ctx) => IconButton(
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                      icon: const Icon(Icons.menu_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BlocBuilder<TodoBloc, TodoState>(
                      builder: (context, state) {
                        String title = 'All Tasks';
                        if (state is TodoLoaded) {
                          if (state.activeIsStarred == true) title = 'Starred';
                          else if (state.activeIsDone == true) title = 'Completed';
                          else if (state.activeIsDone == false) title = 'Active';
                          else if (state.activeCategoryId != null) {
                            final cat = state.categories
                                .where((c) => c.id == state.activeCategoryId)
                                .firstOrNull;
                            title = cat?.name ?? 'All Tasks';
                          }
                        }
                        return Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        );
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _isSearching = true);
                      _fabAnimController.forward();
                    },
                    icon: const Icon(Icons.search_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildMoreMenu(context),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      key: const ValueKey('searchbar'),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (v) => context.read<TodoBloc>().add(SearchTodos(v)),
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          context.read<TodoBloc>().add(SearchTodos(''));
                        },
                        icon: const Icon(Icons.close_rounded),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              setState(() => _isSearching = false);
              _searchController.clear();
              context.read<TodoBloc>().add(LoadTodos());
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreMenu(BuildContext context) {
    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (v) {
        if (v == 'delete_completed') {
          _confirmDeleteCompleted(context);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'delete_completed',
          child: Row(
            children: [
              Icon(Icons.delete_sweep_outlined, color: Color(0xFFEF4444), size: 18),
              SizedBox(width: 8),
              Text('Delete Completed', style: TextStyle(color: Color(0xFFEF4444))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context, TodoLoaded state, bool isDark) {
    return CustomScrollView(
      slivers: [
        // Stats Dashboard
        SliverToBoxAdapter(
          child: _buildStatsSection(context, state, isDark),
        ),

        // Filter chips
        SliverToBoxAdapter(
          child: _buildFilterChips(context, state),
        ),

        // Task count header
        if (state.todos.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Text(
                '${state.todos.length} ${state.todos.length == 1 ? 'task' : 'tasks'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ),

        // Todo list
        if (state.todos.isEmpty)
          SliverFillRemaining(
            child: _buildEmptyState(context, state),
          )
        else
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16.w).copyWith(bottom: 100.h),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => TodoItemCard(todo: state.todos[i]),
                childCount: state.todos.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, TodoLoaded state, bool isDark) {
    final theme = Theme.of(context);
    final stats = state.stats;

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overview',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _todayGreeting(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if ((stats['total'] ?? 0) > 0) ...[
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    children: [
                      CircularProgressIndicator(
                        value: (stats['done'] ?? 0) / (stats['total'] ?? 1),
                        backgroundColor: Colors.white.withOpacity(0.2),
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                      Center(
                        child: Text(
                          '${(((stats['done'] ?? 0) / (stats['total'] ?? 1)) * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatCard(value: '${stats['total'] ?? 0}', label: 'Total', color: Colors.white),
              const SizedBox(width: 8),
              _StatCard(value: '${stats['done'] ?? 0}', label: 'Done', color: const Color(0xFF34D399)),
              const SizedBox(width: 8),
              _StatCard(value: '${stats['today'] ?? 0}', label: 'Today', color: const Color(0xFFFBBF24)),
              const SizedBox(width: 8),
              _StatCard(
                value: '${stats['overdue'] ?? 0}',
                label: 'Overdue',
                color: const Color(0xFFF87171),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, TodoLoaded state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            isSelected: state.activeCategoryId == null && state.activeIsDone == null && state.activeIsStarred == null,
            onTap: () => context.read<TodoBloc>().add(SetFilter()),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Active',
            icon: Icons.radio_button_unchecked_rounded,
            isSelected: state.activeIsDone == false,
            color: const Color(0xFF6366F1),
            onTap: () => context.read<TodoBloc>().add(SetFilter(isDone: false)),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Done',
            icon: Icons.check_circle_outline_rounded,
            isSelected: state.activeIsDone == true,
            color: const Color(0xFF10B981),
            onTap: () => context.read<TodoBloc>().add(SetFilter(isDone: true)),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Starred',
            icon: Icons.star_outline_rounded,
            isSelected: state.activeIsStarred == true,
            color: const Color(0xFFF59E0B),
            onTap: () => context.read<TodoBloc>().add(SetFilter(isStarred: true)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, TodoLoaded state) {
    final theme = Theme.of(context);
    String message = 'No tasks yet.\nTap + to add your first task!';
    String emoji = '✨';

    if (state.searchQuery.isNotEmpty) {
      message = 'No tasks found for\n"${state.searchQuery}"';
      emoji = '🔍';
    } else if (state.activeIsDone == true) {
      message = 'No completed tasks yet.\nFinish something!';
      emoji = '🎯';
    } else if (state.activeIsStarred == true) {
      message = 'No starred tasks.\nStar important tasks!';
      emoji = '⭐';
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FF),
      child: SafeArea(
        child: BlocBuilder<TodoBloc, TodoState>(
          builder: (context, state) {
            final cats = state is TodoLoaded ? state.categories : <Category>[];
            final stats = state is TodoLoaded ? state.stats : <String, int>{};
            final activeCategory = state is TodoLoaded ? state.activeCategoryId : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'TaskMaster',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${stats['total'] ?? 0} tasks',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
                Divider(color: theme.dividerColor.withOpacity(0.3), height: 1),
                const SizedBox(height: 8),

                // Smart Lists
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'SMART LISTS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.hintColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                _DrawerItem(
                  icon: Icons.all_inbox_rounded,
                  label: 'All Tasks',
                  count: stats['total'],
                  isSelected: state is TodoLoaded &&
                      state.activeCategoryId == null &&
                      state.activeIsDone == null &&
                      state.activeIsStarred == null,
                  onTap: () {
                    context.read<TodoBloc>().add(SetFilter());
                    Navigator.pop(context);
                  },
                ),
                _DrawerItem(
                  icon: Icons.today_rounded,
                  label: 'Due Today',
                  count: stats['today'],
                  color: const Color(0xFFF59E0B),
                  isSelected: false,
                  onTap: () {
                    context.read<TodoBloc>().add(SetFilter(isDone: false));
                    Navigator.pop(context);
                  },
                ),
                _DrawerItem(
                  icon: Icons.star_rounded,
                  label: 'Starred',
                  color: const Color(0xFFF59E0B),
                  isSelected: state is TodoLoaded && state.activeIsStarred == true,
                  onTap: () {
                    context.read<TodoBloc>().add(SetFilter(isStarred: true));
                    Navigator.pop(context);
                  },
                ),
                _DrawerItem(
                  icon: Icons.warning_amber_rounded,
                  label: 'Overdue',
                  count: stats['overdue'],
                  color: const Color(0xFFEF4444),
                  isSelected: false,
                  onTap: () {
                    context.read<TodoBloc>().add(SetFilter(isDone: false));
                    Navigator.pop(context);
                  },
                ),
                _DrawerItem(
                  icon: Icons.check_circle_rounded,
                  label: 'Completed',
                  count: stats['done'],
                  color: const Color(0xFF10B981),
                  isSelected: state is TodoLoaded && state.activeIsDone == true,
                  onTap: () {
                    context.read<TodoBloc>().add(SetFilter(isDone: true));
                    Navigator.pop(context);
                  },
                ),

                const SizedBox(height: 8),
                Divider(color: theme.dividerColor.withOpacity(0.3), height: 1),
                const SizedBox(height: 8),

                // Categories
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        'CATEGORIES',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.hintColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _showAddCategoryDialog(context),
                        child: Icon(Icons.add_rounded, size: 18, color: theme.hintColor),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: cats
                        .map((cat) => _DrawerItem(
                              icon: IconData(cat.iconCodePoint, fontFamily: 'MaterialIcons'),
                              label: cat.name,
                              color: cat.color,
                              isSelected: activeCategory == cat.id,
                              onTap: () {
                                context.read<TodoBloc>().add(SetFilter(categoryId: cat.id));
                                Navigator.pop(context);
                              },
                              onLongPress: () => _confirmDeleteCategory(context, cat),
                            ))
                        .toList(),
                  ),
                ),

                // Theme toggle
                Divider(color: theme.dividerColor.withOpacity(0.3), height: 1),
                ListTile(
                  leading: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                  title: Text(isDark ? 'Light Mode' : 'Dark Mode'),
                  onTap: () {
                    Navigator.pop(context);
                    context.read<ThemeBloc>().add(ToggleTheme());
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    int selectedColor = 0xFF6366F1;
    int selectedIcon = Icons.folder.codePoint;

    final colors = [
      0xFF6366F1, 0xFF0EA5E9, 0xFF10B981, 0xFFF43F5E,
      0xFFF59E0B, 0xFF8B5CF6, 0xFFEC4899, 0xFF14B8A6,
    ];
    final icons = [
      Icons.folder.codePoint, Icons.work.codePoint, Icons.person.codePoint,
      Icons.shopping_cart.codePoint, Icons.favorite.codePoint, Icons.school.codePoint,
      Icons.attach_money.codePoint, Icons.fitness_center.codePoint,
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('New Category', style: TextStyle(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Category name'),
              ),
              const SizedBox(height: 16),
              const Text('Color', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: colors.map((c) => GestureDetector(
                  onTap: () => setDialogState(() => selectedColor = c),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: selectedColor == c
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                      boxShadow: selectedColor == c
                          ? [BoxShadow(color: Color(c).withOpacity(0.5), blurRadius: 4)]
                          : null,
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Icon', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: icons.map((ic) => GestureDetector(
                  onTap: () => setDialogState(() => selectedIcon = ic),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: selectedIcon == ic
                          ? Color(selectedColor).withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      IconData(ic, fontFamily: 'MaterialIcons'),
                      size: 18,
                      color: selectedIcon == ic ? Color(selectedColor) : Colors.grey,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                context.read<TodoBloc>().add(AddCategory(
                  Category(
                    name: nameController.text.trim(),
                    colorValue: selectedColor,
                    iconCodePoint: selectedIcon,
                  ),
                ));
                Navigator.pop(ctx);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCategory(BuildContext context, Category cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Category'),
        content: Text('Delete "${cat.name}"? Tasks in this category will keep their data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<TodoBloc>().add(DeleteCategory(cat.id!));
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCompleted(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Completed'),
        content: const Text('This will permanently delete all completed tasks.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<TodoBloc>().add(DeleteCompleted());
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  String _todayGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning!';
    if (hour < 17) return 'Good afternoon!';
    return 'Good evening!';
  }
}

// ── WIDGETS ──────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCard({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = color ?? const Color(0xFF6366F1);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (isDark ? const Color(0xFF1A1A2E) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : theme.dividerColor.withOpacity(0.3),
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: activeColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : (color ?? theme.hintColor),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? count;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _DrawerItem({
    required this.icon,
    required this.label,
    this.count,
    this.color,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = color ?? const Color(0xFF6366F1);

    return GestureDetector(
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          dense: true,
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: activeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: activeColor),
          ),
          title: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? activeColor : null,
            ),
          ),
          trailing: count != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: activeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: activeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
          onTap: onTap,
        ),
      ),
    );
  }
}