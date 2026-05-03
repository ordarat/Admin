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

  // شاشەی دروستکردن یان دەستکاریکردنی شەفت
  void _showShiftFormDialog({String? docId, Map<String, dynamic>? existingData}) {
    bool isEditing = docId != null;
    
    final TextEditingController nameCtrl = TextEditingController(text: isEditing ? existingData!['name'] : '');
    final TextEditingController maxDriversCtrl = TextEditingController(text: isEditing ? (existingData!['max_capacity'] ?? 50).toString() : '50');
    final TextEditingController bonusCtrl = TextEditingController(text: isEditing ? (existingData!['bonus_amount'] ?? 0).toString() : '0');
    
    TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 16, minute: 0);

    if (isEditing && existingData!['start_time'] != null) {
      try {
        var parts = existingData['start_time'].split(':');
        startTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (e) {}
    }
    if (isEditing && existingData!['end_time'] != null) {
      try {
        var parts = existingData['end_time'].split(':');
        endTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (e) {}
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            
            Future<void> pickTime(bool isStart) async {
              TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: isStart ? startTime : endTime,
                builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Colors.indigo)), child: child!),
              );
              if (picked != null) {
                setStateDialog(() {
                  if (isStart) startTime = picked;
                  else endTime = picked;
                });
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(isEditing ? 'دەستکاریکردنی شەفت' : 'دروستکردنی شەفتی نوێ', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('زانیارییە سەرەکییەکان', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 10),
                      TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ناوی شەفت (نموونە: بەیانیان)', prefixIcon: Icon(Icons.work))),
                      const SizedBox(height: 15),
                      
                      const Text('کاتی کارکردن', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: OutlinedButton.icon(onPressed: () => pickTime(true), icon: const Icon(Icons.wb_sunny, color: Colors.orange), label: Text('لە: ${startTime.format(context)}'))),
                          const SizedBox(width: 10),
                          Expanded(child: OutlinedButton.icon(onPressed: () => pickTime(false), icon: const Icon(Icons.nights_stay, color: Colors.indigo), label: Text('تا: ${endTime.format(context)}'))),
                        ],
                      ),
                      const SizedBox(height: 15),

                      const Text('رێکخستنە پێشکەوتووەکان', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 10),
                      TextField(controller: maxDriversCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'گەورەترین توانای شۆفێر (Max Capacity)', prefixIcon: Icon(Icons.groups))),
                      const SizedBox(height: 10),
                      TextField(controller: bonusCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'پاداشتی شەفت بۆ هەر ئۆردەرێک (بە دینار)', prefixIcon: Icon(Icons.attach_money, color: Colors.green))),
                      const SizedBox(height: 5),
                      const Text('تێبینی: ئەگەر ئەمە شەفتی شەوانە، دەتوانیت ٥٠٠ دینار بنووسیت بۆ هاندانی شۆفێران.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('پاشگەزبوونەوە', style: TextStyle(color: Colors.red))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty) return;
                    Navigator.pop(context);

                    Map<String, dynamic> shiftData = {
                      'name': nameCtrl.text.trim(),
                      'start_time': '${startTime.hour}:${startTime.minute}',
                      'end_time': '${endTime.hour}:${endTime.minute}',
                      'max_capacity': int.tryParse(maxDriversCtrl.text) ?? 50,
                      'bonus_amount': int.tryParse(bonusCtrl.text) ?? 0,
                      'is_active': existingData?['is_active'] ?? true,
                    };

                    if (isEditing) {
                      await FirebaseFirestore.instance.collection('Shifts').doc(docId).update(shiftData);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شەفتەکە نوێکرایەوە!'), backgroundColor: Colors.blue));
                    } else {
                      shiftData['created_at'] = FieldValue.serverTimestamp();
                      await FirebaseFirestore.instance.collection('Shifts').add(shiftData);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شەفتەکە بە سەرکەوتوویی دروست کرا!'), backgroundColor: Colors.green));
                    }
                  },
                  child: Text(isEditing ? 'سەیڤکردن' : 'دروستکردن'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _toggleShiftStatus(String docId, bool currentStatus) async {
    await FirebaseFirestore.instance.collection('Shifts').doc(docId).update({'is_active': !currentStatus});
  }

  void _deleteShift(String docId, String shiftName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('سڕینەوەی شەفت!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text('ئایا دڵنیایت دەتەوێت شەفتی ($shiftName) بسڕیتەوە؟ تێبینی: ئەگەر شۆفێر لەم شەفتەدا بن، دەبێت سەرەتا شەفتەکانیان بگۆڕیت.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('نەخێر')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance.collection('Shifts').doc(docId).delete();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شەفتەکە سڕایەوە.'), backgroundColor: Colors.red));
            },
            child: const Text('بەڵێ، بیسڕەوە'),
          ),
        ],
      ),
    );
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('سیستەمی زیرەکی شەفتەکان', style: TextStyle(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E2C))),
                    const SizedBox(height: 5),
                    const Text('بەڕێوەبردنی کاتەکان، توانای شۆفێران، و پاداشتی گەیاندن', style: TextStyle(color: Colors.grey)),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
                  onPressed: () => _showShiftFormDialog(),
                  icon: const Icon(Icons.add_circle),
                  label: const Text('شەفتی نوێ', style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const SizedBox(height: 30),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('Shifts').orderBy('created_at', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Center(child: Text('هەڵەیەک روویدا لە هێنانی داتاکان.'));
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  var docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 15),
                          const Text('هیچ شەفتێک نەدۆزرایەوە', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 1 : 3,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: isMobile ? 1.8 : 1.5,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      String docId = docs[index].id;
                      String shiftName = data['name'] ?? 'بێ ناو';
                      bool isActive = data['is_active'] ?? true;
                      int bonus = data['bonus_amount'] ?? 0;
                      int maxCapacity = data['max_capacity'] ?? 50;

                      String formatTimeStr(String? timeStr) {
                        if (timeStr == null) return '--:--';
                        var parts = timeStr.split(':');
                        var tod = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
                        // لێرەدا دەتوانیت format(context) بەکاربهێنیت یان تەنها string
                        return '${tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod}:${tod.minute.toString().padLeft(2, '0')} ${tod.period == DayPeriod.am ? 'AM' : 'PM'}';
                      }

                      String timeRange = '${formatTimeStr(data['start_time'])} بۆ ${formatTimeStr(data['end_time'])}';

                      // هێنانی ژمارەی ئەو شۆفێرانەی لەم شەفتەدان ڕاستەوخۆ لە داتابەیسەوە
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('Drivers').where('shift', isEqualTo: shiftName).snapshots(),
                        builder: (context, driverSnap) {
                          int currentDrivers = driverSnap.hasData ? driverSnap.data!.docs.length : 0;
                          bool isFull = currentDrivers >= maxCapacity;

                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isActive ? Colors.transparent : Colors.grey[300]!, width: 2),
                                color: isActive ? Colors.white : Colors.grey[100],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(color: isActive ? Colors.indigo[50] : Colors.grey[200], shape: BoxShape.circle),
                                          child: Icon(Icons.work_history, color: isActive ? Colors.indigo : Colors.grey, size: 30),
                                        ),
                                        Row(
                                          children: [
                                            Switch(value: isActive, activeColor: Colors.green, onChanged: (val) => _toggleShiftStatus(docId, isActive)),
                                            PopupMenuButton<String>(
                                              onSelected: (value) {
                                                if (value == 'edit') _showShiftFormDialog(docId: docId, existingData: data);
                                                if (value == 'delete') _deleteShift(docId, shiftName);
                                              },
                                              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                                const PopupMenuItem<String>(value: 'edit', child: ListTile(leading: Icon(Icons.edit, color: Colors.blue), title: Text('دەستکاری'))),
                                                const PopupMenuItem<String>(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('سڕینەوە'))),
                                              ],
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                    const Spacer(),
                                    Text(shiftName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isActive ? Colors.black : Colors.grey)),
                                    const SizedBox(height: 5),
                                    Row(children: [const Icon(Icons.access_time, size: 16, color: Colors.grey), const SizedBox(width: 5), Text(timeRange, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))]),
                                    const SizedBox(height: 15),
                                    
                                    const Divider(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('توانای شۆفێران', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                            Text('$currentDrivers / $maxCapacity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isFull ? Colors.red : Colors.green)),
                                          ],
                                        ),
                                        if (bonus > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green[200]!)),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.stars, color: Colors.green, size: 16),
                                                const SizedBox(width: 5),
                                                Text('+$bonus IQD', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
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
  }
}
