// Path: lib/screens/employees_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final Color primaryBlue = const Color(0xFF0056D2);
  bool _isLoading = false;

  final Map<String, String> _allPermissions = {
    'dashboard': 'شاشەی داشبۆرد',
    'orders': 'بۆردی ئۆردەرەکان',
    'users': 'بەڕێوەبردنی بەکارهێنەران',
    'map': 'نەخشەی راستەوخۆ',
    'finance': 'راپۆرتی دارایی و قازانج',
    'settings': 'رێکخستنەکانی سیستەم',
  };

  void _showEmployeeFormDialog({String? uid, Map<String, dynamic>? existingData}) {
    bool isEditing = uid != null;
    
    final TextEditingController nameCtrl = TextEditingController(text: isEditing ? existingData!['name'] : '');
    final TextEditingController emailCtrl = TextEditingController(text: isEditing ? existingData!['email'] : '');
    final TextEditingController passCtrl = TextEditingController(text: isEditing ? existingData!['plain_password'] : '');
    
    bool isSuperAdmin = isEditing ? (existingData!['role'] == 'admin') : false;
    
    Map<String, bool> userPermissions = {};
    _allPermissions.forEach((key, _) {
      if (isEditing && existingData!['permissions'] != null) {
        userPermissions[key] = existingData['permissions'][key] ?? false;
      } else {
        userPermissions[key] = false;
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(isEditing ? 'گۆڕانکاری لە دەسەڵاتەکانی کارمەند' : 'دروستکردنی کارمەندی نوێ', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 450,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ناوی کارمەند', prefixIcon: Icon(Icons.person))),
                      const SizedBox(height: 10),
                      TextField(controller: emailCtrl, enabled: !isEditing, decoration: InputDecoration(labelText: 'ئیمەیڵ', prefixIcon: const Icon(Icons.email), filled: isEditing, fillColor: Colors.grey[200])),
                      const SizedBox(height: 10),
                      TextField(controller: passCtrl, enabled: !isEditing, decoration: InputDecoration(labelText: 'وشەی نهێنی', prefixIcon: const Icon(Icons.lock), filled: isEditing, fillColor: Colors.grey[200])),
                      const SizedBox(height: 20),
                      
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.purple[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.purple[200]!)),
                        child: SwitchListTile(
                          title: const Text('سەڵاحییەتی رەها (Super Admin)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                          subtitle: const Text('دەتوانێت هەموو شتێک ببینێت بێ سنوور'),
                          value: isSuperAdmin,
                          activeColor: Colors.purple,
                          onChanged: (val) => setStateDialog(() => isSuperAdmin = val),
                        ),
                      ),
                      
                      if (!isSuperAdmin) ...[
                        const SizedBox(height: 15),
                        const Text('دەسەڵاتەکان (دیاری بکە چ شاشەیەک ببینێت):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                        const Divider(),
                        ..._allPermissions.entries.map((entry) {
                          return CheckboxListTile(
                            title: Text(entry.value),
                            value: userPermissions[entry.key],
                            activeColor: Colors.green,
                            onChanged: (val) {
                              setStateDialog(() {
                                userPermissions[entry.key] = val ?? false;
                              });
                            },
                          );
                        }),
                      ]
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('پاشگەزبوونەوە', style: TextStyle(color: Colors.red))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: isEditing ? Colors.blue : Colors.green, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty || passCtrl.text.isEmpty) return;
                    Navigator.pop(context);
                    
                    // لێرەدا کێشەکەمان چارەسەر کرد و نیشانەی (!)مان لابرد
                    if (isEditing && uid != null) {
                      await _updateEmployee(uid, nameCtrl.text, isSuperAdmin, userPermissions);
                    } else {
                      await _createEmployeeAccount(nameCtrl.text, emailCtrl.text, passCtrl.text, isSuperAdmin, userPermissions);
                    }
                  },
                  child: Text(isEditing ? 'سەیڤکردنی گۆڕانکاری' : 'دروستکردن'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _createEmployeeAccount(String name, String email, String pass, bool isSuperAdmin, Map<String, bool> permissions) async {
    setState(() => _isLoading = true);
    try {
      FirebaseApp tempApp = await Firebase.initializeApp(name: 'TempAdminApp', options: Firebase.app().options);
      UserCredential userCred = await FirebaseAuth.instanceFor(app: tempApp).createUserWithEmailAndPassword(email: email.trim(), password: pass.trim());
      String newUid = userCred.user!.uid;

      await FirebaseFirestore.instance.collection('Admins').doc(newUid).set({
        'name': name.trim(),
        'email': email.trim(),
        'plain_password': pass.trim(),
        'role': isSuperAdmin ? 'admin' : 'staff',
        'permissions': isSuperAdmin ? null : permissions,
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
      });

      await tempApp.delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('کارمەندەکە بە سەرکەوتوویی دروست کرا!'), backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('هەڵەیەک روویدا: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateEmployee(String employeeId, String name, bool isSuperAdmin, Map<String, bool> permissions) async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('Admins').doc(employeeId).update({
        'name': name.trim(),
        'role': isSuperAdmin ? 'admin' : 'staff',
        'permissions': isSuperAdmin ? null : permissions,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('دەسەڵاتەکان گۆڕدران!'), backgroundColor: Colors.blue));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('هەڵە لە گۆڕانکاری: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleEmployeeStatus(String uid, bool currentStatus) async {
    await FirebaseFirestore.instance.collection('Admins').doc(uid).update({'is_active': !currentStatus});
  }

  Future<void> _deleteEmployee(String uid) async {
    await FirebaseFirestore.instance.collection('Admins').doc(uid).delete();
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 15.0 : 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('بەڕێوەبردنی کارمەندان و دەسەڵاتەکان', style: TextStyle(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E2C))),
            const SizedBox(height: 10),
            const Text('دەتوانیت بۆ هەر کارمەندێک بە دەستی خۆت دیاری بکەیت چ شاشەیەک ببینێت.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            
            if (_isLoading) const Center(child: LinearProgressIndicator()),
            const SizedBox(height: 10),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('Admins').orderBy('created_at', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  var docs = snapshot.data!.docs;

                  if (docs.isEmpty) return const Center(child: Text('هیچ کارمەندێک نییە', style: TextStyle(color: Colors.grey)));

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      String docId = docs[index].id;
                      bool isActive = data['is_active'] ?? true;
                      bool isAdmin = data['role'] == 'admin';

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(15),
                          leading: CircleAvatar(
                            radius: 30,
                            backgroundColor: isAdmin ? Colors.purple[100] : Colors.blue[100],
                            child: Icon(isAdmin ? Icons.admin_panel_settings : Icons.support_agent, color: isAdmin ? Colors.purple : Colors.blue, size: 30),
                          ),
                          title: Text(data['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isActive ? Colors.black : Colors.red, decoration: isActive ? TextDecoration.none : TextDecoration.lineThrough)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 5),
                              Text('ئیمەیڵ: ${data['email']} | پاسۆرد: ${data['plain_password']}'),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(color: isAdmin ? Colors.purple[50] : Colors.blue[50], borderRadius: BorderRadius.circular(5)),
                                child: Text(isAdmin ? 'سەڵاحییەت: بەڕێوەبەری سەرەکی (Admin)' : 'سەڵاحییەت: کارمەندی دیاریکراو', style: TextStyle(color: isAdmin ? Colors.purple : Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'گۆڕینی دەسەڵاتەکانی ئەم کارمەندە',
                                icon: const Icon(Icons.edit_note, color: Colors.blue, size: 30),
                                onPressed: () => _showEmployeeFormDialog(uid: docId, existingData: data),
                              ),
                              const SizedBox(width: 10),
                              Switch(value: isActive, activeColor: Colors.green, onChanged: (val) => _toggleEmployeeStatus(docId, isActive)),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deleteEmployee(docId)),
                            ],
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryBlue,
        onPressed: () => _showEmployeeFormDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('کارمەندی نوێ', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
