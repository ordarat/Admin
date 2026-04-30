// Path: lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/main_layout.dart';
import 'screens/admin_login.dart'; // هێنانی شاشەی چوونەژوورەوە

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase Error: $e');
  }
  runApp(const AdminPanelApp());
}

class AdminPanelApp extends StatelessWidget {
  const AdminPanelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Orderat Admin Panel',
      theme: ThemeData(
        primaryColor: const Color(0xFF1E1E2C),
        scaffoldBackgroundColor: const Color(0xFFF4F7FC),
        cardTheme: CardTheme(color: Colors.white, elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        fontFamily: 'Roboto',
      ),
      // سیستەمی زیرەک: ئەگەر پێشتر لۆگین بووە بیبە ژوورەوە، ئەگەرنا بیبە شاشەی لۆگین
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData && snapshot.data != null) {
            return const MainLayout(); // راستەوخۆ دەچێتە داشبۆرد
          }
          return const AdminLoginScreen(); // دەچێتە شاشەی لۆگین
        },
      ),
    );
  }
}
