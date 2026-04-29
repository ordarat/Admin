import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LiveTrackingScreen extends StatelessWidget {
  const LiveTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // خاڵی دەستپێکی نەخشەکە (بۆ نموونە شاری هەولێر)
    final LatLng initialCenter = const LatLng(36.1900, 43.9930); 

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('نەخشەی راستەوخۆ (OpenStreetMap)', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
          const SizedBox(height: 10),
          const Text('لێرەوە دەتوانیت چاودێری جووڵەی شۆفێرەکان بکەیت لەسەر نەخشە.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: initialCenter, 
                  initialZoom: 13.0, 
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.ibrahim.ordarat',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: initialCenter,
                        width: 80,
                        height: 80,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
