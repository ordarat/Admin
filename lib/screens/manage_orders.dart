// Path: lib/screens/manage_orders.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageOrdersScreen extends StatelessWidget {
  const ManageOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('چاودێریکردنی ئۆردەرەکان (Live)', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
          const SizedBox(height: 10),
          const Text('لێرەوە دەتوانیت سەرجەم ئۆردەرەکانی سیستەمەکە ببینیت.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Orders')
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('هیچ ئۆردەرێک بوونی نییە.'));

                final orders = snapshot.data!.docs;

                return Card(
                  child: ListView.separated(
                    itemCount: orders.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      var order = orders[index].data() as Map<String, dynamic>;
                      
                      Color statusColor;
                      String statusText;
                      switch (order['status']) {
                        case 'pending': statusColor = Colors.red; statusText = 'چاوەڕوانە'; break;
                        case 'accepted': statusColor = Colors.blue; statusText = 'لە رێگایە'; break;
                        case 'delivered': statusColor = Colors.green; statusText = 'گەیەندراوە'; break;
                        default: statusColor = Colors.grey; statusText = 'نەزانراو';
                      }

                      return ListTile(
                        leading: CircleAvatar(backgroundColor: statusColor.withOpacity(0.2), child: Icon(Icons.receipt_long, color: statusColor)),
                        title: Text('کڕیار: ${order['customer_name']} - ${order['customer_phone']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ناونیشان: ${order['address']} | نرخ: ${order['food_price']} IQD'),
                            Text('ئایدی شۆفێر: ${order['driver_id'] ?? 'دیارینەکراوە'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                          child: Text(statusText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
