// Path: lib/screens/dashboard_overview.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardOverview extends StatelessWidget {
  const DashboardOverview({super.key});

  @override
  Widget build(BuildContext context) {
    // پشکنینی قەبارەی شاشەکە
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 15.0 : 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('پوختەی ئامارەکان', style: TextStyle(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E2C))),
          const SizedBox(height: 10),
          Text('بەخێربێیت بۆ ژووری کۆنترۆڵی ئۆردەرات.', style: TextStyle(color: Colors.grey, fontSize: isMobile ? 14 : 16)),
          const SizedBox(height: 40),
          
          // بەکارهێنانی Wrap لەبری Row بۆ ئەوەی لە شاشەی بچووکدا نەبێتە هۆی کراش
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              SizedBox(width: isMobile ? double.infinity : 300, child: _buildStatCard('کۆی شۆفێرەکان', 'Drivers', Icons.motorcycle, Colors.blue)),
              SizedBox(width: isMobile ? double.infinity : 300, child: _buildStatCard('کۆی خوارنگەهەکان', 'Restaurants', Icons.restaurant, Colors.orange)),
              SizedBox(width: isMobile ? double.infinity : 300, child: _buildStatCard('ئۆردەرە چالاکەکان', 'Orders', Icons.shopping_bag, Colors.green, isOrders: true)),
            ],
          ),
          
          const SizedBox(height: 40),
          
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isMobile ? 20 : 30),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.auto_graph, size: isMobile ? 60 : 80, color: Colors.indigo[100]),
                const SizedBox(height: 20),
                Text('سیستەمی ئۆردەرات لە گەشەکردندایە', textAlign: TextAlign.center, style: TextStyle(fontSize: isMobile ? 16 : 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String collection, IconData icon, Color color, {bool isOrders = false}) {
    return StreamBuilder<QuerySnapshot>(
      stream: isOrders 
          ? FirebaseFirestore.instance.collection(collection).where('status', whereIn: ['pending', 'accepted']).snapshots()
          : FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        int count = 0;
        if (snapshot.hasData) count = snapshot.data!.docs.length;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))], border: Border(bottom: BorderSide(color: color, width: 4))),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, size: 30, color: color)),
              const SizedBox(width: 15),
              // ئەگەر نووسینەکە درێژ بوو، Expanded ناهێڵێت شاشەکە رەساسی ببێت
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 5),
                    snapshot.connectionState == ConnectionState.waiting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('$count', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
