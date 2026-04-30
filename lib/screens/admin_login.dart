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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordHidden = true;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تکایە زانیارییەکان پڕبکەرەوە')));
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      if (!mounted) return;
      // کاتێک سەرکەوتوو بوو، دەچێتە ژوورەوە
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainLayout()));
    } on FirebaseAuthException catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ئیمەیڵ یان وشەی نهێنی هەڵەیە'), backgroundColor: Colors.red));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('هەڵە: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C), // رەنگی باکگراوندی ئەدمین پەنەڵ
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400), // بۆ ئەوەی لە کۆمپیوتەر زۆر گەورە نەبێت
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)]),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(padding: const EdgeInsets.all(15), decoration: const BoxDecoration(color: Colors.deepOrange, shape: BoxShape.circle), child: const Icon(Icons.admin_panel_settings, size: 60, color: Colors.white)),
                const SizedBox(height: 20),
                const Text('چوونەژوورەوەی ئیدارە', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2C))),
                const SizedBox(height: 10),
                const Text('تەنها بۆ بەڕێوەبەرانی سیستەمی ئۆردەرات', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),
                
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'ئیمەیڵی ئەدمین', prefixIcon: const Icon(Icons.email, color: Colors.deepOrange), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                ),
                const SizedBox(height: 20),
                
                TextField(
                  controller: _passwordController,
                  obscureText: _isPasswordHidden,
                  decoration: InputDecoration(
                    labelText: 'وشەی نهێنی', 
                    prefixIcon: const Icon(Icons.lock, color: Colors.deepOrange), 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordHidden ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
                    )
                  ),
                ),
                const SizedBox(height: 30),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('چوونە ژوورەوە', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
