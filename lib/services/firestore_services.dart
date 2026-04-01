import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Register PG with unique PG ID
  Future<String?> registerPG(
      String name, String location, String ownerContact) async {
    try {
      DocumentReference pgRef = await _db.collection("PGs").add({
        'name': name,
        'location': location,
        'ownerContact': ownerContact,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Generate Unique PG ID
      String pgId = pgRef.id;
      await pgRef.update({'pgId': pgId});
      return pgId;
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }
}
