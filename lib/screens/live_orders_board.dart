// Path: lib/screens/live_orders_board.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveOrdersBoardScreen extends StatefulWidget {
  const LiveOrdersBoardScreen({super.key});

  @override
  State<LiveOrdersBoardScreen> createState() => _LiveOrdersBoardScreenState();
}

class _LiveOrdersBoardScreenState extends State<LiveOrdersBoardScreen> {
  final Color primaryBlue = const Color(0xFF0056D2);

  // پەنجەرەی دیاریکردنی شۆفێر بە دەستی ئەدمین
  void _assignDriverManually(String orderId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('دیاریکردنی شۆفێر', style: TextStyle(color: Colors.indigo)),
          content: SizedBox(
            width: 300, height: 400,
            child: StreamBuilder<QuerySnapshot>(
              // تەنها ئەو شۆفێرانە دەهێنێت کە ئۆنلاینن
              stream: FirebaseFirestore.instance.collection('Drivers').where('is_online', isEqualTo: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var drivers = snapshot.data!.docs;
                if (drivers.isEmpty) return const Center(child: Text('هیچ شۆفێرێک ئۆنلاین نییە', style: TextStyle(color: Colors.red)));

                return ListView.builder(
                  itemCount: drivers.length,
                  itemBuilder: (context, index) {
                    var driver = drivers[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.motorcycle, color: Colors.white)),
                      title: Text(driver['name'] ?? ''),
                      subtitle: Text(driver['phone'] ?? ''),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white),
                        onPressed: () async {
                          // گۆڕینی شۆفێرەکە و گۆڕینی باری ئۆردەرەکە بۆ (وەرگیراو)
                          await FirebaseFirestore.instance.collection('Orders').doc(orderId).update({
                            'driver_id': drivers[index].id,
                            'status': 'accepted',
                          });
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شۆفێرەکە دیاریکرا!'), backgroundColor: Colors.green));
                        },
                        child: const Text('هەڵبژێرە'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  // کانسەڵکردنی ئۆردەر
  Future<void> _cancelOrder(String orderId) async {
    await FirebaseFirestore.instance.collection('Orders').doc(orderId).update({'status': 'cancelled'});
  }

  // دروستکردنی ستوونی کارتەکان
  Widget _buildOrderColumn(String title, Color headerColor, String statusFilter) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(15)),
        child: Column(
          children: [
            // سەردێڕی ستوونەکە
            Container(
              padding: const EdgeInsets.all(15),
              width: double.infinity,
              decoration: BoxDecoration(color: headerColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(15))),
              child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
            ),
            
            // لیستی ئۆردەرەکانی ناو ئەم ستوونە
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('Orders').where('status', isEqualTo: statusFilter).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  var orders = snapshot.data!.docs;
                  
                  if (orders.isEmpty) {
                    return const Center(child: Text('هیچ ئۆردەرێک نییە', style: TextStyle(color: Colors.grey)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      var order = orders[index].data() as Map<String, dynamic>;
                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text('لە: ${order['restaurant_name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                  Text('${order['total_price']} IQD', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const Divider(),
                              Text('بۆ: ${order['delivery_address']}', style: const TextStyle(fontSize: 13)),
                              Text('مۆبایلی کڕیار: ${order['customer_phone']}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                              const SizedBox(height: 10),
                              
                              // دوگمەکانی خوارەوەی کارتەکە بەپێی جۆری ستوونەکە دەگۆڕێن
                              if (statusFilter == 'pending' || statusFilter == 'accepted')
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white),
                                        onPressed: () => _assignDriverManually(orders[index].id),
                                        child: Text(statusFilter == 'pending' ? 'دانانی شۆفێر' : 'گۆڕینی شۆفێر', style: const TextStyle(fontSize: 12)),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    IconButton(
                                      icon: const Icon(Icons.cancel, color: Colors.red),
                                      tooltip: 'رەتکردنەوەی ئۆردەر',
                                      onPressed: () => _cancelOrder(orders[index].id),
                                    ),
                                  ],
                                ),
                              
                              if (statusFilter == 'completed')
                                const Center(child: Text('گەیشتووە ✅', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    // ئەگەر مۆبایل بوو با بە شێوەی تاب (Tab) بێت بۆ ئەوەی شاشەکە تێک نەچێت
    if (isMobile) {
      return DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: const Text('بۆردی ئۆردەرەکان', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            bottom: const TabBar(
              labelColor: Colors.indigo,
              indicatorColor: Colors.indigo,
              tabs: [
                Tab(text: 'نوێ (چاوەڕێ)'),
                Tab(text: 'لای شۆفێرە'),
                Tab(text: 'گەیشتووە'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _buildOrderColumn('ئۆردەری نوێ', Colors.orange, 'pending'),
              _buildOrderColumn('لە رێگایە', Colors.blue, 'accepted'),
              _buildOrderColumn('تەواوکراو', Colors.green, 'completed'),
            ],
          ),
        ),
      );
    }

    // ئەگەر کۆمپیوتەر یان ئایپاد بوو، با ٣ ستوونەکە بەیەکەوە پیشان بدات (وەک Trello)
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('بۆردی کۆنترۆڵکردنی ئۆردەرەکان (Live Kanban)', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2C))),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                _buildOrderColumn('نوێ (چاوەڕێی شۆفێرە)', Colors.orange, 'pending'),
                _buildOrderColumn('وەرگیراوە (لە رێگایە)', Colors.blue, 'accepted'),
                _buildOrderColumn('گەیشتووە (تەواوکراو)', Colors.green, 'completed'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
