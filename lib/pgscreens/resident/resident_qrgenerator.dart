import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'resident_dashboard.dart';
import 'dart:convert';

class GenerateQr extends StatefulWidget {
  const GenerateQr({Key? key}) : super(key: key);

  @override
  State<GenerateQr> createState() => _GenerateQrState();
}

class _GenerateQrState extends State<GenerateQr> {
  String? qrData;
  bool isLoading = true;
  String? uid;

  @override
  void initState() {
    super.initState();
    loadSavedQrCode();
  }

  Future<void> loadSavedQrCode() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("User not logged in");

      uid = currentUser.uid;

      final doc = await FirebaseFirestore.instance
          .collection('residents')
          .doc(uid)
          .get();
      if (!doc.exists) throw Exception("Resident document not found");

      final data = doc.data()!;
      if (data.containsKey('qrCodeData')) {
        setState(() {
          qrData = data['qrCodeData'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error loading QR: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> generateQrCode() async {
    setState(() => isLoading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("User not logged in");

      final uid = currentUser.uid;
      final doc = await FirebaseFirestore.instance
          .collection('residents')
          .doc(uid)
          .get();
      if (!doc.exists) throw Exception("Resident document not found");

      final data = doc.data()!;
      final pgId = data['pgId'];
      final name = data['name'];
      final roomNo = data['roomNumber'];

      final qrPayload = {
        'uid': uid,
        'pgId': pgId,
        'name': name,
        'roomNo': roomNo,
      };

      final generatedData = jsonEncode(qrPayload);

      await FirebaseFirestore.instance.collection('residents').doc(uid).update({
        'qrCodeData': generatedData,
      });

      setState(() {
        this.uid = uid;
        qrData = generatedData;
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("QR Code generated and saved!")),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> deleteQrCode() async {
    try {
      await FirebaseFirestore.instance.collection('residents').doc(uid).update({
        'qrCodeData': FieldValue.delete(),
      });
      setState(() => qrData = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("QR Code deleted.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error deleting QR: $e")));
    }
  }

  void showFullScreenQR(String data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenQRView(data: data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Generate QR Code"),
        backgroundColor: Colors.blue[300],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const ResidentDashboardScreen()),
            );
          },
        ),
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (qrData != null) ...[
                      GestureDetector(
                        onTap: () => showFullScreenQR(qrData!),
                        child: QrImageView(
                          data: qrData!,
                          version: QrVersions.auto,
                          size: 200.0,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text("Tap QR to view full screen",
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600])),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: deleteQrCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[400],
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text("Delete QR",
                            style:
                                TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ] else ...[
                      const Icon(Icons.qr_code, size: 100, color: Colors.grey),
                      const SizedBox(height: 20),
                      const Text("No QR generated yet."),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: generateQrCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[300],
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text("Generate & Save QR",
                            style:
                                TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ]
                  ],
                ),
              ),
      ),
    );
  }
}

class FullScreenQRView extends StatelessWidget {
  final String data;

  const FullScreenQRView({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Full Screen QR"),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: QrImageView(
          data: data,
          version: QrVersions.auto,
          size: MediaQuery.of(context).size.width * 0.8,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}
