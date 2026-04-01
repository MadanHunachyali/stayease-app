import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminPaymentListScreen extends StatefulWidget {
  final String pgId;

  AdminPaymentListScreen({required this.pgId});

  @override
  _AdminPaymentListScreenState createState() => _AdminPaymentListScreenState();
}

class _AdminPaymentListScreenState extends State<AdminPaymentListScreen> {
  String selectedMonth = DateFormat('MMMM yyyy').format(DateTime.now());
  late DateTime selectedMonthDate;

  @override
  void initState() {
    super.initState();
    selectedMonthDate = DateFormat('MMMM yyyy').parse(selectedMonth);
  }

  List<String> getLast12Months() {
    final now = DateTime.now();
    return List.generate(12, (index) {
      final date = DateTime(now.year, now.month - index, 1);
      return DateFormat('MMMM yyyy').format(date);
    });
  }

  void _onMonthChanged(String? newMonth) {
    if (newMonth != null) {
      setState(() {
        selectedMonth = newMonth;
        selectedMonthDate = DateFormat('MMMM yyyy').parse(selectedMonth);
      });
    }
  }

  Stream<QuerySnapshot> getPaymentsStream() {
    DateTime startOfMonth =
        DateTime(selectedMonthDate.year, selectedMonthDate.month, 1);
    DateTime endOfMonth = DateTime(
      selectedMonthDate.year,
      selectedMonthDate.month + 1,
      0,
      23,
      59,
      59,
    );

    return FirebaseFirestore.instance
        .collectionGroup('transactions')
        .where('pgId', isEqualTo: widget.pgId)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Paid Residents"),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: DropdownButton<String>(
              value: selectedMonth,
              items: getLast12Months()
                  .map((month) => DropdownMenuItem(
                        child: Text(month),
                        value: month,
                      ))
                  .toList(),
              onChanged: _onMonthChanged,
              isExpanded: true,
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getPaymentsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final payments = snapshot.data!.docs;

                if (payments.isEmpty) {
                  return Center(child: Text("No payments for selected month."));
                }

                return ListView.builder(
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final data = payments[index].data() as Map<String, dynamic>;

                    final name = data['name'] ?? 'Unknown';
                    final room = data['roomNumber'] ?? data['roomNo'] ?? 'N/A';
                    final amount = data['amount']?.toString() ?? '0';
                    final timestamp =
                        (data['timestamp'] as Timestamp?)?.toDate();
                    final formattedDate = timestamp != null
                        ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp)
                        : 'Unknown';

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Name: $name",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(height: 6),
                            Text("Room No: $room",
                                style: TextStyle(fontSize: 15)),
                            SizedBox(height: 6),
                            Text("Amount Paid: $amount",
                                style: TextStyle(fontSize: 15)),
                            SizedBox(height: 6),
                            Text("Date: $formattedDate",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[700])),
                          ],
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
    );
  }
}
