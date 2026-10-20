import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Generated standard options for HamPA cross-platform runtime.
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
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyDemoHamPAKeyForWebClient998877',
    appId: '1:1029384756:web:a1b2c3d4e5f6',
    messagingSenderId: '1029384756',
    projectId: 'hampa-planner',
    authDomain: 'hampa-planner.firebaseapp.com',
    storageBucket: 'hampa-planner.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDemoHamPAKeyForAndroidClient112233',
    appId: '1:1029384756:android:b2c3d4e5f6a1',
    messagingSenderId: '1029384756',
    projectId: 'hampa-planner',
    storageBucket: 'hampa-planner.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDemoHamPAKeyForIOSClient445566',
    appId: '1:1029384756:ios:c3d4e5f6a1b2',
    messagingSenderId: '1029384756',
    projectId: 'hampa-planner',
    storageBucket: 'hampa-planner.appspot.com',
    iosBundleId: 'com.hampa.planner',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDemoHamPAKeyForMacOSClient778899',
    appId: '1:1029384756:ios:d4e5f6a1b2c3',
    messagingSenderId: '1029384756',
    projectId: 'hampa-planner',
    storageBucket: 'hampa-planner.appspot.com',
    iosBundleId: 'com.hampa.planner',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDemoHamPAKeyForWindowsClient123456',
    appId: '1:1029384756:web:e5f6a1b2c3d4',
    messagingSenderId: '1029384756',
    projectId: 'hampa-planner',
    authDomain: 'hampa-planner.firebaseapp.com',
    storageBucket: 'hampa-planner.appspot.com',
  );
}
