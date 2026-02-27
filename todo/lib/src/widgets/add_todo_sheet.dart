import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todo/src/bloc/todo_bloc.dart';
import 'package:todo/src/bloc/todo_event.dart';
import 'package:todo/src/bloc/todo_state.dart';
import 'package:todo/src/core/model/category_model.dart';
import 'package:todo/src/core/model/todo_model.dart';

class AddEditTodoSheet extends StatefulWidget {
  final Todo? todo;
  const AddEditTodoSheet({super.key, this.todo});

  @override
  State<AddEditTodoSheet> createState() => _AddEditTodoSheetState();
}

class _AddEditTodoSheetState extends State<AddEditTodoSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _tagsController = TextEditingController();
  final _subTaskController = TextEditingController();

  Priority _priority = Priority.medium;
  int? _categoryId;
  DateTime? _dueDate;
  bool _isStarred = false;
  List<SubTask> _subtasks = [];

  bool get _isEditing => widget.todo != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final t = widget.todo!;
      _titleController.text = t.title;
      _descController.text = t.description ?? '';
      _tagsController.text = t.tags;
      _priority = t.priority;
      _categoryId = t.categoryId;
      _dueDate = t.dueDate;
      _isStarred = t.isStarred;
      _subtasks = List.from(t.subtasks);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _tagsController.dispose();
    _subTaskController.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) return;
    final todo = Todo(
      id: widget.todo?.id,
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      isDone: widget.todo?.isDone ?? false,
      priority: _priority,
      categoryId: _categoryId,
      dueDate: _dueDate,
      isStarred: _isStarred,
      tags: _tagsController.text.trim(),
      createdAt: widget.todo?.createdAt ?? DateTime.now(),
      subtasks: _subtasks,
    );
    if (_isEditing) {
      context.read<TodoBloc>().add(UpdateTodo(todo));
    } else {
      context.read<TodoBloc>().add(AddTodo(todo));
    }
    Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _addSubtask() {
    final title = _subTaskController.text.trim();
    if (title.isEmpty) return;
    setState(() {
      _subtasks.add(SubTask(title: title, todoId: widget.todo?.id));
      _subTaskController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final surfaceColor = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FF);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle + Header
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 4),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        Text(
                          _isEditing ? 'Edit Task' : 'New Task',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        // Star toggle
                        GestureDetector(
                          onTap: () => setState(() => _isStarred = !_isStarred),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              _isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
                              key: ValueKey(_isStarred),
                              color: _isStarred ? const Color(0xFFF59E0B) : theme.iconTheme.color,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        TextField(
                          controller: _titleController,
                          autofocus: !_isEditing,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          decoration: const InputDecoration(
                            hintText: 'Task title *',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                          ),
                          maxLines: 2,
                          minLines: 1,
                        ),
                        const SizedBox(height: 12),

                        // Description
                        TextField(
                          controller: _descController,
                          style: theme.textTheme.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Add description...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                            hintStyle: TextStyle(color: theme.hintColor),
                          ),
                          maxLines: 3,
                          minLines: 1,
                        ),
                        const SizedBox(height: 20),

                        // Properties Row
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              // Priority
                              _PropertyRow(
                                icon: Icons.flag_rounded,
                                iconColor: _priorityColor(_priority),
                                label: 'Priority',
                                child: DropdownButton<Priority>(
                                  value: _priority,
                                  underline: const SizedBox(),
                                  isDense: true,
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                  items: Priority.values.map((p) => DropdownMenuItem(
                                    value: p,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.circle, size: 8, color: _priorityColor(p)),
                                        const SizedBox(width: 6),
                                        Text(p.label),
                                      ],
                                    ),
                                  )).toList(),
                                  onChanged: (p) => setState(() => _priority = p!),
                                ),
                              ),
                              _Divider(),

                              // Due Date
                              _PropertyRow(
                                icon: Icons.calendar_today_rounded,
                                iconColor: const Color(0xFF0EA5E9),
                                label: 'Due Date',
                                child: GestureDetector(
                                  onTap: _pickDate,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _dueDate != null
                                            ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                                            : 'Set date',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: _dueDate != null
                                              ? const Color(0xFF0EA5E9)
                                              : theme.hintColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (_dueDate != null) ...[
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () => setState(() => _dueDate = null),
                                          child: Icon(Icons.close, size: 16, color: theme.hintColor),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              _Divider(),

                              // Category
                              BlocBuilder<TodoBloc, TodoState>(
                                builder: (context, state) {
                                  final cats = state is TodoLoaded ? state.categories : <Category>[];
                                  // Guard: if the stored categoryId is not in the
                                  // loaded list, treat it as null to avoid the
                                  // "exactly one item" DropdownButton assertion.
                                  final validCategoryId = cats.any((c) => c.id == _categoryId)
                                      ? _categoryId
                                      : null;

                                  return _PropertyRow(
                                    icon: Icons.folder_rounded,
                                    iconColor: const Color(0xFF8B5CF6),
                                    label: 'Category',
                                    child: DropdownButton<int?>(
                                      value: validCategoryId,
                                      underline: const SizedBox(),
                                      isDense: true,
                                      hint: Text('None', style: TextStyle(color: theme.hintColor, fontSize: 14)),
                                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                      items: [
                                        const DropdownMenuItem<int?>(value: null, child: Text('None')),
                                        ...cats.map((c) => DropdownMenuItem<int?>(
                                          value: c.id,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(c.icon, size: 14, color: c.color),
                                              const SizedBox(width: 6),
                                              Text(c.name),
                                            ],
                                          ),
                                        )),
                                      ],
                                      onChanged: (v) => setState(() => _categoryId = v),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Tags
                        Text('Tags', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _tagsController,
                          decoration: const InputDecoration(
                            hintText: 'work, urgent, project-x',
                            prefixIcon: Icon(Icons.label_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Subtasks
                        Row(
                          children: [
                            Text('Subtasks', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                            const Spacer(),
                            if (_subtasks.isNotEmpty)
                              Text(
                                '${_subtasks.where((s) => s.isDone).length}/${_subtasks.length}',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._subtasks.asMap().entries.map((entry) {
                          final i = entry.key;
                          final sub = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => setState(() {
                                    _subtasks[i] = sub.copyWith(isDone: !sub.isDone);
                                  }),
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: sub.isDone ? const Color(0xFF10B981) : Colors.transparent,
                                      border: Border.all(
                                        color: sub.isDone ? const Color(0xFF10B981) : theme.dividerColor,
                                        width: 2,
                                      ),
                                    ),
                                    child: sub.isDone
                                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    sub.title,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      decoration: sub.isDone ? TextDecoration.lineThrough : null,
                                      color: sub.isDone ? theme.hintColor : null,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => setState(() => _subtasks.removeAt(i)),
                                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                                  color: theme.hintColor,
                                ),
                              ],
                            ),
                          );
                        }),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _subTaskController,
                                decoration: const InputDecoration(
                                  hintText: 'Add subtask...',
                                  prefixIcon: Icon(Icons.add_circle_outline_rounded),
                                ),
                                onSubmitted: (_) => _addSubtask(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _addSubtask,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _save,
                            child: Text(_isEditing ? 'Save Changes' : 'Create Task'),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _priorityColor(Priority p) {
    switch (p) {
      case Priority.low:
        return const Color(0xFF10B981);
      case Priority.medium:
        return const Color(0xFFF59E0B);
      case Priority.high:
        return const Color(0xFFEF4444);
      case Priority.urgent:
        return const Color(0xFF7C3AED);
    }
  }
}

class _PropertyRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget child;

  const _PropertyRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
          const Spacer(),
          child,
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.3)),
    );
  }
}