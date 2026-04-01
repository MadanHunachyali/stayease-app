import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewsScreen extends StatelessWidget {
  final String pgId;

  ReviewsScreen({required this.pgId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PG Reviews'),
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('reviews')
            .where('pgId', isEqualTo: pgId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('Review load error: ${snapshot.error}');
            return Center(child: Text('Error loading reviews.'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No reviews available.'));
          }

          final reviews = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              final rating = review['rating'] ?? 0.0;
              final comment = review['reviewText'] ?? 'No comment';
              final reviewerName = review['residentName'] ?? 'Anonymous';

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.blueAccent,
                            child: Text(
                              (reviewerName.isNotEmpty
                                  ? reviewerName[0]
                                  : '?'), // Display first letter of name
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            reviewerName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Rating: ${rating.toString()} / 5',
                        style: TextStyle(fontSize: 14, color: Colors.amber),
                      ),
                      SizedBox(height: 5),
                      Text(
                        comment,
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
