import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_visitordetails.dart';
import 'package:intl/intl.dart';

class VisitorListScreen extends StatefulWidget {
  const VisitorListScreen({Key? key}) : super(key: key);

  @override
  State<VisitorListScreen> createState() => _VisitorListScreenState();
}

class _VisitorListScreenState extends State<VisitorListScreen> {
  bool _isDeleting = false;
  String pgId = '';
  String? selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchPGId();
  }

  void _fetchPGId() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        pgId = userDoc['pgId'];
      });
    }
  }

  void _confirmDeleteVisitor(String visitorId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this visitor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isDeleting = true);
              try {
                await FirebaseFirestore.instance
                    .collection('visitors')
                    .doc(visitorId)
                    .delete();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Visitor deleted successfully'),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              } finally {
                setState(() => _isDeleting = false);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        selectedDate = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: pgId.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: _pickDate,
                            child: Text(
                              selectedDate ?? 'Select Date',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        if (selectedDate != null)
                          GestureDetector(
                            onTap: () {
                              setState(() => selectedDate = null);
                            },
                            child: const Icon(Icons.cancel, color: Colors.red),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('visitors')
                        .where('pgId', isEqualTo: pgId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text('Error fetching data'));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No visitors found'));
                      }

                      var visitors = snapshot.data!.docs.where((doc) {
                        if (selectedDate == null) return true;
                        return doc['date'] == selectedDate;
                      }).toList();

                      if (visitors.isEmpty) {
                        return const Center(
                            child: Text('No visitors for this date'));
                      }

                      return ListView.builder(
                        itemCount: visitors.length,
                        itemBuilder: (context, index) {
                          var visitor = visitors[index];
                          return Card(
                            color: Colors.grey[200],
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading:
                                  const Icon(Icons.person, color: Colors.blue),
                              title: Text(
                                visitor['name'] ?? 'No Name',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                  'Room No: ${visitor['roomNo'] ?? 'N/A'}'),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VisitorDetailsScreen(
                                        visitorId: visitor.id),
                                  ),
                                );
                              },
                              trailing: _isDeleting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () =>
                                          _confirmDeleteVisitor(visitor.id),
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
