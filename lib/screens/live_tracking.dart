// Path: lib/screens/live_tracking.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

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

  bool _showOnlineDrivers = true;
  bool _showOfflineDrivers = true;
  bool _showRestaurants = true;

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

  // --- ناردنی نامەی تایبەت لەناو پڕۆفایلەوە ---
  void _showNotificationDialog(String? token, String userName) {
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ئەم بەکارهێنەرە هێشتا ئەپەکەی نەکردووەتەوە.'), backgroundColor: Colors.orange));
      return;
    }
    final TextEditingController titleCtrl = TextEditingController();
    final TextEditingController bodyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('ناردنی نامە بۆ: $userName', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'سەردێڕ', prefixIcon: Icon(Icons.title))),
            const SizedBox(height: 10),
            TextField(controller: bodyCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'ناوەڕۆکی نامە...', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('پاشگەزبوونەوە', style: TextStyle(color: Colors.red))),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            onPressed: () async {
              if (titleCtrl.text.isEmpty || bodyCtrl.text.isEmpty) return;
              Navigator.pop(context);
              const String serverKey = 'سێرڤەر_کلیلەکەت_لێرە_دابنێ'; 
              try {
                await http.post(
                  Uri.parse('https://fcm.googleapis.com/fcm/send'),
                  headers: {'Content-Type': 'application/json', 'Authorization': 'key=$serverKey'},
                  body: jsonEncode({'to': token, 'notification': {'title': titleCtrl.text, 'body': bodyCtrl.text, 'sound': 'default'}}),
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نامەکە نێردرا!'), backgroundColor: Colors.green));
              } catch (e) {
                debugPrint("Error: $e");
              }
            },
            icon: const Icon(Icons.send), label: const Text('ناردن'),
          ),
        ],
      ),
    );
  }

  // --- پڕۆفایلی تەواوەتی کاتێک کلیک لە نەخشەکە دەکەیت ---
  void _showUserProfile(String uid, String collection, Map<String, dynamic> data) {
    bool isActive = data['is_active'] ?? true;
    String? imageUrl = data['profile_image'] ?? data['image_url'];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 500, padding: const EdgeInsets.all(25),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(alignment: Alignment.topLeft, child: IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => Navigator.pop(context))),
                
                // وێنەی پڕۆفایل لەناو دیالۆگەکە
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: collection == 'Drivers' ? Colors.blue[50] : Colors.orange[50],
                    border: Border.all(color: collection == 'Drivers' ? Colors.blue : Colors.orange, width: 3),
                  ),
                  child: (imageUrl != null && imageUrl.isNotEmpty)
                      ? ClipOval(child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(collection == 'Drivers' ? Icons.motorcycle : Icons.storefront, size: 40, color: Colors.grey)))
                      : Icon(collection == 'Drivers' ? Icons.motorcycle : Icons.storefront, size: 40, color: collection == 'Drivers' ? Colors.blue : Colors.orange),
                ),
                const SizedBox(height: 15),
                
                Text(data['name'] ?? 'بێ ناو', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(data['phone'] ?? '', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                if (collection == 'Drivers') 
                  Text((data['is_online'] ?? false) ? 'ئێستا ئۆنلاینە 🟢' : 'ئۆفلاینە ⚪', style: TextStyle(fontWeight: FontWeight.bold, color: (data['is_online'] ?? false) ? Colors.green : Colors.grey)),
                
                const Divider(height: 40),

                Row(
                  children: [
                    Expanded(child: _buildStatBox('باڵانس', '${data['wallet_balance'] ?? 0} IQD', Icons.account_balance_wallet, Colors.green)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildStatBox('ئۆردەرەکان', '${data['completed_orders'] ?? 0}', Icons.shopping_bag, Colors.blue)),
                  ],
                ),
                const SizedBox(height: 20),

                if (collection == 'Drivers') ...[
                  SizedBox(
                    width: double.infinity, height: 45,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: () { Navigator.pop(context); _showNotificationDialog(data['fcm_token'], data['name'] ?? ''); },
                      icon: const Icon(Icons.notifications_active), label: const Text('ناردنی نامە بۆ مۆبایلەکەی'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                SizedBox(
                  width: double.infinity, height: 45,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: isActive ? Colors.orange : Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () async {
                      await FirebaseFirestore.instance.collection(collection).doc(uid).update({'is_active': !isActive});
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                    icon: Icon(isActive ? Icons.block : Icons.check_circle),
                    label: Text(isActive ? 'راگرتنی هەژمار (باندکردن)' : 'چالاککردنەوە', style: const TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(children: [
        Icon(icon, color: color, size: 30), const SizedBox(height: 10),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('Drivers').snapshots(),
          builder: (context, driverSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Restaurants').snapshots(),
              builder: (context, restSnap) {
                List<Marker> markers = [];

                // --- دروستکردنی مارکەری خوارنگەهەکان بە وێنەوە ---
                if (restSnap.hasData && _showRestaurants) {
                  for (var doc in restSnap.data!.docs) {
                    var d = doc.data() as Map<String, dynamic>;
                    if (d['latitude'] != null) {
                      String? imageUrl = d['profile_image'] ?? d['image_url'];
                      
                      markers.add(Marker(
                        point: LatLng(d['latitude'], d['longitude']),
                        width: 80, height: 80,
                        child: GestureDetector(
                          onTap: () => _showUserProfile(doc.id, 'Restaurants', d),
                          child: Column(children: [
                            Container(
                              width: 45, height: 45,
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.orange, width: 3), color: Colors.white, boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)]),
                              child: (imageUrl != null && imageUrl.isNotEmpty)
                                  ? ClipOval(child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.storefront, color: Colors.orange)))
                                  : const Icon(Icons.storefront, color: Colors.orange),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                              child: Text(d['name'] ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange), overflow: TextOverflow.ellipsis),
                            ),
                          ]),
                        ),
                      ));
                    }
                  }
                }

                int onlineCount = 0;
                int offlineCount = 0;

                // --- دروستکردنی مارکەری شۆفێرەکان بە وێنەوە ---
                if (driverSnap.hasData) {
                  for (var doc in driverSnap.data!.docs) {
                    var d = doc.data() as Map<String, dynamic>;
                    bool isOnline = d['is_online'] ?? false;
                    
                    if (isOnline) onlineCount++;
                    else offlineCount++;

                    if (d['latitude'] != null) {
                      if ((isOnline && _showOnlineDrivers) || (!isOnline && _showOfflineDrivers)) {
                        String? imageUrl = d['profile_image'] ?? d['image_url'];

                        markers.add(Marker(
                          point: LatLng(d['latitude'], d['longitude']),
                          width: 60, height: 60,
                          child: GestureDetector(
                            onTap: () => _showUserProfile(doc.id, 'Drivers', d),
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                // بازنەی وێنەی شۆفێر
                                Container(
                                  width: 50, height: 50,
                                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isOnline ? Colors.green : Colors.grey, width: 3), color: Colors.white, boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)]),
                                  child: (imageUrl != null && imageUrl.isNotEmpty)
                                      ? ClipOval(child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c,e,s) => Icon(Icons.motorcycle, color: isOnline ? Colors.green : Colors.grey)))
                                      : Icon(Icons.motorcycle, color: isOnline ? Colors.green : Colors.grey),
                                ),
                                // نیشانەی ئۆنلاین/ئۆفلاین لە تەنیشت وێنەکە
                                Positioned(
                                  bottom: 0, right: 0,
                                  child: CircleAvatar(radius: 8, backgroundColor: Colors.white, child: CircleAvatar(radius: 6, backgroundColor: isOnline ? Colors.green : Colors.grey)),
                                ),
                              ],
                            ),
                          ),
                        ));
                      }
                    }
                  }
                }

                return Stack(
                  children: [
                    FlutterMap(
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
                    ),

                    Positioned(
                      top: 20, left: 20,
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ئاماری زیندوو', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                            const SizedBox(height: 10),
                            Row(children: [const CircleAvatar(radius: 5, backgroundColor: Colors.green), const SizedBox(width: 8), Text('$onlineCount شۆفێری ئۆنلاین', style: const TextStyle(fontWeight: FontWeight.bold))]),
                            const SizedBox(height: 5),
                            Row(children: [const CircleAvatar(radius: 5, backgroundColor: Colors.grey), const SizedBox(width: 8), Text('$offlineCount شۆفێری ئۆفلاین', style: const TextStyle(color: Colors.grey))]),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),

        Positioned(
          top: 20, right: 20,
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('فلتەری نەخشە', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                const Divider(),
                _buildFilterToggle('شۆفێری ئۆنلاین', _showOnlineDrivers, Colors.green, (val) => setState(() => _showOnlineDrivers = val)),
                _buildFilterToggle('شۆفێری ئۆفلاین', _showOfflineDrivers, Colors.grey, (val) => setState(() => _showOfflineDrivers = val)),
                _buildFilterToggle('خوارنگەهەکان', _showRestaurants, Colors.orange, (val) => setState(() => _showRestaurants = val)),
              ],
            ),
          ),
        ),

        Positioned(
          bottom: 90, right: 20,
          child: FloatingActionButton(
            heroTag: 'recenter',
            backgroundColor: Colors.white,
            foregroundColor: Colors.indigo,
            onPressed: () => _mapController.move(_mapCenter, 13.0),
            child: const Icon(Icons.my_location),
          ),
        ),

        Positioned(
          bottom: 20, right: 20,
          child: FloatingActionButton.extended(
            heroTag: 'addRest',
            backgroundColor: _isEditingLocation ? Colors.red : const Color(0xFF0056D2),
            onPressed: _isEditingLocation ? () => setState(() => _isEditingLocation = false) : _showRestPicker,
            label: Text(_isEditingLocation ? 'پاشگەزبوونەوە' : 'دانانی لۆکەیشنی خوارنگەهـ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            icon: Icon(_isEditingLocation ? Icons.close : Icons.add_location_alt, color: Colors.white),
          ),
        ),

        if (_isEditingLocation)
          Positioned(
            top: 20, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)]),
                child: Text('تکایە کلیک لەسەر نەخشەکە بکە بۆ دیاریکردنی شوێنی [ $_editingRestaurantName ]', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterToggle(String title, bool value, Color color, Function(bool) onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(value ? Icons.check_box : Icons.check_box_outline_blank, color: color, size: 20),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: value ? Colors.black : Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _showRestPicker() {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('خوارنگەهێک هەڵبژێرە بۆ دیاریکردنی شوێنەکەی', style: TextStyle(color: Colors.indigo, fontSize: 16)),
      content: SizedBox(width: 300, height: 300, child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Restaurants').snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          var docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('هیچ خوارنگەهێک نییە'));
          return ListView(children: docs.map((d) => ListTile(
            leading: const Icon(Icons.storefront, color: Colors.orange),
            title: Text(d['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(d['latitude'] != null ? 'لۆکەیشنی هەیە' : 'بێ لۆکەیشن', style: TextStyle(color: d['latitude'] != null ? Colors.green : Colors.red)),
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لۆکەیشنی خوارنگەهەکە جێگیر کرا!'), backgroundColor: Colors.green));
  }
}
