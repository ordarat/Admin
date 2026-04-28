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

      // بەکارهێنانی رێگەیەکی سەلامەتتر بۆ بانگکردنی ئەپی دووەم بەبێ پچڕانی هێڵ
      FirebaseApp secondaryApp;
      try {
        secondaryApp = Firebase.app('SecondaryApp');
      } catch (e) {
        secondaryApp = await Firebase.initializeApp(
          name: 'SecondaryApp',
          options: Firebase.app().options,
        );
      }
      
      UserCredential userCredential = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(email: fakeEmail, password: password);
          
      await FirebaseFirestore.instance.collection(_userType).doc(userCredential.user!.uid).set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'password': password, 
        'is_active': true,
        'wallet_balance': 0,
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
                    TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'وشەی نهێنی (بۆ پێدانی بە کەسەکە)', border: OutlineInputBorder())),
                    const SizedBox(height: 20),
                    _isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _createUser,
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
                    child: Text('لیستی تۆمارکراوەکان', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                            return ListTile(
                              leading: Icon(_userType == 'Drivers' ? Icons.motorcycle : Icons.restaurant),
                              title: Text(userData['name'] ?? 'بێ ناو'),
                              subtitle: Text(userData['phone'] ?? ''),
                              trailing: Switch(
                                value: userData['is_active'] ?? true,
                                onChanged: (bool value) {
                                  FirebaseFirestore.instance.collection(_userType).doc(users[index].id).update({'is_active': value});
                                },
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
