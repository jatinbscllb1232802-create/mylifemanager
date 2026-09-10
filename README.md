# MyLifeManager

Android-first Flutter task manager with Google Sign-In, Cloud Firestore task sync, local notifications, and WorkManager-based background reminders.

## Prerequisites

1. Install Flutter (stable) and Android Studio with the Android SDK.
2. From the project directory run:

```bash
flutter pub get
```

## Firebase setup

The Android package name is:

`com.mylifemanager.app`

The repository includes the Android Firebase configuration and generated FlutterFire options used by the project.

In Firebase Console:

1. Enable Google sign-in under Authentication.
2. Create/enable Cloud Firestore.
3. Deploy `firestore.rules`.

## Firestore data layout

- `users/{uid}` — profile plus `reminderIntervalMinutes` and `themeMode`
- `users/{uid}/tasks/{taskId}` — task fields and timestamps
- `app_meta/version` — optional update metadata

### `app_meta/version`

| Field | Type | Purpose |
|---|---|---|
| `latestVersionCode` | int | Release version code to compare with the installed app |
| `latestVersionName` | string | Display version, e.g. `1.0.1` |
| `apkUrl` | string | HTTPS download URL for the release APK |
| `releaseNotes` | string | Shown in the update dialog |
| `forceUpdate` | bool | Prevents dismissing a required update |

## Reminders

Reminders use **WorkManager** as the single background scheduling system. Android WorkManager has a 15-minute minimum periodic interval, so the app accepts reminder intervals from 15 minutes through 24 hours.

The Settings diagnostics include an immediate notification test and a one-minute one-off WorkManager test. Android 13+ notification permission is requested when reminder diagnostics are used.

WorkManager may defer execution because Android controls background scheduling and battery optimization. A periodic interval is therefore a scheduling hint, not an exact alarm.

## Offline task changes

Task additions, completion, snoozing, and deletion can be queued while offline. Every queued operation is bound to the Firebase UID that created it so operations cannot be replayed into another signed-in account.

## Release build

```bash
flutter build apk --release
```

Output:

`build/app/outputs/flutter-apk/app-release.apk`

Bump the `version:` in `pubspec.yaml` before shipping a new release. The `+` suffix is the Android version code.

## Repository hygiene

Generated Flutter/Dart tooling and IDE files are intentionally ignored and should not be committed. Run `flutter pub get` after cloning to regenerate local dependency metadata.

## Project layout

- `lib/` — Flutter UI, providers, services, and background task handler
- `android/` — Android application configuration
- `firestore.rules` — Firestore security rules
