import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Button Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ButtonManagerHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ButtonManagerHome extends StatefulWidget {
  const ButtonManagerHome({super.key});

  @override
  State<ButtonManagerHome> createState() => _ButtonManagerHomeState();
}

class _ButtonManagerHomeState extends State<ButtonManagerHome> {
  List<ButtonData> buttons = [];
  final ConfettiController _confettiController =
      ConfettiController(duration: const Duration(seconds: 1));

  @override
  void initState() {
    super.initState();
    // Load saved buttons here (would use shared_preferences in a real app)
    _loadButtons();
  }

  void _loadButtons() {
    // Mock data for demonstration
    setState(() {
      buttons = [
        ButtonData('عصام', 5, Colors.blue),
        ButtonData('محمود', 3, Colors.red),
        ButtonData('محمد', 7, Colors.green),
        ButtonData('السيد', 2, Colors.yellow),
        ButtonData('محمود', 4, Colors.purple),
      ];
    });
  }

  void _saveButtons() {
    // Would save to shared_preferences in a real app
  }

  int get totalCount {
    return buttons.fold(0, (sum, button) => sum + button.count);
  }

  void _addButton(ButtonData newButton) {
    setState(() {
      buttons.add(newButton);
    });
    _saveButtons();
  }

  void _updateButton(int index, ButtonData updatedButton) {
    setState(() {
      buttons[index] = updatedButton;
    });
    _saveButtons();
  }

  void _deleteButton(int index) {
    setState(() {
      buttons.removeAt(index);
    });
    _saveButtons();
  }

  void _decrementCount(int index) {
    setState(() {
      buttons[index].count--;
      if (buttons[index].count == 0) {
        _confettiController.play();
      }
    });
    _saveButtons();
  }

  void _showAddButtonDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ButtonEditDialog(
          onSave: _addButton,
        );
      },
    );
  }

  void _showEditButtonDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ButtonEditDialog(
          button: buttons[index],
          onSave: (updatedButton) => _updateButton(index, updatedButton),
          onDelete: () => _deleteButton(index),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Button Manager'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                'Total: $totalCount',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (buttons.isEmpty)
            const Center(
              child: Text(
                'No buttons yet!\nTap the + button to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          else
            GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: buttons.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onLongPress: () => _showEditButtonDialog(index),
                  child: ButtonWidget(
                    data: buttons[index],
                    onPressed: () => _decrementCount(index),
                  ),
                );
              },
            ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.1,
              numberOfParticles: 20,
              gravity: 0.1,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddButtonDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }
}

class ButtonData {
  String label;
  int count;
  Color color;

  ButtonData(this.label, this.count, this.color);
}

class ButtonWidget extends StatefulWidget {
  final ButtonData data;
  final VoidCallback onPressed;

  const ButtonWidget({
    super.key,
    required this.data,
    required this.onPressed,
  });

  @override
  State<ButtonWidget> createState() => _ButtonWidgetState();
}

class _ButtonWidgetState extends State<ButtonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.data.count == 0;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _animationController.forward(),
        onTapUp: (_) {
          _animationController.reverse();
          widget.onPressed();
        },
        onTapCancel: () => _animationController.reverse(),
        child: Container(
          decoration: BoxDecoration(
            color: widget.data.color.withOpacity(isCompleted ? 0.7 : 1.0),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isCompleted
                ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.data.label,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.green.shade900 : Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.data.count.toString(),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.green.shade900 : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class ButtonEditDialog extends StatefulWidget {
  final ButtonData? button;
  final Function(ButtonData) onSave;
  final VoidCallback? onDelete;

  const ButtonEditDialog({
    super.key,
    this.button,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<ButtonEditDialog> createState() => _ButtonEditDialogState();
}

class _ButtonEditDialogState extends State<ButtonEditDialog> {
  late TextEditingController _labelController;
  late TextEditingController _countController;
  late Color _selectedColor;
  final List<Color> _colorOptions = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.yellow,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.button?.label ?? '');
    _countController =
        TextEditingController(text: widget.button?.count.toString() ?? '1');
    _selectedColor = widget.button?.color ?? Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.button == null ? 'Add New Button' : 'Edit Button'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Label',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _countController,
              decoration: const InputDecoration(
                labelText: 'Count',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            const Text('Select Color:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _colorOptions.map((color) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: _selectedColor == color
                          ? Border.all(color: Colors.black, width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.button != null && widget.onDelete != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete!();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveButton,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveButton() {
    final label = _labelController.text.trim();
    if (label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a label')),
      );
      return;
    }

    final count = int.tryParse(_countController.text) ?? 1;
    if (count < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Count must be a positive number')),
      );
      return;
    }

    final newButton = ButtonData(label, count, _selectedColor);
    widget.onSave(newButton);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _labelController.dispose();
    _countController.dispose();
    super.dispose();
  }
}
