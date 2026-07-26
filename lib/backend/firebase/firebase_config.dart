import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyBMZXXpMihGop4tOZi65rTKht88pyKpDdI",
            authDomain: "espaceperso-483p30.firebaseapp.com",
            projectId: "espaceperso-483p30",
            storageBucket: "espaceperso-483p30.firebasestorage.app",
            messagingSenderId: "563376260248",
            appId: "1:563376260248:web:e6817d2dbee80de4fd7ced"));
  } else {
    await Firebase.initializeApp();
  }
}
