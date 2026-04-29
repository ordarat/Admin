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
  // کۆنترۆڵەرەکان بۆ زانیارییە سەرەکییەکان
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // کۆنترۆڵەرە نوێیەکان بۆ دانانی لینکی وێنەکان
  final TextEditingController _profileImageLinkCtrl = TextEditingController();
  final TextEditingController _idCardController = TextEditingController(); // بۆ ژمارەی ناسنامە
  final TextEditingController _idCardLinkCtrl = TextEditingController(); // بۆ لینکی وێنەی ناسنامە
  final TextEditingController _drivingLicenseController = TextEditingController(); // بۆ ژمارەی مۆڵەت
  final TextEditingController _licenseLinkCtrl = TextEditingController(); // بۆ لینکی وێنەی مۆڵەت
  
  String _userType = 'Drivers'; 
  bool _isLoading = false;
  bool _showArchived = false; 

  Future<void> _createUser() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تکایە خانە سەرەکییەکان پڕبکەرەوە!'), backgroundColor: Colors.red));
      return;
    }

    if (_userType == 'Drivers' && (_idCardController.text.isEmpty || _drivingLicenseController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تکایە ژمارەی ناسنامە و مۆڵەت پڕبکەرەوە!'), backgroundColor: Colors.red));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      String fakeEmail = "${_phoneController.text.trim()}@company.com";
      String password = _passwordController.text.trim();
      
      // وەرگرتنی لینکەکان لە خانەکانەوە
      String profileImageUrl = _profileImageLinkCtrl.text.trim();
      String idCardUrl = _idCardLinkCtrl.text.trim();
      String licenseUrl = _licenseLinkCtrl.text.trim();

      FirebaseApp secondaryApp;
      try {
        secondaryApp = Firebase.app('SecondaryApp');
      } catch (e) {
        secondaryApp = await Firebase.initializeApp(name: 'SecondaryApp', options: Firebase.app().options);
      }
      
      UserCredential userCredential = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(email: fakeEmail, password: password);
          
      Map<String, dynamic> userData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'password': password, 
        'is_active': true,
        'is_archived': false, 
        'wallet_balance': 0, 
        'profile_image': profileImageUrl, // لینکی وێنەی پڕۆفایل
        'created_at': FieldValue.serverTimestamp(),
      };

      if (_userType == 'Drivers') {
        userData.addAll({
          'completed_orders': 0, 
          'vehicle_type': 'ماتۆڕسکیل', 
          'id_card': _idCardController.text.trim(),
          'driving_license': _drivingLicenseController.text.trim(),
          'id_card_url': idCardUrl, // لینکی وێنەی ناسنامە
          'driving_license_url': licenseUrl, // لینکی وێنەی مۆڵەت
        });
      }

      await FirebaseFirestore.instance.collection(_userType).doc(userCredential.user!.uid).set(userData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('بە سەرکەوتوویی تۆمار کرا!'), backgroundColor: Colors.green));
      
      // پاککردنەوەی هەموو خانەکان
      _nameController.clear();
      _phoneController.clear();
      _passwordController.clear();
      _profileImageLinkCtrl.clear();
      _idCardController.clear();
      _idCardLinkCtrl.clear();
      _drivingLicenseController.clear();
      _licenseLinkCtrl.clear();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('هەڵە: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() { _isLoading = false; });
    }
  }

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
            },
            child: const Text('بەڵێ، پارەکەم پێدا', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _archiveUser(String userId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ئەرشیڤکردنی بەکارهێنەر', style: TextStyle(color: Colors.orange)),
        content: Text('ئایا دڵنیایت دەتەوێت ($name) لاببەیت؟ بەم کارە دەچێتە ناو ئەرشیڤ.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('پاشگەزبوونەوە')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              FirebaseFirestore.instance.collection(_userType).doc(userId).update({'is_archived': true, 'is_active': false});
              Navigator.pop(context);
            },
            child: const Text('بەڵێ، ئەرشیڤی بکە', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _restoreUser(String userId, String name) {
    FirebaseFirestore.instance.collection(_userType).doc(userId).update({'is_archived': false, 'is_active': true});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('هەژماری ($name) گەڕێندرایەوە!'), backgroundColor: Colors.green));
  }

  void _hardDeleteUser(String userId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('سڕینەوەی یەکجاری!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text('ئایا دڵنیایت دەتەوێت هەژماری ($name) بە یەکجاری بسڕیتەوە؟ ئەم کارە ناگەڕێتەوە و هەموو داتاکانی دەسڕێنەوە!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('پاشگەزبوونەوە')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              FirebaseFirestore.instance.collection(_userType).doc(userId).delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('بە یەکجاری سڕایەوە!'), backgroundColor: Colors.red));
            },
            child: const Text('بەڵێ، بیسڕەوە', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
            IconButton(icon: const Icon(Icons.cancel, color: Colors.red, size: 40), onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  void _showUserProfileReport(String userId, Map<String, dynamic> userData) {
    String fieldToQuery = _userType == 'Drivers' ? 'driver_id' : 'restaurant_id';
    String? imageUrl = userData['profile_image'];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 800,
            height: 700,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => (imageUrl != null && imageUrl.isNotEmpty) ? _showFullImage(context, imageUrl) : null,
                      child: Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.indigo, width: 3),
                          image: (imageUrl != null && imageUrl.isNotEmpty)
                              ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                              : null,
                        ),
                        child: (imageUrl == null || imageUrl.isEmpty) ? Icon(_userType == 'Drivers' ? Icons.motorcycle : Icons.restaurant, size: 50, color: Colors.indigo) : null,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userData['name'] ?? 'بێ ناو', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                          Text('مۆبایل: ${userData['phone']} | باڵانس: ${userData['wallet_balance'] ?? 0} IQD', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                          const SizedBox(height: 10),
                          
                          if (_userType == 'Drivers') ...[
                            Text('ناسنامە: ${userData['id_card'] ?? 'نییە'}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                            Text('مۆڵەت: ${userData['driving_license'] ?? 'نییە'}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                            Text('کۆی گەیاندنەکان: ${userData['completed_orders'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            const SizedBox(height: 10),
                            const Text('وێنە یاساییەکان:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                if (userData['id_card_url'] != null && userData['id_card_url'].toString().isNotEmpty)
                                  GestureDetector(
                                    onTap: () => _showFullImage(context, userData['id_card_url']),
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 10),
                                      width: 100, height: 60,
                                      decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(5)),
                                      child: Image.network(userData['id_card_url'], fit: BoxFit.cover),
                                    ),
                                  ),
                                if (userData['driving_license_url'] != null && userData['driving_license_url'].toString().isNotEmpty)
                                  GestureDetector(
                                    onTap: () => _showFullImage(context, userData['driving_license_url']),
                                    child: Container(
                                      width: 100, height: 60,
                                      decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(5)),
                                      child: Image.network(userData['driving_license_url'], fit: BoxFit.cover),
                                    ),
                                  ),
                              ],
                            ),
                          ]
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const Divider(height: 30, thickness: 2),
                const Text('راپۆرتی کارەکان (ئۆردەرەکان)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('Orders').where(fieldToQuery, isEqualTo: userId).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('هیچ ئۆردەرێکی تۆمارکراو نییە.', style: TextStyle(color: Colors.grey, fontSize: 16)));

                      var userOrders = snapshot.data!.docs.toList();
                      userOrders.sort((a, b) {
                        Timestamp? timeA = (a.data() as Map)['created_at'] as Timestamp?;
                        Timestamp? timeB = (b.data() as Map)['created_at'] as Timestamp?;
                        if (timeA == null || timeB == null) return 0;
                        return timeB.compareTo(timeA);
                      });

                      return ListView.builder(
                        itemCount: userOrders.length,
                        itemBuilder: (context, index) {
                          var order = userOrders[index].data() as Map<String, dynamic>;
                          Color statusColor = order['status'] == 'pending' ? Colors.red : order['status'] == 'accepted' ? Colors.blue : Colors.green;
                          String statusText = order['status'] == 'pending' ? 'چاوەڕوانە' : order['status'] == 'accepted' ? 'لە رێگایە' : 'گەیەندراوە';

                          return Card(
                            color: Colors.grey[50],
                            child: ListTile(
                              leading: Icon(Icons.receipt_long, color: statusColor),
                              title: Text('کڕیار: ${order['customer_name']}'),
                              subtitle: Text('نرخ: ${order['food_price']} IQD | ناونیشان: ${order['address']}'),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                                child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                              ),
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
        );
      },
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
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                      const SizedBox(height: 15),
                      
                      // خانەی دانانی لینکی وێنەی پڕۆفایل
                      TextField(
                        controller: _profileImageLinkCtrl, 
                        decoration: const InputDecoration(
                          labelText: 'لینکی وێنەی پڕۆفایل (ئارەزوومەندانە)', 
                          border: OutlineInputBorder(), 
                          prefixIcon: Icon(Icons.link, color: Colors.indigo)
                        )
                      ),
                      
                      if (_userType == 'Drivers') ...[
                        const Divider(height: 30, thickness: 1),
                        const Text('زانیارییە یاساییەکان', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                        const SizedBox(height: 10),
                        TextField(controller: _idCardController, decoration: const InputDecoration(labelText: 'ژمارەی ناسنامە', border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge))),
                        const SizedBox(height: 10),
                        TextField(controller: _idCardLinkCtrl, decoration: const InputDecoration(labelText: 'لینکی وێنەی ناسنامە', border: OutlineInputBorder(), prefixIcon: Icon(Icons.link))),
                        const SizedBox(height: 15),
                        TextField(controller: _drivingLicenseController, decoration: const InputDecoration(labelText: 'ژمارەی مۆڵەت', border: OutlineInputBorder(), prefixIcon: Icon(Icons.drive_eta))),
                        const SizedBox(height: 10),
                        TextField(controller: _licenseLinkCtrl, decoration: const InputDecoration(labelText: 'لینکی وێنەی مۆڵەت', border: OutlineInputBorder(), prefixIcon: Icon(Icons.link))),
                      ],
                      const SizedBox(height: 20),
                      _isLoading 
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _createUser,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                            child: const Text('تۆمارکردن', style: TextStyle(fontSize: 18)),
                          ),
                    ],
                  ),
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
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_showArchived ? 'لیستی ئەرشیڤکراوەکان' : 'لیستی چالاکەکان', 
                             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _showArchived ? Colors.red : Colors.indigo)),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: _showArchived ? Colors.green : Colors.red[100], foregroundColor: _showArchived ? Colors.white : Colors.red),
                          onPressed: () => setState(() => _showArchived = !_showArchived),
                          icon: Icon(_showArchived ? Icons.arrow_back : Icons.archive),
                          label: Text(_showArchived ? 'گەڕانەوە' : 'پیشاندانی ئەرشیڤ'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection(_userType).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        
                        var users = snapshot.data!.docs.where((doc) {
                          bool isArchived = (doc.data() as Map)['is_archived'] ?? false;
                          return isArchived == _showArchived;
                        }).toList();

                        if (users.isEmpty) return Center(child: Text(_showArchived ? 'هیچ کەسێک لە ئەرشیڤدا نییە' : 'هیچ بەکارهێنەرێکی چالاک نییە', style: const TextStyle(fontSize: 18, color: Colors.grey)));

                        return ListView.separated(
                          itemCount: users.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            var userData = users[index].data() as Map<String, dynamic>;
                            String userId = users[index].id;
                            String? imageUrl = userData['profile_image'];
                            String userName = userData['name'] ?? 'بێ ناو';
                            
                            return ListTile(
                              onTap: () => _showUserProfileReport(userId, userData),
                              leading: GestureDetector(
                                onTap: () => (imageUrl != null && imageUrl.isNotEmpty) ? _showFullImage(context, imageUrl) : null,
                                child: Container(
                                  width: 55, height: 55,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: _showArchived ? Colors.grey[300] : Colors.indigo[50],
                                    border: Border.all(color: Colors.indigo, width: 1.5),
                                    image: (imageUrl != null && imageUrl.isNotEmpty)
                                        ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                                        : null,
                                  ),
                                  child: (imageUrl == null || imageUrl.isEmpty) 
                                      ? Icon(_userType == 'Drivers' ? Icons.motorcycle : Icons.restaurant, color: _showArchived ? Colors.grey : Colors.indigo, size: 30) 
                                      : null,
                                ),
                              ),
                              title: Text(userName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _showArchived ? Colors.grey : Colors.black)),
                              subtitle: Text('مۆبایل: ${userData['phone']} | باڵانس: ${userData['wallet_balance'] ?? 0} IQD', style: const TextStyle(color: Colors.blueGrey)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_showArchived) ...[
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                      onPressed: () => _restoreUser(userId, userName),
                                      icon: const Icon(Icons.restore),
                                      label: const Text('گەڕاندنەوە'),
                                    ),
                                    const SizedBox(width: 10),
                                    IconButton(
                                      tooltip: 'سڕینەوەی یەکجاری',
                                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                                      onPressed: () => _hardDeleteUser(userId, userName),
                                    ),
                                  ] else ...[
                                    IconButton(
                                      tooltip: 'پاکتاوکردنی پارە',
                                      icon: const Icon(Icons.payments, color: Colors.green),
                                      onPressed: () => _clearWalletBalance(userId, '${userData['wallet_balance'] ?? 0}'),
                                    ),
                                    Switch(
                                      activeColor: Colors.indigo,
                                      value: userData['is_active'] ?? true,
                                      onChanged: (bool value) => FirebaseFirestore.instance.collection(_userType).doc(userId).update({'is_active': value}),
                                    ),
                                    IconButton(
                                      tooltip: 'ئەرشیڤکردن',
                                      icon: const Icon(Icons.archive, color: Colors.orange),
                                      onPressed: () => _archiveUser(userId, userName),
                                    ),
                                  ],
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
