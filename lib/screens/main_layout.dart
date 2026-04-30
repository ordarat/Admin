// Path: lib/screens/main_layout.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2C),
        foregroundColor: Colors.white,
        title: const Text('پەناڵی بەڕێوەبردن (سەرکەوتوو بوو)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          )
        ],
      ),
      body: const Center(
        child: Text(
          'بناغەی سیستەمەکە سەد لە سەد بێ کێشەیە!\nئێستا دەتوانین شاشەکانی تری تێبکەین.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
        ),
      ),
    );
  }
}
