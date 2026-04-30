// Path: lib/screens/main_layout.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_login.dart'; 
import 'dashboard_overview.dart';
import 'manage_users.dart'; 
import 'live_tracking.dart';   // چالاک کرا
import 'settings_screen.dart'; // چالاک کرا

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // هەموو ٤ شاشەکە بە تەواوی ئامادەن
  final List<Widget> _screens = [
    const DashboardOverview(), 
    const ManageUsersScreen(), 
    const LiveTrackingScreen(), 
    const SettingsScreen(),     
  ];

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    Widget sidebarContent = Column(
      children: [
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.deepOrange, shape: BoxShape.circle), child: const Icon(Icons.delivery_dining, color: Colors.white, size: 35)),
            const SizedBox(width: 15),
            const Text('Orderat', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ],
        ),
        const SizedBox(height: 10),
        const Text('Admin Dashboard', style: TextStyle(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 50),
        
        _buildMenuItem(index: 0, title: 'داشبۆرد', icon: Icons.dashboard, isMobile: isMobile),
        _buildMenuItem(index: 1, title: 'بەکارهێنەران', icon: Icons.people, isMobile: isMobile),
        _buildMenuItem(index: 2, title: 'نەخشەی راستەوخۆ', icon: Icons.map, isMobile: isMobile),
        _buildMenuItem(index: 3, title: 'رێکخستنەکان', icon: Icons.settings, isMobile: isMobile),
        
        const Spacer(),
        const Divider(color: Colors.white24),
        
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: const Text('چوونە دەرەوە', style: TextStyle(color: Colors.redAccent, fontSize: 16)),
          onTap: () async {
            if (isMobile) Navigator.pop(context);
            await FirebaseAuth.instance.signOut();
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
              (route) => false,
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );

    return Scaffold(
      appBar: isMobile ? AppBar(title: const Text('ئۆردەرات ئەدمین'), backgroundColor: const Color(0xFF1E1E2C), foregroundColor: Colors.white) : null,
      drawer: isMobile ? Drawer(backgroundColor: const Color(0xFF1E1E2C), child: sidebarContent) : null,
      body: Row(
        children: [
          if (!isMobile) Container(width: 260, color: const Color(0xFF1E1E2C), child: sidebarContent),
          Expanded(child: Container(color: Theme.of(context).scaffoldBackgroundColor, child: _screens[_selectedIndex])),
        ],
      ),
    );
  }

  Widget _buildMenuItem({required int index, required String title, required IconData icon, required bool isMobile}) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _selectedIndex = index);
        if (isMobile) Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(color: isSelected ? Colors.deepOrange.withOpacity(0.15) : Colors.transparent, borderRadius: BorderRadius.circular(10), border: isSelected ? const Border(left: BorderSide(color: Colors.deepOrange, width: 4)) : null),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.deepOrange : Colors.white60, size: 24),
            const SizedBox(width: 20),
            Text(title, style: TextStyle(color: isSelected ? Colors.deepOrange : Colors.white70, fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
