// Path: lib/screens/manage_users.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  String _searchQuery = '';
  bool _isLoading = false;
  final Color primaryBlue = const Color(0xFF0056D2);

  // --- ناردنی نامەی تایبەت ---
  void _showNotificationDialog(String? token, String userName) {
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ئەم شۆفێرە هێشتا ئەپەکەی نەکردووەتەوە.'), backgroundColor: Colors.orange));
      return;
    }
    final TextEditingController titleCtrl = TextEditingController();
    final TextEditingController bodyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('ناردنی نامە بۆ: $userName', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'سەردێڕ (نموونە: ئاگاداری)', prefixIcon: Icon(Icons.title))),
            const SizedBox(height: 10),
            TextField(controller: bodyCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'ناوەڕۆکی نامە...', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('پاشگەزبوونەوە', style: TextStyle(color: Colors.red))),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            onPressed: () async {
              if (titleCtrl.text.isEmpty || bodyCtrl.text.isEmpty) return;
              Navigator.pop(context);
              await _sendCustomNotification(token, titleCtrl.text, bodyCtrl.text);
            },
            icon: const Icon(Icons.send), label: const Text('ناردن'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendCustomNotification(String token, String title, String body) async {
    const String serverKey = 'سێرڤەر_کلیلەکەت_لێرە_دابنێ'; 
    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'key=$serverKey'},
        body: jsonEncode({'to': token, 'notification': {'title': title, 'body': body, 'sound': 'default'}}),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نامەکە نێردرا!'), backgroundColor: Colors.green));
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // --- دروستکردنی هەژماری نوێ ---
  void _showAddUserDialog(String roleType) {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController phoneCtrl = TextEditingController();
    final TextEditingController passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(roleType == 'Drivers' ? 'شۆفێری نوێ' : 'خوارنگەهی نوێ', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ناوی تەواو', prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 10),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'مۆبایل (بێ سفر)', prefixIcon: Icon(Icons.phone))),
            const SizedBox(height: 10),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'وشەی نهێنی', prefixIcon: Icon(Icons.lock))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('پاشگەزبوونەوە', style: TextStyle(color: Colors.red))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () async {
              if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty || passCtrl.text.isEmpty) return;
              Navigator.pop(context);
              await _createNewAccount(roleType, nameCtrl.text, phoneCtrl.text, passCtrl.text);
            },
            child: const Text('دروستکردن'),
          ),
        ],
      ),
    );
  }

  Future<void> _createNewAccount(String role, String name, String phone, String pass) async {
    setState(() => _isLoading = true);
    try {
      String finalPhone = phone.startsWith('0') ? phone : '0$phone';
      String finalEmail = "$finalPhone@company.com";
      FirebaseApp tempApp = await Firebase.initializeApp(name: 'TempApp_${DateTime.now().millisecondsSinceEpoch}', options: Firebase.app().options);
      UserCredential userCred = await FirebaseAuth.instanceFor(app: tempApp).createUserWithEmailAndPassword(email: finalEmail, password: pass);
      
      Map<String, dynamic> userData = {
        'name': name.trim(), 'phone': finalPhone, 'plain_password': pass.trim(),
        'is_active': true, 'wallet_balance': 0, 'completed_orders': 0,
        'role': role == 'Drivers' ? 'driver' : 'restaurant', 'created_at': FieldValue.serverTimestamp(),
      };
      if (role == 'Drivers') userData['is_online'] = false;

      await FirebaseFirestore.instance.collection(role).doc(userCred.user!.uid).set(userData);
      await tempApp.delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('بە سەرکەوتوویی دروست کرا!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('کێشەیەک روویدا: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- دەستکاریکردن و گۆڕینی زانیاری (Edit User) ---
  void _showEditUserDialog(String uid, String collection, Map<String, dynamic> currentData) {
    final TextEditingController nameCtrl = TextEditingController(text: currentData['name']);
    final TextEditingController phoneCtrl = TextEditingController(text: currentData['phone']);
    final TextEditingController passCtrl = TextEditingController(text: currentData['plain_password']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('گۆڕینی زانیارییەکان', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ناو', prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 10),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'مۆبایل', prefixIcon: Icon(Icons.phone))),
            const SizedBox(height: 10),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'وشەی نهێنی نوێ', prefixIcon: Icon(Icons.lock_reset))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('پاشگەزبوونەوە', style: TextStyle(color: Colors.red))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance.collection(collection).doc(uid).update({
                'name': nameCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
                'plain_password': passCtrl.text.trim(),
              });
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('زانیارییەکان نوێکرانەوە!'), backgroundColor: Colors.green));
            },
            child: const Text('سەیڤکردن'),
          ),
        ],
      ),
    );
  }

  // --- سڕینەوەی یەکجاری ئەکاونت ---
  void _deleteUser(String uid, String collection, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('سڕینەوەی یەکجاری!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text('ئایا دڵنیایت دەتەوێت ($name) بە یەکجاری بسڕیتەوە؟ ئەم کارە ناگەڕێتەوە.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('نەخێر')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              Navigator.pop(context); // داخستنی پڕۆفایلەکەش
              await FirebaseFirestore.instance.collection(collection).doc(uid).delete();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ئەکاونتەکە سڕایەوە.'), backgroundColor: Colors.red));
            },
            child: const Text('بەڵێ، بیسڕەوە'),
          ),
        ],
      ),
    );
  }

  // --- پڕۆفایلی VIP بەکارهێنەر ---
  void _showUserProfile(String uid, String collection, Map<String, dynamic> data) {
    bool isActive = data['is_active'] ?? true;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 500, padding: const EdgeInsets.all(25),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), tooltip: 'دەستکاری زانیاری', onPressed: () => _showEditUserDialog(uid, collection, data)),
                    IconButton(icon: const Icon(Icons.delete_forever, color: Colors.red), tooltip: 'سڕینەوەی یەکجاری', onPressed: () => _deleteUser(uid, collection, data['name'])),
                  ],
                ),
                CircleAvatar(radius: 50, backgroundColor: collection == 'Drivers' ? Colors.blue[100] : Colors.orange[100], child: Icon(collection == 'Drivers' ? Icons.motorcycle : Icons.restaurant, size: 50, color: collection == 'Drivers' ? Colors.blue : Colors.orange)),
                const SizedBox(height: 15),
                Text(data['name'] ?? 'بێ ناو', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(data['phone'] ?? '', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const Divider(height: 40),

                Row(
                  children: [
                    Expanded(child: _buildStatBox('باڵانس', '${data['wallet_balance'] ?? 0} IQD', Icons.account_balance_wallet, Colors.green)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildStatBox('ئۆردەرەکان', '${data['completed_orders'] ?? 0}', Icons.shopping_bag, Colors.blue)),
                  ],
                ),
                const SizedBox(height: 20),

                if (collection == 'Drivers') ...[
                  SizedBox(
                    width: double.infinity, height: 45,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: () { Navigator.pop(context); _showNotificationDialog(data['fcm_token'], data['name'] ?? ''); },
                      icon: const Icon(Icons.notifications_active), label: const Text('ناردنی نامە بۆ مۆبایلەکەی'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                ListTile(
                  tileColor: Colors.grey[100], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  leading: const Icon(Icons.lock, color: Colors.redAccent),
                  title: const Text('وشەی نهێنی (پاسۆرد)', style: TextStyle(color: Colors.grey)),
                  subtitle: Text(data['plain_password'] ?? 'نەزانراوە', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: isActive ? Colors.orange : Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () async {
                      await FirebaseFirestore.instance.collection(collection).doc(uid).update({'is_active': !isActive});
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                    icon: Icon(isActive ? Icons.block : Icons.check_circle),
                    label: Text(isActive ? 'راگرتنی هەژمار (باندکردن)' : 'چالاککردنەوە', style: const TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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

  // --- لیستی بەکارهێنەران لەگەڵ سیستەمی تاج ---
  Widget _buildUserList(String collection) {
    return StreamBuilder<QuerySnapshot>(
      // لێرەدا نهێنییەکە هەیە: ریزبەندکردن بەپێی زۆرترین ئۆردەر!
      stream: FirebaseFirestore.instance.collection(collection).orderBy('completed_orders', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String name = (data['name'] ?? '').toString().toLowerCase();
          String phone = (data['phone'] ?? '').toString();
          return name.contains(_searchQuery.toLowerCase()) || phone.contains(_searchQuery);
        }).toList();

        if (docs.isEmpty) return const Center(child: Text('هیچ داتایەک نەدۆزرایەوە', style: TextStyle(color: Colors.grey, fontSize: 18)));

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            String uid = docs[index].id;
            bool isActive = data['is_active'] ?? true;
            bool isOnline = collection == 'Drivers' ? (data['is_online'] ?? false) : false;
            
            // دیاریکردنی تاجی ریزبەندی
            Widget? crown;
            if (index == 0 && data['completed_orders'] > 0) crown = const Icon(Icons.workspace_premium, color: Colors.amber, size: 30); // ئاڵتوون
            else if (index == 1 && data['completed_orders'] > 0) crown = const Icon(Icons.workspace_premium, color: Colors.grey, size: 30); // زیو
            else if (index == 2 && data['completed_orders'] > 0) crown = const Icon(Icons.workspace_premium, color: Colors.brown, size: 30); // بڕۆنز

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                onTap: () => _showUserProfile(uid, collection, data),
                leading: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(radius: 25, backgroundColor: isActive ? Colors.grey[200] : Colors.red[100], child: Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54))),
                    if (crown != null) Positioned(top: -15, left: -10, child: crown),
                    if (collection == 'Drivers') CircleAvatar(radius: 8, backgroundColor: Colors.white, child: CircleAvatar(radius: 6, backgroundColor: isOnline ? Colors.green : Colors.grey)),
                  ],
                ),
                title: Text(data['name'] ?? 'بێ ناو', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, decoration: isActive ? TextDecoration.none : TextDecoration.lineThrough, color: isActive ? Colors.black : Colors.red)),
                subtitle: Text('${data['phone']}\nباڵانس: ${data['wallet_balance'] ?? 0} IQD | ئۆردەر: ${data['completed_orders'] ?? 0}', style: const TextStyle(height: 1.5)),
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
          Container(
            padding: const EdgeInsets.all(20), color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(hintText: 'گەڕان بۆ ناو یان مۆبایل...', prefixIcon: const Icon(Icons.search, color: Colors.indigo), filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                  ),
                ),
                const SizedBox(width: 15),
                if (_isLoading) const CircularProgressIndicator()
              ],
            ),
          ),
          Container(
            color: Colors.white,
            child: const TabBar(labelColor: Colors.indigo, unselectedLabelColor: Colors.grey, indicatorColor: Colors.indigo, indicatorWeight: 4, tabs: [Tab(icon: Icon(Icons.motorcycle), text: 'ریزبەندی شۆفێران'), Tab(icon: Icon(Icons.restaurant), text: 'ریزبەندی خوارنگەهەکان')]),
          ),
          Expanded(
            child: TabBarView(
              children: [
                Stack(children: [_buildUserList('Drivers'), Positioned(bottom: 20, right: 20, child: FloatingActionButton.extended(heroTag: 'd', onPressed: () => _showAddUserDialog('Drivers'), icon: const Icon(Icons.add), label: const Text('شۆفێری نوێ'), backgroundColor: Colors.blue))]),
                Stack(children: [_buildUserList('Restaurants'), Positioned(bottom: 20, right: 20, child: FloatingActionButton.extended(heroTag: 'r', onPressed: () => _showAddUserDialog('Restaurants'), icon: const Icon(Icons.add), label: const Text('خوارنگەهی نوێ'), backgroundColor: Colors.orange))]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
