import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/task.dart';
import '../providers/tasks_provider.dart';

class AddEditTaskScreen extends StatefulWidget {
  const AddEditTaskScreen({super.key, this.task, this.initialTitle});

  final Task? task;
  final String? initialTitle;

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  late final TextEditingController _titleController;
  bool _hasDeadline = false;
  DateTime? _deadline;
  String? _category;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleController = TextEditingController(
      text: t?.title ?? widget.initialTitle ?? '',
    );
    _hasDeadline = t?.deadline != null;
    _deadline = t?.deadline;
    _category = t?.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _toggleVoice() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }

    final available = await _speech.initialize();
    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return;
    }

    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _titleController.text = result.recognizedWords;
          _titleController.selection = TextSelection.fromPosition(
            TextPosition(offset: _titleController.text.length),
          );
        });
      },
    );
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final initial = _deadline ?? now.add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    setState(() {
      _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _hasDeadline = true;
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required.')),
      );
      return;
    }

    final tasks = context.read<TasksProvider>();
    final existing = widget.task;

    if (existing == null) {
      await tasks.addTask(
        title: title,
        deadline: _hasDeadline ? _deadline : null,
        category: _category,
      );
    } else {
      final updated = existing.copyWith(
        title: title,
        deadline: _hasDeadline ? _deadline : null,
        deadlineClear: !_hasDeadline,
        category: _category,
        categoryClear: _category == null,
        updatedAt: DateTime.now(),
      );
      await tasks.updateTask(updated);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.task != null;
    final df = DateFormat.yMMMd().add_jm();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit task' : 'New task'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: _listening ? 'Stop' : 'Voice input',
                  icon: Icon(_listening ? Icons.mic : Icons.mic_none),
                  color: _listening ? Colors.red : null,
                  onPressed: _toggleVoice,
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            Text('Category', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('None'),
                  selected: _category == null,
                  onSelected: (_) => setState(() => _category = null),
                ),
                for (final c in Task.categories)
                  ChoiceChip(
                    label: Text(c),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Deadline'),
              value: _hasDeadline,
              onChanged: (v) {
                setState(() {
                  _hasDeadline = v;
                  if (v && _deadline == null) {
                    _deadline = DateTime.now().add(const Duration(days: 1));
                  }
                });
              },
            ),
            if (_hasDeadline)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _deadline == null
                      ? 'Pick date & time'
                      : df.format(_deadline!),
                ),
                trailing: const Icon(Icons.event),
                onTap: _pickDeadline,
              ),
          ],
        ),
      ),
    );
  }
}