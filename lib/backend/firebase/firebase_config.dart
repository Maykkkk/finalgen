import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyB6rjbxZd6mvyM4PSHpcbDFGmb1-L7nKN4",
            authDomain: "gptclone-ff12d.firebaseapp.com",
            projectId: "gptclone-ff12d",
            storageBucket: "gptclone-ff12d.firebasestorage.app",
            messagingSenderId: "483562007711",
            appId: "1:483562007711:web:9c49ad96fa36bfb08346aa",
            measurementId: "G-TDYSVLXDC6"));
  } else {
    await Firebase.initializeApp();
  }
}
