import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // لێرەدا کۆنفیگەکانی تۆم داناوە بۆ ئەوەی وێبەکە بێ کێشە کار بکات
  if (kIsWeb) {
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
  } else {
    // بۆ ئەندرۆید و پلاتفۆرمەکانی تر بە شێوازە ئاساییەکە دەستپێدەکات
    await Firebase.initializeApp();
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ordarat Admin',
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        primaryColor: const Color(0xFF0056D2),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0056D2)),
        useMaterial3: true, 
      ),
      home: const SplashScreen(), 
    );
  }
}
