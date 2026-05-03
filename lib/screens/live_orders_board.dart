// Path: lib/screens/live_orders_board.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveOrdersBoardScreen extends StatefulWidget {
  const LiveOrdersBoardScreen({super.key});

  @override
  State<LiveOrdersBoardScreen> createState() => _LiveOrdersBoardScreenState();
}

class _LiveOrdersBoardScreenState extends State<LiveOrdersBoardScreen> {
  final Color primaryBlue = const Color(0xFF0056D2);

  // دۆخە نوێیەکان کە (تەرخانکراو - assigned)ی بۆ زیاد کراوە
  final List<String> _statuses = ['pending', 'assigned', 'delivering', 'completed', 'cancelled'];
  final Map<String, String> _statusNames = {
    'pending': 'چاوەڕێی ئەدمین',
    'assigned': 'دراوە بە شۆفێر',
    'delivering': 'لە رێگایە',
    'completed': 'گەیەندراو',
    'cancelled': 'ڕەتکراوە'
  };

  final Map<String, Color> _statusColors = {
    'pending': Colors.orange,
    'assigned': Colors.indigo,
    'delivering': Colors.purple,
    'completed': Colors.green,
    'cancelled': Colors.red,
  };

  // مێشکی سیستەمەکە: حیسابکردنی دووری نێوان دوو خاڵ بە کیلۆمەتر
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 + c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a)); 
  }

  // مێشکی دارایی: حیسابکردنی نرخی گەیاندن
  double _calculateDeliveryFee(double distanceKm) {
    double baseFee = 1500.0; // نرخی سەرەتایی
    double perKmFee = 500.0; // نرخی هەر کیلۆمەترێک
    return baseFee + (distanceKm * perKmFee);
  }

  // تەرخانکردنی ئۆردەر بۆ شۆفێر
  Future<void> _assignOrderToDriver(String orderId, String driverId, String driverName) async {
    await FirebaseFirestore.instance.collection('Orders').doc(orderId).update({
      'status': 'assigned',
      'assigned_driver_id': driverId,
      'driver_name': driverName,
      'assigned_at': FieldValue.serverTimestamp(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ئۆردەرەکە نێردرا بۆ شۆفێر: $driverName'), backgroundColor: Colors.green));
    }
  }

  // گۆڕینی دۆخی ئۆردەر بە گشتی
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    await FirebaseFirestore.instance.collection('Orders').doc(orderId).update({'status': newStatus});
  }

  Future<void> _deleteOrder(String orderId) async {
    await FirebaseFirestore.instance.collection('Orders').doc(orderId).delete();
  }

  // دروستکردنی ئۆردەری خەیاڵی بۆ تاقیکردنەوەی سیستەمە زیرەکەکە
  Future<void> _createDummySmartOrder() async {
    // لۆکەیشنی خەیاڵی خوارنگەهـ و کڕیار بۆ تاقیکردنەوە
    double restLat = 36.1900; double restLng = 44.0000;
    double custLat = 36.2100; double custLng = 44.0200;

    double distance = _calculateDistance(restLat, restLng, custLat, custLng);
    double deliveryFee = _calculateDeliveryFee(distance);

    await FirebaseFirestore.instance.collection('Orders').add({
      'restaurant_name': 'خوارنگەهی ڤی ئای پی',
      'customer_phone': '0750 123 4567',
      'customer_address': 'گەڕەکی بەختیاری، ماڵی ژمارە ١٢',
      'rest_lat': restLat, 'rest_lng': restLng,
      'cust_lat': custLat, 'cust_lng': custLng,
      'distance_km': double.parse(distance.toStringAsFixed(2)),
      'delivery_fee': deliveryFee.toInt(),
      'food_price': 15000,
      'total_price': 15000 + deliveryFee.toInt(),
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // شاشەی هەڵبژاردنی شۆفێر
  void _showAssignDriverDialog(String orderId, Map<String, dynamic> orderData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('هەڵبژاردنی شۆفێر بۆ ئەم ئۆردەرە', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400, height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('دووری: ${orderData['distance_km'] ?? 0} کم', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('کرێی گەیاندن: ${orderData['delivery_fee'] ?? 0} دینار', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              const Text('شۆفێرە ئۆنلاینەکان:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const Divider(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('Drivers').where('is_online', isEqualTo: true).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    var drivers = snapshot.data!.docs;
                    if (drivers.isEmpty) return const Center(child: Text('هیچ شۆفێرێک ئۆنلاین نییە!', style: TextStyle(color: Colors.red)));

                    return ListView.builder(
                      itemCount: drivers.length,
                      itemBuilder: (context, index) {
                        var driver = drivers[index].data() as Map<String, dynamic>;
                        return ListTile(
                          leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.motorcycle, color: Colors.white)),
                          title: Text(driver['name'] ?? 'بێ ناو', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(driver['phone'] ?? ''),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                            onPressed: () {
                              Navigator.pop(context);
                              _assignOrderToDriver(orderId, drivers[index].id, driver['name'] ?? 'شۆفێر');
                            },
                            child: const Text('ناردن'),
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
      ),
    );
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
                    Text('کۆنترۆڵی ئۆردەرەکان (Dispatch)', style: TextStyle(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E2C))),
                    const SizedBox(height: 5),
                    const Text('ئۆردەرەکان وەربگرە و بڕیار بدە بیدەیت بە کام شۆفێر', style: TextStyle(color: Colors.grey)),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  onPressed: _createDummySmartOrder,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('ئۆردەری تاقیکردنەوە'),
                )
              ],
            ),
            const SizedBox(height: 20),
            
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('Orders').orderBy('created_at', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Center(child: Text('کێشەیەک هەیە'));
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  var allOrders = snapshot.data!.docs;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _statuses.map((status) {
                        var statusOrders = allOrders.where((doc) => (doc.data() as Map<String, dynamic>)['status'] == status).toList();
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

  Widget _buildKanbanColumn(String status, List<QueryDocumentSnapshot> orders) {
    Color colColor = _statusColors[status]!;
    
    return Container(
      width: 320,
      margin: const EdgeInsets.only(left: 15),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[200]!)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: colColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
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
          
          Expanded(
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                var data = orders[index].data() as Map<String, dynamic>;
                String orderId = orders[index].id;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: status == 'pending' ? Colors.orange : Colors.transparent, width: status == 'pending' ? 2 : 0)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(data['restaurant_name'] ?? 'نەزانراو', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
                            IconButton(constraints: const BoxConstraints(), padding: EdgeInsets.zero, icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => _deleteOrder(orderId)),
                          ],
                        ),
                        const Divider(),
                        Row(children: [const Icon(Icons.location_on, size: 14, color: Colors.grey), const SizedBox(width: 5), Expanded(child: Text(data['customer_address'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis))]),
                        const SizedBox(height: 5),
                        
                        // پیشاندانی دووری و کرێی گەیاندن
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('دووری: ${data['distance_km'] ?? 0} کم', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              Text('کرێ: ${data['delivery_fee'] ?? 0} IQD', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        
                        if (status == 'pending') ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                              onPressed: () => _showAssignDriverDialog(orderId, data),
                              icon: const Icon(Icons.motorcycle),
                              label: const Text('هەڵبژاردنی شۆفێر'),
                            ),
                          )
                        ] else ...[
                          if (data['driver_name'] != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(children: [const Icon(Icons.person, size: 14, color: Colors.indigo), const SizedBox(width: 5), Text('شۆفێر: ${data['driver_name']}', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 12))]),
                            ),
                          Container(
                            height: 35, padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true, value: status, icon: const Icon(Icons.arrow_drop_down, size: 20),
                                style: const TextStyle(fontSize: 12, color: Colors.black, fontFamily: 'KurdishFont'),
                                items: _statuses.map((String s) => DropdownMenuItem<String>(value: s, child: Text('گۆڕین بۆ: ${_statusNames[s]}'))).toList(),
                                onChanged: (newVal) { if (newVal != null && newVal != status) _updateOrderStatus(orderId, newVal); },
                              ),
                            ),
                          ),
                        ]
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
