// Path: lib/screens/financial_report.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class FinancialReportScreen extends StatefulWidget {
  const FinancialReportScreen({super.key});

  @override
  State<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends State<FinancialReportScreen> {
  final Color primaryBlue = const Color(0xFF0056D2);
  
  // گۆڕاوەکان بۆ هەڵگرتنی داتا
  num _totalCompanyIncome = 0;
  List<int> _weeklyOrders = List.filled(7, 0); // بۆ ٧ رۆژی هەفتە
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFinancialData();
  }

  Future<void> _fetchFinancialData() async {
    try {
      // ١. هێنانی کۆی گشتی قازانجی کۆمپانیا
      var revDoc = await FirebaseFirestore.instance.collection('App_Settings').doc('Revenue').get();
      if (revDoc.exists && revDoc.data() != null) {
        _totalCompanyIncome = revDoc.data()!['total_income'] ?? 0;
      }

      // ٢. هێنانی ئۆردەرەکانی ٧ رۆژی رابردوو بۆ دروستکردنی گرافیک
      DateTime sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      var ordersQuery = await FirebaseFirestore.instance
          .collection('Orders')
          .where('status', isEqualTo: 'completed')
          .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
          .get();

      List<int> tempWeeklyOrders = List.filled(7, 0);
      int todayIndex = DateTime.now().weekday; // 1 (Mon) to 7 (Sun)

      for (var doc in ordersQuery.docs) {
        Timestamp ts = doc['created_at'];
        DateTime date = ts.toDate();
        int dayDiff = DateTime.now().difference(date).inDays;
        
        if (dayDiff >= 0 && dayDiff < 7) {
          // جێگیرکردنی ئۆردەرەکە لە رۆژەکەی خۆیدا لە گرافیکەکە
          int index = 6 - dayDiff; 
          tempWeeklyOrders[index]++;
        }
      }

      setState(() {
        _weeklyOrders = tempWeeklyOrders;
        _isLoading = false;
      });

    } catch (e) {
      debugPrint("Error fetching finance: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 15.0 : 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('راپۆرتی دارایی و ئامارەکان', style: TextStyle(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E2C))),
          const SizedBox(height: 20),

          // کارتی قازانجی کۆمپانیا (VIP)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0056D2), Color(0xFF003D99)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 10))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.account_balance, color: Colors.white, size: 30),
                    SizedBox(width: 10),
                    Text('کۆی قازانجی پوختی کۆمپانیا', style: TextStyle(color: Colors.white70, fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  '$_totalCompanyIncome IQD',
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // گرافیکی ئۆردەرەکان
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ئاماری گەیاندنەکانی ٧ رۆژی رابردوو', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  const SizedBox(height: 30),
                  
                  _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      height: 300,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (_weeklyOrders.reduce((a, b) => a > b ? a : b) + 5).toDouble(), // بەرزترین ستوون دیاری دەکات
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (double value, TitleMeta meta) {
                                  // دروستکردنی ناوی رۆژەکان لە خوارەوەی گرافیکەکە
                                  const style = TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12);
                                  Widget text;
                                  switch (value.toInt()) {
                                    case 0: text = const Text('٦ رۆژ پێش', style: style); break;
                                    case 1: text = const Text('٥ رۆژ پێش', style: style); break;
                                    case 2: text = const Text('٤ رۆژ پێش', style: style); break;
                                    case 3: text = const Text('٣ رۆژ پێش', style: style); break;
                                    case 4: text = const Text('پێڕێ', style: style); break;
                                    case 5: text = const Text('دوێنێ', style: style); break;
                                    case 6: text = const Text('ئەمڕۆ', style: style); break;
                                    default: text = const Text(''); break;
                                  }
                                  return SideTitleWidget(axisSide: meta.axisSide, child: text);
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: const FlGridData(show: true, drawVerticalLine: false),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(7, (index) {
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: _weeklyOrders[index].toDouble(),
                                  color: index == 6 ? Colors.green : Colors.blueAccent, // رۆژی ئەمڕۆ بە سەوز دەردەکەوێت
                                  width: 20,
                                  borderRadius: BorderRadius.circular(5),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: (_weeklyOrders.reduce((a, b) => a > b ? a : b) + 5).toDouble(),
                                    color: Colors.grey[200],
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
