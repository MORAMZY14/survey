// Placeholder generated-file shape.
//
// Run `flutterfire configure` before using the app. FlutterFire will replace
// this file with the options for your own Firebase project.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'This starter is configured for Android and iOS. '
        'Run flutterfire configure to add web.',
      );
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => throw UnsupportedError(
        'Block Survey currently supports Android and iOS.',
      ),
    };
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_FIREBASE_API_KEY',
    appId: 'YOUR_ANDROID_FIREBASE_APP_ID',
    messagingSenderId: 'YOUR_FIREBASE_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_FIREBASE_API_KEY',
    appId: 'YOUR_IOS_FIREBASE_APP_ID',
    messagingSenderId: 'YOUR_FIREBASE_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.firebasestorage.app',
    iosBundleId: 'com.mmr.blockSurvey',
  );
}
