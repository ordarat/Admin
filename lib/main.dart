// Path: lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // لێرەدا گەڕاندمانەوە بۆ شێوازە ئاساییەکەی خۆت بەبێ فایلی firebase_options
  await Firebase.initializeApp();
  
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
