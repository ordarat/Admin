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

  // هێنانی ژمارە کۆنەکە بۆ ناو خانەکە
  Future<void> _loadSettings() async {
    var doc = await FirebaseFirestore.instance.collection('App_Settings').doc('Contact').get();
    if (doc.exists && doc.data() != null) {
      setState(() {
        _whatsappController.text = doc.data()!['whatsapp'] ?? '';
      });
    }
  }

  // سەیڤکردنی ژمارە نوێیەکە
  Future<void> _saveSettings() async {
    setState(() { _isLoading = true; });
    try {
      await FirebaseFirestore.instance.collection('App_Settings').doc('Contact').set({
        'whatsapp': _whatsappController.text.trim(),
      }, SetOptions(merge: true));
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ژمارەی واتسئاپ بە سەرکەوتوویی نوێکرایەوە!'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('هەڵە: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('رێکخستنەکانی سیستەم', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.indigo)),
          const SizedBox(height: 20),
          
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('بەستەری پەیوەندیکردن (واتسئاپ)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text('ئەم ژمارەیە لە شاشەی لۆگینی هەموو شۆفێر و خوارنگەهەکان دەردەکەوێت بۆ ئەوەی راستەوخۆ نامەت بۆ بنێرن. (بۆ نموونە: 9647501234567)', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _whatsappController,
                          decoration: InputDecoration(
                            labelText: 'ژمارەی مۆبایل بە کۆدی وڵاتەوە',
                            prefixIcon: const Icon(Icons.chat, color: Colors.green),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isLoading ? null : _saveSettings,
                        icon: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.save),
                        label: const Text('سەیڤکردن', style: TextStyle(fontSize: 18)),
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
