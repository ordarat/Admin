// Path: lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/main_layout.dart';
import 'screens/admin_login.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      // بانگکردنی سیستەمی پشکنەری زیرەک لەبری ئەوەی یەکسەر فایەربەیس بەکاربهێنێت
      home: const AppInitializer(),
    );
  }
}

// ئەم کلاسە کێشەی شاشە رەساسییەکە چارەسەر دەکات
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isFirebaseReady = false;

  @override
  void initState() {
    super.initState();
    _initializeSafeFirebase();
  }

  // بە سەلامەتی فایەربەیس کارپێدەکات بێ ئەوەی کراش بکات
  Future<void> _initializeSafeFirebase() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase Init Error: $e');
    }
    
    if (mounted) {
      setState(() {
        _isFirebaseReady = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ئەگەر فایەربەیس ئامادە نەبوو، شاشەیەکی لۆدینگی جوان پیشان بدە نەک رەساسی
    if (!_isFirebaseReady) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E1E2C),
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepOrange),
        ),
      );
    }

    // ئێستا کە فایەربەیس سەلامەتە، بزانە لۆگین بووە یان نا
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF1E1E2C),
            body: Center(child: CircularProgressIndicator(color: Colors.deepOrange)),
          );
        }
        
        // ئەگەر پێشتر لۆگین بووبوو، یەکسەر بیبە ژوورەوە (Auto-Login)
        if (snapshot.hasData && snapshot.data != null) {
          return const MainLayout();
        }
        
        // ئەگەرنا، بیبە شاشەی لۆگین
        return const AdminLoginScreen();
      },
    );
  }
}
