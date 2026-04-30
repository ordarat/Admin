// Path: lib/screens/main_layout.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text('Orderat - ژووری کۆنترۆڵ', style: TextStyle(color: Colors.white)),
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
        child: Text('سەرکەوتوو بوو! پەیکەری سەرەکی ئامادەیە.', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
      ),
    );
  }
}
