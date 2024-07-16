import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('DefaultFirebaseOptions have not been configured for web - you can reconfigure this by running the FlutterFire CLI again.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError('DefaultFirebaseOptions have not been configured for macos - you can reconfigure this by running the FlutterFire CLI again.');
      case TargetPlatform.windows:
        throw UnsupportedError('DefaultFirebaseOptions have not been configured for windows - you can reconfigure this by running the FlutterFire CLI again.');
      case TargetPlatform.linux:
        throw UnsupportedError('DefaultFirebaseOptions have not been configured for linux - you can reconfigure this by running the FlutterFire CLI again.');
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCJ7j6UkusqSYmYJVxOhX5FBNJIHgRoPzg',
    appId: '1:956543722682:android:585fae88e7cfeaa3cece83',
    messagingSenderId: '956543722682',
    projectId: 'ukbtapp',
    storageBucket: 'ukbtapp.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDezXBSJCmaxOI2Q8002zdgSzEolXUu_7w',
    appId: '1:956543722682:ios:a869bdc80ab5d6dccece83',
    messagingSenderId: '956543722682',
    projectId: 'ukbtapp',
    storageBucket: 'ukbtapp.appspot.com',
    iosBundleId: 'com.ukbt.ukbtapp',
  );
}
