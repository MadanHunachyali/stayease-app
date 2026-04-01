import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:mobile_scanner/mobile_scanner.dart';

class AdminQRScannerScreen extends StatefulWidget {
  const AdminQRScannerScreen({Key? key}) : super(key: key);

  @override
  State<AdminQRScannerScreen> createState() => _AdminQRScannerScreenState();
}

class _AdminQRScannerScreenState extends State<AdminQRScannerScreen> {
  String? adminPgId;
  bool _isProcessing = false;
  String statusMessage = "Scan a resident QR code";

  @override
  void initState() {
    super.initState();
    fetchAdminPgId();
  }

  Future<void> fetchAdminPgId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        adminPgId = userDoc['pgId'];
      });
    }
  }

  Future<void> _handleScan(String rawValue) async {
    if (_isProcessing || adminPgId == null) return;

    setState(() => _isProcessing = true);

    try {
      final data = jsonDecode(rawValue);
      final String uid = data['uid'];
      final String name = data['name'];
      final String roomNo = data['roomNo'];
      final String pgId = data['pgId'];

      if (pgId != adminPgId) {
        setState(() {
          statusMessage = "This QR is not from your PG";
          _isProcessing = false;
        });
        return;
      }

      final now = DateTime.now();
      final firestore = FirebaseFirestore.instance;

      // Determine type based on last entry (optional, for info)
      final previousLogsQuery = await firestore
          .collection('pgs')
          .doc(pgId)
          .collection('residentLogs')
          .where('uid', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      String nextType = 'check-in';
      if (previousLogsQuery.docs.isNotEmpty) {
        final lastType = previousLogsQuery.docs.first['type'];
        nextType = lastType == 'check-in' ? 'check-out' : 'check-in';
      }

      // Always add a new log regardless of previous
      await firestore
          .collection('pgs')
          .doc(pgId)
          .collection('residentLogs')
          .add({
        'uid': uid,
        'name': name,
        'roomNo': roomNo,
        'pgId': pgId,
        'type': nextType,
        'timestamp': FieldValue.serverTimestamp(),
        'formattedTime': DateFormat.yMd().add_jm().format(now),
        'date': DateFormat('yyyy-MM-dd').format(now),
      });

      setState(() {
        statusMessage = '$nextType marked for $name';
      });
    } catch (e) {
      setState(() {
        statusMessage = "Invalid QR code or error: $e";
      });
    }

    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _isProcessing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (adminPgId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: MobileScanner(
              onDetect: (BarcodeCapture barcode) {
                final raw = barcode.barcodes.first.rawValue;
                if (raw != null) {
                  _handleScan(raw);
                }
              },
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                statusMessage,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
