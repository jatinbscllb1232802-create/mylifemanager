import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/user_settings.dart';

class SettingsService {
  SettingsService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  Stream<UserSettings> watchSettings(String uid) {
    return _userDoc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) {
        return UserSettings.initial();
      }
      return UserSettings.fromFirestore(data);
    });
  }

  Future<UserSettings> getSettings(String uid) async {
    final doc = await _userDoc(uid).get();
    final data = doc.data();
    if (data == null) {
      return UserSettings.initial();
    }
    return UserSettings.fromFirestore(data);
  }

  /// Ensures `users/{uid}` exists with sane defaults (merge write).
  Future<void> ensureUserDocument({
    required String uid,
    String? displayName,
    String? email,
    String? phone,
  }) async {
    final ref = _userDoc(uid);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        if (displayName != null) 'displayName': displayName,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
        'reminderIntervalMinutes': 30,
        'themeMode': 'system',
      });
      return;
    }

    await ref.set({
      if (displayName != null) 'displayName': displayName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
    }, SetOptions(merge: true));
  }

  Future<void> updateReminderInterval(String uid, int minutes) async {
    final safe = minutes.clamp(15, 24 * 60);
    await _userDoc(uid).update({
      'reminderIntervalMinutes': safe,
    });
  }

  Future<void> updateThemeMode(String uid, ThemeMode mode) async {
    await _userDoc(uid).update({
      'themeMode': UserSettings.themeModeToStorage(mode),
    });
  }
}
