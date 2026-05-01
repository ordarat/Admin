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
  final TextEditingController _companyPercentController = TextEditingController();
  final TextEditingController _driverDeliveryFeeController = TextEditingController();
  
  // زیادکراوەکان بۆ زۆنی شارەکە
  final TextEditingController _zoneLatController = TextEditingController();
  final TextEditingController _zoneLngController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    var contactDoc = await FirebaseFirestore.instance.collection('App_Settings').doc('Contact').get();
    if (contactDoc.exists && contactDoc.data() != null) {
      setState(() => _whatsappController.text = contactDoc.data()!['whatsapp'] ?? '');
    }

    var financeDoc = await FirebaseFirestore.instance.collection('App_Settings').doc('Financials').get();
    if (financeDoc.exists && financeDoc.data() != null) {
      setState(() {
        _companyPercentController.text = financeDoc.data()!['company_percent']?.toString() ?? '10';
        _driverDeliveryFeeController.text = financeDoc.data()!['driver_delivery_fee']?.toString() ?? '2000';
      });
    }

    // هێنانی زۆنی شارەکە
    var zoneDoc = await FirebaseFirestore.instance.collection('App_Settings').doc('MapZone').get();
    if (zoneDoc.exists && zoneDoc.data() != null) {
      setState(() {
        _zoneLatController.text = zoneDoc.data()!['latitude']?.toString() ?? '36.8679'; // دهۆک وەک دیفۆڵت
        _zoneLngController.text = zoneDoc.data()!['longitude']?.toString() ?? '42.9830';
      });
    } else {
      _zoneLatController.text = '36.8679';
      _zoneLngController.text = '42.9830';
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('App_Settings').doc('Contact').set({'whatsapp': _whatsappController.text.trim()}, SetOptions(merge: true));
      
      await FirebaseFirestore.instance.collection('App_Settings').doc('Financials').set({
        'company_percent': double.tryParse(_companyPercentController.text) ?? 10.0,
        'driver_delivery_fee': double.tryParse(_driverDeliveryFeeController.text) ?? 2000.0,
      }, SetOptions(merge: true));

      // سەیڤکردنی زۆنی نەخشەکە
      await FirebaseFirestore.instance.collection('App_Settings').doc('MapZone').set({
        'latitude': double.tryParse(_zoneLatController.text) ?? 36.8679,
        'longitude': double.tryParse(_zoneLngController.text) ?? 42.9830,
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رێکخستنەکان بە سەرکەوتوویی نوێکرانەوە!'), backgroundColor: Colors.green));
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
          const SizedBox(height: 20),
          
          // بەشی نەخشە و زۆن
          _buildCard(
            title: 'زۆنی کارکردن (نەخشە)',
            subtitle: 'هێڵی درێژی و پانی سەنتەری شارەکەت بنووسە بۆ ئەوەی نەخشەکە فۆکەسی بکاتە سەر.',
            icon: Icons.map,
            color: Colors.blue,
            child: Row(
              children: [
                Expanded(child: TextField(controller: _zoneLatController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Latitude (هێڵی پانی)', border: OutlineInputBorder()))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _zoneLngController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Longitude (هێڵی درێژی)', border: OutlineInputBorder()))),
              ],
            ),
          ),
          const SizedBox(height: 15),

          _buildCard(
            title: 'پەیوەندی (واتسئاپ)', subtitle: 'ئەم ژمارەیە بۆ پەیوەندیکردنی شۆفێر و خوارنگەهەکانە.', icon: Icons.chat, color: Colors.green,
            child: TextField(controller: _whatsappController, decoration: const InputDecoration(labelText: 'ژمارەی واتسئاپ', border: OutlineInputBorder())),
          ),
          const SizedBox(height: 15),

          _buildCard(
            title: 'رێکخستنە داراییەکان', subtitle: 'پشکی کۆمپانیا و شۆفێر.', icon: Icons.monetization_on, color: Colors.orange,
            child: Column(
              children: [
                TextField(controller: _companyPercentController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'رێژەی قازانجی کۆمپانیا (%)', suffixText: '%', border: OutlineInputBorder())),
                const SizedBox(height: 15),
                TextField(controller: _driverDeliveryFeeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'کرێی جێگیری شۆفێر (دینار)', suffixText: 'IQD', border: OutlineInputBorder())),
              ],
            ),
          ),
          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity, height: 55,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: _isLoading ? null : _saveSettings,
              icon: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.save),
              label: const Text('پاشەکەوتکردنی گۆڕانکارییەکان', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required String subtitle, required IconData icon, required Color color, required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icon, color: color, size: 30), const SizedBox(width: 10), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 5), Text(subtitle, style: const TextStyle(color: Colors.grey)), const Divider(height: 30), child,
        ]),
      ),
    );
  }
}
