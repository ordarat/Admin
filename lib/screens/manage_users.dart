import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  
  String _selectedRole = 'خوارنگەهـ'; // یان 'شۆفێر'
  bool _isLoading = false;

  Future<void> _createNewAccount() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تکایە خانە سەرەکییەکان پڕبکەرەوە!'), backgroundColor: Colors.red));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // ١. رێکخستنی ژمارە و ئیمەیڵ بۆ ئەوەی لەگەڵ مۆبایلەکە یەکبگرێتەوە
      String phoneInput = _phoneController.text.trim();
      String finalPhone = phoneInput.startsWith('0') ? phoneInput : '0$phoneInput';
      String finalEmail = "$finalPhone@company.com";
      String password = _passwordController.text.trim();

      // ٢. دروستکردنی فایەربەیسی کاتی بۆ ئەوەی ئەدمینەکە لۆگئاوت نەبێت! (تایبەتمەندی پرۆفێشناڵ)
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'TempApp_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      // دروستکردنی هەژمارەکە لە فایەربەیسی کاتی
      UserCredential userCred = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(email: finalEmail, password: password);

      String newUid = userCred.user!.uid;

      // ٣. خەزنکردنی داتاکان لە داتابەیس بەو شێوەیەی مۆبایلەکە دەیخوێنێتەوە
      if (_selectedRole == 'شۆفێر') {
        await FirebaseFirestore.instance.collection('Drivers').doc(newUid).set({
          'name': _nameController.text.trim(),
          'phone': finalPhone,
          'profile_image': _imageController.text.trim(),
          'is_active': true,           // زۆر گرنگە بۆ چوونەژوورەوەی مۆبایل
          'wallet_balance': 0,         // باڵانسی سەرەتایی
          'completed_orders': 0,       // بۆ سیستەمی خەڵات و ریزبەندی
          'role': 'driver',
          'created_at': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseFirestore.instance.collection('Restaurants').doc(newUid).set({
          'name': _nameController.text.trim(),
          'phone': finalPhone,
          'profile_image': _imageController.text.trim(),
          'is_active': true,           // زۆر گرنگە
          'wallet_balance': 0,
          'role': 'restaurant',
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      // سڕینەوەی فایەربەیسە کاتییەکە
      await tempApp.delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هەژمارەکە بە سەرکەوتوویی دروست کرا!'), backgroundColor: Colors.green));
      
      // پاککردنەوەی خانەکان
      _nameController.clear();
      _phoneController.clear();
      _passwordController.clear();
      _imageController.clear();

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ئەم ژمارە مۆبایلە پێشتر تۆمار کراوە!'), backgroundColor: Colors.orange));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('هەڵە: ${e.message}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('کێشەیەک روویدا: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------- بەشی چەپ: فۆڕمی دروستکردن ----------------
          Expanded(
            flex: 1,
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('دروستکردنی هەژماری نوێ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: ['خوارنگەهـ', 'شۆفێر'].map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                      onChanged: (val) => setState(() => _selectedRole = val!),
                    ),
                    const SizedBox(height: 15),
                    
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'ناو', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 15),
                    
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'ژمارەی مۆبایل', border: OutlineInputBorder()),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 15),
                    
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'وشەی نهێنی', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 15),
                    
                    TextField(
                      controller: _imageController,
                      decoration: const InputDecoration(labelText: 'لینکی وێنەی پڕۆفایل', border: OutlineInputBorder(), prefixIcon: Icon(Icons.link)),
                    ),
                    const SizedBox(height: 25),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        onPressed: _isLoading ? null : _createNewAccount,
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('تۆمارکردن', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 20),
          
          // ---------------- بەشی راست: لیستی چالاکەکان ----------------
          Expanded(
            flex: 2,
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('لیستی چالاکەکان', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(20)),
                          child: const Row(
                            children: [
                              Icon(Icons.stop_circle, color: Colors.red, size: 16),
                              SizedBox(width: 5),
                              Text('پیشاندانی ناچالاکەکان', style: TextStyle(color: Colors.red, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 30, thickness: 1),
                    
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection(_selectedRole == 'شۆفێر' ? 'Drivers' : 'Restaurants').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                          var docs = snapshot.data!.docs;
                          
                          if (docs.isEmpty) return const Center(child: Text('هیچ بەکارهێنەرێک نییە', style: TextStyle(color: Colors.grey)));

                          return ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              var data = docs[index].data() as Map<String, dynamic>;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: data['profile_image'] != null && data['profile_image'].toString().isNotEmpty ? NetworkImage(data['profile_image']) : null,
                                  child: data['profile_image'] == null || data['profile_image'].toString().isEmpty ? Icon(_selectedRole == 'شۆفێر' ? Icons.motorcycle : Icons.restaurant) : null,
                                ),
                                title: Text(data['name'] ?? 'بێ ناو'),
                                subtitle: Text(data['phone'] ?? ''),
                                trailing: Icon(data['is_active'] == true ? Icons.check_circle : Icons.cancel, color: data['is_active'] == true ? Colors.green : Colors.red),
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
          ),
        ],
      ),
    );
  }
}
