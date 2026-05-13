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
    apiKey: 'AIzaSyBKTqL1YdvuV5pxJ-X8LBVFfS2yDhlrZ9Y',
    appId: '1:430458590777:android:b0299d90ace687f7d11fe8',
    messagingSenderId: '430458590777',
    projectId: 'smarthjelp-4dd66',
    storageBucket: 'smarthjelp-4dd66.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'demo',
    appId: 'demo',
    messagingSenderId: 'demo',
    projectId: 'demo',
  );
}