import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResidentComplaintPage extends StatefulWidget {
  @override
  _ResidentComplaintPageState createState() => _ResidentComplaintPageState();
}

class _ResidentComplaintPageState extends State<ResidentComplaintPage> {
  final TextEditingController _complaintController = TextEditingController();
  String? _residentName;
  String? _roomNumber;
  String? _pgId;

  @override
  void initState() {
    super.initState();
    _fetchResidentDetails();
  }

  Future<void> _fetchResidentDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('residents') // <--- changed to residents collection
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          _residentName = doc['name'];
          _roomNumber = doc['roomNumber'];
          _pgId = doc['pgId']; // fetching pgId
        });
      }
    }
  }

  Future<void> _submitComplaint() async {
    if (_complaintController.text.isEmpty ||
        _residentName == null ||
        _roomNumber == null ||
        _pgId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a complaint.')));
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('complaints').add({
        'studentId': FirebaseAuth.instance.currentUser?.uid,
        'name': _residentName,
        'roomNumber': _roomNumber,
        'pgId': _pgId, // <--- added pgId
        'complaint': _complaintController.text,
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      _complaintController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint submitted successfully.')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _editComplaint(
      String complaintId, String currentComplaint) async {
    _complaintController.text = currentComplaint;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Complaint'),
          content: TextField(
            controller: _complaintController,
            maxLines: 3,
            decoration:
                const InputDecoration(labelText: 'Update your complaint'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _complaintController.clear();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_complaintController.text.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('complaints')
                      .doc(complaintId)
                      .update({'complaint': _complaintController.text});
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Complaint updated successfully.')));
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteComplaint(String complaintId) async {
    await FirebaseFirestore.instance
        .collection('complaints')
        .doc(complaintId)
        .delete();
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint deleted successfully.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Raise a Complaint'),
        backgroundColor: Colors.blue[300],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Your Complaints",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('complaints')
                    .where('studentId',
                        isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No complaints yet."));
                  }
                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      return Card(
                        color: Colors.grey[200],
                        child: ListTile(
                          title: Text(doc['complaint']),
                          subtitle: Text("Status: ${doc['status']}"),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editComplaint(doc.id, doc['complaint']);
                              } else if (value == 'delete') {
                                _deleteComplaint(doc.id);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                            icon: const Icon(Icons.more_vert),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            TextField(
              controller: _complaintController,
              decoration:
                  const InputDecoration(labelText: "Enter your complaint"),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _submitComplaint,
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.blue[300]),
              child: const Text("Submit Complaint",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
