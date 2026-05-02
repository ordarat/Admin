// Path: lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// هێنانی شاشەکان بۆ ناو فایلی سەرەکی (ئەمە ئەو دێڕەیە کە کێشەکەی چارەسەر کرد)
import 'screens/admin_login.dart';
import 'screens/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // کاراکردنی فایەربەیس
  try {
    await Firebase.initializeApp(
      // تێبینیی گرنگ بۆ مامۆستا ئیبراهیم:
      // ئەگەر پێشتر کۆدێکی درێژی فایەربەیس (apiKey, appId...) لێرە بوو، ئەوا لەناو ئەم قەوسەدا دایبنێوە.
      // یان ئەگەر فایلی (firebase_options.dart)ت هەیە، دەتوانیت ئەمە بەکاربهێنیت:
      // options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }
  
  runApp(const OrdaratAdminApp());
}

class OrdaratAdminApp extends StatelessWidget {
  const OrdaratAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ئۆردەرات - پەنەڵی بەڕێوەبەر',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0056D2),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0056D2)),
      ),
      home: const SplashScreen(), // یەکەم شاشە دەچێتە سپلاش سکرین بۆ پشکنین
    );
  }
}

// شاشەی سەرەتا (Splash Screen) کە دیزاینێکی زۆر ناوازەی هەیە
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  // مێشکی ئەپەکە: پشکنین دەکات بزانێت پێشتر لۆگینت کردووە یان نا
  Future<void> _checkAuthentication() async {
    // چاوەڕێکردن بۆ ٢ چرکە بۆ ئەوەی لۆگۆکە بە جوانی پیشان بدات
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // هێنانی داتای بەکارهێنەر لە فایەربەیسەوە
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // ئەگەر لۆگینی کردبوو، ڕاستەوخۆ بیبە بۆ پەنەڵی سەرەکی
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainLayout()),
      );
    } else {
      // ئەگەر لۆگینی نەکردبوو، بیبە بۆ شاشەی چوونەژوورەوە 
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C), // رەنگی باکگراوندی تاریکی ئەدمین پەنەڵ
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // بازنەیەکی سپی و لۆگۆیەکی شین
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.dashboard_customize,
                size: 80,
                color: Color(0xFF0056D2),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'ئۆردەرات ئەدمین',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'سیستەمی بەڕێوەبردنی گەیاندن',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
