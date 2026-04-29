// Path: lib/screens/live_tracking.dart

import 'package:flutter/material.dart';

class LiveTrackingScreen extends StatelessWidget {
  const LiveTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('نەخشەی راستەوخۆ (Live Map)', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
          const SizedBox(height: 10),
          const Text('لەم شاشەیەدا بەم زووانە نەخشەی گووگڵ دادەنرێت بۆ بینینی جووڵەی شۆفێرەکان.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey, width: 2),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 100, color: Colors.grey),
                    SizedBox(height: 20),
                    Text('چاوەڕوانی بەستنەوە بە Google Maps API...', style: TextStyle(fontSize: 18, color: Colors.black54)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
