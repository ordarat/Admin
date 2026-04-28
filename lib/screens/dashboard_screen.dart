// Path: lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_login.dart';
import 'manage_users.dart'; // فایلی داهاتوو

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // ئەو شاشانەی کە ئەدمین دەیانبینێت
  final List<Widget> _pages = [
    const Center(child: Text('ئامارە گشتییەکان لێرە دەردەکەون (ژمارەی ئۆردەر، قازانج...)', style: TextStyle(fontSize: 24))),
    const ManageUsersScreen(), // شاشەی کۆنترۆڵکردنی شۆفێر و خوارنگەهـ
    const Center(child: Text('شاشەی کۆنترۆڵکردنی ئۆردەرەکان لێرە دەبێت')),
    const Center(child: Text('شاشەی حیسابات و پاکتاوکردن لێرە دەبێت')),
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
        title: const Text('Ordarat - Admin Control Panel', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _logout),
        ],
      ),
      body: Row(
        children: [
          // لیستی لاتەنیشت بۆ وێب
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() { _selectedIndex = index; });
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.white,
            elevation: 5,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('داشبۆرد')),
              NavigationRailDestination(icon: Icon(Icons.people), label: Text('بەکارهێنەران')),
              NavigationRailDestination(icon: Icon(Icons.delivery_dining), label: Text('ئۆردەرەکان')),
              NavigationRailDestination(icon: Icon(Icons.account_balance_wallet), label: Text('دارایی')),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // پیشاندانی شاشەی هەڵبژێردراو
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}
