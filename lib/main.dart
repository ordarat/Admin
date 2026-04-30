// Path: lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'screens/admin_login.dart';
import 'screens/main_layout.dart';

// رێگەی سەلامەت بۆ کارپێکردنی فایەربەیس پێش کردنەوەی ئەپەکە
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyDnxL-BwDIeYAD-r0K_NOsMm1i1Za_9OEg",
          authDomain: "ordarat-app.firebaseapp.com",
          databaseURL: "https://ordarat-app-default-rtdb.europe-west1.firebasedatabase.app",
          projectId: "ordarat-app",
          storageBucket: "ordarat-app.firebasestorage.app",
          messagingSenderId: "734935691543",
          appId: "1:734935691543:web:bc364b11c214cdad9c0752",
          measurementId: "G-B2427LRVWN",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint("Firebase Error: $e");
  }

  runApp(const AdminControlPanel());
}

class AdminControlPanel extends StatelessWidget {
  const AdminControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ordarat Admin',
      theme: ThemeData(
        primaryColor: const Color(0xFF1E1E2C),
        scaffoldBackgroundColor: const Color(0xFFF4F7FC),
        fontFamily: 'Roboto',
      ),
      // پشکنەری زیرەک بۆ لۆگین
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF1E1E2C),
              body: Center(child: CircularProgressIndicator(color: Colors.deepOrange)),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return const MainLayout();
          }
          return const AdminLoginScreen();
        },
      ),
    );
  }
}
