import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return web;
      default:
        throw UnsupportedError(
          'Unsupported platform for Firebase',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'demo',
    appId: 'demo',
    messagingSenderId: 'demo',
    projectId: 'demo',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'demo',
    appId: 'demo',
    messagingSenderId: 'demo',
    projectId: 'demo',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'demo',
    appId: 'demo',
    messagingSenderId: 'demo',
    projectId: 'demo',
  );
}