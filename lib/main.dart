// Path: lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

void main() async {
  // دڵنیابوون لەوەی هەموو شتێک ئامادەیە پێش کارپێکردنی ئەپەکە
  WidgetsFlutterBinding.ensureInitialized();
  
  // بەستنەوەی ئەپەکە بە فایەربەیسەوە بە بەکارهێنانی کۆنفگەکانی وێب
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ordarat Admin',
      debugShowCheckedModeBanner: false, // شاردنەوەی نیشانەی دیبەگ لە سەرەوە
      theme: ThemeData(
        // بەکارهێنانی ڕەنگە شینەکەی لۆگۆکەت وەک ڕەنگی سەرەکی سیستەمەکە
        primaryColor: const Color(0xFF0056D2),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0056D2)),
        useMaterial3: true, // بەکارهێنانی نوێترین دیزاینی گوگڵ
      ),
      // یەکەم شاشە کە دەکرێتەوە شاشەی لۆگۆکەیە
      home: const SplashScreen(), 
    );
  }
}
