import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AdminNotificationScreen extends StatefulWidget {
  @override
  _AdminNotificationScreenState createState() =>
      _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  final CollectionReference notificationsRef =
      FirebaseFirestore.instance.collection('pg_notifications');

  String? pgId;
  String? senderId = FirebaseAuth.instance.currentUser?.uid;
  bool _loadingPgId = true;

  @override
  void initState() {
    super.initState();
    _fetchPgId();
  }

  Future<void> _fetchPgId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data() != null && userDoc['pgId'] != null) {
        setState(() {
          pgId = userDoc['pgId'];
          senderId = uid;
          _loadingPgId = false;
        });
        print('Fetched PG ID: $pgId');
      } else {
        setState(() => _loadingPgId = false);
        print('PG ID not found for user');
      }
    } catch (e) {
      print('Error fetching PG ID: $e');
      setState(() => _loadingPgId = false);
    }
  }

  Future<void> _sendNotification() async {
    final String title = _titleController.text.trim();
    final String body = _bodyController.text.trim();

    if (pgId == null || title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please fill all fields')));
      return;
    }

    try {
      await notificationsRef.add({
        'pgId': pgId,
        'title': title,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
        'senderId': senderId,
      });

      final HttpsCallable sendNotification =
          FirebaseFunctions.instance.httpsCallable('sendNotificationToPG');
      await sendNotification.call({'pgId': pgId, 'title': title, 'body': body});

      _titleController.clear();
      _bodyController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notification sent successfully!')));
    } catch (e) {
      print('Error sending notification: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _deleteNotification(String docId) async {
    try {
      await notificationsRef.doc(docId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error deleting notification')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingPgId) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Loading PG...'),
          backgroundColor: Colors.blue,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (pgId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Error'),
          backgroundColor: Colors.blue,
        ),
        body: Center(child: Text('PG ID not found for current user.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Send Notification'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _bodyController,
              decoration: InputDecoration(labelText: 'Body'),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _sendNotification,
                child: Text('Send Notification'),
              ),
            ),
            SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: notificationsRef
                    .where('pgId', isEqualTo: pgId)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                    return Center(child: Text('No notifications sent yet.'));

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final docId = docs[index].id;

                      return Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(vertical: 6),
                        child: Card(
                          elevation: 2,
                          child: ListTile(
                            title: Text(data['title'] ?? ''),
                            subtitle: Text(data['body'] ?? ''),
                            trailing: IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => _deleteNotification(docId),
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
      ),
    );
  }
}
