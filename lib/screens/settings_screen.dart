// Path: lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Color primaryBlue = const Color(0xFF0056D2);
  
  // کۆنترۆڵکەری خانەکان
  final TextEditingController _baseFeeController = TextEditingController();
  final TextEditingController _pricePerKmController = TextEditingController();
  final TextEditingController _companyShareController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // هێنانی رێکخستنەکان لە داتابەیسەوە
  Future<void> _loadSettings() async {
    try {
      // هێنانی رێکخستنی دارایی
      var financeDoc = await FirebaseFirestore.instance.collection('App_Settings').doc('Financials').get();
      if (financeDoc.exists && financeDoc.data() != null) {
        _baseFeeController.text = (financeDoc.data()!['base_fee'] ?? 1500).toString();
        _pricePerKmController.text = (financeDoc.data()!['price_per_km'] ?? 500).toString();
        _companyShareController.text = (financeDoc.data()!['company_share'] ?? 500).toString();
      }

      // هێنانی رێکخستنی پەیوەندی (واتسئاپ)
      var contactDoc = await FirebaseFirestore.instance.collection('App_Settings').doc('Contact').get();
      if (contactDoc.exists && contactDoc.data() != null) {
        _whatsappController.text = contactDoc.data()!['whatsapp'] ?? '';
      }
    } catch (e) {
      debugPrint("Error loading settings: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // سەیڤکردنی گۆڕانکارییەکان بۆ ناو فایەربەیس
  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      // سەیڤکردنی داراییەکان
      await FirebaseFirestore.instance.collection('App_Settings').doc('Financials').set({
        'base_fee': num.tryParse(_baseFeeController.text.trim()) ?? 1500,
        'price_per_km': num.tryParse(_pricePerKmController.text.trim()) ?? 500,
        'company_share': num.tryParse(_companyShareController.text.trim()) ?? 500,
      }, SetOptions(merge: true));

      // سەیڤکردنی ژمارەی واتسئاپ
      await FirebaseFirestore.instance.collection('App_Settings').doc('Contact').set({
        'whatsapp': _whatsappController.text.trim(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رێکخستنەکان بە سەرکەوتوویی سەیڤ کران!'), backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('هەڵە لە سەیڤکردن: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return _isLoading 
      ? const Center(child: CircularProgressIndicator()) 
      : SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 15.0 : 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('رێکخستنەکانی سیستەم', style: TextStyle(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E2C))),
              const SizedBox(height: 20),

              // کارتی رێکخستنە داراییەکان (Dynamic Pricing)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.monetization_on, color: Colors.green, size: 30),
                          SizedBox(width: 10),
                          Text('رێکخستنی نرخی گەیاندن (زیرەک)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                        ],
                      ),
                      const Divider(height: 30),
                      
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_baseFeeController, 'کرێی سەرەتایی جێگیر (دینار)', Icons.flag)),
                          const SizedBox(width: 15),
                          Expanded(child: _buildTextField(_pricePerKmController, 'نرخی هەر کیلۆمەترێک زیاتر (دینار)', Icons.add_road)),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(_companyShareController, 'پشکی کۆمپانیا لە هەر ئۆردەرێک (دینار)', Icons.business),
                      
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue[200]!)),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 10),
                            Expanded(child: Text('نموونە: ئەگەر کڕیار ٣ کیلۆمەتر دوور بێت، کرێی گەیاندن دەبێتە: کرێی سەرەتایی + (٣ × نرخی کیلۆمەتر). پاشان پشکی کۆمپانیا لەو بڕە پارەیە دەبڕدرێت و ئەوەی دەمێنێتەوە بۆ شۆفێرەکە دەبێت.', style: TextStyle(color: Colors.blue))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // کارتی رێکخستنی پەیوەندی
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.support_agent, color: Colors.orange, size: 30),
                          SizedBox(width: 10),
                          Text('رێکخستنی پەیوەندی', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                        ],
                      ),
                      const Divider(height: 30),
                      _buildTextField(_whatsappController, 'ژمارەی واتسئاپی ئیدارە (بە کۆدی وڵاتەوە وەکو 964750...)', Icons.message),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // دوگمەی سەیڤکردن
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                  ),
                  onPressed: _isSaving ? null : _saveSettings,
                  icon: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.save),
                  label: Text(_isSaving ? 'سەیڤ دەکرێت...' : 'سەیڤکردنی گۆڕانکارییەکان', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        );
  }

  // دیزاینی خانەی نووسین
  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.indigo),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.indigo, width: 2)),
      ),
    );
  }
}
