// Path: lib/screens/leaderboard_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final TextEditingController _firstPrizeCtrl = TextEditingController();
  final TextEditingController _secondPrizeCtrl = TextEditingController();
  final TextEditingController _thirdPrizeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPrizes();
  }

  Future<void> _loadPrizes() async {
    var doc = await FirebaseFirestore.instance.collection('App_Settings').doc('Prizes').get();
    if (doc.exists) {
      var data = doc.data() as Map<String, dynamic>;
      _firstPrizeCtrl.text = data['first_prize']?.toString() ?? '0';
      _secondPrizeCtrl.text = data['second_prize']?.toString() ?? '0';
      _thirdPrizeCtrl.text = data['third_prize']?.toString() ?? '0';
    }
  }

  Future<void> _savePrizes() async {
    await FirebaseFirestore.instance.collection('App_Settings').doc('Prizes').set({
      'first_prize': int.tryParse(_firstPrizeCtrl.text) ?? 0,
      'second_prize': int.tryParse(_secondPrizeCtrl.text) ?? 0,
      'third_prize': int.tryParse(_thirdPrizeCtrl.text) ?? 0,
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خەڵاتەکان دیاری کران!'), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('سیستەمی ریزبەندی و خەڵاتەکان (مانگانە)', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
          const SizedBox(height: 20),
          
          // بەشی دیاریکردنی خەڵاتەکان
          Card(
            color: Colors.amber[50],
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                children: [
                  Expanded(child: TextField(controller: _firstPrizeCtrl, decoration: const InputDecoration(labelText: 'خەڵاتی یەکەم (IQD)', prefixIcon: Icon(Icons.looks_one, color: Colors.amber)))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: _secondPrizeCtrl, decoration: const InputDecoration(labelText: 'خەڵاتی دووەم (IQD)', prefixIcon: Icon(Icons.looks_two, color: Colors.grey)))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: _thirdPrizeCtrl, decoration: const InputDecoration(labelText: 'خەڵاتی سێیەم (IQD)', prefixIcon: Icon(Icons.looks_3, color: Colors.brown)))),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: _savePrizes,
                    icon: const Icon(Icons.save),
                    label: const Text('سەیڤکردن'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.all(18)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // لیستی شۆفێرەکان بەپێی زۆری ئۆردەرەکانیان (لە یەکەمەوە بۆ کۆتایی)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Drivers').orderBy('completed_orders', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final drivers = snapshot.data!.docs;
                if (drivers.isEmpty) return const Center(child: Text('هیچ شۆفێرێک نییە'));

                return ListView.builder(
                  itemCount: drivers.length,
                  itemBuilder: (context, index) {
                    var data = drivers[index].data() as Map<String, dynamic>;
                    
                    // دیاریکردنی رەنگی مەدالیاکان
                    Color medalColor = Colors.transparent;
                    IconData? medalIcon;
                    if (index == 0) { medalColor = Colors.amber; medalIcon = Icons.emoji_events; }
                    else if (index == 1) { medalColor = Colors.grey[400]!; medalIcon = Icons.emoji_events; }
                    else if (index == 2) { medalColor = Colors.brown[400]!; medalIcon = Icons.emoji_events; }

                    return Card(
                      elevation: index < 3 ? 5 : 1, // یەکەمەکان بەرزتر دەردەکەون
                      color: index < 3 ? Colors.yellow[50] : Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: medalColor == Colors.transparent ? Colors.blue[100] : medalColor,
                          child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        ),
                        title: Text(data['name'] ?? 'بێ ناو', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Text('ژمارەی مۆبایل: ${data['phone']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${data['completed_orders'] ?? 0} ئۆردەر', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                            if (medalIcon != null) ...[const SizedBox(width: 10), Icon(medalIcon, color: medalColor, size: 30)],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
