// Path: lib/screens/manage_users.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  String _searchQuery = '';
  String _selectedCityFilter = 'هەموو شارەکان';
  String _selectedSort = 'نوێترین'; // فلتەری نوێ بۆ ڕیزکردن
  bool _isLoading = false;
  bool _showArchived = false; 
  final Color primaryBlue = const Color(0xFF0056D2);

  final List<String> _cities = ['هەموو شارەکان', 'دهۆک', 'زاخۆ', 'هەولێر', 'سلێمانی', 'کەرکوک', 'هەڵەبجە'];
  final List<String> _formCities = ['دهۆک', 'زاخۆ', 'هەولێر', 'سلێمانی', 'کەرکوک', 'هەڵەبجە'];
  final List<String> _sortOptions = ['نوێترین', 'کۆنترین', 'زۆرترین ئۆردەر'];

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

  // هەژمارکردنی ماوەی خزمەت (چەندە لەگەڵمانە)
  String _getServiceDuration(String joinDateStr) {
    try {
      DateTime joinDate = DateTime.parse(joinDateStr);
      Duration diff = DateTime.now().difference(joinDate);
      int days = diff.inDays;
      if (days < 30) return '$days ڕۆژ';
      int months = days ~/ 30;
      if (months < 12) return '$months مانگ';
      int years = months ~/ 12;
      int remMonths = months % 12;
      return remMonths > 0 ? '$years ساڵ و $remMonths مانگ' : '$years ساڵ';
    } catch(e) {
      return 'نەزانراو';
    }
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
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'سەردێڕ', prefixIcon: Icon(Icons.title))),
            const SizedBox(height: 10),
            TextField(controller: bodyCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'ناوەڕۆک...', border: OutlineInputBorder())),
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
    
    // بەرواری دەستبەکاربوون (بە دیفۆڵت ئەمڕۆیە)
    final TextEditingController joinDateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    
    final TextEditingController salaryCtrl = TextEditingController(text: '0'); 
    final TextEditingController contractStartCtrl = TextEditingController();
    final TextEditingController contractEndCtrl = TextEditingController();
    
    final TextEditingController profileImgCtrl = TextEditingController();
    final TextEditingController nationalIdCtrl = TextEditingController();
    final TextEditingController licenseCtrl = TextEditingController();

    String selectedShift = _dynamicShifts.isNotEmpty ? _dynamicShifts[0] : 'کاتی ئازاد (بێ شەفت)';
    String selectedCity = _formCities[0]; 

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(roleType == 'Drivers' ? 'دروستکردنی شۆفێری نوێ' : 'دروستکردنی خوارنگەهی نوێ', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 450,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedCity,
                        decoration: const InputDecoration(labelText: 'شار', prefixIcon: Icon(Icons.location_city, color: Colors.blue)),
                        items: _formCities.map((String val) => DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                        onChanged: (newVal) => setStateDialog(() => selectedCity = newVal!),
                      ),
                      const SizedBox(height: 15),
                      TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ناوی تەواو', prefixIcon: Icon(Icons.person))),
                      const SizedBox(height: 10),
                      TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'مۆبایل', prefixIcon: Icon(Icons.phone))),
                      const SizedBox(height: 10),
                      TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'وشەی نهێنی', prefixIcon: Icon(Icons.lock))),
                      const SizedBox(height: 10),
                      
                      // خانەی بەرواری دەستبەکاربوون
                      TextField(
                        controller: joinDateCtrl, readOnly: true, 
                        onTap: () => _selectDate(context, joinDateCtrl), 
                        decoration: InputDecoration(
                          labelText: roleType == 'Drivers' ? 'بەرواری دامەزراندنی شۆفێر' : 'بەرواری پەیوەندی بە کۆمپانیا', 
                          prefixIcon: const Icon(Icons.history_edu, color: Colors.brown)
                        )
                      ),
                      
                      if (roleType == 'Drivers') ...[
                        const SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          value: selectedShift,
                          decoration: const InputDecoration(labelText: 'کاتی کارکردن (شەفت)', prefixIcon: Icon(Icons.access_time)),
                          items: _dynamicShifts.map((String val) => DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (newVal) => setStateDialog(() => selectedShift = newVal!),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: salaryCtrl, 
                          keyboardType: TextInputType.number, 
                          decoration: const InputDecoration(labelText: 'مووچەی مانگانە (بە دینار)', prefixIcon: Icon(Icons.payments, color: Colors.purple), hintText: 'ئەگەر مووچەی جێگیری هەیە لێرە بنووسە'),
                        ),
                      ],

                      if (roleType == 'Restaurants') ...[
                        const SizedBox(height: 15),
                        const Divider(),
                        const Text('زانیاری گرێبەست', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                        const SizedBox(height: 10),
                        TextField(controller: contractStartCtrl, readOnly: true, onTap: () => _selectDate(context, contractStartCtrl), decoration: const InputDecoration(labelText: 'بەرواری دەستپێك', prefixIcon: Icon(Icons.calendar_today, color: Colors.green))),
                        const SizedBox(height: 10),
                        TextField(controller: contractEndCtrl, readOnly: true, onTap: () => _selectDate(context, contractEndCtrl), decoration: const InputDecoration(labelText: 'بەرواری کۆتایی', prefixIcon: Icon(Icons.event_busy, color: Colors.red))),
                      ],

                      const SizedBox(height: 15),
                      const Divider(),
                      const Text('بەڵگەنامەکان و وێنە (لینک)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                      const SizedBox(height: 10),
                      TextField(controller: profileImgCtrl, decoration: InputDecoration(labelText: roleType == 'Drivers' ? 'لینکی وێنەی پڕۆفایل' : 'لینکی لۆگۆی خوارنگەهـ', prefixIcon: const Icon(Icons.image, color: Colors.blue))),
                      
                      if (roleType == 'Drivers') ...[
                        const SizedBox(height: 10),
                        TextField(controller: nationalIdCtrl, decoration: const InputDecoration(labelText: 'لینکی کارتی نیشتیمانی', prefixIcon: Icon(Icons.badge, color: Colors.orange))),
                        const SizedBox(height: 10),
                        TextField(controller: licenseCtrl, decoration: const InputDecoration(labelText: 'لینکی مۆڵەتی شۆفێری', prefixIcon: Icon(Icons.drive_eta, color: Colors.green))),
                      ],
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
                    Navigator.pop(context);
                    
                    double monthlySalary = double.tryParse(salaryCtrl.text.trim()) ?? 0.0;

                    await _createNewAccount(
                      role: roleType, name: nameCtrl.text, phone: phoneCtrl.text, pass: passCtrl.text, 
                      shift: selectedShift, monthlySalary: monthlySalary, joinDate: joinDateCtrl.text,
                      cStart: contractStartCtrl.text, cEnd: contractEndCtrl.text, city: selectedCity,
                      profileImg: profileImgCtrl.text, nationalId: nationalIdCtrl.text, license: licenseCtrl.text
                    );
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

  Future<void> _createNewAccount({
    required String role, required String name, required String phone, required String pass, 
    required String shift, required double monthlySalary, required String joinDate,
    required String cStart, required String cEnd, required String city,
    required String profileImg, required String nationalId, required String license
  }) async {
    setState(() => _isLoading = true);
    try {
      String finalPhone = phone.startsWith('0') ? phone : '0$phone';
      String finalEmail = "$finalPhone@ordarat.com"; 
      
      FirebaseApp tempApp = await Firebase.initializeApp(name: 'TempApp_${DateTime.now().millisecondsSinceEpoch}', options: Firebase.app().options);
      UserCredential userCred = await FirebaseAuth.instanceFor(app: tempApp).createUserWithEmailAndPassword(email: finalEmail, password: pass.trim());
      
      Map<String, dynamic> userData = {
        'name': name.trim(), 
        'phone': finalPhone, 
        'plain_password': pass.trim(),
        'city': city,
        'join_date': joinDate, // خەزنکردنی بەرواری دەستبەکاربوون
        'is_active': true,
        'is_archived': false, 
        'wallet_balance': 0, 
        'completed_orders': 0,
        'role': role == 'Drivers' ? 'driver' : 'restaurant', 
        'created_at': FieldValue.serverTimestamp(),
        'profile_image': profileImg.trim(),
        'national_id_image': nationalId.trim(),
        'driving_license_image': license.trim(),
      };
      
      if (role == 'Drivers') {
        userData['is_online'] = false;
        userData['shift'] = shift;
        userData['monthly_salary'] = monthlySalary; 
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
    
    // هێنانی بەرواری دەستبەکاربوون
    String existingJoinDate = currentData['join_date'] ?? '';
    if (existingJoinDate.isEmpty && currentData['created_at'] != null) {
      existingJoinDate = DateFormat('yyyy-MM-dd').format((currentData['created_at'] as Timestamp).toDate());
    } else if (existingJoinDate.isEmpty) {
      existingJoinDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }
    final TextEditingController joinDateCtrl = TextEditingController(text: existingJoinDate);

    final TextEditingController contractStartCtrl = TextEditingController(text: currentData['contract_start'] ?? '');
    final TextEditingController contractEndCtrl = TextEditingController(text: currentData['contract_end'] ?? '');
    final TextEditingController salaryCtrl = TextEditingController(text: (currentData['monthly_salary'] ?? 0).toString());

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
                      decoration: const InputDecoration(labelText: 'شار', prefixIcon: Icon(Icons.location_city, color: Colors.blue)),
                      items: _formCities.map((String val) => DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                      onChanged: (newVal) => setStateDialog(() => selectedCity = newVal!),
                    ),
                    const SizedBox(height: 15),

                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ناو', prefixIcon: Icon(Icons.person))),
                    const SizedBox(height: 10),
                    TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'مۆبایل', prefixIcon: Icon(Icons.phone))),
                    const SizedBox(height: 10),
                    TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'وشەی نهێنی نوێ', prefixIcon: Icon(Icons.lock_reset))),
                    const SizedBox(height: 10),
                    TextField(
                      controller: joinDateCtrl, readOnly: true, 
                      onTap: () => _selectDate(context, joinDateCtrl), 
                      decoration: const InputDecoration(labelText: 'بەرواری دەستبەکاربوون (دامەزراندن)', prefixIcon: Icon(Icons.history_edu, color: Colors.brown))
                    ),
                    
                    if (collection == 'Drivers') ...[
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: selectedShift,
                        decoration: const InputDecoration(labelText: 'گۆڕینی شەفت', prefixIcon: Icon(Icons.access_time)),
                        items: _dynamicShifts.map((String val) => DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (newVal) => setStateDialog(() => selectedShift = newVal!),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: salaryCtrl, 
                        keyboardType: TextInputType.number, 
                        decoration: const InputDecoration(labelText: 'مووچەی مانگانە (بە دینار)', prefixIcon: Icon(Icons.payments, color: Colors.purple)),
                      ),
                    ],

                    if (collection == 'Restaurants') ...[
                      const SizedBox(height: 15),
                      const Divider(),
                      const Text('نوێکردنەوەی گرێبەست', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                      const SizedBox(height: 10),
                      TextField(controller: contractStartCtrl, readOnly: true, onTap: () => _selectDate(context, contractStartCtrl), decoration: const InputDecoration(labelText: 'دەستپێك', prefixIcon: Icon(Icons.calendar_today, color: Colors.green))),
                      const SizedBox(height: 10),
                      TextField(controller: contractEndCtrl, readOnly: true, onTap: () => _selectDate(context, contractEndCtrl), decoration: const InputDecoration(labelText: 'کۆتایی', prefixIcon: Icon(Icons.event_busy, color: Colors.red))),
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
                      'join_date': joinDateCtrl.text,
                    };
                    if (collection == 'Drivers') {
                      updates['shift'] = selectedShift;
                      updates['monthly_salary'] = double.tryParse(salaryCtrl.text.trim()) ?? 0.0;
                    }
                    else if (collection == 'Restaurants') { 
                      updates['contract_start'] = contractStartCtrl.text; 
                      updates['contract_end'] = contractEndCtrl.text; 
                    }

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

  void _showPenaltyDialog(String uid, String collection, String name, double currentBalance) {
    final TextEditingController amountCtrl = TextEditingController();
    final TextEditingController reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('سزای دارایی بۆ: $name', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
              child: Text('باڵانسی ئێستا: ${currentBalance.toInt()} دینار', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 15),
            TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'بڕی سزا (بە دینار)', prefixIcon: Icon(Icons.money_off, color: Colors.red))),
            const SizedBox(height: 10),
            TextField(controller: reasonCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'هۆکاری سزا...', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('پاشگەزبوونەوە')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              if (amountCtrl.text.isEmpty || reasonCtrl.text.isEmpty) return;
              double penaltyAmount = double.tryParse(amountCtrl.text) ?? 0;
              if (penaltyAmount <= 0) return;

              Navigator.pop(context);
              await FirebaseFirestore.instance.collection(collection).doc(uid).update({
                'wallet_balance': FieldValue.increment(-penaltyAmount)
              });
              
              await FirebaseFirestore.instance.collection('Penalties').add({
                'user_id': uid, 'user_name': name, 'role': collection,
                'amount': penaltyAmount, 'reason': reasonCtrl.text, 'date': FieldValue.serverTimestamp(),
              });

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سزای دارایی جێبەجێ کرا!'), backgroundColor: Colors.red));
            },
            child: const Text('سەپاندنی سزا'),
          ),
        ],
      ),
    );
  }

  void _showBanOptionsDialog(String uid, String collection, String name, bool isCurrentlyActive) {
    if (!isCurrentlyActive) {
      FirebaseFirestore.instance.collection(collection).doc(uid).update({'is_active': true, 'ban_until': FieldValue.delete()});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هەژمارەکە چالاک کرایەوە!'), backgroundColor: Colors.green));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('سڕکردنی هەژمار: $name', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('بۆ چەند کاتێک دەتەوێت ئەم هەژمارە ڕابگریت؟', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 15),
            ListTile(leading: const Icon(Icons.timer), title: const Text('٢٤ کاتژمێر'), onTap: () => _applyBan(context, uid, collection, const Duration(hours: 24))),
            ListTile(leading: const Icon(Icons.date_range), title: const Text('٣ ڕۆژ'), onTap: () => _applyBan(context, uid, collection, const Duration(days: 3))),
            ListTile(leading: const Icon(Icons.calendar_month), title: const Text('١ هەفتە'), onTap: () => _applyBan(context, uid, collection, const Duration(days: 7))),
            const Divider(),
            ListTile(leading: const Icon(Icons.block, color: Colors.red), title: const Text('هەمیشەیی (باندی تەواو)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), onTap: () => _applyBan(context, uid, collection, null)),
          ],
        ),
      ),
    );
  }

  Future<void> _applyBan(BuildContext dialogContext, String uid, String collection, Duration? duration) async {
    Navigator.pop(dialogContext);
    Map<String, dynamic> updates = {'is_active': false};
    if (duration != null) {
      DateTime unbanDate = DateTime.now().add(duration);
      updates['ban_until'] = unbanDate;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('هەژمارەکە سڕکرا تاوەکو: ${DateFormat('yyyy-MM-dd HH:mm').format(unbanDate)}'), backgroundColor: Colors.orange));
    } else {
      updates['ban_until'] = FieldValue.delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هەژمارەکە بە یەکجاری باند کرا!'), backgroundColor: Colors.red));
    }
    await FirebaseFirestore.instance.collection(collection).doc(uid).update(updates);
  }

  void _archiveUser(String uid, String collection, String name, bool isCurrentlyArchived) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isCurrentlyArchived ? 'هێنانەدەرەوە لە ئەرشیف' : 'ئەرشیفکردنی ئەکاونت', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
        content: Text(isCurrentlyArchived ? 'ئایا دەتەوێت ($name) بگەڕێنیتەوە بۆ لیستی سەرەکی؟' : 'ئایا دەتەوێت ($name) بخەیتە ئەرشیفەوە؟ بەم کارە لە لیستی سەرەکی نامێنێت بەڵام داتاکانی نافەوتێت و نەسڕێتەوە.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('نەخێر')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isCurrentlyArchived ? Colors.green : Colors.indigo, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context); Navigator.pop(context); 
              await FirebaseFirestore.instance.collection(collection).doc(uid).update({'is_archived': !isCurrentlyArchived});
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isCurrentlyArchived ? 'گەڕێنرایەوە لیستی سەرەکی.' : 'خرایە ئەرشیفەوە.'), backgroundColor: Colors.blue));
            },
            child: Text(isCurrentlyArchived ? 'هێنانەدەرەوە' : 'بەڵێ، ئەرشیفی بکە'),
          ),
        ],
      ),
    );
  }

  void _showUpdateDocumentsDialog(String uid, String collection, Map<String, dynamic> currentData) {
    final TextEditingController profileCtrl = TextEditingController(text: currentData['profile_image'] ?? '');
    final TextEditingController idCtrl = TextEditingController(text: currentData['national_id_image'] ?? '');
    final TextEditingController licenseCtrl = TextEditingController(text: currentData['driving_license_image'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('نوێکردنەوەی بەڵگەنامەکان و وێنە', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('تکایە لینکی وێنەکان (URL) لێرە دابنێ.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 15),
                TextField(controller: profileCtrl, decoration: const InputDecoration(labelText: 'لینکی وێنەی پڕۆفایل', prefixIcon: Icon(Icons.account_circle))),
                const SizedBox(height: 10),
                if (collection == 'Drivers') ...[
                  TextField(controller: idCtrl, decoration: const InputDecoration(labelText: 'لینکی کارتی نیشتیمانی', prefixIcon: Icon(Icons.badge))),
                  const SizedBox(height: 10),
                  TextField(controller: licenseCtrl, decoration: const InputDecoration(labelText: 'لینکی مۆڵەتی شۆفێری', prefixIcon: Icon(Icons.drive_eta))),
                ]
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('پاشگەزبوونەوە')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              Map<String, dynamic> updates = {'profile_image': profileCtrl.text.trim()};
              if (collection == 'Drivers') {
                updates['national_id_image'] = idCtrl.text.trim();
                updates['driving_license_image'] = licenseCtrl.text.trim();
              }
              await FirebaseFirestore.instance.collection(collection).doc(uid).update(updates);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('بەڵگەنامەکان نوێکرانەوە!'), backgroundColor: Colors.green));
            },
            child: const Text('سەیڤکردن'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(String uid, String collection, String phone) {
    final TextEditingController passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('گۆڕینی پاسۆرد', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('تێبینی: گۆڕینی پاسۆرد لێرەوە وا دەکات کاتێک بەکارهێنەر لۆگین دەکات، بەم پاسۆردە نوێیە بچێتە ژوورەوە.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 15),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'پاسۆردی نوێ بنووسە', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('پاشگەزبوونەوە')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              if (passCtrl.text.isEmpty) return;
              Navigator.pop(context);
              await FirebaseFirestore.instance.collection(collection).doc(uid).update({'plain_password': passCtrl.text.trim()});
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('پاسۆردەکە نوێکرایەوە بە سەرکەوتوویی!'), backgroundColor: Colors.green));
            },
            child: const Text('گۆڕین'),
          ),
        ],
      ),
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

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نەتوانرا پەیوەندی بکرێت، دڵنیابە لە ژمارەکە.'), backgroundColor: Colors.red));
      }
    }
  }

  // --- پڕۆفایلی زەبەلاح (مۆدێرن) ---
  void _showUserProfile(String uid, String collection, Map<String, dynamic> data) {
    bool isActive = data['is_active'] ?? true;
    bool isArchived = data['is_archived'] ?? false;
    bool isOnline = collection == 'Drivers' ? (data['is_online'] ?? false) : false;
    double walletBalance = (data['wallet_balance'] ?? 0).toDouble();
    double monthlySalary = (data['monthly_salary'] ?? 0).toDouble();
    
    // زانینی کاتی دەستبەکاربوون و ماوەکەی
    String joinDate = data['join_date'] ?? '';
    if (joinDate.isEmpty && data['created_at'] != null) {
      joinDate = DateFormat('yyyy-MM-dd').format((data['created_at'] as Timestamp).toDate());
    }
    String serviceDuration = joinDate.isNotEmpty ? _getServiceDuration(joinDate) : 'نەزانراو';

    bool isContractExpired = false;
    if (collection == 'Restaurants' && data['contract_end'] != null && data['contract_end'].toString().isNotEmpty) {
      try { if (DateTime.parse(data['contract_end']).isBefore(DateTime.now())) isContractExpired = true; } catch (e) {}
    }

    String banInfo = '';
    if (!isActive && data['ban_until'] != null) {
      DateTime banUntil = (data['ban_until'] as Timestamp).toDate();
      if (banUntil.isAfter(DateTime.now())) {
        banInfo = 'باندکراوە تا: ${DateFormat('yyyy-MM-dd HH:mm').format(banUntil)}';
      }
    }

    String profileImg = data['profile_image'] ?? '';
    Color themeColor = collection == 'Drivers' ? Colors.blue : Colors.orange;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 750, height: 750,
          child: Column(
            children: [
              Container(
                height: 120, width: double.infinity,
                decoration: BoxDecoration(gradient: LinearGradient(colors: [isArchived ? Colors.grey : themeColor.withOpacity(0.8), isArchived ? Colors.grey[700]! : themeColor])),
                child: Stack(
                  children: [
                    Positioned(top: 10, right: 10, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))),
                    if (isArchived) Positioned(top: 15, left: 15, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)), child: const Text('لە ئەرشیفدایە', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                  ],
                ),
              ),
              
              Transform.translate(
                offset: const Offset(0, -50),
                child: Column(
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                      child: profileImg.isNotEmpty 
                        ? ClipOval(child: Image.network(profileImg, fit: BoxFit.cover, errorBuilder: (c,e,s) => Icon(collection == 'Drivers' ? Icons.motorcycle : Icons.storefront, size: 50, color: themeColor)))
                        : CircleAvatar(backgroundColor: themeColor.withOpacity(0.1), child: Icon(collection == 'Drivers' ? Icons.motorcycle : Icons.storefront, size: 50, color: themeColor)),
                    ),
                    const SizedBox(height: 10),
                    Text(data['name'] ?? 'بێ ناو', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2C))),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]), const SizedBox(width: 4),
                        Text(data['city'] ?? 'دیاری نەکراوە', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildBadge(isActive ? 'هەژماری چالاک' : 'هەژماری باندکراو', isActive ? Colors.green : Colors.red),
                        const SizedBox(width: 10),
                        if (collection == 'Drivers') _buildBadge(isOnline ? 'ئۆنلاین' : 'ئۆفلاین', isOnline ? Colors.green : Colors.grey),
                        if (collection == 'Restaurants') _buildBadge(isContractExpired ? 'گرێبەست بەسەرچووە' : 'گرێبەست کارایە', isContractExpired ? Colors.red : Colors.green),
                      ],
                    ),
                    if (banInfo.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(banInfo, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 15),
                    
                    if (data['phone'] != null && data['phone'].toString().isNotEmpty)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 3,
                        ),
                        onPressed: () => _makePhoneCall(data['phone']),
                        icon: const Icon(Icons.phone),
                        label: Text('پەیوەندیکردن (${data['phone']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
              
              Expanded(
                child: Transform.translate(
                  offset: const Offset(0, -30),
                  child: DefaultTabController(
                    length: 4, 
                    child: Column(
                      children: [
                        TabBar(
                          labelColor: themeColor, unselectedLabelColor: Colors.grey, indicatorColor: themeColor, isScrollable: true,
                          tabs: const [Tab(text: 'دارایی و کار'), Tab(text: 'بەڵگەنامەکان'), Tab(text: 'سکیورێتی'), Tab(text: 'زانیاری کەسی')],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              // تابی 1: دارایی و کار 
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(child: _buildStatCard('باڵانس', '${walletBalance.toInt()} IQD', Icons.account_balance_wallet, Colors.green)),
                                          const SizedBox(width: 10),
                                          Expanded(child: _buildStatCard('ئۆردەرەکان', '${data['completed_orders'] ?? 0}', Icons.shopping_bag, themeColor)),
                                          if (collection == 'Drivers') ...[
                                            const SizedBox(width: 10),
                                            Expanded(child: _buildStatCard('مووچەی جێگیر', '${monthlySalary.toInt()} IQD', Icons.payments, Colors.purple)),
                                          ]
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      
                                      SizedBox(
                                        width: double.infinity, height: 45,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50], foregroundColor: Colors.red, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.red))),
                                          onPressed: () => _showPenaltyDialog(uid, collection, data['name'], walletBalance),
                                          icon: const Icon(Icons.money_off), label: const Text('سەپاندنی سزای دارایی', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      if (collection == 'Drivers')
                                        ListTile(tileColor: Colors.indigo[50], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), leading: const Icon(Icons.access_time, color: Colors.indigo), title: const Text('شەفتی کارکردن', style: TextStyle(fontWeight: FontWeight.bold)), trailing: Text(data['shift'] ?? 'بێ شەفت', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold))),
                                      
                                      if (collection == 'Restaurants') ...[
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
                                        const SizedBox(height: 10),
                                        SizedBox(
                                          width: double.infinity, height: 40,
                                          child: OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(foregroundColor: Colors.green, side: const BorderSide(color: Colors.green)),
                                            onPressed: () { Navigator.pop(context); _showEditUserDialog(uid, collection, data); },
                                            icon: const Icon(Icons.autorenew), label: const Text('نوێکردنەوەی گرێبەست'),
                                          ),
                                        )
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              
                              // تابی 2: بەڵگەنامە و وێنەکان
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => _showUpdateDocumentsDialog(uid, collection, data), icon: const Icon(Icons.upload_file), label: const Text('دانان یان گۆڕینی لینکی بەڵگەنامەکان'))),
                                      const SizedBox(height: 20),
                                      if (collection == 'Drivers') ...[
                                        const Text('کارتی نیشتیمانی:', style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 5),
                                        _buildDocumentPreviewCard(data['national_id_image']),
                                        const SizedBox(height: 15),
                                        const Text('مۆڵەتی شۆفێری:', style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 5),
                                        _buildDocumentPreviewCard(data['driving_license_image']),
                                      ] else ...[
                                        const Text('لۆگۆ / وێنەی خوارنگەهـ:', style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 5),
                                        _buildDocumentPreviewCard(data['profile_image']),
                                      ]
                                    ],
                                  ),
                                ),
                              ),

                              // تابی 3: سکیورێتی
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red[200]!)),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('پاسۆردی ئێستا', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))]),
                                          Text(data['plain_password'] ?? 'نەزانراوە', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => _showChangePasswordDialog(uid, collection, data['phone']), icon: const Icon(Icons.lock_reset, color: Colors.red), label: const Text('پێدانی پاسۆردی نوێ', style: TextStyle(color: Colors.red)))),
                                    const Divider(height: 30),
                                    
                                    SizedBox(width: double.infinity, height: 45, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: isActive ? Colors.orange : Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () => _showBanOptionsDialog(uid, collection, data['name'], isActive), icon: Icon(isActive ? Icons.block : Icons.check_circle), label: Text(isActive ? 'سڕکردنی هەژمار (Temp Ban)' : 'لابردنی باند (چالاککردنەوە)', style: const TextStyle(fontSize: 16)))),
                                    const SizedBox(height: 15),
                                    
                                    SizedBox(width: double.infinity, height: 45, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: isArchived ? Colors.green : Colors.indigo, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () => _archiveUser(uid, collection, data['name'], isArchived), icon: Icon(isArchived ? Icons.unarchive : Icons.archive), label: Text(isArchived ? 'هێنانەدەرەوە لە ئەرشیف' : 'خستنە ئەرشیفەوە', style: const TextStyle(fontSize: 16)))),
                                    const SizedBox(height: 15),

                                    SizedBox(width: double.infinity, height: 45, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () { Navigator.pop(context); _deleteUser(uid, collection, data['name']); }, icon: const Icon(Icons.delete_forever), label: const Text('سڕینەوەی یەکجاری', style: TextStyle(fontSize: 16)))),
                                  ],
                                ),
                              ),

                              // تابی 4: زانیاری کەسی و دەستبەکاربوون
                              ListView(
                                padding: const EdgeInsets.all(20),
                                children: [
                                  ListTile(leading: const Icon(Icons.phone), title: const Text('ژمارە مۆبایل'), subtitle: Text(data['phone'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                                  const Divider(),
                                  ListTile(leading: const Icon(Icons.email), title: const Text('ئیمەیڵی لۆگین'), subtitle: Text('${data['phone']}@ordarat.com', style: const TextStyle(fontSize: 16))),
                                  const Divider(),
                                  Container(
                                    padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.brown[50], borderRadius: BorderRadius.circular(10)),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.history_edu, color: Colors.brown, size: 30),
                                        const SizedBox(width: 15),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(collection == 'Drivers' ? 'بەرواری دامەزراندن' : 'بەرواری پەیوەندی بە کۆمپانیا', style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
                                            Text(joinDate.isNotEmpty ? joinDate : 'دیاری نەکراوە', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 5),
                                            Text('ماوەی خزمەت: $serviceDuration', style: const TextStyle(color: Colors.brown, fontSize: 12, fontWeight: FontWeight.bold)),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ],
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

  Widget _buildDocumentPreviewCard(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        height: 150, width: double.infinity,
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[400]!, style: BorderStyle.solid)),
        child: const Center(child: Text('هێشتا وێنە دانەنراوە', style: TextStyle(color: Colors.grey))),
      );
    }
    return Container(
      height: 200, width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.indigo[200]!), image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)),
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
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  // --- مێشکی ڕیزکردنی زیرەک ---
  Widget _buildUserList(String collection) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        var allDocs = snapshot.data!.docs.toList();
        
        // جێبەجێکردنی فلتەری ڕیزکردن (کۆنترین، نوێترین، زۆرترین ئۆردەر)
        allDocs.sort((a, b) {
          var dataA = a.data() as Map<String, dynamic>;
          var dataB = b.data() as Map<String, dynamic>;
          
          if (_selectedSort == 'زۆرترین ئۆردەر') {
            int ordersA = dataA['completed_orders'] ?? 0;
            int ordersB = dataB['completed_orders'] ?? 0;
            return ordersB.compareTo(ordersA); // ڕیزکردن لە زۆرەوە بۆ کەم
          } else {
            String dateA = dataA['join_date'] ?? '';
            String dateB = dataB['join_date'] ?? '';
            
            // ئەگەر بەرواری دەستبەکاربوون نەبوو، کاتی دروستبوونی ئەکاونت بەکاربهێنە
            if (dateA.isEmpty && dataA['created_at'] != null) {
              dateA = DateFormat('yyyy-MM-dd').format((dataA['created_at'] as Timestamp).toDate());
            }
            if (dateB.isEmpty && dataB['created_at'] != null) {
              dateB = DateFormat('yyyy-MM-dd').format((dataB['created_at'] as Timestamp).toDate());
            }

            if (_selectedSort == 'کۆنترین') {
              return dateA.compareTo(dateB); // ڕیزکردن لە کۆنەوە بۆ نوێ
            } else {
              return dateB.compareTo(dateA); // ڕیزکردن لە نوێەوە بۆ کۆن (دیفۆڵت)
            }
          }
        });

        var docs = allDocs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String name = (data['name'] ?? '').toString().toLowerCase();
          String phone = (data['phone'] ?? '').toString();
          String city = data['city'] ?? '';
          bool isArchived = data['is_archived'] ?? false;
          
          if (isArchived != _showArchived) return false;

          bool matchesCity = _selectedCityFilter == 'هەموو شارەکان' || city == _selectedCityFilter;
          bool matchesSearch = name.contains(_searchQuery.toLowerCase()) || phone.contains(_searchQuery);
          
          return matchesCity && matchesSearch;
        }).toList();

        if (docs.isEmpty) return Center(child: Text(_showArchived ? 'هیچ ئەکاونتێک لە ئەرشیفدا نییە' : 'هیچ داتایەک نەدۆزرایەوە', style: const TextStyle(color: Colors.grey, fontSize: 18)));

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
            
            // هێنانی بەرواری دەستبەکاربوون بۆ لیستی دەرەوە
            String joinDate = data['join_date'] ?? '';
            if (joinDate.isEmpty && data['created_at'] != null) {
              joinDate = DateFormat('yyyy-MM-dd').format((data['created_at'] as Timestamp).toDate());
            }
            
            bool isContractExpired = false;
            if (collection == 'Restaurants' && data['contract_end'] != null && data['contract_end'].toString().isNotEmpty) {
              try { if (DateTime.parse(data['contract_end']).isBefore(DateTime.now())) isContractExpired = true; } catch (e) {}
            }
            
            Widget? crown;
            if (!_showArchived && _selectedSort == 'زۆرترین ئۆردەر') {
               if (index == 0 && data['completed_orders'] > 0) crown = const Icon(Icons.workspace_premium, color: Colors.amber, size: 30); 
               else if (index == 1 && data['completed_orders'] > 0) crown = const Icon(Icons.workspace_premium, color: Colors.grey, size: 30); 
               else if (index == 2 && data['completed_orders'] > 0) crown = const Icon(Icons.workspace_premium, color: Colors.brown, size: 30); 
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 2,
              color: _showArchived ? Colors.grey[100] : Colors.white,
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
                    const SizedBox(height: 2),
                    Text('لەگەڵمانە لە: ${joinDate.isNotEmpty ? joinDate : 'نەزانراو'}', style: const TextStyle(color: Colors.brown, fontSize: 11, fontWeight: FontWeight.bold)),
                    
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
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _selectedCityFilter,
                    decoration: InputDecoration(filled: true, fillColor: Colors.blue[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                    items: _cities.map((String val) => DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)))).toList(),
                    onChanged: (newVal) => setState(() => _selectedCityFilter = newVal!),
                  ),
                ),
                const SizedBox(width: 10),
                // فلتەری نوێ بۆ ڕیزکردن (کۆنترین، نوێترین)
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _selectedSort,
                    decoration: InputDecoration(filled: true, fillColor: Colors.amber[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                    items: _sortOptions.map((String val) => DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 12)))).toList(),
                    onChanged: (newVal) => setState(() => _selectedSort = newVal!),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(15), foregroundColor: _showArchived ? Colors.white : Colors.indigo, backgroundColor: _showArchived ? Colors.indigo : Colors.white),
                  onPressed: () => setState(() => _showArchived = !_showArchived),
                  icon: Icon(_showArchived ? Icons.folder_special : Icons.archive),
                  label: Text(_showArchived ? 'گەڕانەوە' : 'ئەرشیف'),
                ),
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
                Stack(children: [_buildUserList('Drivers'), if (!_showArchived) Positioned(bottom: 20, right: 20, child: FloatingActionButton.extended(heroTag: 'd', onPressed: () => _showAddUserDialog('Drivers'), icon: const Icon(Icons.add), label: const Text('شۆفێری نوێ'), backgroundColor: Colors.blue))]),
                Stack(children: [_buildUserList('Restaurants'), if (!_showArchived) Positioned(bottom: 20, right: 20, child: FloatingActionButton.extended(heroTag: 'r', onPressed: () => _showAddUserDialog('Restaurants'), icon: const Icon(Icons.add), label: const Text('خوارنگەهی نوێ'), backgroundColor: Colors.orange))]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
