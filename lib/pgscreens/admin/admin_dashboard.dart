import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'add_resident.dart';
import 'admin_profile.dart';
import 'admin_mealmenu.dart';
import 'admin_attendance.dart';
import 'admin_complaint.dart';
import 'admin_residentlist.dart';
import 'admin_addvisitor.dart';
import 'admin_payment.dart';
import 'admin_notification.dart';
import 'admin_qrscanner.dart';
import 'admin_visitor_list.dart';
import 'admin_manageroom.dart';
import 'admin_logscreen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String pgId;

  const AdminDashboardScreen({Key? key, required this.pgId}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  String pgName = '';
  bool isLoading = true;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _fetchPgName();
  }

  Future<void> _fetchPgName() async {
    try {
      final pgDoc = await FirebaseFirestore.instance
          .collection('pgs')
          .doc(widget.pgId)
          .get();

      if (pgDoc.exists && pgDoc.data() != null) {
        setState(() {
          pgName = pgDoc['pgName'] ?? 'Your PG';
          isLoading = false;
        });
      } else {
        setState(() {
          pgName = 'PG Not Found';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        pgName = 'Error Fetching PG';
        isLoading = false;
      });
    }

    _pages.addAll([
      AdminDashboardContent(pgId: widget.pgId),
      ResidentListScreen(),
      AddVisitorPage(),
      VisitorListScreen(),
      AdminQRScannerScreen(),
    ]);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[300],
        title: Text(
          isLoading ? 'Loading...' : 'Welcome to - $pgName',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.account_circle,
              color: Colors.white,
              size: 30,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.grey[200],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.blue),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list, color: Colors.blue),
            label: 'Students',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add_alt_1, color: Colors.blue),
            label: 'Visitors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group, color: Colors.blue),
            label: 'Visitorslist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner, color: Colors.blue),
            label: 'Scan QR',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        onTap: _onItemTapped,
      ),
    );
  }
}

class AdminDashboardContent extends StatelessWidget {
  final String pgId;

  const AdminDashboardContent({Key? key, required this.pgId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildDashboardTile(
            context,
            icon: Icons.person_add,
            label: 'Add Resident',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AddResident(pgId: pgId)),
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
                    builder: (context) => AdminMealMenuPage(pgId: pgId)),
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
                    builder: (context) => AdminAttendancePage(pgId: pgId)),
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
                    builder: (context) => AdminPaymentListScreen(pgId: pgId)),
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
                    builder: (context) => AdminNotificationScreen()),
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
                    builder: (context) => AdminComplaintPage(pgId: pgId)),
              );
            },
          ),
          _buildDashboardTile(
            context,
            icon: Icons.meeting_room,
            label: 'Manage Rooms',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RoomManagementScreen()),
              );
            },
          ),
          _buildDashboardTile(
            context,
            icon: Icons.donut_large,
            label: 'Log List',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminLogScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTile(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
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
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
