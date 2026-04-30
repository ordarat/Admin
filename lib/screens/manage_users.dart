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
  
  String _selectedRole = 'خوارنگەهـ'; 
  bool _isLoading = false;

  Future<void> _createNewAccount() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _passwordController.text.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      String phoneInput = _phoneController.text.trim();
      String finalPhone = phoneInput.startsWith('0') ? phoneInput : '0$phoneInput';
      String finalEmail = "$finalPhone@company.com";
      String password = _passwordController.text.trim();

      FirebaseApp tempApp = await Firebase.initializeApp(name: 'TempApp_${DateTime.now().millisecondsSinceEpoch}', options: Firebase.app().options);
      UserCredential userCred = await FirebaseAuth.instanceFor(app: tempApp).createUserWithEmailAndPassword(email: finalEmail, password: password);
      String newUid = userCred.user!.uid;

      Map<String, dynamic> userData = {
        'name': _nameController.text.trim(),
        'phone': finalPhone,
        'is_active': true,           
        'wallet_balance': 0,         
        'completed_orders': 0,       
        'role': _selectedRole == 'شۆفێر' ? 'driver' : 'restaurant',
        'created_at': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection(_selectedRole == 'شۆفێر' ? 'Drivers' : 'Restaurants').doc(newUid).set(userData);
      await tempApp.delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('بە سەرکەوتوویی دروست کرا!'), backgroundColor: Colors.green));
      _nameController.clear(); _phoneController.clear(); _passwordController.clear();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('کێشەیەک روویدا: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // فەنکشنی پیشاندانی پڕۆفایلی بەکارهێنەر (باڵانس و داتا)
  void _showUserProfile(String uid, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(20),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 40, backgroundColor: Colors.indigo, child: Icon(_selectedRole == 'شۆفێر' ? Icons.motorcycle : Icons.restaurant, size: 40, color: Colors.white)),
                const SizedBox(height: 15),
                Text(data['name'] ?? 'بێ ناو', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(data['phone'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 16)),
                const Divider(height: 30),
                
                // داتای دارایی و ئامارەکان
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildProfileStat('باڵانس', '${data['wallet_balance'] ?? 0} IQD', Icons.account_balance_wallet, Colors.green),
                    _buildProfileStat('ئۆردەرەکان', '${data['completed_orders'] ?? 0}', Icons.shopping_bag, Colors.blue),
                  ],
                ),
                const SizedBox(height: 20),
                
                // گۆڕینی حاڵەتی ئەکاونت (چالاک / راگیراو)
                ListTile(
                  tileColor: data['is_active'] == true ? Colors.red[50] : Colors.green[50],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  leading: Icon(data['is_active'] == true ? Icons.block : Icons.check_circle, color: data['is_active'] == true ? Colors.red : Colors.green),
                  title: Text(data['is_active'] == true ? 'راگرتنی هەژمار (باندکردن)' : 'چالاککردنەوەی هەژمار', style: TextStyle(color: data['is_active'] == true ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                  onTap: () async {
                    Navigator.pop(context);
                    await FirebaseFirestore.instance.collection(_selectedRole == 'شۆفێر' ? 'Drivers' : 'Restaurants').doc(uid).update({'is_active': !(data['is_active'] ?? true)});
                  },
                ),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('داخستن', style: TextStyle(color: Colors.grey)))],
        );
      },
    );
  }

  Widget _buildProfileStat(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 15.0 : 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('بەڕێوەبردنی بەکارهێنەران', style: TextStyle(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E2C))),
          const SizedBox(height: 20),
          
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), labelText: 'جۆری هەژمار'),
                    items: ['خوارنگەهـ', 'شۆفێر'].map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                    onChanged: (val) => setState(() => _selectedRole = val!),
                  ),
                  const SizedBox(height: 15),
                  isMobile 
                  ? Column(children: [
                      TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'ناو', border: OutlineInputBorder())), const SizedBox(height: 10),
                      TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'مۆبایل', border: OutlineInputBorder())), const SizedBox(height: 10),
                      TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'وشەی نهێنی', border: OutlineInputBorder())),
                    ])
                  : Row(children: [
                      Expanded(child: TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'ناو', border: OutlineInputBorder()))), const SizedBox(width: 10),
                      Expanded(child: TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'مۆبایل', border: OutlineInputBorder()))), const SizedBox(width: 10),
                      Expanded(child: TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'وشەی نهێنی', border: OutlineInputBorder()))),
                    ]),
                  const SizedBox(height: 20),
                  SizedBox(width: double.infinity, height: 45, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white), onPressed: _isLoading ? null : _createNewAccount, child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('دروستکردن', style: TextStyle(fontSize: 16)))),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('لیستی بەکارهێنەران (کلیک بکە بۆ بینینی پڕۆفایل)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  const Divider(),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection(_selectedRole == 'شۆفێر' ? 'Drivers' : 'Restaurants').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      var docs = snapshot.data!.docs;
                      if (docs.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text('هیچ بەکارهێنەرێک نییە')));

                      return ListView.builder(
                        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var data = docs[index].data() as Map<String, dynamic>;
                          String uid = docs[index].id;
                          return ListTile(
                            onTap: () => _showUserProfile(uid, data), // کاتێک کلیک دەکات پڕۆفایل دەکرێتەوە
                            leading: CircleAvatar(backgroundColor: data['is_active'] == true ? Colors.indigo[100] : Colors.red[100], child: Icon(_selectedRole == 'شۆفێر' ? Icons.motorcycle : Icons.restaurant, color: data['is_active'] == true ? Colors.indigo : Colors.red)),
                            title: Text(data['name'] ?? 'بێ ناو', style: TextStyle(fontWeight: FontWeight.bold, decoration: data['is_active'] == true ? TextDecoration.none : TextDecoration.lineThrough)),
                            subtitle: Text('${data['phone']} | باڵانس: ${data['wallet_balance'] ?? 0} IQD', style: const TextStyle(color: Colors.green)),
                            trailing: const Icon(Icons.remove_red_eye, color: Colors.grey),
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
