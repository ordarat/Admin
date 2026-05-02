// Path: lib/screens/financial_report.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FinancialReportScreen extends StatefulWidget {
  const FinancialReportScreen({super.key});

  @override
  State<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends State<FinancialReportScreen> {
  final Color primaryBlue = const Color(0xFF0056D2);
  
  // دیفۆڵت: لە ٧ رۆژی رابردووەوە تا ئەمڕۆ
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  
  bool _isLoading = true;
  num _periodIncome = 0;
  int _periodOrdersCount = 0;
  List<Map<String, dynamic>> _ordersList = [];

  @override
  void initState() {
    super.initState();
    _fetchFinancialData();
  }

  // هێنانی داتا بەپێی ئەو بەروارەی دیاریکراوە
  Future<void> _fetchFinancialData() async {
    setState(() => _isLoading = true);
    try {
      // هێنانی هەموو ئۆردەرە تەواوکراوەکان (بۆ ئەوەی کێشەی Indexی فایەربەیس دروست نەبێت، لێرە فلتەری دەکەین)
      var ordersQuery = await FirebaseFirestore.instance.collection('Orders').where('status', isEqualTo: 'completed').get();

      num totalIncome = 0;
      List<Map<String, dynamic>> tempOrders = [];

      // هێنانی پشکی کۆمپانیا لە رێکخستنەکان (ئەگەر نەبوو ٥٠٠ دینار حیساب دەکات)
      var financeDoc = await FirebaseFirestore.instance.collection('App_Settings').doc('Financials').get();
      num companySharePerOrder = (financeDoc.exists && financeDoc.data() != null) ? (financeDoc.data()!['company_share'] ?? 500) : 500;

      // فلتەرکردنی بەروارەکە
      for (var doc in ordersQuery.docs) {
        var data = doc.data();
        if (data['created_at'] != null) {
          Timestamp ts = data['created_at'];
          DateTime orderDate = ts.toDate();
          
          // ئایا ئۆردەرەکە دەکەوێتە نێوان ئەو دوو بەروارەی دیاریمان کردووە؟
          if (orderDate.isAfter(_startDate.subtract(const Duration(days: 1))) && 
              orderDate.isBefore(_endDate.add(const Duration(days: 1)))) {
            
            totalIncome += companySharePerOrder; // زیادکردنی قازانجی کۆمپانیا
            tempOrders.add(data);
          }
        }
      }

      // رێکخستنی لیستەکە لە نوێترینەوە بۆ کۆنترین
      tempOrders.sort((a, b) => (b['created_at'] as Timestamp).compareTo(a['created_at'] as Timestamp));

      setState(() {
        _periodIncome = totalIncome;
        _periodOrdersCount = tempOrders.length;
        _ordersList = tempOrders;
        _isLoading = false;
      });

    } catch (e) {
      debugPrint("Error fetching finance: $e");
      setState(() => _isLoading = false);
    }
  }

  // پەنجەرەی هەڵبژاردنی بەروار (Date Range Picker)
  Future<void> _pickDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.indigo, onPrimary: Colors.white, onSurface: Colors.black),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchFinancialData(); // نوێکردنەوەی داتاکان بەپێی بەروارە نوێیەکە
    }
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 15.0 : 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // سەردێڕ و دوگمەی هەڵبژاردنی بەروار
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('راپۆرتی دارایی', style: TextStyle(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E2C))),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
                onPressed: _pickDateRange,
                icon: const Icon(Icons.calendar_month),
                label: Text('لە: ${_formatDate(_startDate)} تا ${_formatDate(_endDate)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else ...[
            // کارتەکانی ئامار
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'قازانجی پوختی کۆمپانیا', '$_periodIncome IQD', Icons.account_balance, [const Color(0xFF0056D2), const Color(0xFF003D99)]
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildSummaryCard(
                    'ژمارەی ئۆردەرەکان', '$_periodOrdersCount ئۆردەر', Icons.shopping_bag, [Colors.green[600]!, Colors.green[800]!]
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // لیستی وەسڵەکان
            const Text('وردەکاری ئۆردەرەکان (لەو بەروارەدا)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 10),
            
            Expanded(
              child: _ordersList.isEmpty 
              ? const Center(child: Text('هیچ ئۆردەرێک لەم بەروارەدا نییە', style: TextStyle(color: Colors.grey, fontSize: 16)))
              : ListView.builder(
                  itemCount: _ordersList.length,
                  itemBuilder: (context, index) {
                    var order = _ordersList[index];
                    DateTime dt = (order['created_at'] as Timestamp).toDate();
                    String timeString = "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
                    String dateString = _formatDate(dt);

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.greenAccent, child: Icon(Icons.check, color: Colors.white)),
                        title: Text('خوارنگەهـ: ${order['restaurant_name'] ?? 'نەزانراو'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('گەیشتووەتە: ${order['delivery_address']}\nبەروار: $dateString لە $timeString'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${order['total_price']} IQD', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
                            const Text('نرخی وەسڵ', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ),
          ],
        ],
      ),
    );
  }

  // دیزاینی کارتی سەرەوە
  Widget _buildSummaryCard(String title, String value, IconData icon, List<Color> gradientColors) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: gradientColors[0].withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 30),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 16))),
            ],
          ),
          const SizedBox(height: 15),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
