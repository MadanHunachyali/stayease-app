import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAttendancePage extends StatefulWidget {
  final String pgId;

  const AdminAttendancePage({Key? key, required this.pgId}) : super(key: key);

  @override
  _AdminAttendancePageState createState() => _AdminAttendancePageState();
}

class _AdminAttendancePageState extends State<AdminAttendancePage> {
  String? _mealType;
  bool _isAttendanceActive = false;

  @override
  void initState() {
    super.initState();
    _checkActiveAttendance();
  }

  Future<void> _checkActiveAttendance() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('pgs')
          .doc(widget.pgId)
          .collection('attendance')
          .doc('active')
          .get();

      if (doc.exists && (doc.data()?['active'] == true)) {
        final data = doc.data();
        setState(() {
          _mealType = data?['mealType'];
          _isAttendanceActive = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking active attendance: $e')),
      );
    }
  }

  Future<void> _activateAttendance() async {
    try {
      if (_mealType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a meal type')),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('pgs')
          .doc(widget.pgId)
          .collection('attendance')
          .doc('active')
          .set({
        'mealType': _mealType,
        'active': true,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isAttendanceActive = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance activated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error activating attendance: $e')),
      );
    }
  }

  Future<void> _deactivateAttendance() async {
    bool confirm = await _showConfirmationDialog();
    if (!confirm) return;

    try {
      final residentsSnapshot = await FirebaseFirestore.instance
          .collection('pgs')
          .doc(widget.pgId)
          .collection('attendance')
          .doc('active')
          .collection('residents')
          .get();

      if (residentsSnapshot.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in residentsSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      await FirebaseFirestore.instance
          .collection('pgs')
          .doc(widget.pgId)
          .collection('attendance')
          .doc('active')
          .delete();

      setState(() {
        _isAttendanceActive = false;
        _mealType = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance deactivated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deactivating attendance: $e')),
      );
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Deactivation'),
            content: const Text(
                'Are you sure you want to deactivate attendance? This will delete all resident records.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[300],
        title: const Text('Meal Attendance',
            style: TextStyle(color: Colors.black)),
      ),
      body: _isAttendanceActive
          ? ActiveAttendanceUI(
              pgId: widget.pgId,
              mealType: _mealType,
              deactivateAttendance: _deactivateAttendance,
            )
          : SetAttendanceUI(
              mealType: _mealType,
              onMealTypeChanged: (value) {
                setState(() {
                  _mealType = value;
                });
              },
              activateAttendance: _activateAttendance,
            ),
    );
  }
}

class SetAttendanceUI extends StatelessWidget {
  final String? mealType;
  final Function(String?) onMealTypeChanged;
  final Future<void> Function() activateAttendance;

  const SetAttendanceUI({
    Key? key,
    required this.mealType,
    required this.onMealTypeChanged,
    required this.activateAttendance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Select Meal Type:', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ['Breakfast', 'Lunch', 'Dinner'].map((type) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        mealType == type ? Colors.blue[300] : Colors.grey[200],
                    foregroundColor:
                        mealType == type ? Colors.white : Colors.black,
                  ),
                  onPressed: () => onMealTypeChanged(type),
                  child: Text(type),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: activateAttendance,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[300],
              foregroundColor: Colors.white,
            ),
            child: const Text('Activate Attendance'),
          ),
        ],
      ),
    );
  }
}

class ActiveAttendanceUI extends StatelessWidget {
  final String? mealType;
  final Future<void> Function() deactivateAttendance;
  final String pgId;

  const ActiveAttendanceUI({
    Key? key,
    required this.pgId,
    required this.mealType,
    required this.deactivateAttendance,
  }) : super(key: key);

  Future<Map<String, dynamic>?> _getResidentData(String uid) async {
    final doc =
        await FirebaseFirestore.instance.collection('residents').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: deactivateAttendance,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[300]),
            child: const Text('Deactivate Attendance',
                style: TextStyle(color: Colors.white)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Meal Type: $mealType',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const Divider(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('pgs')
                .doc(pgId)
                .collection('attendance')
                .doc('active')
                .collection('residents')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No residents marked yet.'));
              }

              final residentDocs = snapshot.data!.docs;
              final totalCount = residentDocs.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Total students marked attendance: $totalCount',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: Future.wait(residentDocs.map((doc) async {
                        final uid = doc.id;
                        final data = await _getResidentData(uid);
                        return {
                          'name': data?['name'] ?? 'Unknown',
                          'roomNumber': data?['roomNumber'] ?? 'N/A',
                        };
                      })),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final residents = snapshot.data!;
                        return ListView.builder(
                          itemCount: residents.length,
                          itemBuilder: (context, index) {
                            final res = residents[index];
                            return ListTile(
                              leading: const Icon(Icons.person),
                              title: Text(res['name']),
                              subtitle: Text('Room No: ${res['roomNumber']}'),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
