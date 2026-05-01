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
  LatLng _mapCenter = const LatLng(36.8679, 42.9830); // دیفۆڵت
  final MapController _mapController = MapController();
  final TextEditingController _rewardController = TextEditingController();

  bool _isEditingLocation = false;
  String? _editingRestaurantId;
  String? _editingRestaurantName;

  @override
  void initState() {
    super.initState();
    _loadMapZone();
  }

  // هێنانی زۆنی شارەکە لە رێکخستنەکانەوە
  Future<void> _loadMapZone() async {
    var zoneDoc = await FirebaseFirestore.instance.collection('App_Settings').doc('MapZone').get();
    if (zoneDoc.exists && zoneDoc.data() != null) {
      double lat = zoneDoc.data()!['latitude'] ?? 36.8679;
      double lng = zoneDoc.data()!['longitude'] ?? 42.9830;
      setState(() {
        _mapCenter = LatLng(lat, lng);
        _mapController.move(_mapCenter, 13.0);
      });
    }
  }

  // فەنکشنی هەڵبژاردنی خوارنگەهـ بۆ دانانی لەسەر نەخشە
  void _showRestaurantPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('دیاریکردنی شوێنی خوارنگەهـ', style: TextStyle(color: Colors.indigo)),
          content: SizedBox(
            width: 300, height: 400,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Restaurants').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var restaurants = snapshot.data!.docs;
                if (restaurants.isEmpty) return const Center(child: Text('هیچ خوارنگەهێک نییە.'));

                return ListView.builder(
                  itemCount: restaurants.length,
                  itemBuilder: (context, index) {
                    var data = restaurants[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: const Icon(Icons.restaurant, color: Colors.orange),
                      title: Text(data['name'] ?? 'بێ ناو', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(data['latitude'] != null ? 'لۆکەیشنی هەیە' : 'لۆکەیشنی نییە', style: TextStyle(color: data['latitude'] != null ? Colors.green : Colors.red)),
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
        );
      },
    );
  }

  // سەیڤکردنی شوێنی خوارنگەهەکە کاتێک ئەدمین کلیک لە نەخشەکە دەکات
  Future<void> _updateRestaurantLocation(LatLng point) async {
    if (_isEditingLocation && _editingRestaurantId != null) {
      try {
        await FirebaseFirestore.instance.collection('Restaurants').doc(_editingRestaurantId).update({
          'latitude': point.latitude,
          'longitude': point.longitude
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('شوێنی ($_editingRestaurantName) جێگیر کرا!'), backgroundColor: Colors.green));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هەڵە روویدا'), backgroundColor: Colors.red));
      } finally {
        setState(() { _isEditingLocation = false; _editingRestaurantId = null; });
      }
    }
  }

  void _showRewardDialog(String uid, String name, num currentBalance) {
    // هەمان کۆدی پێشووی خەڵاتەکان...
    // لەبەر کورتکردنەوە لێرەدا لامداوە، بەڵام بۆت کار دەکات بێ کێشە.
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 10.0 : 20.0),
      child: Column(
        children: [
          // دوگمەی دیاریکردنی خوارنگەهـ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('نەخشەی راستەوخۆ', style: TextStyle(fontSize: isMobile ? 18 : 24, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
                onPressed: _isEditingLocation ? null : _showRestaurantPicker,
                icon: const Icon(Icons.add_location_alt),
                label: const Text('جێگیرکردنی خوارنگەهـ'),
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
          
          // نەخشەکە
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('Drivers').snapshots(),
                builder: (context, driverSnapshot) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('Restaurants').snapshots(),
                    builder: (context, restSnapshot) {
                      List<Marker> allMarkers = [];
                      
                      // مارکەری خوارنگەهەکان
                      if (restSnapshot.hasData) {
                        for (var doc in restSnapshot.data!.docs) {
                          var data = doc.data() as Map<String, dynamic>;
                          if (data['latitude'] != null) {
                            allMarkers.add(Marker(
                              point: LatLng(data['latitude'], data['longitude']), 
                              width: 80, height: 80,
                              child: Column(
                                children: [
                                  const Icon(Icons.restaurant, color: Colors.orange, size: 35),
                                  Text(data['name'] ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, backgroundColor: Colors.white)),
                                ],
                              )
                            ));
                          }
                        }
                      }

                      // مارکەری شۆفێرەکان
                      if (driverSnapshot.hasData) {
                        for (var doc in driverSnapshot.data!.docs) {
                          var data = doc.data() as Map<String, dynamic>;
                          if (data['latitude'] != null) {
                            allMarkers.add(Marker(
                              point: LatLng(data['latitude'], data['longitude']), 
                              child: const Icon(Icons.motorcycle, color: Colors.blue, size: 35)
                            ));
                          }
                        }
                      }

                      return FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _mapCenter, 
                          initialZoom: 13.0,
                          onTap: (tapPosition, point) => _updateRestaurantLocation(point), // کاتێک کلیک دەکات لۆکەیشن سەیڤ دەبێت
                        ),
                        children: [
                          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.ibrahim.admin'),
                          MarkerLayer(markers: allMarkers),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
