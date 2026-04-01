import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

Future<void> loginUser(
    String email, String password, String expectedRole) async {
  try {
    // Sign in user
    await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);

    // Call Cloud Function to validate role
    HttpsCallable callable =
        FirebaseFunctions.instance.httpsCallable('validateUserRole');
    final result =
        await callable.call({'email': email, 'expectedRole': expectedRole});

    if (result.data['success']) {
      print('Login successful as $expectedRole');
    } else {
      print('Role mismatch');
    }
  } catch (e) {
    print('Error during login: $e');
  }
}
