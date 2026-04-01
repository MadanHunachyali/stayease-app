import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResidentAttendancePage extends StatefulWidget {
  final String pgId;

  const ResidentAttendancePage({Key? key, required this.pgId})
      : super(key: key);

  @override
  _ResidentAttendancePageState createState() => _ResidentAttendancePageState();
}

class _ResidentAttendancePageState extends State<ResidentAttendancePage> {
  bool _isLoading = true;
  bool _isAttendanceActive = false;
  String? _mealType;
  bool _hasMarked = false;
  String? _residentName;
  String? _roomNumber;

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadResidentData();
  }

  Future<void> _loadResidentData() async {
    try {
      final pgRef =
          FirebaseFirestore.instance.collection('pgs').doc(widget.pgId);
      final activeDoc =
          await pgRef.collection('attendance').doc('active').get();

      if (!activeDoc.exists || activeDoc.data()?['active'] != true) {
        setState(() {
          _isLoading = false;
          _isAttendanceActive = false;
        });
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (userDoc.exists) {
        _residentName = userDoc.data()?['name'];
        _roomNumber = userDoc.data()?['roomNumber'];
      }

      final markedDoc = await pgRef
          .collection('attendance')
          .doc('active')
          .collection('residents')
          .doc(user!.uid)
          .get();

      setState(() {
        _mealType = activeDoc.data()?['mealType'];
        _isAttendanceActive = true;
        _hasMarked = markedDoc.exists;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Future<void> _markAttendance() async {
    try {
      final pgRef =
          FirebaseFirestore.instance.collection('pgs').doc(widget.pgId);

      await pgRef
          .collection('attendance')
          .doc('active')
          .collection('residents')
          .doc(user!.uid)
          .set({
        'name': _residentName ?? 'Unknown',
        'roomNumber': _roomNumber ?? 'N/A',
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() => _hasMarked = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance marked successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking attendance: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resident Attendance'),
        backgroundColor: Colors.blue[300],
      ),
      body: Center(
        child: _isAttendanceActive
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Meal Type: $_mealType',
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 20),
                  _hasMarked
                      ? const Text('You have already marked attendance.')
                      : ElevatedButton(
                          onPressed: _markAttendance,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[300],
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Mark Attendance'),
                        ),
                ],
              )
            : const Text('No active meal set by Admin right now.'),
      ),
    );
  }
}
