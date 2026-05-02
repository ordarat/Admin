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

  // پەنجەرەی دروستکردنی کارمەندی نوێ
  void _showAddEmployeeDialog() {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController emailCtrl = TextEditingController();
    final TextEditingController passCtrl = TextEditingController();
    String selectedRole = 'support'; // دیفۆڵت: کارمەندی ئاسایی

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('دروستکردنی هەژماری کارمەند', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ناوی کارمەند', prefixIcon: Icon(Icons.person))),
                      const SizedBox(height: 10),
                      TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'ئیمەیڵ', prefixIcon: Icon(Icons.email))),
                      const SizedBox(height: 10),
                      TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'وشەی نهێنی (لانی کەم ٦ پیت)', prefixIcon: Icon(Icons.lock))),
                      const SizedBox(height: 20),
                      
                      const Align(alignment: Alignment.centerRight, child: Text('جۆری سەڵاحییەت:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                      RadioListTile(
                        title: const Text('بەڕێوەبەر (Admin)'),
                        subtitle: const Text('دەسەڵاتی بەسەر هەموو شتێکدا هەیە', style: TextStyle(fontSize: 12)),
                        value: 'admin',
                        groupValue: selectedRole,
                        onChanged: (val) => setStateDialog(() => selectedRole = val.toString()),
                      ),
                      RadioListTile(
                        title: const Text('چاودێر / پاڵپشتی (Support)'),
                        subtitle: const Text('تەنها دەتوانێت ئۆردەر و نەخشە و بەکارهێنەران ببینێت', style: TextStyle(fontSize: 12)),
                        value: 'support',
                        groupValue: selectedRole,
                        onChanged: (val) => setStateDialog(() => selectedRole = val.toString()),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('پاشگەزبوونەوە', style: TextStyle(color: Colors.red))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty || passCtrl.text.isEmpty) return;
                    Navigator.pop(context);
                    await _createEmployeeAccount(nameCtrl.text, emailCtrl.text, passCtrl.text, selectedRole);
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

  // مێشکی دروستکردنی هەژمارەکە لە فایەربەیس
  Future<void> _createEmployeeAccount(String name, String email, String pass, String role) async {
    setState(() => _isLoading = true);
    try {
      // بەکارهێنانی Appی کاتی بۆ ئەوەی ئەدمینە سەرەکییەکە لۆگئاوت نەبێت
      FirebaseApp tempApp = await Firebase.initializeApp(name: 'TempAdminApp', options: Firebase.app().options);
      UserCredential userCred = await FirebaseAuth.instanceFor(app: tempApp).createUserWithEmailAndPassword(email: email.trim(), password: pass.trim());
      String newUid = userCred.user!.uid;

      await FirebaseFirestore.instance.collection('Admins').doc(newUid).set({
        'name': name.trim(),
        'email': email.trim(),
        'plain_password': pass.trim(),
        'role': role,
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
      });

      await tempApp.delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('کارمەندەکە بە سەرکەوتوویی زیاد کرا!'), backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('هەڵەیەک روویدا: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // سڕینەوە یان راگرتنی هەژمار
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
            Text('بەڕێوەبردنی کارمەندان', style: TextStyle(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E2C))),
            const SizedBox(height: 10),
            const Text('لێرە دەتوانیت هەژمار بۆ کارمەندەکانت دروست بکەیت و سەڵاحییەتیان پێ بدەیت.', style: TextStyle(color: Colors.grey)),
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
                              Text('ئیمەیڵ: ${data['email']}'),
                              Text('پاسۆرد: ${data['plain_password']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(color: isAdmin ? Colors.purple[50] : Colors.blue[50], borderRadius: BorderRadius.circular(5)),
                                child: Text(isAdmin ? 'سەڵاحییەت: بەڕێوەبەر (Admin)' : 'سەڵاحییەت: چاودێر (Support)', style: TextStyle(color: isAdmin ? Colors.purple : Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
        onPressed: _showAddEmployeeDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('کارمەندی نوێ', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
