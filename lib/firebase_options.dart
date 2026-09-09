// File generated for Firebase project: mylifemanager-25220

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('MyLifeManager is Android-only in this project.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCIiOhCk9vGEHI-ga0MRTZ2mNY_8-cxFdQ',
    appId: '1:891664406669:android:1e0e321a8e53576382eac4',
    messagingSenderId: '891664406669',
    projectId: 'mylifemanager-25220',
    storageBucket: 'mylifemanager-25220.firebasestorage.app',
  );
}