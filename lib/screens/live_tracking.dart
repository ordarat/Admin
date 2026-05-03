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
  LatLng _mapCenter = const LatLng(36.8679, 42.9830); // دیفۆڵت (دهۆک)
  final MapController _mapController = MapController();
  
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

  // --- فەنکشن بۆ پەیوەندیکردن ---
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نەتوانرا پەیوەندی بکرێت.'), backgroundColor: Colors.red));
      }
    }
  }

  // --- سڕینەوەی لۆکەیشن ---
  Future<void> _removeLocation(String uid, String collection) async {
    await FirebaseFirestore.instance.collection(collection).doc(uid).update({
      'latitude': FieldValue.delete(),
      'longitude': FieldValue.delete(),
    });
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لۆکەیشنەکە بە سەرکەوتوویی سڕایەوە!'), backgroundColor: Colors.green));
    }
  }

  // --- دیالۆگی نوێی پڕۆفایل لەسەر نەخشە ---
  void _showMapProfileDialog(String uid, String collection, Map<String, dynamic> data) {
    String profileImg = data['profile_image'] ?? data['image_url'] ?? '';
    Color themeColor = collection == 'Drivers' ? Colors.blue : Colors.orange;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 350, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(alignment: Alignment.topRight, child: IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context))),
              
              // وێنەی پڕۆفایل
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: themeColor, width: 3)),
                child: profileImg.isNotEmpty 
                  ? ClipOval(child: Image.network(profileImg, fit: BoxFit.cover, errorBuilder: (c,e,s) => Icon(collection == 'Drivers' ? Icons.motorcycle : Icons.storefront, size: 40, color: themeColor)))
                  : CircleAvatar(backgroundColor: themeColor.withOpacity(0.1), child: Icon(collection == 'Drivers' ? Icons.motorcycle : Icons.storefront, size: 40, color: themeColor)),
              ),
              const SizedBox(height: 10),
              
              // ناو و ژمارە
              Text(data['name'] ?? 'بێ ناو', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(data['phone'] ?? '', style: const TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 15),

              // زانیاری ئۆردەر و باڵانس
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      const Text('باڵانس', style: TextStyle(color: Colors.grey)),
                      Text('${data['wallet_balance'] ?? 0} IQD', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                    ],
                  ),
                  Container(width: 1, height: 40, color: Colors.grey[300]),
                  Column(
                    children: [
                      const Text('ئۆردەرەکان', style: TextStyle(color: Colors.grey)),
                      Text('${data['completed_orders'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // دوگمەی پەیوەندیکردن
              SizedBox(
                width: double.infinity, height: 45,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () => _makePhoneCall(data['phone'] ?? ''),
                  icon: const Icon(Icons.phone), label: const Text('پەیوەندیکردن'),
                ),
              ),
              const SizedBox(height: 10),
              
              // دوگمەی سڕینەوەی لۆکەیشن لەبری باندکردن
              SizedBox(
                width: double.infinity, height: 45,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50], foregroundColor: Colors.red, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.red))),
                  onPressed: () => _removeLocation(uid, collection),
                  icon: const Icon(Icons.location_off), label: const Text('سڕینەوەی لۆکەیشن'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- تابی زۆر شاز بۆ دانانی لۆکەیشنی خوارنگەهـ ---
  void _showSetLocationDialog() {
    String? selectedRestId;
    TextEditingController linkCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.add_location_alt, color: Colors.indigo),
                SizedBox(width: 10),
                Text('دانانی لۆکەیشنی دەقیق', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('١. خوارنگەهـ هەڵبژێرە:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),
                  
                  // هێنانی لیستی خوارنگەهەکان ڕاستەوخۆ لە فایەربەیس
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('Restaurants').orderBy('name').snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) return const CircularProgressIndicator();
                      var docs = snap.data!.docs;
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[300]!)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            hint: const Text('ناوی خوارنگەهـ...'),
                            value: selectedRestId,
                            items: docs.map((doc) {
                              var data = doc.data() as Map<String, dynamic>;
                              bool hasLoc = data['latitude'] != null;
                              return DropdownMenuItem<String>(
                                value: doc.id,
                                child: Text('${data['name']} ${hasLoc ? "(لۆکەیشنی هەیە)" : "(بێ لۆکەیشن)"}', style: TextStyle(color: hasLoc ? Colors.green : Colors.red)),
                              );
                            }).toList(),
                            onChanged: (val) => setStateDialog(() => selectedRestId = val),
                          ),
                        ),
                      );
                    }
                  ),
                  const SizedBox(height: 20),

                  const Text('٢. لینکی گوگڵ ماپ (Google Maps):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: linkCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'لینکەکە لێرە Paste بکە...\nیان کۆردینەیت (36.192, 44.012)',
                      filled: true, fillColor: Colors.blue[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('پاشگەزبوونەوە')),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () async {
                  if (selectedRestId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تکایە خوارنگەهـ هەڵبژێرە'), backgroundColor: Colors.red));
                    return;
                  }
                  
                  String text = linkCtrl.text;
                  // دۆزینەوەی ژمارەی دەقیق لەناو لینکەکە یان تێکستەکە
                  RegExp regExp = RegExp(r'(-?\d+\.\d+)[,\s]+(-?\d+\.\d+)');
                  var match = regExp.firstMatch(text);
                  
                  if (match != null) {
                    double lat = double.parse(match.group(1)!);
                    double lng = double.parse(match.group(2)!);
                    
                    Navigator.pop(context); // داخستنی دیالۆگەکە
                    
                    await FirebaseFirestore.instance.collection('Restaurants').doc(selectedRestId).update({
                      'latitude': lat,
                      'longitude': lng,
                    });
                    
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لۆکەیشن بە دەقیقی دانرا!'), backgroundColor: Colors.green));
                    _mapController.move(LatLng(lat, lng), 15.0); // فڕینی نەخشەکە بۆ شوێنە نوێیەکە
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نەتوانرا لۆکەیشنەکە لە لینکەکە دەربهێنرێت!'), backgroundColor: Colors.orange));
                  }
                },
                icon: const Icon(Icons.check_circle), label: const Text('سەیڤکردن لەسەر نەخشە'),
              )
            ],
          );
        }
      ),
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

                if (restSnap.hasData && _showRestaurants) {
                  for (var doc in restSnap.data!.docs) {
                    var d = doc.data() as Map<String, dynamic>;
                    if (d['latitude'] != null) {
                      String? imageUrl = d['profile_image'] ?? d['image_url'];
                      markers.add(Marker(
                        point: LatLng(d['latitude'], d['longitude']),
                        width: 80, height: 80,
                        child: GestureDetector(
                          onTap: () => _showMapProfileDialog(doc.id, 'Restaurants', d),
                          child: Column(children: [
                            Container(width: 45, height: 45, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.orange, width: 3), color: Colors.white, boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)]), child: (imageUrl != null && imageUrl.isNotEmpty) ? ClipOval(child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.storefront, color: Colors.orange))) : const Icon(Icons.storefront, color: Colors.orange)),
                            const SizedBox(height: 4),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]), child: Text(d['name'] ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange), overflow: TextOverflow.ellipsis)),
                          ]),
                        ),
                      ));
                    }
                  }
                }

                int onlineCount = 0;
                int offlineCount = 0;

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
                            onTap: () => _showMapProfileDialog(doc.id, 'Drivers', d),
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                Container(width: 50, height: 50, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isOnline ? Colors.green : Colors.grey, width: 3), color: Colors.white, boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)]), child: (imageUrl != null && imageUrl.isNotEmpty) ? ClipOval(child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c,e,s) => Icon(Icons.motorcycle, color: isOnline ? Colors.green : Colors.grey))) : Icon(Icons.motorcycle, color: isOnline ? Colors.green : Colors.grey)),
                                Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 8, backgroundColor: Colors.white, child: CircleAvatar(radius: 6, backgroundColor: isOnline ? Colors.green : Colors.grey))),
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

        // دوگمەی دانانی لۆکەیشنی نوێ
        Positioned(
          bottom: 20, right: 20,
          child: FloatingActionButton.extended(
            heroTag: 'addLocationMap',
            backgroundColor: const Color(0xFF0056D2),
            onPressed: _showSetLocationDialog,
            label: const Text('دانانی لۆکەیشنی خوارنگەهـ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            icon: const Icon(Icons.add_location_alt, color: Colors.white),
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
        child: Row(children: [Icon(value ? Icons.check_box : Icons.check_box_outline_blank, color: color, size: 20), const SizedBox(width: 8), Text(title, style: TextStyle(color: value ? Colors.black : Colors.grey, fontSize: 13))]),
      ),
    );
  }
}
