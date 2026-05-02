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
  String _searchQuery = '';
  bool _isLoading = false;

  // فەنکشنی کردنەوەی پەنجەرەی دروستکردنی هەژمار
  void _showAddUserDialog(String roleType) {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController phoneCtrl = TextEditingController();
    final TextEditingController passCtrl = TextEditingController();
    final TextEditingController idUrlCtrl = TextEditingController();
    final TextEditingController licenseUrlCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(roleType == 'Drivers' ? 'زیادکردنی شۆفێری نوێ' : 'زیادکردنی خوارنگەهی نوێ', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ناوی تەواو', prefixIcon: Icon(Icons.person))),
                  const SizedBox(height: 10),
                  TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'ژمارەی مۆبایل (بێ سفر)', prefixIcon: Icon(Icons.phone))),
                  const SizedBox(height: 10),
                  TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'وشەی نهێنی', prefixIcon: Icon(Icons.lock))),
                  
                  if (roleType == 'Drivers') ...[
                    const SizedBox(height: 15),
                    const Divider(),
                    const Text('لینکەکانی دۆکیومێنت (ئارەزوومەندانە)', style: TextStyle(color: Colors.grey)),
                    TextField(controller: idUrlCtrl, decoration: const InputDecoration(labelText: 'لینکی وێنەی ناسنامە', prefixIcon: Icon(Icons.badge))),
                    TextField(controller: licenseUrlCtrl, decoration: const InputDecoration(labelText: 'لینکی مۆڵەتی شۆفێری', prefixIcon: Icon(Icons.drive_eta))),
                  ]
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('پاشگەزبوونەوە', style: TextStyle(color: Colors.red))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () async {
                if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty || passCtrl.text.isEmpty) return;
                Navigator.pop(context); // داخستنی پەنجەرەکە
                await _createNewAccount(roleType, nameCtrl.text, phoneCtrl.text, passCtrl.text, idUrlCtrl.text, licenseUrlCtrl.text);
              },
              child: const Text('دروستکردن'),
            ),
          ],
        );
      },
    );
  }

  // مێشکی دروستکردنی هەژمار
  Future<void> _createNewAccount(String role, String name, String phone, String pass, String idUrl, String licUrl) async {
    setState(() => _isLoading = true);
    try {
      String finalPhone = phone.startsWith('0') ? phone : '0$phone';
      String finalEmail = "$finalPhone@company.com";

      FirebaseApp tempApp = await Firebase.initializeApp(name: 'TempApp_${DateTime.now().millisecondsSinceEpoch}', options: Firebase.app().options);
      UserCredential userCred = await FirebaseAuth.instanceFor(app: tempApp).createUserWithEmailAndPassword(email: finalEmail, password: pass);
      String newUid = userCred.user!.uid;

      Map<String, dynamic> userData = {
        'name': name.trim(),
        'phone': finalPhone,
        'plain_password': pass.trim(),
        'is_active': true,
        'wallet_balance': 0,
        'completed_orders': 0,
        'role': role == 'Drivers' ? 'driver' : 'restaurant',
        'created_at': FieldValue.serverTimestamp(),
      };

      if (role == 'Drivers') {
        userData['id_card_url'] = idUrl.trim();
        userData['license_url'] = licUrl.trim();
        userData['is_online'] = false; // شۆفێری نوێ سەرەتا ئۆفلاینە
      }

      await FirebaseFirestore.instance.collection(role).doc(newUid).set(userData);
      await tempApp.delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هەژمارەکە بە سەرکەوتوویی دروست کرا!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('کێشەیەک روویدا: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // پەنجەرەی پرۆفایلی VIP
  void _showUserProfile(String uid, String collection, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        bool isActive = data['is_active'] ?? true;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(25),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(radius: 50, backgroundColor: collection == 'Drivers' ? Colors.blue[100] : Colors.orange[100], child: Icon(collection == 'Drivers' ? Icons.motorcycle : Icons.restaurant, size: 50, color: collection == 'Drivers' ? Colors.blue : Colors.orange)),
                  const SizedBox(height: 15),
                  Text(data['name'] ?? 'بێ ناو', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(data['phone'] ?? '', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  const Divider(height: 40, thickness: 2),

                  Row(
                    children: [
                      Expanded(child: _buildStatBox('باڵانس', '${data['wallet_balance'] ?? 0} IQD', Icons.account_balance_wallet, Colors.green)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildStatBox('ئۆردەرەکان', '${data['completed_orders'] ?? 0}', Icons.shopping_bag, Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  ListTile(
                    tileColor: Colors.grey[100], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    leading: const Icon(Icons.lock, color: Colors.redAccent),
                    title: const Text('وشەی نهێنی هەژمار', style: TextStyle(color: Colors.grey)),
                    subtitle: Text(data['plain_password'] ?? 'نەزانراوە', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                  const SizedBox(height: 20),

                  if (collection == 'Drivers') ...[
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
                      style: ElevatedButton.styleFrom(backgroundColor: isActive ? Colors.red : Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection(collection).doc(uid).update({'is_active': !isActive});
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
                      icon: Icon(isActive ? Icons.block : Icons.check_circle),
                      label: Text(isActive ? 'راگرتنی هەژمار (باندکردن)' : 'چالاککردنەوەی هەژمار', style: const TextStyle(fontSize: 16)),
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
      child: Column(children: [
        Icon(icon, color: color, size: 30), const SizedBox(height: 10),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ]),
    );
  }

  Widget _buildDocumentImage(String title, String? url) {
    bool hasUrl = url != null && url.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 5),
        Container(
          height: 120, width: double.infinity,
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[400]!)),
          child: hasUrl 
            ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(url, fit: BoxFit.cover, errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, color: Colors.grey)))
            : const Icon(Icons.image_not_supported, color: Colors.grey),
        ),
      ],
    );
  }

  // دروستکردنی لیستی بەکارهێنەران بۆ هەر تابێک بە سیستەمی گەڕانەوە
  Widget _buildUserList(String collection) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).orderBy('created_at', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        // جێبەجێکردنی سیستەمی گەڕان (Search Filter)
        var docs = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String name = (data['name'] ?? '').toString().toLowerCase();
          String phone = (data['phone'] ?? '').toString();
          return name.contains(_searchQuery.toLowerCase()) || phone.contains(_searchQuery);
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 10),
                const Text('هیچ داتایەک نەدۆزرایەوە', style: TextStyle(color: Colors.grey, fontSize: 18)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            String uid = docs[index].id;
            bool isActive = data['is_active'] ?? true;
            bool isOnline = collection == 'Drivers' ? (data['is_online'] ?? false) : false;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                onTap: () => _showUserProfile(uid, collection, data),
                leading: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: isActive ? (collection == 'Drivers' ? Colors.blue[100] : Colors.orange[100]) : Colors.red[100], 
                      child: Icon(collection == 'Drivers' ? Icons.motorcycle : Icons.restaurant, color: isActive ? (collection == 'Drivers' ? Colors.blue : Colors.orange) : Colors.red)
                    ),
                    if (collection == 'Drivers') 
                      CircleAvatar(radius: 8, backgroundColor: Colors.white, child: CircleAvatar(radius: 6, backgroundColor: isOnline ? Colors.green : Colors.grey)),
                  ],
                ),
                title: Text(data['name'] ?? 'بێ ناو', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, decoration: isActive ? TextDecoration.none : TextDecoration.lineThrough, color: isActive ? Colors.black : Colors.red)),
                subtitle: Text('${data['phone']} \nباڵانس: ${data['wallet_balance'] ?? 0} IQD'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // بەشی سەرەوە (گەڕان)
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'گەڕان بۆ ناو یان مۆبایل...',
                      prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                if (_isLoading) const CircularProgressIndicator()
              ],
            ),
          ),
          
          // تابی شۆفێر و خوارنگەهـ
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: Colors.indigo,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.indigo,
              indicatorWeight: 4,
              tabs: [
                Tab(icon: Icon(Icons.motorcycle), text: 'شۆفێران'),
                Tab(icon: Icon(Icons.restaurant), text: 'خوارنگەهەکان'),
              ],
            ),
          ),
          
          // لیستی داتاکان
          Expanded(
            child: TabBarView(
              children: [
                Stack(
                  children: [
                    _buildUserList('Drivers'),
                    Positioned(bottom: 20, right: 20, child: FloatingActionButton.extended(heroTag: 'd', onPressed: () => _showAddUserDialog('Drivers'), icon: const Icon(Icons.add), label: const Text('شۆفێری نوێ'), backgroundColor: Colors.blue)),
                  ],
                ),
                Stack(
                  children: [
                    _buildUserList('Restaurants'),
                    Positioned(bottom: 20, right: 20, child: FloatingActionButton.extended(heroTag: 'r', onPressed: () => _showAddUserDialog('Restaurants'), icon: const Icon(Icons.add), label: const Text('خوارنگەهی نوێ'), backgroundColor: Colors.orange)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
