// Path: lib/screens/manage_users.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _userType = 'Drivers'; 
  bool _isLoading = false;

  Future<void> _createUser() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _passwordController.text.isEmpty) return;

    setState(() { _isLoading = true; });

    try {
      String fakeEmail = "${_phoneController.text.trim()}@company.com";
      String password = _passwordController.text.trim();

      FirebaseApp secondaryApp;
      try {
        secondaryApp = Firebase.app('SecondaryApp');
      } catch (e) {
        secondaryApp = await Firebase.initializeApp(name: 'SecondaryApp', options: Firebase.app().options);
      }
      
      UserCredential userCredential = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(email: fakeEmail, password: password);
          
      // زانیارییە نوێیەکانمان بۆ داتابەیسەکە زیاد کرد
      await FirebaseFirestore.instance.collection(_userType).doc(userCredential.user!.uid).set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'password': password, 
        'is_active': true,
        'wallet_balance': 0, // پارەی جزدان
        'completed_orders': 0, // تەنها بۆ شۆفێر پێویستە بەڵام ئاساییە هەبێت
        'vehicle_type': 'ماتۆڕسکیل', // دیفاڵت
        'created_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('بە سەرکەوتوویی تۆمار کرا!'), backgroundColor: Colors.green));
      _nameController.clear();
      _phoneController.clear();
      _passwordController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('هەڵە: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  // فەنکشنی پاکتاوکردنی حیسابات (پێدانی پارە و سفرکردنەوەی جزدان)
  void _clearWalletBalance(String userId, String currentBalance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('پاکتاوکردنی حیسابات'),
        content: Text('ئایا دڵنیایت کە بڕی ($currentBalance IQD) دەدەیت بەم کەسە و جزدانەکەی سفر دەکەیتەوە؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('نەخێر')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              FirebaseFirestore.instance.collection(_userType).doc(userId).update({'wallet_balance': 0});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('باڵانس سفر کرایەوە')));
            },
            child: const Text('بەڵێ، پارەکەم پێدا', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('دروستکردنی هەژماری نوێ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _userType,
                      items: const [
                        DropdownMenuItem(value: 'Drivers', child: Text('شۆفێر')),
                        DropdownMenuItem(value: 'Restaurants', child: Text('خوارنگەهـ')),
                      ],
                      onChanged: (val) => setState(() => _userType = val!),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 15),
                    TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'ناو', border: OutlineInputBorder())),
                    const SizedBox(height: 15),
                    TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'ژمارەی مۆبایل', border: OutlineInputBorder())),
                    const SizedBox(height: 15),
                    TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'وشەی نهێنی', border: OutlineInputBorder())),
                    const SizedBox(height: 20),
                    _isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _createUser,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                          child: const Padding(padding: EdgeInsets.all(12.0), child: Text('تۆمارکردن', style: TextStyle(fontSize: 18))),
                        ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          
          Expanded(
            flex: 2,
            child: Card(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(15.0),
                    child: Text('لیستی تۆمارکراوەکان و حیسابات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection(_userType).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        
                        final users = snapshot.data!.docs;
                        return ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            var userData = users[index].data() as Map<String, dynamic>;
                            String userId = users[index].id;
                            
                            return ListTile(
                              leading: Icon(_userType == 'Drivers' ? Icons.motorcycle : Icons.restaurant, color: Colors.indigo),
                              title: Text(userData['name'] ?? 'بێ ناو', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('مۆبایل: ${userData['phone']} | باڵانس: ${userData['wallet_balance'] ?? 0} IQD'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // دوگمەی نوێ بۆ سفرکردنەوەی باڵانس (پێدانی پارە)
                                  IconButton(
                                    tooltip: 'پاکتاوکردنی پارە',
                                    icon: const Icon(Icons.payments, color: Colors.green),
                                    onPressed: () => _clearWalletBalance(userId, '${userData['wallet_balance'] ?? 0}'),
                                  ),
                                  const SizedBox(width: 10),
                                  Switch(
                                    activeColor: Colors.indigo,
                                    value: userData['is_active'] ?? true,
                                    onChanged: (bool value) {
                                      FirebaseFirestore.instance.collection(_userType).doc(userId).update({'is_active': value});
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
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
