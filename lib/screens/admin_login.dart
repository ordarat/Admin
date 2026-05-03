// Path: lib/screens/admin_login.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_layout.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePass = true;
  
  final Color primaryBlue = const Color(0xFF0056D2);

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: _emailCtrl.text.trim(), password: _passCtrl.text.trim());
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainLayout()));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ئیمەیڵ یان پاسۆرد هەڵەیە!'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logo.png', height: 100),
                const SizedBox(height: 20),
                Text('پەنەڵی بەڕێوەبەرایەتی', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryBlue)),
                const SizedBox(height: 10),
                const Text('تکایە زانیارییەکانت بنووسە بۆ چوونەژوورەوە', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),
                
                TextField(
                  controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: 'ئیمەیڵ', prefixIcon: Icon(Icons.email, color: primaryBlue), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.grey[50]),
                ),
                const SizedBox(height: 15),
                
                TextField(
                  controller: _passCtrl, obscureText: _obscurePass,
                  decoration: InputDecoration(
                    labelText: 'وشەی نهێنی', prefixIcon: Icon(Icons.lock, color: primaryBlue), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.grey[50],
                    suffixIcon: IconButton(icon: Icon(_obscurePass ? Icons.visibility : Icons.visibility_off, color: Colors.grey), onPressed: () => setState(() => _obscurePass = !_obscurePass)),
                  ),
                ),
                const SizedBox(height: 30),
                
                SizedBox(
                  width: double.infinity, height: 50,
                  child: _isLoading 
                    ? Center(child: CircularProgressIndicator(color: primaryBlue))
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 5),
                        onPressed: _login,
                        child: const Text('چوونەژوورەوە', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
