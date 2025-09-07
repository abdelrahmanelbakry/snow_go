// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for Web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios; // reuse iOS values if you target macOS
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBbSHu9HWcqc8LhvWYl-_FwsGdmV_n-pv0',
    appId: '1:231046720884:android:a0ad79d503baebaa55d021',
    messagingSenderId: '231046720884',
    projectId: 'snowclearing-22e83',
    storageBucket: 'snowclearing-22e83.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: '231046720884', // same sender ID
    projectId: 'snowclearing-22e83',
    storageBucket: 'snowclearing-22e83.firebasestorage.app',
    iosBundleId: 'com.masstech.snow_go',
  );
}
