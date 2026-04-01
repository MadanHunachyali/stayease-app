import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'pg_details_screen.dart';
import 'feedback_screen.dart'; // Import your FeedbackScreen here

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({Key? key}) : super(key: key);

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int pgCount = 0;
  int adminCount = 0;
  int residentCount = 0;
  int feedbackCount = 0;

  List<QueryDocumentSnapshot> pgList = [];

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    final usersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();
    final pgsSnapshot =
        await FirebaseFirestore.instance.collection('pgs').get();
    final feedbackSnapshot =
        await FirebaseFirestore.instance.collection('feedback').get();

    int admin = 0;
    int resident = 0;

    for (var doc in usersSnapshot.docs) {
      final role = doc.data()['role'];
      if (role == 'admin') admin++;
      if (role == 'resident') resident++;
    }

    setState(() {
      adminCount = admin;
      residentCount = resident;
      pgCount = pgsSnapshot.docs.length;
      feedbackCount = feedbackSnapshot.docs.length;
      pgList = pgsSnapshot.docs;
    });
  }

  void deletePG(String pgId) async {
    await FirebaseFirestore.instance.collection('pgs').doc(pgId).delete();
    fetchDashboardData(); // Refresh after deletion
  }

  Widget buildDashboardCard(String title, int count, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('$count', style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Dashboard'),
        backgroundColor: Colors.blue,
      ),
      body: RefreshIndicator(
        onRefresh: fetchDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  buildDashboardCard('Total PGs', pgCount),
                  buildDashboardCard('Admins', adminCount),
                  buildDashboardCard('Residents', residentCount),
                  buildDashboardCard(
                    'Feedbacks',
                    feedbackCount,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const FeedbackListScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'PG List',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pgList.length,
                itemBuilder: (context, index) {
                  final pgDoc = pgList[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(
                        pgDoc['pgName'] ?? 'Unnamed PG',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(pgDoc['manualLocation'] ?? 'No location'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deletePG(pgDoc.id),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PGDetailsScreen(pgData: pgDoc),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
