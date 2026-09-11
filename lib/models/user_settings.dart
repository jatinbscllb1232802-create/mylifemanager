import 'package:flutter/material.dart';

class UserSettings {
  UserSettings({
    required this.reminderIntervalMinutes,
    required this.themeMode,
  });

  factory UserSettings.initial() => UserSettings(
        reminderIntervalMinutes: 30,
        themeMode: themeModeFromStorage(null),
      );

  final int reminderIntervalMinutes;
  final ThemeMode themeMode;

  UserSettings copyWith({
    int? reminderIntervalMinutes,
    ThemeMode? themeMode,
  }) {
    return UserSettings(
      reminderIntervalMinutes:
          reminderIntervalMinutes ?? this.reminderIntervalMinutes,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  static ThemeMode themeModeFromStorage(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String themeModeToStorage(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static UserSettings fromFirestore(Map<String, dynamic> data) {
    final interval = (data['reminderIntervalMinutes'] as num?)?.toInt() ?? 30;
    final themeRaw = data['themeMode'] as String?;
    return UserSettings(
      reminderIntervalMinutes: interval.clamp(15, 24 * 60),
      themeMode: themeModeFromStorage(themeRaw),
    );
  }

  Map<String, dynamic> toFirestoreFields() {
    return {
      'reminderIntervalMinutes': reminderIntervalMinutes,
      'themeMode': themeModeToStorage(themeMode),
    };
  }
}
