import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AdminLogScreen extends StatefulWidget {
  const AdminLogScreen({Key? key}) : super(key: key);

  @override
  State<AdminLogScreen> createState() => _AdminLogScreenState();
}

class _AdminLogScreenState extends State<AdminLogScreen> {
  String pgId = '';
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchPGID();
  }

  Future<void> fetchPGID() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        pgId = doc['pgId'];
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Resident Logs"),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Date: $formattedDate",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: pgId.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('pgs')
                        .doc(pgId)
                        .collection('residentLogs')
                        .where('formattedTime',
                            isGreaterThanOrEqualTo: formattedDate)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                            child: Text("No logs found for selected date."));
                      }

                      final logs = snapshot.data!.docs.where((doc) {
                        final time = doc['formattedTime'];
                        return time
                            .startsWith(DateFormat.yMd().format(selectedDate));
                      }).toList();

                      return ListView.builder(
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(
                                  "${log['name']} (Room ${log['roomNo']})"),
                              subtitle: Text("${log['formattedTime']}"),
                              trailing: Text(
                                log['type'] == 'check-in'
                                    ? 'Check-In'
                                    : 'Check-Out',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: log['type'] == 'check-in'
                                      ? Colors.green
                                      : Colors.red,
                                ),
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
    );
  }
}
