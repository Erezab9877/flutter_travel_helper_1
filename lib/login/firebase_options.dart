// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDDnGSbHTrEGN_54gsbVP5zVgPuq34tIrs',
    appId: '1:459985937820:web:5715be7abdb0f3190ad459',
    messagingSenderId: '459985937820',
    projectId: 'login-flutter-69296',
    authDomain: 'login-flutter-69296.firebaseapp.com',
    storageBucket: 'login-flutter-69296.appspot.com',
    measurementId: 'G-SXHT9E1XHN',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCtSM7qTRFaCiPJ3p_9mXRX3h9qIwu3Ugg',
    appId: '1:459985937820:android:2e0e31c0235af5e00ad459',
    messagingSenderId: '459985937820',
    projectId: 'login-flutter-69296',
    storageBucket: 'login-flutter-69296.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBmQgVcDXDAsQhe91C-_HXRYG_3AzF_9Nw',
    appId: '1:459985937820:ios:78feda8ad89cbadc0ad459',
    messagingSenderId: '459985937820',
    projectId: 'login-flutter-69296',
    storageBucket: 'login-flutter-69296.appspot.com',
    iosClientId: '459985937820-46j8ab1vjqmhsbco0jb3ekubbuuc1fre.apps.googleusercontent.com',
    iosBundleId: 'com.example.loginSingup',
  );
}
