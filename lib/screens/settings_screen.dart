// Path: lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _deliveryFeeController = TextEditingController();
  final TextEditingController _driverCutController = TextEditingController();
  final TextEditingController _companyCutController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // هێنانی زانیارییەکان لە فایەربەیسەوە لە کاتی کردنەوەی شاشەکە
  Future<void> _loadSettings() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('App_Settings').doc('Financials').get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        _deliveryFeeController.text = data['default_delivery_fee'].toString();
        _driverCutController.text = data['default_driver_cut'].toString();
        _companyCutController.text = data['default_company_cut'].toString();
      } else {
        // ئەگەر یەکەم جار بوو، ئەم نرخانە وەک سەرەتا دادەنێت
        _deliveryFeeController.text = '3000';
        _driverCutController.text = '2500';
        _companyCutController.text = '500';
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  // خەزنکردنی گۆڕانکارییەکان بۆ ناو فایەربەیس
  Future<void> _saveSettings() async {
    setState(() { _isLoading = true; });
    try {
      await FirebaseFirestore.instance.collection('App_Settings').doc('Financials').set({
        'default_delivery_fee': int.tryParse(_deliveryFeeController.text.trim()) ?? 0,
        'default_driver_cut': int.tryParse(_driverCutController.text.trim()) ?? 0,
        'default_company_cut': int.tryParse(_companyCutController.text.trim()) ?? 0,
        'last_updated': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رێکخستنەکان بە سەرکەوتوویی نوێکرانەوە'), backgroundColor: Colors.green));
    } catch (e) {
      print(e);
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('رێکخستنە داراییە دینامیکییەکان', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
              const SizedBox(height: 10),
              const Text('هەر گۆڕانکارییەک لێرە بکەیت، راستەوخۆ لەسەر مۆبایلی شۆفێر و خوارنگەهەکان جێبەجێ دەبێت.', style: TextStyle(color: Colors.grey)),
              const Divider(height: 40, thickness: 1),
              
              SizedBox(
                width: 400,
                child: Column(
                  children: [
                    TextField(
                      controller: _deliveryFeeController,
                      decoration: const InputDecoration(labelText: 'کۆی گشتی کرێی گەیاندن (بۆ کڕیار)', border: OutlineInputBorder(), prefixText: 'IQD '),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _driverCutController,
                      decoration: const InputDecoration(labelText: 'پشکی شۆفێر لە گەیاندنەکە', border: OutlineInputBorder(), prefixText: 'IQD '),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _companyCutController,
                      decoration: const InputDecoration(labelText: 'پشکی سافی کۆمپانیا', border: OutlineInputBorder(), prefixText: 'IQD '),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save),
                      label: const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text('پاشەکەوتکردنی گۆڕانکارییەکان', style: TextStyle(fontSize: 18)),
                      ),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
