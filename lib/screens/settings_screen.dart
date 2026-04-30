// Path: lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _whatsappController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    var doc = await FirebaseFirestore.instance.collection('App_Settings').doc('Contact').get();
    if (doc.exists && doc.data() != null) {
      setState(() { _whatsappController.text = doc.data()!['whatsapp'] ?? ''; });
    }
  }

  Future<void> _saveSettings() async {
    if (_whatsappController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('App_Settings').doc('Contact').set({
        'whatsapp': _whatsappController.text.trim(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ژمارەکە بە سەرکەوتوویی نوێکرایەوە!'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('هەڵە: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 15.0 : 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('رێکخستنەکانی سیستەم', style: TextStyle(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E2C))),
          const SizedBox(height: 30),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 15.0 : 25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ژمارەی واتسئاپ بۆ پەیوەندی کردن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text('ئەم ژمارەیە لەلایەن شۆفێر و خوارنگەهەکانەوە بەکاردێت بۆ پەیوەندیکردن بە ئیدارەوە.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  
                  isMobile 
                  ? Column(
                      children: [
                        TextField(controller: _whatsappController, decoration: InputDecoration(labelText: 'ژمارەی واتسئاپ بەبێ (+)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), prefixIcon: const Icon(Icons.chat, color: Colors.green))),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                            onPressed: _isLoading ? null : _saveSettings,
                            icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
                            label: const Text('سەیڤکردن', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: TextField(controller: _whatsappController, decoration: InputDecoration(labelText: 'ژمارەی واتسئاپ بەبێ (+)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), prefixIcon: const Icon(Icons.chat, color: Colors.green)))),
                        const SizedBox(width: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20)),
                          onPressed: _isLoading ? null : _saveSettings,
                          icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
                          label: const Text('سەیڤکردن', style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
