// Path: lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/admin_login.dart';
import 'screens/main_layout.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AdminApp());
}

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  bool _isInit = false;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebaseSafe();
  }

  // ئەمە نهێنییەکەیە بۆ ئەوەی قەت شاشەی رەساسی نەدات
  Future<void> _initializeFirebaseSafe() async {
    try {
      await Firebase.initializeApp();
      if (mounted) setState(() => _isInit = true);
    } catch (e) {
      if (mounted) setState(() => _isError = true);
      debugPrint('Firebase Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ئەگەر کێشەی فایەربەیس هەبوو
    if (_isError) {
      return const MaterialApp(home: Scaffold(body: Center(child: Text('کێشە لە پەیوەندی بە داتابەیسەوە هەیە', style: TextStyle(color: Colors.red, fontSize: 20)))));
    }

    // ئەگەر خەریکی لۆدینگە
    if (!_isInit) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF1E1E2C),
          body: Center(child: CircularProgressIndicator(color: Colors.deepOrange)),
        ),
      );
    }

    // کاتێک هەموو شتێک ئامادەیە
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Orderat Admin Control',
      theme: ThemeData(
        primaryColor: const Color(0xFF1E1E2C),
        scaffoldBackgroundColor: const Color(0xFFF4F7FC),
        fontFamily: 'Roboto',
      ),
      // پشکنەری زیرەک: ئەگەر لۆگین بووە بیبە ژوورەوە، ئەگەرنا بۆ شاشەی لۆگین
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(backgroundColor: Color(0xFF1E1E2C), body: Center(child: CircularProgressIndicator(color: Colors.deepOrange)));
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
