import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

void main() {
  runApp(const RootApp());
}

/// アプリ全体（ダークモード・UIモード管理）
class RootApp extends StatefulWidget {
  const RootApp({super.key});

  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  bool darkMode = false;
  int uiMode = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      darkMode = prefs.getBool("darkMode") ?? false;
      uiMode = prefs.getInt("uiMode") ?? 0;
    });
  }

  void refresh() => _loadSettings();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: TodoHomePage(
        uiMode: uiMode,
        onSettingsChanged: refresh,
      ),
    );
  }
}

/// メイン画面
class TodoHomePage extends StatefulWidget {
  final int uiMode;
  final VoidCallback onSettingsChanged;

  const TodoHomePage({
    super.key,
    required this.uiMode,
    required this.onSettingsChanged,
  });

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  List<Map<String, dynamic>> todos = [];
  List<Map<String, dynamic>> priorities = [];
  final TextEditingController controller = TextEditingController();
  String? selectedPriority;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();

    final t = prefs.getString("todos");
    if (t != null) todos = List<Map<String, dynamic>>.from(json.decode(t));

    final p = prefs.getString("priorities");
    if (p != null) {
      priorities = List<Map<String, dynamic>>.from(json.decode(p));
    } else {
      priorities = [
        {"name": "普通", "color": Colors.blue.value}
      ];
    }

    selectedPriority ??= priorities.first["name"];

    setState(() {});
  }

  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("todos", json.encode(todos));
  }

  Future<void> _savePriorities() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("priorities", json.encode(priorities));
  }

  void addTodo() {
    final text = controller.text.trim();
    if (text.isEmpty || selectedPriority == null) return;

    final p = priorities.firstWhere((e) => e["name"] == selectedPriority);

    setState(() {
      todos.add({
        "title": text,
        "done": false,
        "priority": p["name"],
        "color": p["color"],
      });
    });

    controller.clear();
    _saveTodos();
  }

  void toggleDone(int index, bool? v) {
    setState(() {
      todos[index]["done"] = v ?? false;
    });
    _saveTodos();
  }

  void deleteTodo(int index) {
    setState(() {
      todos.removeAt(index);
    });
    _saveTodos();
  }

  void addPriority() {
    TextEditingController nameCtrl = TextEditingController();
    Color selected = Colors.red;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("優先度を追加"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "名前"),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  Color? picked = await showDialog(
                    context: context,
                    builder: (context) => ColorPickerDialog(selected),
                  );
                  if (picked != null) {
                    setState(() => selected = picked);
                  }
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: selected,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            ],
          ),
          actions: [
            TextButton(
              child: const Text("キャンセル"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("追加"),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;

                setState(() {
                  priorities.add({
                    "name": nameCtrl.text.trim(),
                    "color": selected.value,
                  });
                  selectedPriority = nameCtrl.text.trim();
                });

                _savePriorities();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildCard(int index) {
    final todo = todos[index];
    final color = Color(todo["color"]);
    final ui = widget.uiMode;

    switch (ui) {
      case 0: // A 色強調
        return Card(
          color: color.withOpacity(0.4),
          child: ListTile(
            leading: Checkbox(
              value: todo["done"],
              onChanged: (v) => toggleDone(index, v),
            ),
            title: Text(
              todo["title"],
              style: TextStyle(
                decoration: todo["done"] ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(todo["priority"]),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => deleteTodo(index),
            ),
          ),
        );

      case 1: // B シンプル
        return Card(
          child: ListTile(
            leading: Checkbox(
              value: todo["done"],
              onChanged: (v) => toggleDone(index, v),
            ),
            title: Text(
              todo["title"],
              style: TextStyle(
                decoration: todo["done"] ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Row(
              children: [
                CircleAvatar(backgroundColor: color, radius: 6),
                const SizedBox(width: 6),
                Text(todo["priority"]),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => deleteTodo(index),
            ),
          ),
        );

      case 2: // C 大きめ
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(20),
            leading: Checkbox(
              value: todo["done"],
              onChanged: (v) => toggleDone(index, v),
            ),
            title: Text(
              todo["title"],
              style: TextStyle(
                fontSize: 20,
                decoration: todo["done"] ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Row(
              children: [
                CircleAvatar(backgroundColor: color, radius: 8),
                const SizedBox(width: 8),
                Text(todo["priority"]),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => deleteTodo(index),
            ),
          ),
        );

      case 3: // D アイコン強調
        return Card(
          child: ListTile(
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: todo["done"],
                  onChanged: (v) => toggleDone(index, v),
                ),
                CircleAvatar(backgroundColor: color, radius: 10),
              ],
            ),
            title: Text(
              todo["title"],
              style: TextStyle(
                decoration: todo["done"] ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(todo["priority"]),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => deleteTodo(index),
            ),
          ),
        );

      case 4: // E ミニマル
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Checkbox(
                value: todo["done"],
                onChanged: (v) => toggleDone(index, v),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  todo["title"],
                  style: TextStyle(
                    decoration:
                        todo["done"] ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => deleteTodo(index),
              )
            ],
          ),
        );
    }

    return const SizedBox.shrink();
  }

  void openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsPage(
          onChanged: widget.onSettingsChanged,
        ),
      ),
    );
    _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("全部入り ToDo"),
        actions: [
          IconButton(
            icon: const Icon(Icons.color_lens),
            onPressed: addPriority,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: openSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: "タスクを入力",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedPriority,
                  items: priorities.map((p) {
                    return DropdownMenuItem<String>(
                      value: p["name"],
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Color(p["color"]),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(p["name"]),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => selectedPriority = v),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: addTodo,
                  child: const Text("追加"),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: todos.length,
              itemBuilder: (context, i) => buildCard(i),
            ),
          ),
        ],
      ),
    );
  }
}

/// 設定画面
class SettingsPage extends StatefulWidget {
  final VoidCallback onChanged;

  const SettingsPage({super.key, required this.onChanged});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool darkMode = false;
  int uiMode = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      darkMode = prefs.getBool("darkMode") ?? false;
      uiMode = prefs.getInt("uiMode") ?? 0;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("darkMode", darkMode);
    await prefs.setInt("uiMode", uiMode);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("設定")),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("ダークモード"),
            value: darkMode,
            onChanged: (v) {
              setState(() => darkMode = v);
              _save();
            },
          ),
          ListTile(
            title: const Text("UI モード"),
            subtitle: Text(
              ["A：色強調", "B：シンプル", "C：大きめ", "D：アイコン", "E：ミニマル"][uiMode],
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return SimpleDialog(
                    title: const Text("UI モードを選択"),
                    children: List.generate(5, (i) {
                      return SimpleDialogOption(
                        child: Text([
                          "A：色強調",
                          "B：シンプル",
                          "C：大きめ",
                          "D：アイコン",
                          "E：ミニマル"
                        ][i]),
                        onPressed: () {
                          setState(() => uiMode = i);
                          _save();
                          Navigator.pop(context);
                        },
                      );
                    }),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 色選択ダイアログ
class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  const ColorPickerDialog(this.initialColor, {super.key});

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color color;

  @override
  void initState() {
    super.initState();
    color = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("色を選択"),
      content: SingleChildScrollView(
        child: BlockPicker(
          pickerColor: color,
          onColorChanged: (c) => setState(() => color = c),
        ),
      ),
      actions: [
        TextButton(
          child: const Text("OK"),
          onPressed: () => Navigator.pop(context, color),
        )
      ],
    );
  }
}