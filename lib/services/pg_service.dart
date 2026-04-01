import 'package:cloud_firestore/cloud_firestore.dart';

class PGService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch PGs by location
  Future<List<Map<String, dynamic>>> searchPGs(String location) async {
    try {
      QuerySnapshot querySnapshot = await _db
          .collection("PGs")
          .where("location", isEqualTo: location)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print("Error fetching PGs: $e");
      return [];
    }
  }

  // Add Review for PG (only for past or current residents)
  Future<void> addReview(
      String pgId, String userId, double rating, String feedback) async {
    try {
      await _db.collection("PGs").doc(pgId).collection("reviews").add({
        'userId': userId,
        'rating': rating,
        'feedback': feedback,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error adding review: $e");
    }
  }

  // Fetch Reviews for a PG
  Future<List<Map<String, dynamic>>> getReviews(String pgId) async {
    try {
      QuerySnapshot querySnapshot =
          await _db.collection("PGs").doc(pgId).collection("reviews").get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print("Error fetching reviews: $e");
      return [];
    }
  }
}
