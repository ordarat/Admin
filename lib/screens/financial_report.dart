// Path: lib/screens/financial_report.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FinancialReportScreen extends StatefulWidget {
  const FinancialReportScreen({super.key});

  @override
  State<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends State<FinancialReportScreen> {
  final Color primaryBlue = const Color(0xFF0056D2);
  
  // دیاریکردنی کاتی سەرەتا و کۆتایی بۆ ڕاپۆرتەکە (دیفۆڵت: ئەم مانگە)
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();

  Future<void> _pickDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Colors.indigo)), child: child!),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  // دروستکردنی فایلی PDF
  Future<void> _generateAndDownloadPDF(
      List<QueryDocumentSnapshot> orders, 
      double totalRevenue, 
      Map<String, Map<String, dynamic>> restStats, 
      Map<String, Map<String, dynamic>> driverStats) async {
    
    final pdf = pw.Document();
    final String dateRangeStr = '${DateFormat('yyyy-MM-dd').format(_startDate)} to ${DateFormat('yyyy-MM-dd').format(_endDate)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // سەردێڕی ڕاپۆرت
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Ordarat - Official Financial Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Date: $dateRangeStr', style: const pw.TextStyle(fontSize: 14)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // ئاماری گشتی
            pw.Text('1. General Overview', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Text('Total Completed Orders: ${orders.length}'),
            pw.Text('Total Revenue: ${totalRevenue.toInt()} IQD', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 30),

            // ئاماری خوارنگەهەکان
            pw.Text('2. Restaurants Breakdown', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Table.fromTextArray(
              headers: ['Restaurant Name', 'Total Orders', 'Total Revenue (IQD)'],
              data: restStats.entries.map((e) => [
                e.key, 
                e.value['count'].toString(), 
                e.value['total'].toInt().toString()
              ]).toList(),
            ),
            pw.SizedBox(height: 30),

            // ئاماری شۆفێران
            pw.Text('3. Drivers Breakdown', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Table.fromTextArray(
              headers: ['Driver Name', 'Total Deliveries', 'Generated Revenue (IQD)'],
              data: driverStats.entries.map((e) => [
                e.key, 
                e.value['count'].toString(), 
                e.value['total'].toInt().toString()
              ]).toList(),
            ),
          ];
        },
      ),
    );

    // پیشاندانی شاشەی پرینت/سەیڤکردن
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Ordarat_Financial_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;
    String dateRangeDisplay = '${DateFormat('yyyy-MM-dd').format(_startDate)}  بۆ  ${DateFormat('yyyy-MM-dd').format(_endDate)}';

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: EdgeInsets.all(isMobile ? 15.0 : 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // بەشی سەرەوە: سەردێڕ و ساڵنامە
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ڕاپۆرتی دارایی و قازانج', style: TextStyle(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E2C))),
                      const SizedBox(height: 5),
                      const Text('بەدواداچوون بۆ داهاتی گشتی، خوارنگەهـ و شۆفێران', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  if (!isMobile) _buildActionButtons(),
                ],
              ),
              const SizedBox(height: 20),
              
              if (isMobile) _buildActionButtons(),
              if (isMobile) const SizedBox(height: 20),

              // دوگمەی هەڵبژاردنی بەروار
              InkWell(
                onTap: _pickDateRange,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.indigo[100]!)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_month, color: Colors.indigo),
                      const SizedBox(width: 10),
                      Text('بەرواری ڕاپۆرت: $dateRangeDisplay', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 16)),
                      const SizedBox(width: 10),
                      const Icon(Icons.edit, size: 16, color: Colors.indigo),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // تابی شاشەکان
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: const TabBar(
                  labelColor: Colors.indigo, unselectedLabelColor: Colors.grey, indicatorColor: Colors.indigo, indicatorWeight: 4,
                  tabs: [Tab(icon: Icon(Icons.pie_chart), text: 'گشتی'), Tab(icon: Icon(Icons.restaurant), text: 'خوارنگەهەکان'), Tab(icon: Icon(Icons.motorcycle), text: 'شۆفێران')],
                ),
              ),
              const SizedBox(height: 15),

              // جەستەی ڕاپۆرتەکە
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('Orders').where('status', isEqualTo: 'completed').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                    // فلتەرکردنی داتاکان بەپێی کاتە دیاریکراوەکە
                    List<QueryDocumentSnapshot> filteredOrders = snapshot.data!.docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      if (data['created_at'] == null) return false;
                      DateTime orderDate = (data['created_at'] as Timestamp).toDate();
                      // پشکنین دەکات بزانێت لەناو کاتەکەدایە یان نا
                      return orderDate.isAfter(_startDate.subtract(const Duration(days: 1))) && orderDate.isBefore(_endDate.add(const Duration(days: 1)));
                    }).toList();

                    // ئامادەکردنی داتاکان
                    double totalRevenue = 0;
                    Map<String, Map<String, dynamic>> restStats = {};
                    Map<String, Map<String, dynamic>> driverStats = {};

                    for (var doc in filteredOrders) {
                      var data = doc.data() as Map<String, dynamic>;
                      double price = (data['total_price'] ?? 0).toDouble();
                      String restName = data['restaurant_name'] ?? 'بێ ناو';
                      String driverName = data['driver_name'] ?? 'بێ شۆفێر';

                      totalRevenue += price;

                      // حیسابی خوارنگەهـ
                      if (!restStats.containsKey(restName)) restStats[restName] = {'count': 0, 'total': 0.0};
                      restStats[restName]!['count'] += 1;
                      restStats[restName]!['total'] += price;

                      // حیسابی شۆفێر
                      if (!driverStats.containsKey(driverName)) driverStats[driverName] = {'count': 0, 'total': 0.0};
                      driverStats[driverName]!['count'] += 1;
                      driverStats[driverName]!['total'] += price;
                    }

                    // دیزاینی PDF بۆ دوگمەکە
                    _pdfCallback() => _generateAndDownloadPDF(filteredOrders, totalRevenue, restStats, driverStats);

                    if (filteredOrders.isEmpty) {
                      return const Center(child: Text('هیچ ئۆردەرێکی تەواوبوو لەم بەروارەدا نییە.', style: TextStyle(color: Colors.grey, fontSize: 18)));
                    }

                    return Column(
                      children: [
                        // دوگمەی داگرتن کە بە داتا نوێیەکان کار دەکات
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                            onPressed: _pdfCallback,
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('دابەزاندنی PDF'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        
                        Expanded(
                          child: TabBarView(
                            children: [
                              // تابی 1: گشتی
                              _buildGeneralTab(filteredOrders.length, totalRevenue),
                              // تابی 2: خوارنگەهەکان
                              _buildListTab(restStats, Icons.restaurant, Colors.orange),
                              // تابی 3: شۆفێران
                              _buildListTab(driverStats, Icons.motorcycle, Colors.green),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
              _endDate = DateTime.now();
            });
          },
          icon: const Icon(Icons.refresh),
          label: const Text('گەڕانەوە بۆ ئەم مانگە'),
        ),
      ],
    );
  }

  Widget _buildGeneralTab(int totalOrders, double totalRevenue) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('کۆی گشتی ئۆردەرەکان', totalOrders.toString(), Icons.shopping_bag, Colors.blue)),
            const SizedBox(width: 20),
            Expanded(child: _buildStatCard('کۆی داهات (IQD)', totalRevenue.toInt().toString(), Icons.attach_money, Colors.green)),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[200]!)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('تێکڕای نرخی هەر ئۆردەرێک:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
              Text('${totalOrders > 0 ? (totalRevenue / totalOrders).toInt() : 0} IQD', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildListTab(Map<String, Map<String, dynamic>> statsMap, IconData icon, Color color) {
    var sortedEntries = statsMap.entries.toList()..sort((a, b) => b.value['total'].compareTo(a.value['total']));

    return ListView.builder(
      itemCount: sortedEntries.length,
      itemBuilder: (context, index) {
        var entry = sortedEntries[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)),
            title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: Text('کۆی ئۆردەر: ${entry.value['count']}'),
            trailing: Text('${entry.value['total'].toInt()} IQD', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.3)), boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10)]),
      child: Column(
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}
