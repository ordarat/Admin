// Path: lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/main_layout.dart'; // ئەمە ئەو فایلە نوێیەیە کە دروستی دەکەین

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
        primaryColor: const Color(0xFF1E1E2C), // رەنگی سەرەکی داشبۆرد (شینێکی تاریکی شاز)
        scaffoldBackgroundColor: const Color(0xFFF4F7FC), // باکگراوندێکی رەساسی زۆر کاڵ بۆ دەرخستنی کارتەکان
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        fontFamily: 'Roboto', // فۆنتێکی ستاندارد و خاوێن
      ),
      // راستەوخۆ دەچێتە ناو داشبۆردە نوێیەکە
      home: const MainLayout(), 
    );
  }
}
