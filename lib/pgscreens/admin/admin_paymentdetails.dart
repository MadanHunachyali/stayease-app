import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> payment;

  PaymentDetailScreen({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Payment Details")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Resident Name: ${payment['name']}",
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text("Room No: ${payment['roomNo']}"),
            Text("Contact: ${payment['contact']}"),
            Text("PG ID: ${payment['pgId']}"),
            Text("Amount Paid: ₹${payment['amount']}"),
            Text("Transaction ID: ${payment['transactionId']}"),
            Text("Status: ${payment['status']}"),
            Text(
                "Date: ${payment['timestamp'].toDate().toString().split(' ').first}"),
          ],
        ),
      ),
    );
  }
}
