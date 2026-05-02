// Path: lib/screens/manage_shifts.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageShiftsScreen extends StatefulWidget {
  const ManageShiftsScreen({super.key});

  @override
  State<ManageShiftsScreen> createState() => _ManageShiftsScreenState();
}

class _ManageShiftsScreenState extends State<ManageShiftsScreen> {
  final Color primaryBlue = const Color(0xFF0056D2);

  // فەنکشنی هەڵبژاردنی کاتژمێر
  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Colors.indigo)),
          child: child!,
        );
      },
    );
    if (picked != null && context.mounted) {
      controller.text = picked.format(context);
    }
  }

  // پەنجەرەی دروستکردن یان دەستکاریکردنی شەفت
  void _showShiftDialog({String? docId, Map<String, dynamic>? existingData}) {
    final TextEditingController nameCtrl = TextEditingController(text: existingData?['name'] ?? '');
    final TextEditingController startCtrl = TextEditingController(text: existingData?['start_time'] ?? '');
    final TextEditingController endCtrl = TextEditingController(text: existingData?['end_time'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(docId == null ? 'دروستکردنی شەفتی نوێ' : 'گۆڕینی کاتەکانی شەفت', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ناوی شەفت (نموونە: شەفتی بەیانیان)', prefixIcon: Icon(Icons.title))),
              const SizedBox(height: 15),
              TextField(
                controller: startCtrl, readOnly: true,
                onTap: () => _selectTime(context, startCtrl),
                decoration: const InputDecoration(labelText: 'کاتژمێری دەستپێك', prefixIcon: Icon(Icons.timer, color: Colors.green)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: endCtrl, readOnly: true,
                onTap: () => _selectTime(context, endCtrl),
                decoration: const InputDecoration(labelText: 'کاتژمێری کۆتایی هاتن', prefixIcon: Icon(Icons.timer_off, color: Colors.red)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('پاشگەزبوونەوە', style: TextStyle(color: Colors.red))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              onPressed: () async {
                if (nameCtrl.text.isEmpty || startCtrl.text.isEmpty || endCtrl.text.isEmpty) return;
                Navigator.pop(context);
                
                if (docId == null) {
                  // شەفتی نوێ
                  await FirebaseFirestore.instance.collection('Shifts').add({
                    'name': nameCtrl.text.trim(),
                    'start_time': startCtrl.text.trim(),
                    'end_time': endCtrl.text.trim(),
                    'created_at': FieldValue.serverTimestamp(),
                  });
                } else {
                  // نوێکردنەوەی شەفتی کۆن
                  await FirebaseFirestore.instance.collection('Shifts').doc(docId).update({
                    'name': nameCtrl.text.trim(),
                    'start_time': startCtrl.text.trim(),
                    'end_time': endCtrl.text.trim(),
                  });
                }
              },
              child: const Text('سەیڤکردن'),
            ),
          ],
        );
      },
    );
  }

  // پەنجەرەی هەڵبژاردنی شۆفێران بۆ ناو ئەم شەفتە
  void _showAssignDriversDialog(String shiftId, String shiftName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('دیاریکردنی شۆفێران بۆ: $shiftName', style: const TextStyle(color: Colors.indigo, fontSize: 16, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 400, height: 500,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Drivers').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var drivers = snapshot.data!.docs;
                if (drivers.isEmpty) return const Center(child: Text('هیچ شۆفێرێک نییە.'));

                return ListView.builder(
                  itemCount: drivers.length,
                  itemBuilder: (context, index) {
                    var driverData = drivers[index].data() as Map<String, dynamic>;
                    String driverId = drivers[index].id;
                    String currentShiftId = driverData['shift_id'] ?? '';
                    bool isInThisShift = currentShiftId == shiftId;

                    return CheckboxListTile(
                      title: Text(driverData['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(isInThisShift ? 'لەناو ئەم شەفتەدایە ✅' : 'سەر بە شەفتێکی ترە یان ئازادە'),
                      value: isInThisShift,
                      activeColor: Colors.green,
                      onChanged: (val) async {
                        // راستەوخۆ لەناو فایەربەیس دەیگۆڕێت کە کلیکی لێ دەکەیت
                        if (val == true) {
                          await FirebaseFirestore.instance.collection('Drivers').doc(driverId).update({'shift_id': shiftId, 'shift': shiftName});
                        } else {
                          await FirebaseFirestore.instance.collection('Drivers').doc(driverId).update({'shift_id': FieldValue.delete(), 'shift': 'کاتی ئازاد'});
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context),
              child: const Text('تەواو'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteShift(String docId) async {
    await FirebaseFirestore.instance.collection('Shifts').doc(docId).delete();
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
            Text('بەڕێوەبردنی شەفتەکان', style: TextStyle(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E2C))),
            const SizedBox(height: 10),
            const Text('لێرە دەتوانیت کاتی شەفتەکان دیاری بکەیت و شۆفێرەکان دابەش بکەیت.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('Shifts').orderBy('created_at', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  var shifts = snapshot.data!.docs;

                  if (shifts.isEmpty) {
                    return const Center(child: Text('هیچ شەفتێک دروست نەکراوە.', style: TextStyle(color: Colors.grey, fontSize: 18)));
                  }

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 1 : 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: isMobile ? 2.5 : 3.0,
                    ),
                    itemCount: shifts.length,
                    itemBuilder: (context, index) {
                      var data = shifts[index].data() as Map<String, dynamic>;
                      String shiftId = shifts[index].id;

                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(data['name'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
                                  Row(
                                    children: [
                                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showShiftDialog(docId: shiftId, existingData: data)),
                                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteShift(shiftId)),
                                    ],
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
                                child: Text('لە: ${data['start_time']}  تاوەکو: ${data['end_time']}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                  onPressed: () => _showAssignDriversDialog(shiftId, data['name']),
                                  icon: const Icon(Icons.people),
                                  label: const Text('دیاریکردنی شۆفێران بۆ ئەم شەفتە'),
                                ),
                              ),
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
        onPressed: () => _showShiftDialog(),
        icon: const Icon(Icons.add),
        label: const Text('دروستکردنی شەفت', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
