import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class PgIdScreen extends StatefulWidget {
  const PgIdScreen({Key? key}) : super(key: key);

  @override
  _PgIdScreenState createState() => _PgIdScreenState();
}

class _PgIdScreenState extends State<PgIdScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? pgId;
  String? userUid;
  bool loading = false;
  String? error;

  Future<void> fetchPgId() async {
    setState(() {
      loading = true;
      error = null;
      pgId = null;
      userUid = null;
    });

    try {
      final authResult = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = authResult.user!.uid;
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (doc.exists && doc.data()!.containsKey('pgId')) {
        setState(() {
          pgId = doc['pgId'];
          userUid = uid;
        });
      } else {
        setState(() {
          error = 'PG ID not found in user record.';
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        error = e.message;
      });
    } catch (e) {
      setState(() {
        error = 'Something went wrong. Try again.';
      });
    }

    setState(() {
      loading = false;
    });
  }

  void copyToClipboard(String label, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/pgid.jpg',
                      height: 350,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "Enter your credentials to get your PG ID and UID",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: loading ? null : fetchPgId,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Submit",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (pgId != null && userUid != null)
                    Card(
                      color: Colors.green.shade50,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    "PG ID:",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 20),
                                  onPressed: () =>
                                      copyToClipboard("PG ID", pgId!),
                                )
                              ],
                            ),
                            SelectableText(pgId!),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    "UID:",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 20),
                                  onPressed: () =>
                                      copyToClipboard("UID", userUid!),
                                )
                              ],
                            ),
                            SelectableText(userUid!),
                          ],
                        ),
                      ),
                    ),

                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
