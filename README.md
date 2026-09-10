# MyLifeManager

Android-only Flutter app: Firebase Auth (Google + phone OTP), Firestore tasks, periodic local reminders (rich notification actions), light/dark theme, and a Firestore-driven APK update prompt.

## Prerequisites

1. Install [Flutter](https://docs.flutter.dev/get-started/install) (stable) and Android Studio (Android SDK).
2. From this folder, let Flutter generate missing Android wrapper artifacts if needed:

```bash
cd mylifemanager
flutter create .
```

This fills items like `android/gradle/wrapper/gradle-wrapper.jar` while keeping your `lib/` and `pubspec.yaml`.

3. Install dependencies:

```bash
flutter pub get
```

## Firebase setup (one-time)

Create a Firebase project and register an **Android app** with package name:

`com.mylifemanager.app`

1. Download `google-services.json` and place it at `android/app/google-services.json`.
2. Replace `lib/firebase_options.dart` using FlutterFire CLI (recommended):

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Pick your Firebase project and Android app. This overwrites `lib/firebase_options.dart` with real values.

3. **Authentication**
   - Enable **Google** sign-in provider.
   - Enable **Phone** sign-in provider.
   - For development, add **Phone auth test numbers** in Firebase Console to avoid SMS charges while testing.

4. **Firestore**
   - Create a Firestore database.
   - Deploy rules from `firestore.rules` (Console → Firestore → Rules), or use Firebase CLI:

```bash
firebase deploy --only firestore:rules
```

5. **SHA-1 for Google / Phone auth**
   - Add your debug keystore SHA-1 to Firebase Project settings (needed for Google Sign-In and some Phone flows):

```bash
cd android
./gradlew signingReport
```

Copy the **SHA1** under `Variant: debug` and add it in Firebase Console → Project settings → Your apps → Android app.

## Firestore data layout

- `users/{uid}` — profile + `reminderIntervalMinutes`, `themeMode`
- `users/{uid}/tasks/{taskId}` — task fields (`title`, optional `deadline`, `completed`, timestamps)
- `app_meta/version` — update metadata (public read; maintain via Console)

### `app_meta/version` fields

Create document ID **`version`** inside collection **`app_meta`**:

| Field | Type | Purpose |
|-----|-----|--------|
| `latestVersionCode` | int | Must be greater than `versionCode` in `pubspec.yaml` to prompt update |
| `latestVersionName` | string | Display string, e.g. `1.0.1` |
| `apkUrl` | string | HTTPS download URL for the release APK (see Storage below) |
| `releaseNotes` | string | Shown in update dialog |
| `forceUpdate` | bool | If `true`, user cannot dismiss the dialog |

### Hosting update APKs (free tier friendly)

1. Enable **Firebase Storage**.
2. Upload `app-release.apk` (see build below) to a bucket path, e.g. `releases/mylifemanager-1.0.1.apk`.
3. Create a **download token** link or use a **public** rule for that object if this is acceptable for your threat model (tiny private group). Paste that HTTPS URL into `apkUrl`.

> Keep APK links private if possible (signed URLs / locked-down rules). This template uses a plain URL for simplicity.

## Run on a device / emulator

```bash
flutter run
```

On first launch after login, Android may prompt for:

- Notifications (Android 13+)
- Exact alarms / battery optimizations (best-effort for periodic reminders)

## Release build

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Shipping an update

1. Bump `version:` in `pubspec.yaml`, e.g. `1.0.1+2` (`+` suffix is `versionCode`).
2. `flutter build apk --release`
3. Upload the new APK to Storage; copy the HTTPS download URL.
4. Update Firestore `app_meta/version` with new `latestVersionCode`, `latestVersionName`, `apkUrl`, and `releaseNotes`.

Users see the dialog on next cold start / post-login navigation (`navigateAfterAuthenticated`).

## Notes / limitations

- **Android Doze** can delay alarms; intervals under ~15 minutes are especially unreliable without a foreground service (see TODO in `lib/background/reminder_callback.dart`).
- **Offline mode** is not implemented (by design).
- **iOS / Web** are out of scope for this repo.

## Project layout

- `lib/` — Flutter UI + services
- `android/` — Android embedding, manifest permissions, Kotlin `MainActivity`
- `firestore.rules` — security rules to paste/deploy
