import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResidentMealMenuPage extends StatelessWidget {
  ResidentMealMenuPage({Key? key}) : super(key: key);

  final List<String> weekDays = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday"
  ];

  Future<Map<String, dynamic>> _fetchMealMenu(String pgId) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('mealmenu')
          .doc(pgId) // Fetch meal menu based on pgId
          .get();

      if (docSnapshot.exists) {
        return docSnapshot.data() as Map<String, dynamic>;
      } else {
        return {};
      }
    } catch (e) {
      throw Exception('Error fetching meal menu: $e');
    }
  }

  Future<String> _getResidentPgId() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final uid = currentUser.uid;
      final residentDocRef =
          FirebaseFirestore.instance.collection('residents').doc(uid);
      final docSnapshot = await residentDocRef.get();

      if (docSnapshot.exists) {
        return docSnapshot.data()!['pgId']
            as String; // Get pgId from resident document
      } else {
        throw Exception('Resident document not found');
      }
    } catch (e) {
      throw Exception('Error fetching PG ID: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[300],
        title: const Text('Weekly Meal Menu'),
        centerTitle: true,
      ),
      body: FutureBuilder<String>(
        future: _getResidentPgId(), // Fetch PG ID for the resident
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final pgId = snapshot.data!;

            return FutureBuilder<Map<String, dynamic>>(
              future: _fetchMealMenu(pgId), // Fetch meal menu for that PG
              builder: (context, mealSnapshot) {
                if (mealSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (mealSnapshot.hasError) {
                  return Center(child: Text('Error: ${mealSnapshot.error}'));
                } else if (mealSnapshot.hasData) {
                  final mealMenu = mealSnapshot.data!;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: weekDays.map((day) {
                        final meals =
                            mealMenu[day] as Map<String, dynamic>? ?? {};

                        return Card(
                          color: Colors.grey[200],
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  day,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...["Breakfast", "Lunch", "Dinner"]
                                    .map((mealType) {
                                  final mealValue =
                                      meals[mealType] ?? "Not Available";

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$mealType: ',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(mealValue.toString()),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                } else {
                  return const Center(
                    child: Text('No meal menu available.'),
                  );
                }
              },
            );
          } else {
            return const Center(
              child: Text('No PG ID found for the resident.'),
            );
          }
        },
      ),
    );
  }
}
