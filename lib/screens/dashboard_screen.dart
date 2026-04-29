// Path: lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_login.dart';
import 'manage_users.dart';
import 'manage_orders.dart'; // فایلی نوێ
import 'live_tracking.dart'; // فایلی نوێ
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const Center(child: Text('ئامارە گشتییەکان (بە زوویی زیاد دەکرێت)', style: TextStyle(fontSize: 24))),
    const ManageUsersScreen(),
    const ManageOrdersScreen(), // شاشەی چاودێری ئۆردەرەکان
    const LiveTrackingScreen(), // شاشەی ئامادەکراوی نەخشە
    const Center(child: Text('شاشەی حیسابات لێرە دەبێت')),
    const SettingsScreen(),
  ];

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminLoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ordarat - Admin Command Center', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _logout),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.white,
            elevation: 5,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('داشبۆرد')),
              NavigationRailDestination(icon: Icon(Icons.people), label: Text('بەکارهێنەران')),
              NavigationRailDestination(icon: Icon(Icons.receipt_long), label: Text('ئۆردەرەکان')),
              NavigationRailDestination(icon: Icon(Icons.map), label: Text('نەخشە (Live)')), // تابی نوێ
              NavigationRailDestination(icon: Icon(Icons.account_balance_wallet), label: Text('دارایی')),
              NavigationRailDestination(icon: Icon(Icons.settings), label: Text('رێکخستن')),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}
