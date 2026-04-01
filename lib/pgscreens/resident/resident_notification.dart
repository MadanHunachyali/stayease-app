import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ResidentNotificationScreen extends StatefulWidget {
  @override
  _ResidentNotificationScreenState createState() =>
      _ResidentNotificationScreenState();
}

class _ResidentNotificationScreenState
    extends State<ResidentNotificationScreen> {
  String? pgId;

  @override
  void initState() {
    super.initState();
    fetchUserPGID();
  }

  Future<void> fetchUserPGID() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data() != null && doc['pgId'] != null) {
        setState(() {
          pgId = doc['pgId'];
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    if (pgId == null) return [];

    final querySnapshot = await FirebaseFirestore.instance
        .collection('pg_notifications')
        .where('pgId', isEqualTo: pgId)
        .orderBy('timestamp', descending: true)
        .get();

    return querySnapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'title': doc['title'],
        'body': doc['body'],
        'timestamp': (doc['timestamp'] as Timestamp).toDate(),
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        backgroundColor: Colors.blue, // Blue background
      ),
      body: pgId == null
          ? Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchNotifications(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error fetching notifications'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No notifications available.'));
                } else {
                  final notifications = snapshot.data!;
                  return ListView.separated(
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) => Divider(),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return ListTile(
                        title: Text(notification['title']),
                        subtitle: Text(notification['body']),
                        trailing: Text(
                          notification['timestamp'].toString().substring(0, 16),
                          style: TextStyle(fontSize: 12),
                        ),
                      );
                    },
                  );
                }
              },
            ),
    );
  }
}
