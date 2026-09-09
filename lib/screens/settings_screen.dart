import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;
    final currentMinutes = settings.reminderIntervalMinutes;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Reminder interval',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'A notification will show your pending tasks on this schedule (Android may delay alarms slightly).',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in const [15, 20, 30])
                ChoiceChip(
                  label: Text('$m min'),
                  selected: currentMinutes == m,
                  onSelected: (_) async {
                    await context
                        .read<SettingsProvider>()
                        .setReminderIntervalMinutes(m);
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _customController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Custom interval (minutes)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () async {
              final raw = int.tryParse(_customController.text.trim());
              if (raw == null || raw <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a positive number.')),
                );
                return;
              }
              await context
                  .read<SettingsProvider>()
                  .setReminderIntervalMinutes(raw);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Reminder interval set to $raw minutes'),
                ),
              );
            },
            child: const Text('Apply custom interval'),
          ),
          const SizedBox(height: 16),
          // Shows the currently active interval
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Currently set to every $currentMinutes minute${currentMinutes == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          const Divider(height: 32),
          Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.phone_android_outlined),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (selection) async {
              final mode = selection.first;
              await context.read<SettingsProvider>().setThemeMode(mode);
            },
          ),
        ],
      ),
    );
  }
}