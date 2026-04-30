// Path: lib/screens/manage_users.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  
  String _selectedRole = 'خوارنگەهـ'; 
  bool _isLoading = false;

  Future<void> _createNewAccount() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تکایە خانە سەرەکییەکان پڕبکەرەوە!'), backgroundColor: Colors.red));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      String phoneInput = _phoneController.text.trim();
      String finalPhone = phoneInput.startsWith('0') ? phoneInput : '0$phoneInput';
      String finalEmail = "$finalPhone@company.com";
      String password = _passwordController.text.trim();

      // فایەربەیسی کاتی بۆ ئەوەی ئەدمین لۆگئاوت نەبێت
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'TempApp_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      UserCredential userCred = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(email: finalEmail, password: password);

      String newUid = userCred.user!.uid;

      if (_selectedRole == 'شۆفێر') {
        await FirebaseFirestore.instance.collection('Drivers').doc(newUid).set({
          'name': _nameController.text.trim(),
          'phone': finalPhone,
          'profile_image': _imageController.text.trim(),
          'is_active': true,           
          'wallet_balance': 0,         
          'completed_orders': 0,       
          'role': 'driver',
          'created_at': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseFirestore.instance.collection('Restaurants').doc(newUid).set({
          'name': _nameController.text.trim(),
          'phone': finalPhone,
          'profile_image': _imageController.text.trim(),
          'is_active': true,           
          'wallet_balance': 0,
          'role': 'restaurant',
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      await tempApp.delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هەژمارەکە بە سەرکەوتوویی دروست کرا!'), backgroundColor: Colors.green));
      
      _nameController.clear();
      _phoneController.clear();
      _passwordController.clear();
      _imageController.clear();

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ئەم ژمارە مۆبایلە پێشتر تۆمار کراوە!'), backgroundColor: Colors.orange));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('هەڵە: ${e.message}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('کێشەیەک روویدا: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------- بەشی سەرەوە: فۆڕمی دروستکردن ----------------
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('دروستکردنی هەژماری نوێ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2C))),
                  const SizedBox(height: 20),
                  
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    items: ['خوارنگەهـ', 'شۆفێر'].map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                    onChanged: (val) => setState(() => _selectedRole = val!),
                  ),
                  const SizedBox(height: 15),
                  
                  TextField(controller: _nameController, decoration: InputDecoration(labelText: 'ناو', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 15),
                  
                  TextField(controller: _phoneController, decoration: InputDecoration(labelText: 'ژمارەی مۆبایل', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), keyboardType: TextInputType.phone),
                  const SizedBox(height: 15),
                  
                  TextField(controller: _passwordController, decoration: InputDecoration(labelText: 'وشەی نهێنی', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 15),
                  
                  TextField(controller: _imageController, decoration: InputDecoration(labelText: 'لینکی وێنەی پڕۆفایل', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), prefixIcon: const Icon(Icons.link))),
                  const SizedBox(height: 20),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: _isLoading ? null : _createNewAccount,
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('تۆمارکردن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // ---------------- بەشی خوارەوە: لیستی چالاکەکان ----------------
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('لیستی چالاکەکان', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2C))),
                  const Divider(height: 30, thickness: 1),
                  
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection(_selectedRole == 'شۆفێر' ? 'Drivers' : 'Restaurants').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      var docs = snapshot.data!.docs;
                      
                      if (docs.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text('هیچ بەکارهێنەرێک نییە', style: TextStyle(color: Colors.grey))));

                      return ListView.builder(
                        shrinkWrap: true, // زۆر گرنگە بۆ ئەوەی لەناو Scroll دا کار بکات
                        physics: const NeverScrollableScrollPhysics(), // بۆ ئەوەی کێشە بۆ Scroll ی سەرەکی دروست نەکات
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var data = docs[index].data() as Map<String, dynamic>;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey[200],
                              backgroundImage: data['profile_image'] != null && data['profile_image'].toString().isNotEmpty ? NetworkImage(data['profile_image']) : null,
                              child: data['profile_image'] == null || data['profile_image'].toString().isEmpty ? Icon(_selectedRole == 'شۆفێر' ? Icons.motorcycle : Icons.restaurant, color: Colors.grey[600]) : null,
                            ),
                            title: Text(data['name'] ?? 'بێ ناو', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(data['phone'] ?? ''),
                            trailing: Icon(data['is_active'] == true ? Icons.check_circle : Icons.cancel, color: data['is_active'] == true ? Colors.green : Colors.red),
                          );
                        },
                      );
                    },
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
