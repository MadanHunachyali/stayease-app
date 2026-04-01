// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'home_page.dart';
// import 'register_screen.dart';

// class AuthScreen extends StatefulWidget {
//   @override
//   _AuthScreenState createState() => _AuthScreenState();
// }

// class _AuthScreenState extends State<AuthScreen> {
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   void _login() async {
//     try {
//       await _auth.signInWithEmailAndPassword(
//         email: _emailController.text.trim(),
//         password: _passwordController.text.trim(),
//       );
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => HomePage()),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Login failed: ${e.toString()}")),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Livio", style: TextStyle(fontWeight: FontWeight.bold)),
//         backgroundColor: Colors.blue,
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Image.asset("assets/home.jpg", height: 200, fit: BoxFit.cover),
//             Padding(
//               padding: EdgeInsets.all(20),
//               child: Card(
//                 elevation: 5,
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(15)),
//                 child: Padding(
//                   padding: EdgeInsets.all(20),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text("Login",
//                           style: TextStyle(
//                               fontSize: 24, fontWeight: FontWeight.bold)),
//                       SizedBox(height: 20),
//                       TextField(
//                         controller: _emailController,
//                         decoration: InputDecoration(
//                             labelText: "Email", border: OutlineInputBorder()),
//                       ),
//                       SizedBox(height: 10),
//                       TextField(
//                         controller: _passwordController,
//                         decoration: InputDecoration(
//                             labelText: "Password",
//                             border: OutlineInputBorder()),
//                         obscureText: true,
//                       ),
//                       SizedBox(height: 20),
//                       ElevatedButton(
//                         onPressed: _login,
//                         style: ElevatedButton.styleFrom(
//                           shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(10)),
//                           backgroundColor: Colors.blue,
//                         ),
//                         child: Text("Login",
//                             style: TextStyle(color: Colors.white)),
//                       ),
//                       SizedBox(height: 10),
//                       TextButton(
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                                 builder: (context) => RegisterScreen()),
//                           );
//                         },
//                         child: Text("Don't have an account? Register"),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
