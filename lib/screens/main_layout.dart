// Path: lib/screens/main_layout.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dashboard_overview.dart';
import 'live_orders_board.dart';
import 'manage_users.dart';
import 'live_tracking.dart';
import 'manage_shifts.dart'; 
import 'financial_report.dart';
import 'settings_screen.dart';
import 'employees_screen.dart';
import 'admin_login.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isAdmin = false;
  Map<String, dynamic> _permissions = {};

  final List<Widget> _activeScreens = [];
  final List<NavigationRailDestination> _navRailItems = [];
  final List<BottomNavigationBarItem> _bottomNavItems = [];

  @override
  void initState() {
    super.initState();
    _loadUserPermissions();
  }

  // مێشکی سیستەمەکە کە کێشەکەی تۆی چارەسەر کرد
  Future<void> _loadUserPermissions() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String uid = user.uid;
      String email = user.email ?? 'admin@ordarat.com';

      // پشکنین دەکات بزانێت ئەم کەسە سەڵاحییەتی هەیە لە داتابەیس؟
      var doc = await FirebaseFirestore.instance.collection('Admins').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        // ئەگەر پێشتر هەبوو، سەڵاحییەتەکانی بخوێنەوە
        var data = doc.data()!;
        _isAdmin = data['role'] == 'admin';
        _permissions = data['permissions'] ?? {};
      } else {
        // ئەگەر نەبوو (واتە ئەمە تۆیت کە خاوەنی ئەپەکەیت)، یەکسەر دەتکات بە بەڕێوەبەری سەرەکی!
        await FirebaseFirestore.instance.collection('Admins').doc(uid).set({
          'name': 'بەڕێوەبەری سەرەکی',
          'email': email,
          'role': 'admin', // سەڵاحییەتی رەها
          'is_active': true,
          'created_at': FieldValue.serverTimestamp(),
        });
        _isAdmin = true;
        _permissions = {};
      }

      _buildDynamicNavigation();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading permissions: $e');
      await FirebaseAuth.instance.signOut();
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminLoginScreen()));
    }
  }

  void _buildDynamicNavigation() {
    _activeScreens.clear();
    _navRailItems.clear();
    _bottomNavItems.clear();

    void addScreen(String id, String title, IconData icon, Widget screen) {
      if (_isAdmin || _permissions[id] == true) {
        _activeScreens.add(screen);
        _navRailItems.add(NavigationRailDestination(icon: Icon(icon), label: Text(title)));
        _bottomNavItems.add(BottomNavigationBarItem(icon: Icon(icon), label: title));
      }
    }

    addScreen('dashboard', 'داشبۆرد', Icons.dashboard, const DashboardOverviewScreen());
    addScreen('orders', 'ئۆردەرەکان', Icons.view_kanban, const LiveOrdersBoardScreen());
    addScreen('users', 'بەکارهێنەران', Icons.people, const ManageUsersScreen());
    addScreen('map', 'نەخشە', Icons.map, const LiveTrackingScreen());
    addScreen('shifts', 'شەفتەکان', Icons.access_time_filled, const ManageShiftsScreen());

    if (_isAdmin) {
      _activeScreens.add(const EmployeesScreen());
      _navRailItems.add(const NavigationRailDestination(icon: Icon(Icons.badge), label: Text('کارمەندان')));
      _bottomNavItems.add(const BottomNavigationBarItem(icon: Icon(Icons.badge), label: 'کارمەندان'));
    }

    addScreen('finance', 'دارایی', Icons.bar_chart, const FinancialReportScreen());
    addScreen('settings', 'رێکخستن', Icons.settings, const SettingsScreen());

    if (_activeScreens.isEmpty) {
      _activeScreens.add(const Center(child: Text('هیچ سەڵاحییەتێکت نییە', style: TextStyle(fontSize: 18, color: Colors.red))));
      _navRailItems.add(const NavigationRailDestination(icon: Icon(Icons.block), label: Text('داخراوە')));
      _bottomNavItems.add(const BottomNavigationBarItem(icon: Icon(Icons.block), label: 'داخراوە'));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: Color(0xFFF4F7FC), body: Center(child: CircularProgressIndicator(color: Colors.indigo)));
    }

    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2C),
        foregroundColor: Colors.white,
        title: const Text('ئۆردەرات - پەنەڵی سەرەکی', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'چوونەدەرەوە',
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminLoginScreen()));
            },
          )
        ],
      ),
      body: Row(
        children: [
          if (!isMobile)
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (int index) => setState(() => _currentIndex = index),
              labelType: NavigationRailLabelType.all,
              backgroundColor: const Color(0xFF1E1E2C),
              unselectedIconTheme: const IconThemeData(color: Colors.white54),
              selectedIconTheme: const IconThemeData(color: Colors.blueAccent),
              unselectedLabelTextStyle: const TextStyle(color: Colors.white54),
              selectedLabelTextStyle: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
              destinations: _navRailItems,
            ),
            
          if (!isMobile) const VerticalDivider(thickness: 1, width: 1, color: Colors.grey),
          
          Expanded(
            child: _activeScreens.isNotEmpty && _currentIndex < _activeScreens.length 
              ? _activeScreens[_currentIndex] 
              : const Center(child: Text('شاشەکە بەردەست نییە')), 
          ),
        ],
      ),
      
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              selectedItemColor: Colors.blueAccent,
              unselectedItemColor: Colors.grey,
              backgroundColor: Colors.white,
              type: BottomNavigationBarType.fixed, 
              elevation: 10,
              items: _bottomNavItems,
            )
          : null,
    );
  }
}
