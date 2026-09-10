import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';
import '../models/user_settings.dart';
import '../services/reminder_scheduler.dart';
import '../services/settings_service.dart';
import 'auth_provider.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({
    required SettingsService settingsService,
    required AuthProvider authProvider,
  })  : _settingsService = settingsService,
        _authProvider = authProvider {
    _authProvider.addListener(_onAuthChanged);
    unawaited(loadCachedTheme());
    _onAuthChanged();
  }

  final SettingsService _settingsService;
  final AuthProvider _authProvider;

  StreamSubscription<UserSettings>? _settingsSub;

  UserSettings _settings = UserSettings.initial();

  UserSettings get settings => _settings;

  Future<void> loadCachedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(StorageKeys.themeMode);
    _settings = _settings.copyWith(
      themeMode: UserSettings.themeModeFromStorage(raw),
    );
    notifyListeners();
  }

  void _onAuthChanged() {
    _settingsSub?.cancel();
    final uid = _authProvider.user?.uid;
    if (uid == null) {
      unawaited(ReminderScheduler.cancel());
      return;
    }
    _settingsSub = _settingsService.watchSettings(uid).listen((remote) async {
      _settings = remote;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        StorageKeys.themeMode,
        UserSettings.themeModeToStorage(remote.themeMode),
      );
      await ReminderScheduler.scheduleEveryMinutes(
        remote.reminderIntervalMinutes,
      );
    });
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final uid = _authProvider.user?.uid;
    if (uid == null) return;
    await _settingsService.updateThemeMode(uid, mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      StorageKeys.themeMode,
      UserSettings.themeModeToStorage(mode),
    );
    _settings = _settings.copyWith(themeMode: mode);
    notifyListeners();
  }

  Future<void> setReminderIntervalMinutes(int minutes) async {
    final uid = _authProvider.user?.uid;
    if (uid == null) return;
    final safe = minutes.clamp(
      ReminderScheduler.minimumIntervalMinutes,
      24 * 60,
    );
    await _settingsService.updateReminderInterval(uid, safe);
    await ReminderScheduler.scheduleEveryMinutes(safe);
  }

  /// Requests the only runtime permission needed by the reminder notification.
  /// WorkManager does not require exact-alarm or battery-optimization permissions.
  Future<void> requestAndroidReminderPermissions() async {
    await Permission.notification.request();
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    _settingsSub?.cancel();
    super.dispose();
  }
}
