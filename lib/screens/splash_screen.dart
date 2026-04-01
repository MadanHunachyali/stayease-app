import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_page.dart';
import '../pgscreens/admin/admin_dashboard.dart';
import '../pgscreens/resident/resident_dashboard.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(Duration(seconds: 2)); // Show splash for 2 seconds

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Not logged in → redirect to HomePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists || userDoc.data() == null) {
        // User data missing → Sign out and go to HomePage
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage()),
        );
        return;
      }

      final data = userDoc.data()!;
      final String? role = data['role'];
      final String? pgId = data['pgId'];

      if (role == 'admin' && pgId != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminDashboardScreen(pgId: pgId)),
        );
      } else if (role == 'resident') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ResidentDashboardScreen()),
        );
      } else {
        // Unknown or invalid role → sign out and go to HomePage
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage()),
        );
      }
    } catch (e) {
      // Any unexpected error → fallback to HomePage
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("STAYEASE",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            SizedBox(height: 20),
            SpinKitThreeBounce(color: Colors.white, size: 30),
          ],
        ),
      ),
    );
  }
}
