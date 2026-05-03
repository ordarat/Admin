// Path: lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_login.dart';
import 'main_layout.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();

    Future.delayed(const Duration(seconds: 3), () {
      User? user = FirebaseAuth.instance.currentUser;
      if (mounted) {
        if (user != null) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainLayout()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminLoginScreen()));
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _animation,
              child: Image.asset('assets/images/logo.png', width: 220),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: Color(0xFF0056D2),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
