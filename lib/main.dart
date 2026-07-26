import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';

const String appVersion = 'V1.0.11';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? firebaseError;
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (options.projectId == 'YOUR_PROJECT_ID') {
      throw StateError(
        'Firebase has not been configured. Run flutterfire configure.',
      );
    }
    await Firebase.initializeApp(options: options);
  } catch (error) {
    firebaseError = error;
  }

  runApp(BlockSurveyApp(firebaseError: firebaseError));
}
