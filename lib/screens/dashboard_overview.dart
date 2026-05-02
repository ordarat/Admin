// Path: lib/screens/dashboard_overview.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardOverviewScreen extends StatelessWidget {
  const DashboardOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 15.0 : 30.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('داشبۆردی سەرەکی (ڕاستەقینە)', style: TextStyle(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E2C))),
              const SizedBox(height: 10),
              const Text('ئەم ئامارانە ڕاستەوخۆ لەناو داتابەیسی فایەربەیسەوە دەخوێندرێنەوە.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),

              // بەشی کارتەکان بە شێوەی زیندوو (Live)
              GridView.count(
                crossAxisCount: isMobile ? 1 : 4,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isMobile ? 2.5 : 1.5,
                children: [
                  // کارتی 1: ئۆردەرە نوێیەکان (Pending)
                  _buildLiveStatCard(
                    title: 'ئۆردەری چاوەڕێکراو',
                    icon: Icons.shopping_cart,
                    color: Colors.orange,
                    stream: FirebaseFirestore.instance.collection('Orders').where('status', isEqualTo: 'pending').snapshots(),
                    countBuilder: (docs) => docs.length.toString(),
                  ),

                  // کارتی 2: شۆفێرە ئۆنلاینەکان
                  _buildLiveStatCard(
                    title: 'شۆفێرە ئۆنلاینەکان',
                    icon: Icons.motorcycle,
                    color: Colors.green,
                    stream: FirebaseFirestore.instance.collection('Drivers').where('is_online', isEqualTo: true).snapshots(),
                    countBuilder: (docs) => docs.length.toString(),
                  ),

                  // کارتی 3: کۆی خوارنگەهەکان
                  _buildLiveStatCard(
                    title: 'خوارنگەهەکان',
                    icon: Icons.restaurant,
                    color: Colors.blue,
                    stream: FirebaseFirestore.instance.collection('Restaurants').snapshots(),
                    countBuilder: (docs) => docs.length.toString(),
                  ),

                  // کارتی 4: قازانجی ئەمڕۆ (نموونەی کۆکردنەوەی پارە)
                  _buildLiveStatCard(
                    title: 'داهاتی ئۆردەرەکان',
                    icon: Icons.attach_money,
                    color: Colors.purple,
                    stream: FirebaseFirestore.instance.collection('Orders').where('status', isEqualTo: 'completed').snapshots(),
                    countBuilder: (docs) {
                      double total = 0;
                      for (var doc in docs) {
                        // گریمانە دەکەین فێڵدی total_price هەیە
                        total += (doc.data() as Map<String, dynamic>)['total_price'] ?? 0.0;
                      }
                      return '${total.toInt()} IQD';
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // فەنکشنێک بۆ دروستکردنی کارتی زیندوو (Live Card) بە بەکارهێنانی StreamBuilder
  Widget _buildLiveStatCard({
    required String title,
    required IconData icon,
    required Color color,
    required Stream<QuerySnapshot> stream,
    required String Function(List<QueryDocumentSnapshot>) countBuilder,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        String displayValue = '...';
        
        if (snapshot.hasError) {
          displayValue = 'هەڵە';
        } else if (snapshot.hasData) {
          displayValue = countBuilder(snapshot.data!.docs);
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
            ],
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(icon, color: color, size: 30),
                  ),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
              const Spacer(),
              Text(
                displayValue,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2C)),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }
}
