import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models/task.dart';

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Manager',
      home: TodoHome(),
    );
  }
}

class TodoHome extends StatefulWidget {
  const TodoHome({super.key});

  @override
  State<TodoHome> createState() => _TodoHomeState();
}

class _TodoHomeState extends State<TodoHome> {
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;

  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _searchController.addListener(_filterTasks);
  }

  void _filterTasks() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTasks = _tasks.where((task) {
        return task.title.toLowerCase().contains(query) ||
            (task.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? stored = prefs.getString('tasks');
    if (stored != null) {
      List<dynamic> decoded = jsonDecode(stored);
      setState(() {
        _tasks = decoded.map((e) => Task.fromJson(e)).toList();
        _filteredTasks = _tasks;
      });
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_tasks.map((e) => e.toJson()).toList());
    await prefs.setString('tasks', encoded);
  }

  void _addTask() {
    if (_taskController.text.trim().isEmpty) return;
    setState(() {
      final newTask = Task(
        title: _taskController.text,
        isCompleted: false,
        description: _descController.text,
        date: _selectedDate,
      );
      _tasks.add(newTask);
      _filteredTasks = _tasks;
      _taskController.clear();
      _descController.clear();
      _selectedDate = null;
    });
    _saveTasks();
  }

  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
      _filteredTasks = _tasks;
    });
    _saveTasks();
  }

  void _toggleComplete(int index) {
    setState(() {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
      _filteredTasks = _tasks;
    });
    _saveTasks();
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedTasks = _filteredTasks.where((t) => t.isCompleted).toList();
    final incompleteTasks = _filteredTasks.where((t) => !t.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('📝 Task Manager'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search tasks...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            _buildInputSection(),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  _buildSection('Pending Tasks', incompleteTasks),
                  const SizedBox(height: 10),
                  _buildSection('Completed Tasks', completedTasks),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      children: [
        TextField(
          controller: _taskController,
          decoration: const InputDecoration(
            labelText: 'Task name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descController,
          decoration: const InputDecoration(
            labelText: 'Description (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(_selectedDate == null
                  ? 'No due date selected'
                  : 'Due: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}'),
            ),
            TextButton.icon(
              onPressed: () => _pickDate(context),
              icon: const Icon(Icons.calendar_today),
              label: const Text("Pick Date"),
            ),
            ElevatedButton(
              onPressed: _addTask,
              child: const Text('Add'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Task> taskList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title (${taskList.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: taskList.length,
          separatorBuilder: (context, index) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final task = taskList[index];
            final originalIndex = _tasks.indexOf(task);
            return Card(
              color: task.isCompleted ? Colors.green[100] : Colors.orange[50],
              elevation: 3,
              child: ListTile(
                leading: Checkbox(
                  value: task.isCompleted,
                  onChanged: (_) => _toggleComplete(originalIndex),
                ),
                title: Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (task.description != null &&
                        task.description!.trim().isNotEmpty)
                      Text(task.description!),
                    if (task.date != null)
                      Text('Due: ${DateFormat('yyyy-MM-dd').format(task.date!)}'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteTask(originalIndex),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}  