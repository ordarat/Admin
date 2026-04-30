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
  final LatLng initialCenter = const LatLng(36.8679, 42.9830); 
  
  bool _isEditingLocation = false;
  String? _editingRestaurantId;
  String? _editingRestaurantName;

  void _showRestaurantPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('دیاریکردنی شوێنی خوارنگەهـ', style: TextStyle(fontSize: 18, color: Colors.indigo)),
          content: SizedBox(
            width: double.maxFinite, height: 400,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Restaurants').where('is_active', isEqualTo: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var restaurants = snapshot.data!.docs;
                if (restaurants.isEmpty) return const Center(child: Text('هیچ خوارنگەهێکی چالاک نییە.'));

                return ListView.builder(
                  itemCount: restaurants.length,
                  itemBuilder: (context, index) {
                    var data = restaurants[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: const Icon(Icons.restaurant, color: Colors.orange),
                      title: Text(data['name'] ?? 'بێ ناو', style: const TextStyle(fontWeight: FontWeight.bold)),
                      onTap: () {
                        setState(() { _isEditingLocation = true; _editingRestaurantId = restaurants[index].id; _editingRestaurantName = data['name']; });
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('داخستن'))],
        );
      },
    );
  }

  Future<void> _updateRestaurantLocation(LatLng point) async {
    if (_isEditingLocation && _editingRestaurantId != null) {
      try {
        await FirebaseFirestore.instance.collection('Restaurants').doc(_editingRestaurantId).update({'latitude': point.latitude, 'longitude': point.longitude});
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شوێنەکە جێگیر کرا!'), backgroundColor: Colors.green));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هەڵە روویدا'), backgroundColor: Colors.red));
      } finally {
        setState(() { _isEditingLocation = false; _editingRestaurantId = null; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    // بەشی نەخشەکە
    Widget mapSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('نەخشەی راستەوخۆ', style: TextStyle(fontSize: isMobile ? 18 : 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E2C))),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
              onPressed: _isEditingLocation ? null : _showRestaurantPicker,
              icon: Icon(Icons.add_location_alt, size: isMobile ? 16 : 20),
              label: Text(isMobile ? 'دیاریکردن' : 'دیاریکردنی شوێنی خوارنگەهـ', style: TextStyle(fontSize: isMobile ? 12 : 14)),
            ),
          ],
        ),
        if (_isEditingLocation) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10), color: Colors.orange[100],
            child: Text('تکایە کلیک لەسەر نەخشەکە بکە بۆ دیاریکردنی شوێنی: [ $_editingRestaurantName ]', style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
          ),
        ],
        const SizedBox(height: 15),
        
        // جیاکردنەوەی باڵانسی نەخشەکە بەپێی ئامێرەکە
        isMobile 
          ? Container(
              height: 400, // باڵانسی جێگیر بۆ مۆبایل
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
              clipBehavior: Clip.hardEdge,
              child: _buildFlutterMap(),
            )
          : Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: _buildFlutterMap(),
              ),
            ),
      ],
    );

    // بەشی پێشەنگەکان (Leaderboard)
    Widget leaderboardSection = Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(color: Colors.blue[800], borderRadius: const BorderRadius.vertical(top: Radius.circular(15))),
            child: const Text('پێشەنگی شۆفێرەکان', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Drivers').orderBy('completed_orders', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var drivers = snapshot.data!.docs;
                if (drivers.isEmpty) return const Center(child: Text('هیچ شۆفێرێک نییە'));
                return ListView.builder(
                  itemCount: drivers.length,
                  itemBuilder: (context, index) {
                    var data = drivers[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.motorcycle, color: Colors.white)),
                      title: Text(data['name'] ?? ''),
                      trailing: Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    );
                  },
                );
              }
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.all(isMobile ? 15.0 : 20.0),
      child: isMobile
          // ئەگەر مۆبایل بوو، بیانخە ژێر یەکتر و سکڕۆڵی پێ بدە
          ? SingleChildScrollView(
              child: Column(
                children: [
                  mapSection,
                  const SizedBox(height: 20),
                  SizedBox(height: 400, child: leaderboardSection), 
                ],
              ),
            )
          // ئەگەر لاپتۆپ بوو، بیانخە تەنیشت یەکتر
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: mapSection),
                const SizedBox(width: 20),
                Expanded(flex: 1, child: leaderboardSection),
              ],
            ),
    );
  }

  // فەنکشنی دروستکردنی نەخشەکە بۆ ئەوەی کۆدەکە کورت بێتەوە
  Widget _buildFlutterMap() {
    return StreamBuilder<QuerySnapshot>(
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
              options: MapOptions(
                initialCenter: initialCenter, initialZoom: 13.0,
                onTap: (tapPosition, point) => _updateRestaurantLocation(point),
              ),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.ibrahim.admin'),
                MarkerLayer(markers: allMarkers),
              ],
            );
          },
        );
      },
    );
  }
}
