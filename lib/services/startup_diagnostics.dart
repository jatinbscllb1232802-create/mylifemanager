import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StartupDiagnostics {
  StartupDiagnostics._();

  static final StartupDiagnostics instance = StartupDiagnostics._();

  static const String _storageKey = 'startup_diagnostic_log';

  Future<void> log(String message) async {
    final timestamp = DateTime.now().toIso8601String();
    final entry = '$timestamp | $message';

    debugPrint('STARTUP | $message');

    try {
      final prefs = await SharedPreferences.getInstance();

      final logs = prefs.getStringList(_storageKey) ?? <String>[];
      logs.add(entry);

      if (logs.length > 200) {
        logs.removeRange(0, logs.length - 200);
      }

      await prefs.setStringList(_storageKey, logs);
    } catch (e) {
      debugPrint('STARTUP LOG ERROR | $e');
    }
  }

  Future<List<String>> getLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_storageKey) ?? <String>[];
    } catch (_) {
      return <String>[];
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }
}