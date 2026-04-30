// Path: lib/screens/live_tracking.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final LatLng initialCenter = const LatLng(36.8679, 42.9830); // سەنتەری دهۆک
  final TextEditingController _rewardController = TextEditingController();

  // فەنکشنی پێدانی خەڵات (زیادکردنی باڵانس بۆ شۆفێر)
  void _showRewardDialog(String uid, String name, num currentBalance) {
    _rewardController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('پێدانی خەڵات بە: $name', style: const TextStyle(color: Colors.indigo, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('بڕی خەڵاتەکە بنووسە (بە دینار) کە دەچێتە سەر باڵانسەکەی:', style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 15),
              TextField(
                controller: _rewardController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'بڕی خەڵات',
                  suffixText: 'IQD',
                  prefixIcon: const Icon(Icons.card_giftcard, color: Colors.green),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('پاشگەزبوونەوە', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () async {
                if (_rewardController.text.isEmpty) return;
                num rewardAmount = num.tryParse(_rewardController.text) ?? 0;
                if (rewardAmount > 0) {
                  Navigator.pop(context);
                  await FirebaseFirestore.instance.collection('Drivers').doc(uid).update({
                    'wallet_balance': FieldValue.increment(rewardAmount),
                  });
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$rewardAmount دینار خرایە سەر باڵانسی $name'), backgroundColor: Colors.green));
                }
              },
              child: const Text('ناردنی خەڵات'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return DefaultTabController(
      length: 2, // دوو تابی سەرەکی
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 10.0 : 20.0),
        child: Column(
          children: [
            // دیزاینی تابەکان
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
              child: const TabBar(
                indicatorColor: Colors.deepOrange,
                labelColor: Colors.deepOrange,
                unselectedLabelColor: Colors.grey,
                indicatorWeight: 4,
                tabs: [
                  Tab(icon: Icon(Icons.map), text: 'نەخشەی راستەوخۆ'),
                  Tab(icon: Icon(Icons.leaderboard), text: 'رێزبەندی و خەڵاتەکان'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // ناوەڕۆکی تابەکان
            Expanded(
              child: TabBarView(
                children: [
                  _buildMapTab(), // تابی یەکەم: نەخشە
                  _buildLeaderboardTab(isMobile), // تابی دووەم: رێزبەندی
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // تابی یەکەم: نەخشەی راستەوخۆ
  Widget _buildMapTab() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Drivers').snapshots(),
        builder: (context, driverSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('Restaurants').snapshots(),
            builder: (context, restSnapshot) {
              List<Marker> allMarkers = [];
              
              if (driverSnapshot.hasData) {
                for (var doc in driverSnapshot.data!.docs) {
                  var data = doc.data() as Map<String, dynamic>;
                  if (data['latitude'] != null) {
                    allMarkers.add(Marker(point: LatLng(data['latitude'], data['longitude']), child: const Icon(Icons.motorcycle, color: Colors.blue, size: 35)));
                  }
                }
              }
              
              if (restSnapshot.hasData) {
                for (var doc in restSnapshot.data!.docs) {
                  var data = doc.data() as Map<String, dynamic>;
                  if (data['latitude'] != null) {
                    allMarkers.add(Marker(point: LatLng(data['latitude'], data['longitude']), child: const Icon(Icons.restaurant, color: Colors.orange, size: 35)));
                  }
                }
              }

              return FlutterMap(
                options: MapOptions(initialCenter: initialCenter, initialZoom: 13.0),
                children: [
                  TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.ibrahim.admin'),
                  MarkerLayer(markers: allMarkers),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // تابی دووەم: رێزبەندی و خەڵاتەکان
  Widget _buildLeaderboardTab(bool isMobile) {
    Widget driverLeaderboard = _buildLeaderboardList(
      title: 'رێزبەندی باشترین شۆفێرەکان',
      collection: 'Drivers',
      icon: Icons.motorcycle,
      color: Colors.blue,
      showRewardButton: true,
    );

    Widget restaurantLeaderboard = _buildLeaderboardList(
      title: 'رێزبەندی باشترین خوارنگەهەکان',
      collection: 'Restaurants',
      icon: Icons.restaurant,
      color: Colors.orange,
      showRewardButton: false,
    );

    return isMobile 
        ? SingleChildScrollView(child: Column(children: [driverLeaderboard, const SizedBox(height: 20), restaurantLeaderboard]))
        : Row(children: [Expanded(child: driverLeaderboard), const SizedBox(width: 20), Expanded(child: restaurantLeaderboard)]);
  }

  // دروستکەری لیستی رێزبەندییەکان
  Widget _buildLeaderboardList({required String title, required String collection, required IconData icon, required Color color, required bool showRewardButton}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(15))),
            child: Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // هێنان بەپێی زۆری ئۆردەرە تەواوکراوەکان (لە زۆرەوە بۆ کەم)
              stream: FirebaseFirestore.instance.collection(collection).orderBy('completed_orders', descending: true).limit(10).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('هیچ داتایەک نییە', style: TextStyle(color: Colors.grey)));

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    String uid = docs[index].id;
                    num orders = data['completed_orders'] ?? 0;
                    num balance = data['wallet_balance'] ?? 0;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: index == 0 ? Colors.amber : (index == 1 ? Colors.grey[400] : (index == 2 ? Colors.brown[300] : color.withOpacity(0.2))),
                        child: Text('#${index + 1}', style: TextStyle(color: index < 3 ? Colors.white : color, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(data['name'] ?? 'بێ ناو', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('ئۆردەرەکان: $orders | باڵانس: $balance', style: TextStyle(color: Colors.grey[700])),
                      trailing: showRewardButton 
                          ? IconButton(
                              icon: const Icon(Icons.card_giftcard, color: Colors.green),
                              tooltip: 'پێدانی خەڵات',
                              onPressed: () => _showRewardDialog(uid, data['name'] ?? 'شۆفێر', balance),
                            )
                          : null,
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
