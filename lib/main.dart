import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(TodoApp());
}

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'To-Do List',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,      // Primary color
          secondary: Colors.orange,    // Accent color
        ),
        scaffoldBackgroundColor: Colors.grey[100],
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),  // Text color for large body text
          bodyMedium: TextStyle(color: Colors.black54),  // Text color for medium body text
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
          ),
          labelStyle: TextStyle(color: Colors.blue),
        ),
      ),
      home: TodoHomeScreen(),
    );
  }
}

class TodoHomeScreen extends StatefulWidget {
  @override
  _TodoHomeScreenState createState() => _TodoHomeScreenState();
}

class _TodoHomeScreenState extends State<TodoHomeScreen> {
  List<Task> tasks = [];
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() async {
    prefs = await SharedPreferences.getInstance();
    String? storedTasks = prefs.getString('tasks');
    if (storedTasks != null) {
      setState(() {
        tasks = (json.decode(storedTasks) as List)
            .map((data) => Task.fromJson(data))
            .toList();
      });
    }
  }

  void _saveTasks() {
    prefs.setString('tasks', json.encode(tasks));
  }

  void _addTask(String title, String description, String priority, DateTime dueDate) {
    setState(() {
      tasks.add(Task(
        title: title,
        description: description,
        priority: priority,
        dueDate: dueDate,
        isCompleted: false,
      ));
      _saveTasks();
    });
  }

  void _editTask(Task task, String newTitle, String newDescription, String newPriority, DateTime newDueDate) {
    setState(() {
      task.title = newTitle;
      task.description = newDescription;
      task.priority = newPriority;
      task.dueDate = newDueDate;
      _saveTasks();
    });
  }

  void _deleteTask(Task task) {
    setState(() {
      tasks.remove(task);
      _saveTasks();
    });
  }

  void _toggleTaskCompletion(Task task) {
    setState(() {
      task.isCompleted = !task.isCompleted;
      _saveTasks();
    });
  }

  void _openTaskDialog({Task? task}) {
    String title = task?.title ?? '';
    String description = task?.description ?? '';
    String priority = task?.priority ?? 'Low';
    DateTime dueDate = task?.dueDate ?? DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(task == null ? 'New Task' : 'Edit Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  onChanged: (value) => title = value,
                  controller: TextEditingController(text: title),
                  decoration: InputDecoration(labelText: 'Title'),
                ),
                SizedBox(height: 8),
                TextField(
                  onChanged: (value) => description = value,
                  controller: TextEditingController(text: description),
                  decoration: InputDecoration(labelText: 'Description'),
                ),
                SizedBox(height: 8),
                DropdownButton<String>(
                  value: priority,
                  onChanged: (String? newValue) {
                    setState(() {
                      priority = newValue!;
                    });
                  },
                  items: <String>['Low', 'Medium', 'High']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    final DateTime? selectedDate = await showDatePicker(
                      context: context,
                      initialDate: dueDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (selectedDate != null && selectedDate != dueDate) {
                      setState(() {
                        dueDate = selectedDate;
                      });
                    }
                  },
                  child: Text('Select Due Date'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                if (task == null) {
                  _addTask(title, description, priority, dueDate);
                } else {
                  _editTask(task, title, description, priority, dueDate);
                }
                Navigator.of(context).pop();
              },
              child: Text(task == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do List'),
      ),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Card(
            elevation: 2,
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              title: Text(
                task.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: task.isCompleted ? colorScheme.primary : Colors.black87,
                ),
              ),
              subtitle: Text(
                'Priority: ${task.priority}, Due: ${task.dueDate.toLocal().toIso8601String().split('T').first}',
                style: TextStyle(
                  color: task.isCompleted ? colorScheme.primary : Colors.black54,
                ),
              ),
              trailing: Checkbox(
                value: task.isCompleted,
                onChanged: (_) => _toggleTaskCompletion(task),
                activeColor: colorScheme.primary,
              ),
              onTap: () => _openTaskDialog(task: task),
              onLongPress: () => _deleteTask(task),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTaskDialog(),
        child: Icon(Icons.add),
        backgroundColor: colorScheme.secondary,
      ),
    );
  }
}

class Task {
  String title;
  String description;
  String priority;
  DateTime dueDate;
  bool isCompleted;

  Task({
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.isCompleted,
  });

  factory Task.fromJson(Map<String, dynamic> jsonData) {
    return Task(
      title: jsonData['title'],
      description: jsonData['description'],
      priority: jsonData['priority'],
      dueDate: DateTime.parse(jsonData['dueDate']),
      isCompleted: jsonData['isCompleted'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'priority': priority,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }
}
