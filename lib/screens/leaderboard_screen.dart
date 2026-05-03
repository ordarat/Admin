// Path: lib/screens/leaderboard_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final Color primaryBlue = const Color(0xFF0056D2);

  // دیاریکردنی ئاست بەپێی ژمارەی ئۆردەر
  String _getUserLevel(int orders) {
    if (orders >= 100) return 'ئەفسانە 💎';
    if (orders >= 50) return 'پڕۆفێشناڵ 🥇';
    if (orders >= 20) return 'شارەزا 🥈';
    return 'ئاسایی 🥉';
  }

  // دیالۆگی پێدانی خەڵاتی دارایی بۆ یەکەمەکان
  void _showRewardDialog(List<QueryDocumentSnapshot> topUsers, String collection) {
    if (topUsers.isEmpty) return;

    final TextEditingController rank1Ctrl = TextEditingController(text: '10000');
    final TextEditingController rank2Ctrl = TextEditingController(text: '5000');
    final TextEditingController rank3Ctrl = TextEditingController(text: '2500');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.redeem, color: Colors.amber, size: 30),
            SizedBox(width: 10),
            Text('پاداشتکردنی پاڵەوانەکان', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('بڕی پاداشتەکە دیاری بکە، ڕاستەوخۆ دەچێتە سەر باڵانسەکەیان.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 15),
            if (topUsers.isNotEmpty) TextField(controller: rank1Ctrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'خەڵاتی یەکەم: ${topUsers[0]['name']}', prefixIcon: const Icon(Icons.looks_one, color: Colors.amber))),
            const SizedBox(height: 10),
            if (topUsers.length > 1) TextField(controller: rank2Ctrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'خەڵاتی دووەم: ${topUsers[1]['name']}', prefixIcon: const Icon(Icons.looks_two, color: Colors.grey))),
            const SizedBox(height: 10),
            if (topUsers.length > 2) TextField(controller: rank3Ctrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'خەڵاتی سێیەم: ${topUsers[2]['name']}', prefixIcon: const Icon(Icons.looks_3, color: Colors.brown))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('پاشگەزبوونەوە')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              
              if (topUsers.isNotEmpty) await _sendReward(topUsers[0].id, collection, double.tryParse(rank1Ctrl.text) ?? 0);
              if (topUsers.length > 1) await _sendReward(topUsers[1].id, collection, double.tryParse(rank2Ctrl.text) ?? 0);
              if (topUsers.length > 2) await _sendReward(topUsers[2].id, collection, double.tryParse(rank3Ctrl.text) ?? 0);

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('پاداشتەکان دابەشکران!'), backgroundColor: Colors.green));
            },
            child: const Text('ناردنی خەڵاتەکان'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendReward(String uid, String collection, double amount) async {
    if (amount <= 0) return;
    await FirebaseFirestore.instance.collection(collection).doc(uid).update({
      'wallet_balance': FieldValue.increment(amount)
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: EdgeInsets.all(isMobile ? 15.0 : 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ڕیزبەندی و خەڵاتەکان', style: TextStyle(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E2C))),
              const SizedBox(height: 5),
              const Text('کێبڕکێی شۆفێران و خوارنگەهەکان بۆ بەدەستهێنانی زۆرترین ئۆردەر', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: const TabBar(
                  labelColor: Colors.amber, unselectedLabelColor: Colors.grey, indicatorColor: Colors.amber, indicatorWeight: 4,
                  tabs: [Tab(icon: Icon(Icons.motorcycle), text: 'شۆفێران'), Tab(icon: Icon(Icons.restaurant), text: 'خوارنگەهەکان')],
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: TabBarView(
                  children: [
                    _buildLeaderboardTab('Drivers'),
                    _buildLeaderboardTab('Restaurants'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardTab(String collection) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).orderBy('completed_orders', descending: true).limit(50).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('هیچ داتایەک نییە'));

        // جیاکردنەوەی ٣ یەکەمەکان
        List<QueryDocumentSnapshot> top3 = docs.take(3).toList();
        List<QueryDocumentSnapshot> theRest = docs.skip(3).toList();

        return Column(
          children: [
            // دوگمەی خەڵاتکردن
            if (top3.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
                  onPressed: () => _showRewardDialog(top3, collection),
                  icon: const Icon(Icons.card_giftcard),
                  label: const Text('پاداشتکردنی یەکەمەکان', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            const SizedBox(height: 20),

            // سەکۆی پاڵەوانان (Podium)
            if (top3.isNotEmpty)
              SizedBox(
                height: 220,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (top3.length > 1) _buildPodiumPlace(top3[1], 2, 140, Colors.grey[300]!, Colors.grey[800]!),
                    _buildPodiumPlace(top3[0], 1, 180, Colors.amber[300]!, Colors.amber[900]!),
                    if (top3.length > 2) _buildPodiumPlace(top3[2], 3, 110, Colors.brown[300]!, Colors.brown[900]!),
                  ],
                ),
              ),
            
            const SizedBox(height: 30),
            
            // لیستی ئەوانی تر
            Expanded(
              child: ListView.builder(
                itemCount: theRest.length,
                itemBuilder: (context, index) {
                  var data = theRest[index].data() as Map<String, dynamic>;
                  int rank = index + 4;
                  int orders = data['completed_orders'] ?? 0;

                  return Card(
                    elevation: 1, margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.grey[200], child: Text('#$rank', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54))),
                      title: Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('ئاست: ${_getUserLevel(orders)}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
                        child: Text('$orders ئۆردەر', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPodiumPlace(QueryDocumentSnapshot doc, int rank, double height, Color bgColor, Color textColor) {
    var data = doc.data() as Map<String, dynamic>;
    String profileImg = data['profile_image'] ?? '';
    int orders = data['completed_orders'] ?? 0;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (rank == 1) const Icon(Icons.workspace_premium, color: Colors.amber, size: 40),
          CircleAvatar(
            radius: 30, backgroundColor: bgColor,
            backgroundImage: profileImg.isNotEmpty ? NetworkImage(profileImg) : null,
            child: profileImg.isEmpty ? Icon(Icons.person, color: textColor) : null,
          ),
          const SizedBox(height: 8),
          Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
          Text('$orders ئۆردەر', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 5),
          Container(
            height: height,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
            ),
            child: Center(child: Text('$rank', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: textColor.withOpacity(0.5)))),
          ),
        ],
      ),
    );
  }
}
