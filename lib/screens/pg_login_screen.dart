import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pgscreens/admin/admin_dashboard.dart';
import '../pgscreens/resident/resident_dashboard.dart';
import '../pgscreens/pg_welcome_screen.dart';
import 'forgot_password.dart';

class PgLoginScreen extends StatefulWidget {
  @override
  _PgLoginScreenState createState() => _PgLoginScreenState();
}

class _PgLoginScreenState extends State<PgLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _pgIdController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  Future<void> _loadRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;
    if (rememberMe) {
      _emailController.text = prefs.getString('email') ?? '';
      _passwordController.text = prefs.getString('password') ?? '';
      _pgIdController.text = prefs.getString('pgId') ?? '';
      setState(() {
        _rememberMe = true;
      });
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final User? user = userCredential.user;
      if (user == null) {
        throw FirebaseAuthException(
            code: 'no-user', message: 'User not found.');
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw FirebaseAuthException(
            code: 'no-doc', message: 'User data not found.');
      }

      final data = userDoc.data();
      final String? role = data?['role'];
      final String? pgId = data?['pgId'];

      if (role == null || pgId == null) {
        throw FirebaseAuthException(
            code: 'missing-fields', message: 'Missing role or PG ID.');
      }

      if (pgId != _pgIdController.text.trim()) {
        throw FirebaseAuthException(
            code: 'pgid-mismatch', message: 'PG ID does not match.');
      }

      if (_rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', true);
        await prefs.setString('email', _emailController.text.trim());
        await prefs.setString('password', _passwordController.text.trim());
        await prefs.setString('pgId', _pgIdController.text.trim());
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('remember_me');
        await prefs.remove('email');
        await prefs.remove('password');
        await prefs.remove('pgId');
      }

      final pgDoc =
          await FirebaseFirestore.instance.collection('pgs').doc(pgId).get();
      final pgName = pgDoc.exists ? pgDoc['pgName'] : 'Your PG';

      Widget nextScreen = role == 'admin'
          ? AdminDashboardScreen(pgId: pgId)
          : ResidentDashboardScreen();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PGWelcomeSplashScreen(
            pgName: pgName,
            nextScreen: nextScreen,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login Failed: ${e.message}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unexpected Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/login.jpg',
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildField(
                          _pgIdController,
                          "Enter PG ID",
                          Icons.business,
                          TextInputType.text,
                          false,
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          _emailController,
                          "Email",
                          Icons.email,
                          TextInputType.emailAddress,
                          false,
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          _passwordController,
                          "Password",
                          Icons.lock,
                          TextInputType.text,
                          true,
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value!;
                                });
                              },
                            ),
                            const Text("Remember Me"),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Forgot Password?",
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          icon: const Icon(
                            Icons.login,
                            color: Colors.black,
                          ),
                          label: const Text("Login",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          onPressed: _login,
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

  Widget _buildField(
      TextEditingController controller, String label, IconData icon,
      [TextInputType type = TextInputType.text, bool obscure = false]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: type,
        validator: (value) =>
            value == null || value.isEmpty ? 'Enter $label' : null,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
