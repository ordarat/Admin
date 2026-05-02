// Path: lib/screens/dashboard_overview.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardOverviewScreen extends StatelessWidget {
  const DashboardOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 15.0 : 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('داشبۆردی سەرەکی', style: TextStyle(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E2C))),
          const SizedBox(height: 20),
          
          // بەکارهێنانی GridView بۆ ئەوەی لەسەر مۆبایل و کۆمپیوتەر رێک بێت
          GridView.count(
            crossAxisCount: isMobile ? 1 : 3,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: isMobile ? 2.5 : 1.5,
            children: [
              _buildStatCard('ژمارەی شۆفێران', 'Drivers', Icons.motorcycle, Colors.blue),
              _buildStatCard('ژمارەی خوارنگەهەکان', 'Restaurants', Icons.restaurant, Colors.orange),
              _buildStatCard('کۆی ئۆردەرەکان', 'Orders', Icons.shopping_bag, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  // دروستکردنی کارتی ئامار بە شێوەیەکی زیرەک کە داتا لە فایەربەیسەوە دەهێنێت
  Widget _buildStatCard(String title, String collectionName, IconData icon, Color color) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collectionName).snapshots(),
      builder: (context, snapshot) {
        int count = 0;
        if (snapshot.hasData) {
          count = snapshot.data!.docs.length;
        }

        return Card(
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                colors: [color.withOpacity(0.8), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), shape: BoxShape.circle),
                  child: Icon(icon, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      else
                        Text('$count', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
