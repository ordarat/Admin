// Path: lib/screens/manage_users.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart'; // بۆ هەڵبژاردنی وێنەی ناسنامە
import 'dart:io';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  String _selectedRole = 'شۆفێر'; 
  bool _isLoading = false;

  // گۆڕاوەکان بۆ وێنەکان (بۆ قۆناغی داهاتوو کە دەیخەینە سەر فایەربەیس ستۆرج)
  XFile? _idCardImage;
  XFile? _licenseImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isIdCard) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isIdCard) _idCardImage = image;
        else _licenseImage = image;
      });
    }
  }

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
        'plain_password': password, // پاسوۆردەکە لێرە هەڵدەگرین بۆ ئەوەی ئەدمین بیبینێت
        'is_active': true,           
        'wallet_balance': 0,         
        'completed_orders': 0,       
        'role': _selectedRole == 'شۆفێر' ? 'driver' : 'restaurant',
        'created_at': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection(_selectedRole == 'شۆفێر' ? 'Drivers' : 'Restaurants').doc(newUid).set(userData);
      await tempApp.delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هەژمارەکە دروست کرا!'), backgroundColor: Colors.green));
      _nameController.clear(); _phoneController.clear(); _passwordController.clear();
      setState(() { _idCardImage = null; _licenseImage = null; });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('کێشەیەک روویدا: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- شاشەی VIP ی پڕۆفایلی بەکارهێنەر ---
  void _showUserProfile(String uid, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(25),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // بەشی سەرەوە (لۆگۆ و ناو)
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(radius: 50, backgroundColor: _selectedRole == 'شۆفێر' ? Colors.blue[100] : Colors.orange[100], child: Icon(_selectedRole == 'شۆفێر' ? Icons.motorcycle : Icons.restaurant, size: 50, color: _selectedRole == 'شۆفێر' ? Colors.blue : Colors.orange)),
                        const SizedBox(height: 15),
                        Text(data['name'] ?? 'بێ ناو', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text(data['phone'] ?? '', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const Divider(height: 40, thickness: 2),

                  // بەشی ئامارەکان (باڵانس و ئۆردەر)
                  const Text('ئامارەکان', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: _buildStatBox('باڵانس', '${data['wallet_balance'] ?? 0} IQD', Icons.account_balance_wallet, Colors.green)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildStatBox('ئۆردەرەکان', '${data['completed_orders'] ?? 0}', Icons.shopping_bag, Colors.blue)),
                    ],
                  ),
                  const Divider(height: 40),

                  // بەشی زانیاری تایبەت و پاسوۆرد
                  const Text('زانیارییە تایبەتەکان', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  const SizedBox(height: 15),
                  ListTile(
                    tileColor: Colors.grey[100], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    leading: const Icon(Icons.lock, color: Colors.redAccent),
                    title: const Text('وشەی نهێنی هەژمار', style: TextStyle(color: Colors.grey)),
                    subtitle: Text(data['plain_password'] ?? 'نەزانراوە', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      tooltip: 'گۆڕینی پاسوۆرد لێرە (تەنها بۆ داتابەیس)',
                      onPressed: () {
                        // لێرەدا دەتوانیت پاسوۆردەکە بگۆڕیت (بۆ قۆناغی داهاتوو)
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('گۆڕینی پاسوۆرد لە داتابەیس بەم زووانە کارا دەبێت')));
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // بەشی دۆکیومێنتەکان (بۆ شۆفێر)
                  if (_selectedRole == 'شۆفێر') ...[
                    const Text('بەڵگەنامە فەرمییەکان', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(child: _buildDocumentBox('وێنەی ناسنامە', Icons.badge)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildDocumentBox('مۆڵەتی شۆفێری', Icons.drive_eta)),
                      ],
                    ),
                    const Divider(height: 40),
                  ],

                  // دوگمەی راگرتن یان چالاککردن
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: data['is_active'] == true ? Colors.red : Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection(_selectedRole == 'شۆفێر' ? 'Drivers' : 'Restaurants').doc(uid).update({'is_active': !(data['is_active'] ?? true)});
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
                      icon: Icon(data['is_active'] == true ? Icons.block : Icons.check_circle),
                      label: Text(data['is_active'] == true ? 'راگرتنی هەژمار (باندکردن)' : 'چالاککردنەوەی هەژمار', style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatBox(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30), const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDocumentBox(String title, IconData icon) {
    return Container(
      height: 100,
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[400]!, style: BorderStyle.solid)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: Colors.grey[600]), const SizedBox(height: 5),
          Text(title, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
        ],
      ),
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
                    items: ['شۆفێر', 'خوارنگەهـ'].map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
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
                  
                  // بەشی دۆکیومێنت بۆ شۆفێر لە کاتی دروستکردن
                  if (_selectedRole == 'شۆفێر') ...[
                    const SizedBox(height: 20),
                    const Text('وێنەی دۆکیومێنتەکان (بۆ قۆناغی داهاتوو سەیڤ دەکرێت)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: OutlinedButton.icon(onPressed: () => _pickImage(true), icon: const Icon(Icons.badge), label: Text(_idCardImage == null ? 'ناسنامە' : 'وێنەکە دانرا'))),
                        const SizedBox(width: 10),
                        Expanded(child: OutlinedButton.icon(onPressed: () => _pickImage(false), icon: const Icon(Icons.drive_eta), label: Text(_licenseImage == null ? 'مۆڵەت' : 'وێنەکە دانرا'))),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),
                  SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: _isLoading ? null : _createNewAccount, child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('دروستکردنی هەژمار', style: TextStyle(fontSize: 18)))),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // لیستی بەکارهێنەران
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('لیستی بەکارهێنەران (کلیک بکە بۆ بینینی پڕۆفایلی تەواو)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
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
                            onTap: () => _showUserProfile(uid, data),
                            leading: CircleAvatar(backgroundColor: data['is_active'] == true ? (_selectedRole == 'شۆفێر' ? Colors.blue[100] : Colors.orange[100]) : Colors.red[100], child: Icon(_selectedRole == 'شۆفێر' ? Icons.motorcycle : Icons.restaurant, color: data['is_active'] == true ? (_selectedRole == 'شۆفێر' ? Colors.blue : Colors.orange) : Colors.red)),
                            title: Text(data['name'] ?? 'بێ ناو', style: TextStyle(fontWeight: FontWeight.bold, decoration: data['is_active'] == true ? TextDecoration.none : TextDecoration.lineThrough)),
                            subtitle: Text('${data['phone']} | باڵانس: ${data['wallet_balance'] ?? 0} IQD'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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
