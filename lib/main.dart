// Path: lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/admin_login.dart';
import 'screens/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // بەستنەوەی فایەربەیس بە کۆدەکانی خۆتەوە
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
      home: const SplashScreen(), 
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainLayout()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminLoginScreen()));
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'کێشە هەیە لە بەستنەوەی فایەربەیس!\nتکایە دڵنیابە کە کۆدەکانی فایەربەیس لەناو فایلی main.dart دانراون.\n\n$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.dashboard_customize, size: 80, color: Color(0xFF0056D2)),
              ),
              const SizedBox(height: 30),
              const Text('ئۆردەرات ئەدمین', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('سیستەمی بەڕێوەبردنی گەیاندن', style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 50),
              
              if (_errorMessage.isEmpty)
                const CircularProgressIndicator(color: Colors.white)
              else
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red)),
                  child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent, fontSize: 14), textAlign: TextAlign.center, textDirection: TextDirection.ltr),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
