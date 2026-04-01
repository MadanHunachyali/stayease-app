import 'dart:io';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:open_file/open_file.dart';

class ResidentPaymentScreen extends StatefulWidget {
  @override
  _ResidentPaymentScreenState createState() => _ResidentPaymentScreenState();
}

class _ResidentPaymentScreenState extends State<ResidentPaymentScreen> {
  final TextEditingController _amountController = TextEditingController();
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    super.dispose();
  }

  void _startPayment(int amount) {
    var options = {
      'key': 'rzp_test_9XEDGMEbhNbe1U', // Replace with your key
      'amount': amount * 100,
      'name': 'PG Rent Payment',
      'description': 'Custom Rent Payment',
      'prefill': {
        'email': FirebaseAuth.instance.currentUser?.email ?? "",
      },
      'theme': {'color': '#2196F3'}, // Blue theme
    };
    _razorpay.open(options);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('residents')
          .doc(uid)
          .get();
      if (!doc.exists) throw Exception("Resident data not found");

      final resident = doc.data()!;
      final amount = int.parse(_amountController.text);
      final now = DateTime.now();

      // final pgDoc = await FirebaseFirestore.instance
      //     .collection('pgs')
      //     .doc(resident['pgId'])
      //     .get();

      // final pgName = pgDoc.data()?['name'] ?? 'N/A';

      final data = {
        'name': resident['name'],
        'roomNo': resident['roomNumber'],
        'contact': resident['contact'],
        'pgId': resident['pgId'],
        // 'pgName': pgName,
        'amount': amount,
        'transactionId': response.paymentId,
        'status': 'Success',
        'timestamp': now,
      };

      await FirebaseFirestore.instance
          .collection('pgs')
          .doc(resident['pgId'])
          .collection('payments')
          .doc(uid)
          .collection('transactions')
          .add(data);

      await _generateReceiptPdf(data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment successful. Receipt downloaded.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment failed. Please try again.")));
  }

  Future<void> _generateReceiptPdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    final date = _extractDate(data['timestamp']);
    final formattedDate = DateFormat('dd-MM-yyyy').format(date);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Padding(
            padding: pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Rent Payment Receipt",
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 24),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey600),
                  columnWidths: {
                    0: pw.FlexColumnWidth(3),
                    1: pw.FlexColumnWidth(5),
                  },
                  children: [
                    _buildRow("PG ID", data['pgId'] ?? 'N/A'),
                    // _buildRow("PG Name", data['pgName']),
                    _buildRow("Resident Name", data['name'] ?? 'N/A'),
                    _buildRow(
                        "Room Number", (data['roomNo'] ?? 'N/A').toString()),
                    _buildRow("Contact", data['contact'] ?? 'N/A'),
                    _buildRow(
                        "Amount Paid", data['amount']?.toString() ?? 'N/A'),
                    _buildRow("Transaction ID", data['transactionId'] ?? 'N/A'),
                    _buildRow("Status", data['status'] ?? 'N/A'),
                    _buildRow("Date", formattedDate),
                  ],
                ),
                pw.SizedBox(height: 32),
                pw.Text(
                  "Thank you for your payment.",
                  style: pw.TextStyle(fontSize: 14),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Request permission
    final status = await Permission.manageExternalStorage.request();
    if (!status.isGranted) {
      throw Exception("Storage permission not granted");
    }

    final dir = Directory('/storage/emulated/0/Download');
    final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');

    await file.writeAsBytes(await pdf.save());
  }

// Helper to build table rows
  pw.TableRow _buildRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: pw.EdgeInsets.all(8),
          color: PdfColors.grey200,
          child: pw.Text(label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Container(
          padding: pw.EdgeInsets.all(8),
          child: pw.Text(value),
        ),
      ],
    );
  }

// Helper to safely extract DateTime from dynamic timestamp
  DateTime _extractDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is DateTime) {
      return timestamp;
    } else {
      throw Exception('Invalid timestamp format');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Make Rent Payment"),
        backgroundColor: Colors.blue[700],
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          // Image below app bar
          Container(
            width: double.infinity,
            height: 400,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/payment.jpg'), // your image path
                fit: BoxFit.cover,
              ),
            ),
          ),

          SizedBox(height: 20),

          // Amount input field - rectangular, full width with margin
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                hintText: "Enter Amount (₹)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              ),
            ),
          ),

          SizedBox(height: 20),

          // Pay Now button full width blue background white text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final amount = int.tryParse(_amountController.text);
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Enter a valid amount")));
                    return;
                  }
                  _startPayment(amount);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
                child: Text(
                  "Pay Now",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
