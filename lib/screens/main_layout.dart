// Path: lib/screens/main_layout.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// هێنانی هەموو شاشەکانی ناو فۆڵدەرەکەت
import 'dashboard_overview.dart';
import 'manage_users.dart';
import 'live_tracking.dart';
import 'financial_report.dart'; // ئەوەتا راپۆرتە داراییەکەمان هێنا
import 'settings_screen.dart';
import 'admin_login.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  // ریزبەندی شاشەکان بەپێی ئەو فایلانەی لە وێنەکەدا هەن
  final List<Widget> _screens = [
    const DashboardOverviewScreen(), // ٠
    const ManageUsersScreen(),       // ١
    const LiveTrackingScreen(),      // ٢
    const FinancialReportScreen(),   // ٣ (بەشە نوێیەکە)
    const SettingsScreen(),          // ٤
  ];

  @override
  Widget build(BuildContext context) {
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
          // ئەگەر شاشەکە گەورە بوو (کۆمپیوتەر)، ئەوا Sidebar پیشان بدە
          if (!isMobile)
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (int index) {
                setState(() => _currentIndex = index);
              },
              labelType: NavigationRailLabelType.all,
              backgroundColor: const Color(0xFF1E1E2C),
              unselectedIconTheme: const IconThemeData(color: Colors.white54),
              selectedIconTheme: const IconThemeData(color: Colors.blueAccent),
              unselectedLabelTextStyle: const TextStyle(color: Colors.white54),
              selectedLabelTextStyle: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('داشبۆرد')),
                NavigationRailDestination(icon: Icon(Icons.people), label: Text('بەکارهێنەران')),
                NavigationRailDestination(icon: Icon(Icons.map), label: Text('نەخشە')),
                NavigationRailDestination(icon: Icon(Icons.bar_chart), label: Text('دارایی')),
                NavigationRailDestination(icon: Icon(Icons.settings), label: Text('رێکخستن')),
              ],
            ),
            
          if (!isMobile) const VerticalDivider(thickness: 1, width: 1, color: Colors.grey),
          
          // پیشاندانی شاشە هەڵبژێردراوەکە
          Expanded(child: _screens[_currentIndex]),
        ],
      ),
      
      // ئەگەر شاشەکە بچووک بوو (مۆبایل)، ئەوا BottomNavigationBar پیشان بدە
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              selectedItemColor: Colors.blueAccent,
              unselectedItemColor: Colors.grey,
              backgroundColor: Colors.white,
              type: BottomNavigationBarType.fixed, // ئەمە زۆر گرنگە بۆ ئەوەی ٥ دوگمە جێگەی ببێتەوە
              elevation: 10,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'داشبۆرد'),
                BottomNavigationBarItem(icon: Icon(Icons.people), label: 'بەکارهێنەران'),
                BottomNavigationBarItem(icon: Icon(Icons.map), label: 'نەخشە'),
                BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'دارایی'),
                BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'رێکخستن'),
              ],
            )
          : null,
    );
  }
}
