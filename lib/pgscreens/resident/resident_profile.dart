import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../screens/home_page.dart'; // Make sure this import path is correct
import 'resident_dashboard.dart';

class ResidentProfile extends StatefulWidget {
  const ResidentProfile({Key? key}) : super(key: key);

  @override
  State<ResidentProfile> createState() => _ResidentProfileState();
}

class _ResidentProfileState extends State<ResidentProfile> {
  Map<String, dynamic>? residentData;
  bool isLoading = true;
  bool hasError = false;

  Future<void> fetchResidentData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final uid = user.uid;
      print('Fetching resident data for UID: $uid');

      final docSnapshot = await FirebaseFirestore.instance
          .collection('residents')
          .doc(uid)
          .get();

      if (!docSnapshot.exists) {
        print('Resident document does NOT exist for UID: $uid');
        throw Exception('Resident data not found');
      }

      setState(() {
        residentData = docSnapshot.data();
        isLoading = false;
      });
    } catch (e) {
      print('Error in fetchResidentData: $e');
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomePage(initialIndex: 2)),
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    fetchResidentData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Resident Profile'),
        backgroundColor: Colors.blue[300],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ResidentDashboardScreen(),
              ),
            );
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? const Center(
                  child: Text(
                    'Failed to fetch resident data.',
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfilePhotoScreen(
                                existingPhotoUrl:
                                    residentData?['profilePhotoUrl'],
                                onUpdate: fetchResidentData,
                              ),
                            ),
                          );
                        },
                        child: ClipOval(
                          child: Container(
                            color: Colors.grey[300],
                            height: 150,
                            width: 150,
                            child: residentData?['profilePhotoUrl'] != null
                                ? Image.network(
                                    residentData!['profilePhotoUrl'],
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.account_circle,
                                    size: 120, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        residentData?['name'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildProfileRow('Email', residentData?['email']),
                      _buildProfileRow('Contact', residentData?['contact']),
                      _buildProfileRow('Gender', residentData?['gender']),
                      _buildProfileRow('Address', residentData?['address']),
                      _buildProfileRow(
                          'Room Number', residentData?['roomNumber']),
                      _buildProfileRow('Rent', residentData?['rent']),
                      _buildProfileRow(
                        'Joining Date',
                        residentData?['joiningDate'] != null
                            ? DateTime.tryParse(residentData!['joiningDate'])
                                    ?.toLocal()
                                    .toString()
                                    .split(' ')[0] ??
                                'N/A'
                            : 'N/A',
                      ),
                      _buildProfileRow('Emergency Contact',
                          residentData?['emergencyContact']),
                      _buildProfileRow('College/Workplace',
                          residentData?['collegeOrWorkspace']),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[400],
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text(
                          "Logout",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Text(value ?? 'N/A', style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

class ProfilePhotoScreen extends StatefulWidget {
  final String? existingPhotoUrl;
  final VoidCallback? onUpdate;

  const ProfilePhotoScreen({Key? key, this.existingPhotoUrl, this.onUpdate})
      : super(key: key);

  @override
  State<ProfilePhotoScreen> createState() => _ProfilePhotoScreenState();
}

class _ProfilePhotoScreenState extends State<ProfilePhotoScreen> {
  bool isUploading = false;
  final picker = ImagePicker();

  Future<void> uploadPhoto() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      isUploading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("No user");

      final ref =
          FirebaseStorage.instance.ref('profile_photos/${user.uid}.jpg');

      await ref.putFile(File(pickedFile.path));
      final downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('residents')
          .doc(user.uid)
          .update({'profilePhotoUrl': downloadUrl});

      widget.onUpdate?.call();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  Future<void> deletePhoto() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('residents')
          .doc(user.uid)
          .update({'profilePhotoUrl': FieldValue.delete()});

      widget.onUpdate?.call();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Photo'),
        backgroundColor: Colors.blue[300],
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.existingPhotoUrl != null
                ? Image.network(
                    widget.existingPhotoUrl!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain,
                  )
                : Container(
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Icon(Icons.account_circle, size: 150),
                  ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: isUploading ? null : uploadPhoto,
                  icon: const Icon(Icons.upload),
                  label: const Text('Change'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[400],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: isUploading ? null : deletePhoto,
                  icon: const Icon(Icons.delete),
                  label: const Text('Remove'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
