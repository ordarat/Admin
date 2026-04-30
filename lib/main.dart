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
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeFirebaseSafe();
  }

  Future<void> _initializeFirebaseSafe() async {
    try {
      // پشکنین دەکات بزانێت پێشتر کارا بووە یان نا
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      if (mounted) setState(() => _isInit = true);
    } catch (e) {
      // لێرەدا ئێرۆرە راستەقینەکە دەگرین بۆ ئەوەی بیخەینە سەر شاشەکە
      if (mounted) setState(() => _errorMessage = e.toString());
      debugPrint('Firebase Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ئەگەر کێشەی فایەربەیس هەبوو، ئێرۆرەکەمان بە ئینگلیزی بۆ پیشان دەدات
    if (_errorMessage.isNotEmpty) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 20),
                  const Text('کێشە لە پەیوەندی بە داتابەیسەوە هەیە', style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  // ئەمە ئەو بەشە گرنگەیە کە پێمان دەڵێت کێشەکە چییە
                  Text(_errorMessage, style: const TextStyle(color: Colors.grey, fontSize: 14), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      );
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

    // کاتێک هەموو شتێک ئامادەیە، بزانە لۆگین بووە یان نا
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Orderat Admin Control',
      theme: ThemeData(
        primaryColor: const Color(0xFF1E1E2C),
        scaffoldBackgroundColor: const Color(0xFFF4F7FC),
        fontFamily: 'Roboto',
      ),
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
