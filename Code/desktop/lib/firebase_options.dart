import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default FirebaseOptions for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAwwtacepuuKo2Q8OGNupZpTj2AAWbtOMc',
    appId: '1:638722588860:web:98babc48aa8e14d76bd0b9',
    messagingSenderId: '638722588860',
    projectId: 'car-care-97882',
    authDomain: 'car-care-97882.firebaseapp.com',
    storageBucket: 'car-care-97882.firebasestorage.app',
    measurementId: 'G-BX4NWYV7YQ',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAwwtacepuuKo2Q8OGNupZpTj2AAWbtOMc',
    appId: '1:638722588860:web:01e8154cc72be9486bd0b9',
    messagingSenderId: '638722588860',
    projectId: 'car-care-97882',
    authDomain: 'car-care-97882.firebaseapp.com',
    storageBucket: 'car-care-97882.firebasestorage.app',
    measurementId: 'G-W922GNQ3P5',
  );
} 