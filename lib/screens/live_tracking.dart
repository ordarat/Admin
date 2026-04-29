// Path: lib/screens/live_tracking.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveTrackingScreen extends StatelessWidget {
  const LiveTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LatLng initialCenter = const LatLng(36.1900, 43.9930); 

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('نەخشەی راستەوخۆی سیستەم (Live GPS)', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
          const SizedBox(height: 10),
          const Text('لێرەوە هەردوو شۆفێرەکان و خوارنگەهەکان دەبینیت بە وێنەی پڕۆفایلەکانیانەوە.', style: TextStyle(color: Colors.grey)),
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
                      
                      List<Marker> allMarkers = [];

                      // ١. زیادکردنی مارکەری شۆفێرەکان (بازنەی شین بە وێنەوە)
                      if (driverSnapshot.hasData) {
                        for (var doc in driverSnapshot.data!.docs) {
                          var data = doc.data() as Map<String, dynamic>;
                          if (data['latitude'] != null && data['longitude'] != null) {
                            String? imageUrl = data['profile_image'];
                            
                            allMarkers.add(
                              Marker(
                                point: LatLng(data['latitude'], data['longitude']),
                                width: 90, height: 90, // کەمێک گەورەترمان کرد بۆ ئەوەی وێنەکە جوان دەربکەویت
                                child: Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.blue, width: 2.5),
                                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                      ),
                                      child: CircleAvatar(
                                        radius: 18,
                                        backgroundColor: Colors.white,
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

                      // ٢. زیادکردنی مارکەری خوارنگەهەکان (بازنەی پرتەقاڵی بە وێنەوە)
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
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.orange, width: 2.5),
                                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                      ),
                                      child: CircleAvatar(
                                        radius: 18,
                                        backgroundColor: Colors.white,
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

                      return FlutterMap(
                        options: MapOptions(
                          initialCenter: initialCenter, 
                          initialZoom: 13.0, 
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.ibrahim.ordarat',
                          ),
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
