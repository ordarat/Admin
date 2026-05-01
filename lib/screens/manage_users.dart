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
  
  // خانە نوێیەکان بۆ لینکی وێنەکان
  final TextEditingController _idCardUrlController = TextEditingController();
  final TextEditingController _licenseUrlController = TextEditingController();
  
  String _selectedRole = 'شۆفێر'; 
  bool _isLoading = false;

  Future<void> _createNewAccount() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تکایە خانە سەرەکییەکان پڕبکەرەوە')));
      return;
    }
    
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
        'plain_password': password, 
        'is_active': true,           
        'wallet_balance': 0,         
        'completed_orders': 0,       
        'role': _selectedRole == 'شۆفێر' ? 'driver' : 'restaurant',
        'created_at': FieldValue.serverTimestamp(),
      };

      // ئەگەر شۆفێر بوو، لینکەکانیش سەیڤ بکە
      if (_selectedRole == 'شۆفێر') {
        userData['id_card_url'] = _idCardUrlController.text.trim();
        userData['license_url'] = _licenseUrlController.text.trim();
      }

      await FirebaseFirestore.instance.collection(_selectedRole == 'شۆفێر' ? 'Drivers' : 'Restaurants').doc(newUid).set(userData);
      await tempApp.delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هەژمارەکە دروست کرا!'), backgroundColor: Colors.green));
      
      _nameController.clear(); 
      _phoneController.clear(); 
      _passwordController.clear();
      _idCardUrlController.clear();
      _licenseUrlController.clear();

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
            width: 600, // کەمێک فراوانتر بۆ ئەوەی وێنەکان جێیان ببێتەوە
            padding: const EdgeInsets.all(25),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

                  const Text('زانیارییە تایبەتەکان', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  const SizedBox(height: 15),
                  ListTile(
                    tileColor: Colors.grey[100], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    leading: const Icon(Icons.lock, color: Colors.redAccent),
                    title: const Text('وشەی نهێنی هەژمار', style: TextStyle(color: Colors.grey)),
                    subtitle: Text(data['plain_password'] ?? 'نەزانراوە', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                  const SizedBox(height: 20),

                  // بەشی دۆکیومێنتەکان (بینینی وێنەکان لە رێگەی لینکەوە)
                  if (_selectedRole == 'شۆفێر') ...[
                    const Text('بەڵگەنامە فەرمییەکان', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(child: _buildDocumentImage('ناسنامە', data['id_card_url'])),
                        const SizedBox(width: 15),
                        Expanded(child: _buildDocumentImage('مۆڵەت', data['license_url'])),
                      ],
                    ),
                    const Divider(height: 40),
                  ],

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

  // فەنکشنی زیرەک بۆ پیشاندانی وێنە لە رێگەی لینکەوە
  Widget _buildDocumentImage(String title, String? url) {
    bool hasUrl = url != null && url.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 5),
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey[400]!),
          ),
          child: hasUrl 
            ? ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Icon(Icons.broken_image, color: Colors.grey, size: 40), Text('لینکەکە هەڵەیە', style: TextStyle(color: Colors.grey))],
                  ),
                ),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Icon(Icons.image_not_supported, color: Colors.grey, size: 40), Text('وێنە دانەنراوە', style: TextStyle(color: Colors.grey))],
              ),
        ),
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
                  
                  // خانەی لینکەکان تەنها بۆ شۆفێر پیشان دەدات
                  if (_selectedRole == 'شۆفێر') ...[
                    const SizedBox(height: 15),
                    const Text('لینکەکانی دۆکیومێنت (ئارەزوومەندانە)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 10),
                    isMobile 
                    ? Column(children: [
                        TextField(controller: _idCardUrlController, decoration: const InputDecoration(labelText: 'لینکی وێنەی ناسنامە', prefixIcon: Icon(Icons.link), border: OutlineInputBorder())), const SizedBox(height: 10),
                        TextField(controller: _licenseUrlController, decoration: const InputDecoration(labelText: 'لینکی مۆڵەتی شۆفێری', prefixIcon: Icon(Icons.link), border: OutlineInputBorder())),
                      ])
                    : Row(children: [
                        Expanded(child: TextField(controller: _idCardUrlController, decoration: const InputDecoration(labelText: 'لینکی وێنەی ناسنامە', prefixIcon: Icon(Icons.link), border: OutlineInputBorder()))), const SizedBox(width: 10),
                        Expanded(child: TextField(controller: _licenseUrlController, decoration: const InputDecoration(labelText: 'لینکی مۆڵەتی شۆفێری', prefixIcon: Icon(Icons.link), border: OutlineInputBorder()))),
                      ]),
                  ],

                  const SizedBox(height: 20),
                  SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: _isLoading ? null : _createNewAccount, child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('دروستکردنی هەژمار', style: TextStyle(fontSize: 18)))),
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
