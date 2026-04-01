import 'package:flutter/material.dart';
import 'resident_qrgenerator.dart';
import 'resident_profile.dart';
import 'resident_mealmenu.dart';
import 'resident_attendance.dart';
import 'resident_complaint.dart';
import 'resident_payment.dart';
import 'resident_notification.dart';
import 'resident_password.dart';
import 'resident_reviewpg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResidentDashboardScreen extends StatefulWidget {
  const ResidentDashboardScreen({Key? key}) : super(key: key);

  @override
  _ResidentDashboardScreenState createState() =>
      _ResidentDashboardScreenState();
}

class _ResidentDashboardScreenState extends State<ResidentDashboardScreen> {
  String? pgId;
  String? profileImageUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchResidentData();
  }

  Future<void> _fetchResidentData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final uid = user.uid;

      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final residentDoc = await FirebaseFirestore.instance
          .collection('residents')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        print('User document not found in "users"');
      }
      if (!residentDoc.exists) {
        print('Resident document not found in "residents"');
      }

      setState(() {
        pgId = userDoc.data()?['pgId'];
        profileImageUrl = residentDoc.data()?['profileImageUrl'];
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching resident data: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (pgId == null) {
      return const Scaffold(
        body: Center(child: Text('Error: PG ID not found')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue[300],
        title: const Text('StayEase',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: profileImageUrl != null && profileImageUrl!.isNotEmpty
                ? CircleAvatar(
                    backgroundImage: NetworkImage(profileImageUrl!),
                    radius: 16,
                    backgroundColor: Colors.white,
                  )
                : const Icon(Icons.account_circle,
                    size: 30, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ResidentProfile()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildDashboardTile(
                    context,
                    icon: Icons.qr_code,
                    label: 'QR CODE',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => GenerateQr()),
                      );
                    },
                  ),
                  _buildDashboardTile(
                    context,
                    icon: Icons.restaurant_menu,
                    label: 'Meal Menu',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ResidentMealMenuPage()),
                      );
                    },
                  ),
                  _buildDashboardTile(
                    context,
                    icon: Icons.fact_check,
                    label: 'Meal Attendance',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                ResidentAttendancePage(pgId: pgId!)),
                      );
                    },
                  ),
                  _buildDashboardTile(
                    context,
                    icon: Icons.payment,
                    label: 'Payments',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ResidentPaymentScreen()),
                      );
                    },
                  ),
                  _buildDashboardTile(
                    context,
                    icon: Icons.notifications,
                    label: 'Notifications',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ResidentNotificationScreen()),
                      );
                    },
                  ),
                  _buildDashboardTile(
                    context,
                    icon: Icons.build,
                    label: 'Complaints',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ResidentComplaintPage()),
                      );
                    },
                  ),
                  _buildDashboardTile(
                    context,
                    icon: Icons.lock,
                    label: 'Change Password',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ChangePasswordScreen()),
                      );
                    },
                  ),
                  _buildDashboardTile(
                    context,
                    icon: Icons.rate_review,
                    label: 'Review PG',
                    onTap: () async {
                      try {
                        final pgSnapshot = await FirebaseFirestore.instance
                            .collection('pgs')
                            .doc(pgId)
                            .get();
                        final pgData = pgSnapshot.data();
                        final pgName = pgData?['pgName'];
                        if (pgName != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PGReviewScreen(pgId: pgId!, pgName: pgName),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('PG Name not found for the PG ID.')),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error fetching PG data: $e')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[200],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            const SizedBox(height: 8),
            Text(label,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
