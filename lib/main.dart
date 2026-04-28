// Path: lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/admin_login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDnxL-BwDIeYAD-r0K_NOsMm1i1Za_9OEg",
      authDomain: "ordarat-app.firebaseapp.com",
      projectId: "ordarat-app",
      storageBucket: "ordarat-app.firebasestorage.app",
      messagingSenderId: "734935691543",
      appId: "1:734935691543:web:bc364b11c214cdad9c0752",
      measurementId: "G-B2427LRVWN",
    ),
  );

  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ordarat Admin Panel',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const AdminLoginScreen(),
    );
  }
}
