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
  final LatLng initialCenter = const LatLng(36.1900, 43.9930); 
  
  bool _isEditingLocation = false;
  String? _editingRestaurantId;
  String? _editingRestaurantName;

  void _showRestaurantPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('کام خوارنگەهـ دەتەوێت شوێنەکەی دیاری بکەیت؟', style: TextStyle(fontSize: 18, color: Colors.indigo)),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
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
                      subtitle: Text(data['phone'] ?? ''),
                      onTap: () {
                        setState(() {
                          _isEditingLocation = true;
                          _editingRestaurantId = restaurants[index].id;
                          _editingRestaurantName = data['name'];
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('پاشگەزبوونەوە', style: TextStyle(color: Colors.red))),
          ],
        );
      },
    );
  }

  Future<void> _updateRestaurantLocation(LatLng point) async {
    if (_isEditingLocation && _editingRestaurantId != null) {
      try {
        await FirebaseFirestore.instance.collection('Restaurants').doc(_editingRestaurantId).update({
          'latitude': point.latitude,
          'longitude': point.longitude,
        });
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('شوێنی ($_editingRestaurantName) بە سەرکەوتوویی لەسەر نەخشە جێگیر کرا!'),
          backgroundColor: Colors.green,
        ));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هەڵە لە گۆڕینی شوێنەکە'), backgroundColor: Colors.red));
      } finally {
        setState(() {
          _isEditingLocation = false;
          _editingRestaurantId = null;
          _editingRestaurantName = null;
        });
      }
    }
  }

  void _cancelEditing() {
    setState(() {
      _isEditingLocation = false;
      _editingRestaurantId = null;
      _editingRestaurantName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('نەخشەی راستەوخۆی سیستەم', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  SizedBox(height: 5),
                  Text('لێرەوە جووڵەی شۆفێرەکان دەبینیت، وە دەتوانیت شوێنی خوارنگەهەکان دیاری بکەیت.', style: TextStyle(color: Colors.grey)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
                onPressed: _isEditingLocation ? null : _showRestaurantPicker,
                icon: const Icon(Icons.add_location_alt),
                label: const Text('جێگیرکردنی شوێنی خوارنگەهـ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          
          if (_isEditingLocation) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange, width: 2)),
              child: Row(
                children: [
                  const Icon(Icons.touch_app, color: Colors.orange, size: 30),
                  const SizedBox(width: 15),
                  Expanded(child: Text('تکایە کلیک لەسەر هەر شوێنێکی نەخشەکە بکە بۆ دانانی لۆکەیشنی خوارنگەهی: [ $_editingRestaurantName ]', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepOrange))),
                  IconButton(tooltip: 'هەڵوەشاندنەوە', icon: const Icon(Icons.cancel, color: Colors.red, size: 30), onPressed: _cancelEditing),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 20),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('Drivers').where('is_active', isEqualTo: true).snapshots(),
                builder: (context, driverSnapshot) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('Restaurants').where('is_active', isEqualTo: true).snapshots(),
                    builder: (context, restSnapshot) {
                      return StreamBuilder<QuerySnapshot>(
                        // هێنانی ئەو ئۆردەرانەی کە هێشتا نەگەیەندراون
                        stream: FirebaseFirestore.instance.collection('Orders').where('status', whereIn: ['pending', 'accepted']).snapshots(),
                        builder: (context, orderSnapshot) {
                          
                          List<Marker> allMarkers = [];
                          List<Polyline> allPolylines = [];

                          // ١. مارکەری شۆفێرەکان (شین)
                          if (driverSnapshot.hasData) {
                            for (var doc in driverSnapshot.data!.docs) {
                              var data = doc.data() as Map<String, dynamic>;
                              if (data['latitude'] != null && data['longitude'] != null) {
                                String? imageUrl = data['profile_image'];
                                allMarkers.add(
                                  Marker(
                                    point: LatLng(data['latitude'], data['longitude']),
                                    width: 90, height: 90,
                                    child: Column(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.blue, width: 2.5), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                                          child: CircleAvatar(
                                            radius: 18, backgroundColor: Colors.white,
                                            backgroundImage: (imageUrl != null && imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null,
                                            child: (imageUrl == null || imageUrl.isEmpty) ? const Icon(Icons.motorcycle, color: Colors.blue, size: 20) : null,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(5), border: Border.all(color: Colors.blue)),
                                          child: Text(data['name'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              }
                            }
                          }

                          // ٢. مارکەری خوارنگەهەکان (پرتەقاڵی)
                          if (restSnapshot.hasData) {
                            for (var doc in restSnapshot.data!.docs) {
                              var data = doc.data() as Map<String, dynamic>;
                              if (data['latitude'] != null && data['longitude'] != null) {
                                String? imageUrl = data['profile_image'];
                                allMarkers.add(
                                  Marker(
                                    point: LatLng(data['latitude'], data['longitude']),
                                    width: 90, height: 90,
                                    child: Column(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.orange, width: 2.5), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                                          child: CircleAvatar(
                                            radius: 18, backgroundColor: Colors.white,
                                            backgroundImage: (imageUrl != null && imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null,
                                            child: (imageUrl == null || imageUrl.isEmpty) ? const Icon(Icons.restaurant, color: Colors.orange, size: 20) : null,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(5), border: Border.all(color: Colors.orange)),
                                          child: Text(data['name'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              }
                            }
                          }

                          // ٣. مارکەری کڕیارەکان (سەوز) و هێڵەکان لەناو ئۆردەرەکان
                          if (orderSnapshot.hasData) {
                            for (var doc in orderSnapshot.data!.docs) {
                              var order = doc.data() as Map<String, dynamic>;
                              
                              if (order['customer_lat'] != null && order['customer_lng'] != null) {
                                LatLng customerLocation = LatLng(order['customer_lat'], order['customer_lng']);
                                
                                // دانانی نیشانەی ماڵی کڕیار
                                allMarkers.add(
                                  Marker(
                                    point: customerLocation,
                                    width: 100, height: 80,
                                    child: Column(
                                      children: [
                                        const Icon(Icons.person_pin_circle, color: Colors.green, size: 40),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(5), border: Border.all(color: Colors.green)),
                                          child: Text('کڕیار: ${order['customer_name']}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                                        )
                                      ],
                                    ),
                                  ),
                                );

                                // کێشانی هێڵ لە نێوان خوارنگەهـ و کڕیار (ئەگەر ئۆردەرەکە چالاک بێت)
                                if (order['restaurant_lat'] != null && order['restaurant_lng'] != null) {
                                  LatLng restLocation = LatLng(order['restaurant_lat'], order['restaurant_lng']);
                                  allPolylines.add(
                                    Polyline(
                                      points: [restLocation, customerLocation],
                                      strokeWidth: 3.0,
                                      color: order['status'] == 'pending' ? Colors.redAccent.withOpacity(0.6) : Colors.blueAccent.withOpacity(0.6),
                                      isDotted: true, // هێڵی پچڕ پچڕ
                                    ),
                                  );
                                }
                              }
                            }
                          }

                          return FlutterMap(
                            options: MapOptions(
                              initialCenter: initialCenter, 
                              initialZoom: 13.0, 
                              onTap: (tapPosition, point) {
                                if (_isEditingLocation) {
                                  _updateRestaurantLocation(point);
                                }
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.ibrahim.ordarat',
                              ),
                              PolylineLayer(polylines: allPolylines), // پیشاندانی هێڵەکان
                              MarkerLayer(markers: allMarkers), // پیشاندانی خاڵەکان
                            ],
                          );
                        }
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
