import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class PGWelcomeSplashScreen extends StatefulWidget {
  final String pgName;
  final Widget nextScreen;

  PGWelcomeSplashScreen({required this.pgName, required this.nextScreen});

  @override
  _PGWelcomeSplashScreenState createState() => _PGWelcomeSplashScreenState();
}

class _PGWelcomeSplashScreenState extends State<PGWelcomeSplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => widget.nextScreen),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Welcome to",
              style: TextStyle(
                fontSize: 22,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              widget.pgName,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            SpinKitThreeBounce(color: Colors.white, size: 30),
          ],
        ),
      ),
    );
  }
}
