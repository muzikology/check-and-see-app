import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyB-TQH560c-OlYvndMiH45CtrFbdYwuKlo",
            authDomain: "ai-health-scanner-5e3b9.firebaseapp.com",
            projectId: "ai-health-scanner-5e3b9",
            storageBucket: "ai-health-scanner-5e3b9.firebasestorage.app",
            messagingSenderId: "285904969298",
            appId: "1:285904969298:web:27eac5a024a90ebe84898b"));
  } else {
    await Firebase.initializeApp();
  }
}
