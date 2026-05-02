// Path: lib/screens/live_tracking.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  LatLng _mapCenter = const LatLng(36.8679, 42.9830);
  final MapController _mapController = MapController();
  
  bool _isEditingLocation = false;
  String? _editingRestaurantId;
  String? _editingRestaurantName;

  @override
  void initState() {
    super.initState();
    _loadMapZone();
  }

  Future<void> _loadMapZone() async {
    var zoneDoc = await FirebaseFirestore.instance.collection('App_Settings').doc('MapZone').get();
    if (zoneDoc.exists && zoneDoc.data() != null) {
      setState(() {
        _mapCenter = LatLng(zoneDoc.data()!['latitude'] ?? 36.8679, zoneDoc.data()!['longitude'] ?? 42.9830);
        _mapController.move(_mapCenter, 13.0);
      });
    }
  }

  // پیشاندانی زانیاری شۆفێر کاتێک کلیکی لێ ده‌که‌یت
  void _showDriverDetails(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        bool isOnline = data['is_online'] ?? false;
        return Container(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 30, backgroundColor: isOnline ? Colors.green[100] : Colors.grey[200], 
                  child: Icon(Icons.motorcycle, color: isOnline ? Colors.green : Colors.grey, size: 35)),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['name'] ?? 'شۆفێر', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(isOnline ? 'چالاکە (Online)' : 'پشووە (Offline)', style: TextStyle(color: isOnline ? Colors.green : Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 30),
              _infoRow(Icons.phone, 'ژمارەی مۆبایل:', data['phone'] ?? '---'),
              _infoRow(Icons.account_balance_wallet, 'باڵانسی ئێستا:', '${data['wallet_balance'] ?? 0} IQD'),
              _infoRow(Icons.shopping_bag, 'ئۆردەرە تەواوکراوەکان:', '${data['completed_orders'] ?? 0}'),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      onPressed: () => launchUrl(Uri.parse('tel:${data['phone']}')),
                      icon: const Icon(Icons.phone), label: const Text('پەیوەندی'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close), label: const Text('داخستن'),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [Icon(icon, size: 20, color: Colors.indigo), const SizedBox(width: 10), Text(label), const Spacer(), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // --- نەخشە ---
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('Drivers').snapshots(),
          builder: (context, driverSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Restaurants').snapshots(),
              builder: (context, restSnap) {
                List<Marker> markers = [];

                // لۆکەیشنی خوارنگەهەکان
                if (restSnap.hasData) {
                  for (var doc in restSnap.data!.docs) {
                    var d = doc.data() as Map<String, dynamic>;
                    if (d['latitude'] != null) {
                      markers.add(Marker(
                        point: LatLng(d['latitude'], d['longitude']),
                        width: 100, height: 100,
                        child: GestureDetector(
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خوارنگەهی: ${d['name']}'))),
                          child: Column(children: [
                            const Icon(Icons.restaurant, color: Colors.orange, size: 35),
                            Container(padding: const EdgeInsets.all(2), color: Colors.white, child: Text(d['name'] ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                          ]),
                        ),
                      ));
                    }
                  }
                }

                // لۆکەیشنی شۆفێرەکان (بە رەنگی جیاواز)
                if (driverSnap.hasData) {
                  for (var doc in driverSnap.data!.docs) {
                    var d = doc.data() as Map<String, dynamic>;
                    if (d['latitude'] != null) {
                      bool isOnline = d['is_online'] ?? false;
                      markers.add(Marker(
                        point: LatLng(d['latitude'], d['longitude']),
                        width: 60, height: 60,
                        child: GestureDetector(
                          onTap: () => _showDriverDetails(d),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(Icons.location_on, color: isOnline ? Colors.green : Colors.grey, size: 50),
                              const Positioned(top: 8, child: Icon(Icons.motorcycle, color: Colors.white, size: 20)),
                            ],
                          ),
                        ),
                      ));
                    }
                  }
                }

                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _mapCenter,
                    initialZoom: 13.0,
                    onTap: (tapPos, point) {
                      if (_isEditingLocation) _updateLocation(point);
                    },
                  ),
                  children: [
                    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.ibrahim.admin'),
                    MarkerLayer(markers: markers),
                  ],
                );
              },
            );
          },
        ),

        // --- ئاماری سەر نەخشە (Overlay) ---
        Positioned(
          top: 20, left: 20,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('Drivers').where('is_online', isEqualTo: true).snapshots(),
            builder: (context, snapshot) {
              int onlineCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)]),
                child: Row(
                  children: [
                    const CircleAvatar(radius: 5, backgroundColor: Colors.green),
                    const SizedBox(width: 8),
                    Text('$onlineCount شۆفێر ئێستا ئۆنلاینن', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                  ],
                ),
              );
            },
          ),
        ),

        // --- دوگمەی جێگیرکردنی خوارنگەهـ ---
        Positioned(
          bottom: 20, right: 20,
          child: FloatingActionButton.extended(
            backgroundColor: _isEditingLocation ? Colors.red : Colors.deepOrange,
            onPressed: _isEditingLocation ? () => setState(() => _isEditingLocation = false) : _showRestPicker,
            label: Text(_isEditingLocation ? 'پاشگەزبوونەوە' : 'جێگیرکردنی خوارنگەهـ'),
            icon: Icon(_isEditingLocation ? Icons.close : Icons.add_location),
          ),
        ),

        if (_isEditingLocation)
          Positioned(
            top: 80, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(10), color: Colors.yellow[700],
                child: Text('دیاریکردنی لۆکەیشن بۆ: [ $_editingRestaurantName ] - کلیک لە نەخشە بکە', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
      ],
    );
  }

  void _showRestPicker() {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('خوارنگەهێک هەڵبژێرە'),
      content: SizedBox(width: 300, height: 300, child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Restaurants').snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const CircularProgressIndicator();
          return ListView(children: snap.data!.docs.map((d) => ListTile(
            title: Text(d['name']),
            onTap: () {
              setState(() { _isEditingLocation = true; _editingRestaurantId = d.id; _editingRestaurantName = d['name']; });
              Navigator.pop(context);
            },
          )).toList());
        }
      )),
    ));
  }

  Future<void> _updateLocation(LatLng p) async {
    await FirebaseFirestore.instance.collection('Restaurants').doc(_editingRestaurantId).update({'latitude': p.latitude, 'longitude': p.longitude});
    setState(() => _isEditingLocation = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شوێنەکە نوێکرایەوە'), backgroundColor: Colors.green));
  }
}
