import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PGReviewScreen extends StatefulWidget {
  final String pgId;
  final String pgName;

  const PGReviewScreen({
    required this.pgId,
    required this.pgName,
    Key? key,
  }) : super(key: key);

  @override
  State<PGReviewScreen> createState() => _PGReviewScreenState();
}

class _PGReviewScreenState extends State<PGReviewScreen> {
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 3.0;
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a review.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final residentSnapshot = await FirebaseFirestore.instance
          .collection('residents')
          .doc(user.uid)
          .get();

      final residentName = residentSnapshot.data()?['name'] ?? 'Anonymous';

      await FirebaseFirestore.instance.collection('reviews').add({
        'pgId': widget.pgId,
        'pgName': widget.pgName,
        'residentName': residentName,
        'reviewText': _reviewController.text.trim(),
        'rating': _rating,
        'timestamp': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully!')),
      );

      Navigator.pop(context); // Go back after submitting
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting review: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Review ${widget.pgName}'),
        backgroundColor: Colors.blue[300],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                'Share your experience at ${widget.pgName}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _reviewController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Write your review',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text(
                    'Rating:',
                    style: TextStyle(fontSize: 16),
                  ),
                  Expanded(
                    child: Slider(
                      value: _rating,
                      min: 0,
                      max: 5,
                      divisions: 10,
                      label: _rating.toString(),
                      activeColor: Colors.blue,
                      onChanged: (value) {
                        setState(() {
                          _rating = value;
                        });
                      },
                    ),
                  ),
                  Text(
                    _rating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitReview,
                  icon: const Icon(Icons.send),
                  label: const Text('Submit Review'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16),
                    backgroundColor: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
