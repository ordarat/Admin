// Path: lib/screens/manage_users.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  String _searchQuery = '';
  String _selectedCityFilter = 'هەموو شارەکان';
  bool _isLoading = false;
  final Color primaryBlue = const Color(0xFF0056D2);

  final List<String> _cities = ['هەموو شارەکان', 'دهۆک', 'زاخۆ', 'هەولێر', 'سلێمانی', 'کەرکوک', 'هەڵەبجە'];
  final List<String> _formCities = ['دهۆک', 'زاخۆ', 'هەولێر', 'سلێمانی', 'کەرکوک', 'هەڵەبجە'];

  List<String> _dynamicShifts = ['کاتی ئازاد (بێ شەفت)'];

  @override
  void initState() {
    super.initState();
    _loadDynamicShifts();
  }

  void _loadDynamicShifts() {
    FirebaseFirestore.instance.collection('Shifts').snapshots().listen((snapshot) {
      List<String> shifts = ['کاتی ئازاد (بێ شەفت)'];
      for (var doc in snapshot.docs) {
        if (doc.data().containsKey('name')) {
          shifts.add(doc['name']);
        }
      }
      if (mounted) setState(() => _dynamicShifts = shifts);
    });
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Colors.indigo)), child: child!),
    );
    if (picked != null) controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
  }

  void _showNotificationDialog(String? token, String userName) {
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ئەم بەکارهێنەرە هێشتا ئەپەکەی نەکردووەتەوە.'), backgroundColor: Colors.orange));
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
              const String serverKey = 'سێرڤەر_کلیلەکەت_لێرە_دابنێ'; 
              try {
                await http.post(
                  Uri.parse('https://fcm.googleapis.com/fcm/send'),
                  headers: {'Content-Type': 'application/json', 'Authorization': 'key=$serverKey'},
                  body: jsonEncode({'to': token, 'notification': {'title': titleCtrl.text, 'body': bodyCtrl.text, 'sound': 'default'}}),
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نامەکە نێردرا!'), backgroundColor: Colors.green));
              } catch (e) {
                debugPrint("Error: $e");
              }
            },
            icon: const Icon(Icons.send), label: const Text('ناردن'),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog(String roleType) {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController phoneCtrl = TextEditingController();
    final TextEditingController passCtrl = TextEditingController();
    final TextEditingController contractStartCtrl = TextEditingController();
    final TextEditingController contractEndCtrl = TextEditingController();
    
    String selectedShift = _dynamicShifts.isNotEmpty ? _dynamicShifts[0] : 'کاتی ئازاد (بێ شەفت)';
    String selectedCity = _formCities[0]; 

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(roleType == 'Drivers' ? 'شۆفێری نوێ' : 'خوارنگەهی نوێ', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedCity,
                      decoration: const InputDecoration(labelText: 'شار (پارێزگا)', prefixIcon: Icon(Icons.location_city, color: Colors.blue)),
                      items: _formCities.map((String val) => DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                      onChanged: (newVal) => setStateDialog(() => selectedCity = newVal!),
                    ),
                    const SizedBox(height: 15),
                    
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ناوی تەواو', prefixIcon: Icon(Icons.person))),
                    const SizedBox(height: 10),
                    TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'مۆبایل (بێ سفر)', prefixIcon: Icon(Icons.phone))),
                    const SizedBox(height: 10),
                    TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'وشەی نهێنی', prefixIcon: Icon(Icons.lock))),
                    
                    if (roleType == 'Drivers') ...[
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: selectedShift,
                        decoration: const InputDecoration(labelText: 'کاتی کارکردن (شەفت)', prefixIcon: Icon(Icons.access_time)),
                        items: _dynamicShifts.map((String val) => DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (newVal) => setStateDialog(() => selectedShift = newVal!),
                      ),
                    ],

                    if (roleType == 'Restaurants') ...[
                      const SizedBox(height: 15),
                      const Divider(),
                      const Text('زانیارییەکانی گرێبەست', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                      const SizedBox(height: 10),
                      TextField(controller: contractStartCtrl, readOnly: true, onTap: () => _selectDate(context, contractStartCtrl), decoration: const InputDecoration(labelText: 'بەرواری دەستپێك', prefixIcon: Icon(Icons.calendar_today, color: Colors.green))),
                      const SizedBox(height: 10),
                      TextField(controller: contractEndCtrl, readOnly: true, onTap: () => _selectDate(context, contractEndCtrl), decoration: const InputDecoration(labelText: 'بەرواری کۆتایی هاتن', prefixIcon: Icon(Icons.event_busy, color: Colors.red))),
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('پاشگەزبوونەوە', style: TextStyle(color: Colors.red))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty || passCtrl.text.isEmpty) return;
                    Navigator.pop(context);
                    await _createNewAccount(roleType, nameCtrl.text, phoneCtrl.text, passCtrl.text, selectedShift, contractStartCtrl.text, contractEndCtrl.text, selectedCity);
                  },
                  child: const Text('دروستکردن'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _createNewAccount(String role, String name, String phone, String pass, String shift, String cStart, String cEnd, String city) async {
    setState(() => _isLoading = true);
    try {
      String finalPhone = phone.startsWith('0') ? phone : '0$phone';
      String finalEmail = "$finalPhone@ordarat.com"; 
      
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'TempApp_${DateTime.now().millisecondsSinceEpoch}', 
        options: Firebase.app().options, 
      );
      
      UserCredential userCred = await FirebaseAuth.instanceFor(app: tempApp).createUserWithEmailAndPassword(email: finalEmail, password: pass.trim());
      
      Map<String, dynamic> userData = {
        'name': name.trim(), 
        'phone': finalPhone, 
        'plain_password': pass.trim(),
        'city': city,
        'is_active': true, 
        'wallet_balance': 0, 
        'completed_orders': 0,
        'role': role == 'Drivers' ? 'driver' : 'restaurant', 
        'created_at': FieldValue.serverTimestamp(),
      };
      
      if (role == 'Drivers') {
        userData['is_online'] = false;
        userData['shift'] = shift;
      } else if (role == 'Restaurants') {
        userData['contract_start'] = cStart;
        userData['contract_end'] = cEnd;
      }

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

  void _showEditUserDialog(String uid, String collection, Map<String, dynamic> currentData) {
    final TextEditingController nameCtrl = TextEditingController(text: currentData['name']);
    final TextEditingController phoneCtrl = TextEditingController(text: currentData['phone']);
    final TextEditingController passCtrl = TextEditingController(text: currentData['plain_password']);
    final TextEditingController contractStartCtrl = TextEditingController(text: currentData['contract_start'] ?? '');
    final TextEditingController contractEndCtrl = TextEditingController(text: currentData['contract_end'] ?? '');

    String selectedShift = currentData['shift'] ?? 'کاتی ئازاد (بێ شەفت)';
    if (!_dynamicShifts.contains(selectedShift)) selectedShift = _dynamicShifts.isNotEmpty ? _dynamicShifts[0] : 'کاتی ئازاد (بێ شەفت)';

    String selectedCity = currentData['city'] ?? _formCities[0];
    if (!_formCities.contains(selectedCity)) selectedCity = _formCities[0];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('گۆڕینی زانیارییەکان', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedCity,
                      decoration: const InputDecoration(labelText: 'شار (پارێزگا)', prefixIcon: Icon(Icons.location_city, color: Colors.blue)),
                      items: _formCities.map((String val) => DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                      onChanged: (newVal) => setStateDialog(() => selectedCity = newVal!),
                    ),
                    const SizedBox(height: 15),

                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ناو', prefixIcon: Icon(Icons.person))),
                    const SizedBox(height: 10),
                    TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'مۆبایل', prefixIcon: Icon(Icons.phone))),
                    const SizedBox(height: 10),
                    TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'وشەی نهێنی نوێ', prefixIcon: Icon(Icons.lock_reset))),
                    
                    if (collection == 'Drivers') ...[
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: selectedShift,
                        decoration: const InputDecoration(labelText: 'گۆڕینی شەفتی کارکردن', prefixIcon: Icon(Icons.access_time)),
                        items: _dynamicShifts.map((String val) => DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (newVal) => setStateDialog(() => selectedShift = newVal!),
                      ),
                    ],

                    if (collection == 'Restaurants') ...[
                      const SizedBox(height: 15),
                      const Divider(),
                      const Text('نوێکردنەوەی گرێبەست', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                      const SizedBox(height: 10),
                      TextField(controller: contractStartCtrl, readOnly: true, onTap: () => _selectDate(context, contractStartCtrl), decoration: const InputDecoration(labelText: 'بەرواری دەستپێك', prefixIcon: Icon(Icons.calendar_today, color: Colors.green))),
                      const SizedBox(height: 10),
                      TextField(controller: contractEndCtrl, readOnly: true, onTap: () => _selectDate(context, contractEndCtrl), decoration: const InputDecoration(labelText: 'بەرواری کۆتایی هاتن', prefixIcon: Icon(Icons.event_busy, color: Colors.red))),
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('پاشگەزبوونەوە', style: TextStyle(color: Colors.red))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  onPressed: () async {
                    Navigator.pop(context);
                    Map<String, dynamic> updates = {
                      'name': nameCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'plain_password': passCtrl.text.trim(),
                      'city': selectedCity,
                    };
                    if (collection == 'Drivers') updates['shift'] = selectedShift;
                    else if (collection == 'Restaurants') { updates['contract_start'] = contractStartCtrl.text; updates['contract_end'] = contractEndCtrl.text; }

                    await FirebaseFirestore.instance.collection(collection).doc(uid).update(updates);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('زانیارییەکان نوێکرانەوە!'), backgroundColor: Colors.green));
                  },
                  child: const Text('سەیڤکردن'),
                ),
              ],
            );
          }
        );
      },
    );
  }

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
              Navigator.pop(context); Navigator.pop(context); 
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

  // مێشکی پڕۆفایلە زەبەلاحە نوێیەکە (360-Degree Profile)
  void _showUserProfile(String uid, String collection, Map<String, dynamic> data) {
    bool isActive = data['is_active'] ?? true;
    bool isOnline = collection == 'Drivers' ? (data['is_online'] ?? false) : false;
    
    bool isContractExpired = false;
    if (collection == 'Restaurants' && data['contract_end'] != null && data['contract_end'].toString().isNotEmpty) {
      try { if (DateTime.parse(data['contract_end']).isBefore(DateTime.now())) isContractExpired = true; } catch (e) {}
    }

    String createdAt = 'نەزانراو';
    if (data['created_at'] != null) {
      try { createdAt = DateFormat('yyyy-MM-dd HH:mm').format((data['created_at'] as Timestamp).toDate()); } catch (e) {}
    }

    Color themeColor = collection == 'Drivers' ? Colors.blue : Colors.orange;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 600,
          height: 700,
          child: Column(
            children: [
              // بەشی سەرەوە (Header)
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(gradient: LinearGradient(colors: [themeColor.withOpacity(0.8), themeColor])),
                child: Stack(
                  children: [
                    Positioned(top: 10, right: 10, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))),
                    Positioned(top: 10, left: 10, child: IconButton(icon: const Icon(Icons.edit, color: Colors.white), tooltip: 'دەستکاری', onPressed: () => _showEditUserDialog(uid, collection, data))),
                  ],
                ),
              ),
              
              // وێنە و ناوی پڕۆفایل
              Transform.translate(
                offset: const Offset(0, -50),
                child: Column(
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                      child: CircleAvatar(backgroundColor: themeColor.withOpacity(0.1), child: Icon(collection == 'Drivers' ? Icons.motorcycle : Icons.storefront, size: 50, color: themeColor)),
                    ),
                    const SizedBox(height: 10),
                    Text(data['name'] ?? 'بێ ناو', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2C))),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(data['city'] ?? 'دیاری نەکراوە', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // باجەکان (Badges)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildBadge(isActive ? 'هەژماری چالاک' : 'هەژماری باندکراو', isActive ? Colors.green : Colors.red),
                        const SizedBox(width: 10),
                        if (collection == 'Drivers') _buildBadge(isOnline ? 'ئۆنلاین' : 'ئۆفلاین', isOnline ? Colors.green : Colors.grey),
                        if (collection == 'Restaurants') _buildBadge(isContractExpired ? 'گرێبەست بەسەرچووە' : 'گرێبەست کارایە', isContractExpired ? Colors.red : Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
              
              // تابەکان بۆ داتای گشتگیر
              Expanded(
                child: Transform.translate(
                  offset: const Offset(0, -30),
                  child: DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        TabBar(
                          labelColor: themeColor, unselectedLabelColor: Colors.grey, indicatorColor: themeColor,
                          tabs: const [Tab(text: 'دارایی و کار'), Tab(text: 'زانیاری کەسی'), Tab(text: 'سکیورێتی')],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              // تابی دارایی و کار
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: _buildStatCard('باڵانسی جزدان', '${data['wallet_balance'] ?? 0} IQD', Icons.account_balance_wallet, Colors.green)),
                                        const SizedBox(width: 15),
                                        Expanded(child: _buildStatCard('کۆی ئۆردەرەکان', '${data['completed_orders'] ?? 0}', Icons.shopping_bag, themeColor)),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    if (collection == 'Drivers')
                                      ListTile(tileColor: Colors.indigo[50], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), leading: const Icon(Icons.access_time, color: Colors.indigo), title: const Text('شەفتی کارکردن', style: TextStyle(fontWeight: FontWeight.bold)), trailing: Text(data['shift'] ?? 'بێ شەفت', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold))),
                                    if (collection == 'Restaurants')
                                      Container(
                                        padding: const EdgeInsets.all(15),
                                        decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange[200]!)),
                                        child: Column(
                                          children: [
                                            const Row(children: [Icon(Icons.handshake, color: Colors.orange), SizedBox(width: 10), Text('زانیاری گرێبەست', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
                                            const Divider(),
                                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('دەستپێک:'), Text(data['contract_start'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold))]),
                                            const SizedBox(height: 5),
                                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('کۆتایی:'), Text(data['contract_end'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold))]),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              
                              // تابی زانیاری کەسی
                              ListView(
                                padding: const EdgeInsets.all(20),
                                children: [
                                  ListTile(leading: const Icon(Icons.phone), title: const Text('ژمارە مۆبایل'), subtitle: Text(data['phone'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                                  const Divider(),
                                  ListTile(leading: const Icon(Icons.email), title: const Text('ئیمەیڵی لۆگین'), subtitle: Text('${data['phone']}@ordarat.com', style: const TextStyle(fontSize: 16))),
                                  const Divider(),
                                  ListTile(leading: const Icon(Icons.calendar_today), title: const Text('بەرواری دروستکردنی هەژمار'), subtitle: Text(createdAt, style: const TextStyle(fontSize: 16))),
                                ],
                              ),

                              // تابی سکیورێتی و کردارەکان
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red[200]!)),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('پاسۆردی ئەکاونت', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)), Text('تەنها بۆ بەڕێوەبەر دەردەکەوێت', style: TextStyle(fontSize: 12, color: Colors.red))]),
                                          Text(data['plain_password'] ?? 'نەزانراوە', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(width: double.infinity, height: 45, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () { Navigator.pop(context); _showNotificationDialog(data['fcm_token'], data['name'] ?? ''); }, icon: const Icon(Icons.notifications_active), label: const Text('ناردنی نۆتیفیکەیشن بۆ مۆبایلەکەی'))),
                                    const SizedBox(height: 15),
                                    SizedBox(width: double.infinity, height: 45, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: isActive ? Colors.orange : Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () async { await FirebaseFirestore.instance.collection(collection).doc(uid).update({'is_active': !isActive}); if (!context.mounted) return; Navigator.pop(context); }, icon: Icon(isActive ? Icons.block : Icons.check_circle), label: Text(isActive ? 'راگرتنی هەژمار (باندکردن)' : 'چالاککردنەوەی هەژمار', style: const TextStyle(fontSize: 16)))),
                                    const SizedBox(height: 15),
                                    SizedBox(width: double.infinity, height: 45, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () { Navigator.pop(context); _deleteUser(uid, collection, data['name']); }, icon: const Icon(Icons.delete_forever), label: const Text('سڕینەوەی یەکجاری', style: TextStyle(fontSize: 16)))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color)),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[200]!), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)]),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildUserList(String collection) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).orderBy('completed_orders', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        var docs = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String name = (data['name'] ?? '').toString().toLowerCase();
          String phone = (data['phone'] ?? '').toString();
          String city = data['city'] ?? '';
          
          bool matchesCity = _selectedCityFilter == 'هەموو شارەکان' || city == _selectedCityFilter;
          bool matchesSearch = name.contains(_searchQuery.toLowerCase()) || phone.contains(_searchQuery);
          
          return matchesCity && matchesSearch;
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
            String shift = collection == 'Drivers' ? (data['shift'] ?? 'کاتی ئازاد (بێ شەفت)') : '';
            String city = data['city'] ?? 'دیاری نەکراوە';
            
            bool isContractExpired = false;
            if (collection == 'Restaurants' && data['contract_end'] != null && data['contract_end'].toString().isNotEmpty) {
              try { if (DateTime.parse(data['contract_end']).isBefore(DateTime.now())) isContractExpired = true; } catch (e) {}
            }
            
            Widget? crown;
            if (index == 0 && data['completed_orders'] > 0) crown = const Icon(Icons.workspace_premium, color: Colors.amber, size: 30); 
            else if (index == 1 && data['completed_orders'] > 0) crown = const Icon(Icons.workspace_premium, color: Colors.grey, size: 30); 
            else if (index == 2 && data['completed_orders'] > 0) crown = const Icon(Icons.workspace_premium, color: Colors.brown, size: 30); 

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
                title: Row(
                  children: [
                    Expanded(child: Text(data['name'] ?? 'بێ ناو', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, decoration: isActive ? TextDecoration.none : TextDecoration.lineThrough, color: isActive ? Colors.black : Colors.red))),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(5)), child: Text(city, style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold))),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    Text('${data['phone']} | باڵانس: ${data['wallet_balance'] ?? 0} IQD\nئۆردەر: ${data['completed_orders'] ?? 0}'),
                    if (collection == 'Drivers') Text(shift, style: const TextStyle(color: Colors.indigo, fontSize: 12, fontWeight: FontWeight.bold)),
                    if (collection == 'Restaurants' && data['contract_end'] != null)
                      Text(isContractExpired ? 'گرێبەست بەسەرچووە ⚠️' : 'گرێبەست کارایە ✅', style: TextStyle(color: isContractExpired ? Colors.red : Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
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
                  flex: 2,
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(hintText: 'گەڕان بۆ ناو...', prefixIcon: const Icon(Icons.search, color: Colors.indigo), filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _selectedCityFilter,
                    decoration: InputDecoration(filled: true, fillColor: Colors.blue[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                    items: _cities.map((String val) => DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)))).toList(),
                    onChanged: (newVal) => setState(() => _selectedCityFilter = newVal!),
                  ),
                ),
                if (_isLoading) const Padding(padding: EdgeInsets.only(right: 15), child: CircularProgressIndicator())
              ],
            ),
          ),
          Container(
            color: Colors.white,
            child: const TabBar(labelColor: Colors.indigo, unselectedLabelColor: Colors.grey, indicatorColor: Colors.indigo, indicatorWeight: 4, tabs: [Tab(icon: Icon(Icons.motorcycle), text: 'شۆفێران'), Tab(icon: Icon(Icons.restaurant), text: 'خوارنگەهەکان')]),
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
