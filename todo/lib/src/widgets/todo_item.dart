import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todo/src/bloc/todo_bloc.dart';
import 'package:todo/src/bloc/todo_event.dart';
import 'package:todo/src/bloc/todo_state.dart';
import 'package:todo/src/core/model/todo_model.dart';
import 'package:todo/src/widgets/add_todo_sheet.dart';

class TodoItemCard extends StatelessWidget {
  final Todo todo;
  const TodoItemCard({super.key, required this.todo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final priorityTint = _priorityColor(todo.priority);

    // Light: subtle priority-tinted off-white. Dark: deep navy.
    final cardColor = isDark
        ? const Color(0xFF1A1A2E)
        : todo.isDone
            ? const Color(0xFFF9FAFB)
            : Color.lerp(Colors.white, priorityTint, 0.032)!;

    final accentColor = todo.isDone
        ? const Color(0xFF10B981)
        : todo.isOverdue
            ? const Color(0xFFEF4444)
            : priorityTint;

    return Dismissible(
      key: Key('todo_${todo.id}'),
      background: _dismissBg(alignment: Alignment.centerLeft),
      secondaryBackground: _dismissBg(alignment: Alignment.centerRight, isDelete: true),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          context.read<TodoBloc>().add(ToggleTodoDone(todo.id!, !todo.isDone));
          return false;
        }
        return await _confirmDelete(context);
      },
      onDismissed: (_) => context.read<TodoBloc>().add(DeleteTodo(todo.id!)),
      child: GestureDetector(
        onTap: () => _openEdit(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: todo.isOverdue
                  ? const Color(0xFFEF4444).withOpacity(0.35)
                  : isDark
                      ? Colors.white.withOpacity(0.06)
                      : accentColor.withOpacity(0.18),
              width: isDark ? 1.0 : 1.2,
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    // Colored glow from priority
                    BoxShadow(
                      color: accentColor.withOpacity(0.12),
                      blurRadius: 14,
                      spreadRadius: 0,
                      offset: const Offset(0, 5),
                    ),
                    // Soft base shadow
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 6,
                      spreadRadius: -1,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Left accent bar ────────────────────────────────────
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 4,
                    color: todo.isDone ? accentColor.withOpacity(0.35) : accentColor,
                  ),
                  // ── Card body ──────────────────────────────────────────
                  Expanded(child: _CardBody(todo: todo)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _priorityColor(Priority p) {
    switch (p) {
      case Priority.low:    return const Color(0xFF10B981);
      case Priority.medium: return const Color(0xFFF59E0B);
      case Priority.high:   return const Color(0xFFEF4444);
      case Priority.urgent: return const Color(0xFF7C3AED);
    }
  }

  Widget _dismissBg({required Alignment alignment, bool isDelete = false}) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDelete ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        isDelete ? Icons.delete_outline_rounded : Icons.check_circle_outline_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  void _openEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<TodoBloc>(),
        child: AddEditTodoSheet(todo: todo),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }
}

// ── Card body (stateless, receives todo) ────────────────────────────────────

class _CardBody extends StatelessWidget {
  final Todo todo;
  const _CardBody({required this.todo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title row ──────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              GestureDetector(
                onTap: () => context
                    .read<TodoBloc>()
                    .add(ToggleTodoDone(todo.id!, !todo.isDone)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: todo.isDone
                        ? const Color(0xFF10B981)
                        : Colors.transparent,
                    border: Border.all(
                      color: todo.isDone
                          ? const Color(0xFF10B981)
                          : _priorityColor(todo.priority),
                      width: 2,
                    ),
                  ),
                  child: todo.isDone
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              // Title + description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: todo.isDone ? TextDecoration.lineThrough : null,
                        color: todo.isDone ? theme.hintColor : null,
                      ),
                    ),
                    if (todo.description != null &&
                        todo.description!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        todo.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ],
                ),
              ),
              // Star
              GestureDetector(
                onTap: () => context
                    .read<TodoBloc>()
                    .add(ToggleStar(todo.id!, !todo.isStarred)),
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(
                    todo.isStarred
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 20,
                    color: todo.isStarred
                        ? const Color(0xFFF59E0B)
                        : theme.hintColor,
                  ),
                ),
              ),
            ],
          ),

          // ── Meta chips row ─────────────────────────────────────────────
          if (_hasMetaInfo) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Row(
                children: [
                  _MetaChip(
                    icon: Icons.flag_rounded,
                    label: todo.priority.label,
                    color: _priorityColor(todo.priority),
                  ),
                  const SizedBox(width: 6),
                  if (todo.dueDate != null) ...[
                    _MetaChip(
                      icon: Icons.calendar_today_rounded,
                      label: _formatDate(todo.dueDate!),
                      color: todo.isOverdue
                          ? const Color(0xFFEF4444)
                          : todo.isDueToday
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF0EA5E9),
                    ),
                    const SizedBox(width: 6),
                  ],
                  BlocBuilder<TodoBloc, TodoState>(
                    buildWhen: (_, curr) => curr is TodoLoaded,
                    builder: (context, state) {
                      if (state is! TodoLoaded || todo.categoryId == null) {
                        return const SizedBox();
                      }
                      final cat = state.categories
                          .where((c) => c.id == todo.categoryId)
                          .firstOrNull;
                      if (cat == null) return const SizedBox();
                      return _MetaChip(
                        icon: cat.iconCodePoint != 0
                            ? IconData(cat.iconCodePoint,
                                fontFamily: 'MaterialIcons')
                            : Icons.folder_rounded,
                        label: cat.name,
                        color: cat.color,
                      );
                    },
                  ),
                  const Spacer(),
                  if (todo.subtasks.isNotEmpty)
                    Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: todo.subtaskProgress,
                              backgroundColor: theme.dividerColor,
                              color: const Color(0xFF10B981),
                              minHeight: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${todo.completedSubtasks}/${todo.subtasks.length}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],

          // ── Tags ───────────────────────────────────────────────────────
          if (todo.tagList.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: todo.tagList
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#$tag',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6366F1),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool get _hasMetaInfo =>
      todo.dueDate != null ||
      todo.categoryId != null ||
      todo.subtasks.isNotEmpty;

  Color _priorityColor(Priority p) {
    switch (p) {
      case Priority.low:    return const Color(0xFF10B981);
      case Priority.medium: return const Color(0xFFF59E0B);
      case Priority.high:   return const Color(0xFFEF4444);
      case Priority.urgent: return const Color(0xFF7C3AED);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) return 'Today';
    final tmrw = now.add(const Duration(days: 1));
    if (date.year == tmrw.year &&
        date.month == tmrw.month &&
        date.day == tmrw.day) return 'Tomorrow';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ── Meta chip ────────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MetaChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}