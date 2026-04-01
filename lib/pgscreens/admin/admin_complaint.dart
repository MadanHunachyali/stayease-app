import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminComplaintPage extends StatelessWidget {
  final String pgId; // PG ID passed to the screen

  AdminComplaintPage({Key? key, required this.pgId}) : super(key: key);

  // Method to update the complaint status in Firestore
  Future<void> _updateComplaintStatus(String docId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(docId)
          .update({'status': status});
    } catch (e) {
      print('Error updating status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // If pgId is empty, show loading instead of wrong query
    if (pgId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Manage Complaints'),
          backgroundColor: Colors.blue[300],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Manage Complaints'),
        backgroundColor: Colors.blue[300],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .where('pgId', isEqualTo: pgId) // Filter complaints by PG ID
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // Debugging print
          print('Building Stream with PG ID: $pgId');

          // Handle waiting state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Handle errors
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Handle no data case
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No complaints yet."));
          }

          // Build the list of complaints
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];

              // Safeguard against missing or incorrect fields
              String complaint = doc['complaint'] ?? 'No complaint provided';
              String name = doc['name'] ?? 'Unknown';
              String roomNumber = doc['roomNumber'] ?? 'Unknown';
              String status = doc['status'] ?? 'Unknown';

              return Card(
                color: Colors.grey[200],
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(complaint,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text("Student: $name",
                          style: TextStyle(color: Colors.grey[700])),
                      Text("Room No: $roomNumber",
                          style: TextStyle(color: Colors.grey[700])),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatusButton(doc.id, "Pending", status),
                          _buildStatusButton(doc.id, "In Progress", status),
                          _buildStatusButton(doc.id, "Resolved", status),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Method to create status buttons for each complaint
  Widget _buildStatusButton(
      String docId, String statusOption, String currentStatus) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () => _updateComplaintStatus(docId, statusOption),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                currentStatus == statusOption ? Colors.blue : Colors.white,
            foregroundColor:
                currentStatus == statusOption ? Colors.white : Colors.black,
            side: const BorderSide(color: Colors.blue),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          child: Text(
            statusOption,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
