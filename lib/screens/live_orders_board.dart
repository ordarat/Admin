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

  // لیست و ناوی دۆخەکانی ئۆردەر
  final List<String> _statuses = ['pending', 'preparing', 'delivering', 'completed', 'cancelled'];
  final Map<String, String> _statusNames = {
    'pending': 'چاوەڕێکراو (نوێ)',
    'preparing': 'ئامادەدەکرێت',
    'delivering': 'لە رێگایە',
    'completed': 'گەیەندراو',
    'cancelled': 'ڕەتکراوە'
  };

  final Map<String, Color> _statusColors = {
    'pending': Colors.orange,
    'preparing': Colors.blue,
    'delivering': Colors.purple,
    'completed': Colors.green,
    'cancelled': Colors.red,
  };

  // گۆڕینی دۆخی ئۆردەر
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    await FirebaseFirestore.instance.collection('Orders').doc(orderId).update({
      'status': newStatus,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('دۆخی ئۆردەرەکە گۆڕدرا بۆ: ${_statusNames[newStatus]}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ));
    }
  }

  // سڕینەوەی ئۆردەر (تەنها بۆ ئەدمین)
  Future<void> _deleteOrder(String orderId) async {
    await FirebaseFirestore.instance.collection('Orders').doc(orderId).delete();
  }

  // دروستکردنی ئۆردەری خەیاڵی بۆ تاقیکردنەوە
  Future<void> _createDummyOrder() async {
    await FirebaseFirestore.instance.collection('Orders').add({
      'restaurant_name': 'خوارنگەهی تاقیکردنەوە',
      'customer_phone': '0750 123 4567',
      'customer_address': 'گەڕەکی بەختیاری، کۆڵانی ٥',
      'total_price': 15000,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 15.0 : 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('بۆردی ئۆردەرەکان (Live)', style: TextStyle(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E2C))),
                    const SizedBox(height: 5),
                    const Text('چاودێری و گۆڕینی دۆخی ئۆردەرەکان بە شێوەی ڕاستەوخۆ', style: TextStyle(color: Colors.grey)),
                  ],
                ),
                // دوگمەی تاقیکردنەوە
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  onPressed: _createDummyOrder,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('ئۆردەری تاقیکردنەوە'),
                )
              ],
            ),
            const SizedBox(height: 20),
            
            // بۆردی کانبان
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('Orders').orderBy('created_at', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Center(child: Text('کێشەیەک هەیە لە هێنانی داتاکان'));
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  var allOrders = snapshot.data!.docs;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _statuses.map((status) {
                        // جیاکردنەوەی ئۆردەرەکان بەپێی دۆخەکانیان
                        var statusOrders = allOrders.where((doc) {
                          var data = doc.data() as Map<String, dynamic>;
                          return data['status'] == status;
                        }).toList();

                        return _buildKanbanColumn(status, statusOrders);
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // دروستکردنی ستوونێکی بۆردەکە
  Widget _buildKanbanColumn(String status, List<QueryDocumentSnapshot> orders) {
    Color colColor = _statusColors[status]!;
    
    return Container(
      width: 300,
      margin: const EdgeInsets.only(left: 15),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // سەردێڕی ستوونەکە
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: colColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(radius: 12, backgroundColor: colColor, child: Text(orders.length.toString(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                const SizedBox(width: 10),
                Text(_statusNames[status]!, style: TextStyle(fontWeight: FontWeight.bold, color: colColor, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          
          // لیستی کارتەکانی ناو ئەم ستوونە
          Expanded(
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                var data = orders[index].data() as Map<String, dynamic>;
                String orderId = orders[index].id;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(data['restaurant_name'] ?? 'نەزانراو', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () => _deleteOrder(orderId),
                              tooltip: 'سڕینەوەی ئۆردەر',
                            ),
                          ],
                        ),
                        const Divider(),
                        Row(children: [const Icon(Icons.phone, size: 14, color: Colors.grey), const SizedBox(width: 5), Text(data['customer_phone'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12))]),
                        const SizedBox(height: 5),
                        Row(children: [const Icon(Icons.location_on, size: 14, color: Colors.grey), const SizedBox(width: 5), Expanded(child: Text(data['customer_address'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis))]),
                        const SizedBox(height: 10),
                        Text('${data['total_price'] ?? 0} IQD', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 10),
                        
                        // دوگمەی گۆڕینی دۆخ (Dropdown)
                        Container(
                          height: 35,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: status,
                              icon: const Icon(Icons.arrow_drop_down, size: 20),
                              style: const TextStyle(fontSize: 12, color: Colors.black, fontFamily: 'KurdishFont'),
                              items: _statuses.map((String s) {
                                return DropdownMenuItem<String>(
                                  value: s,
                                  child: Text('گۆڕین بۆ: ${_statusNames[s]}'),
                                );
                              }).toList(),
                              onChanged: (newVal) {
                                if (newVal != null && newVal != status) {
                                  _updateOrderStatus(orderId, newVal);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
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
