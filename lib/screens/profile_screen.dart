import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'super_admin.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final List<String> options = ['About Us', 'Admin', 'Feedback'];
  List<bool> _expanded = [];

  // Feedback controllers
  final TextEditingController feedbackNameController = TextEditingController();
  final TextEditingController feedbackTextController = TextEditingController();

  // Admin login controllers
  final TextEditingController adminEmailController = TextEditingController();
  final TextEditingController adminPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _expanded = List.filled(options.length, false);
  }

  Future<void> submitFeedback() async {
    final name = feedbackNameController.text.trim();
    final message = feedbackTextController.text.trim();

    if (name.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both fields')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('feedback').add({
        'name': name,
        'message': message,
        'timestamp': Timestamp.now(),
      });

      feedbackNameController.clear();
      feedbackTextController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting feedback: $e')),
      );
    }
  }

  Future<void> handleAdminLogin() async {
    final email = adminEmailController.text.trim();
    final password = adminPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    try {
      // Sign in using Firebase Auth
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final String uid = userCredential.user!.uid;

      // Fetch role from Firestore
      final DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found in Firestore')),
        );
        return;
      }

      final role = userDoc.get('role');
      if (role == 'super_admin') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SuperAdminDashboard()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are not a Super Admin')),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login error: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $e')),
      );
    }
  }

  Widget getExpandedContent(int index) {
    switch (options[index]) {
      case 'About Us':
        return const Text(
          'StayEase is a platform designed to simplify PG and hostel management. '
          'It connects residents and PG owners, providing features such as food attendance, notifications, agreements, reviews, and more.',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        );

      case 'Admin':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: adminEmailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: adminPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: handleAdminLogin,
              child: const Text('Login'),
            ),
          ],
        );

      case 'Feedback':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: feedbackNameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feedbackTextController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Your Feedback',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: submitFeedback,
              child: const Text('Submit'),
            ),
          ],
        );

      default:
        return const Text('No content available.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('STAYEASE', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: ListView.builder(
        itemCount: options.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          return Column(
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  title: Text(
                    options[index],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Icon(
                    _expanded[index]
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 24,
                  ),
                  onTap: () {
                    setState(() {
                      _expanded[index] = !_expanded[index];
                    });
                  },
                ),
              ),
              if (_expanded[index])
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: getExpandedContent(index),
                ),
            ],
          );
        },
      ),
    );
  }
}
