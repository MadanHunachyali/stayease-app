import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AddResident extends StatefulWidget {
  final String pgId;

  const AddResident({Key? key, required this.pgId}) : super(key: key);

  @override
  State<AddResident> createState() => _AddResidentState();
}

class _AddResidentState extends State<AddResident> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController roomController = TextEditingController();
  final TextEditingController rentController = TextEditingController();
  final TextEditingController emergencyContactController =
      TextEditingController();
  final TextEditingController collegeOrWorkspaceController =
      TextEditingController();

  DateTime? joiningDate;
  String gender = "Male";
  bool isLoading = false;
  bool isPhotoUploading = false;
  File? _image;
  String? imageUrl;

  List<String> availableRooms = [];
  String? selectedRoom;

  final _formKey = GlobalKey<FormState>();
  final String defaultPassword = "12345678";

  @override
  void initState() {
    super.initState();
    fetchAvailableRooms();
  }

  Future<void> fetchAvailableRooms() async {
    try {
      final roomSnapshot = await FirebaseFirestore.instance
          .collection('rooms')
          .where('pgId', isEqualTo: widget.pgId)
          .get();
      final resSnapshot = await FirebaseFirestore.instance
          .collection('residents')
          .where('pgId', isEqualTo: widget.pgId)
          .get();

      Map<String, int> roomCounts = {};
      for (var doc in resSnapshot.docs) {
        String roomNum = doc.get('roomNumber') as String;
        roomCounts[roomNum] = (roomCounts[roomNum] ?? 0) + 1;
      }

      List<String> roomsList = [];
      for (var room in roomSnapshot.docs) {
        String roomNumber = room.get('roomNumber') as String;
        int totalBeds = room.get('totalBeds') as int;
        int occupied = roomCounts[roomNumber] ?? 0;
        if (occupied < totalBeds) {
          roomsList.add(roomNumber);
        }
      }

      setState(() {
        availableRooms = roomsList;
      });
    } catch (e) {
      print('Error fetching available rooms: $e');
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> uploadImage(File image) async {
    try {
      setState(() {
        isPhotoUploading = true;
      });

      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference storageRef =
          FirebaseStorage.instance.ref().child("resident_photos/$fileName");

      await storageRef.putFile(image);
      imageUrl = await storageRef.getDownloadURL();

      setState(() {
        isPhotoUploading = false;
      });
    } catch (e) {
      setState(() {
        isPhotoUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: ${e.toString()}')),
      );
    }
  }

  Future<void> addResident() async {
    if (_formKey.currentState?.validate() != true) return;

    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an ID proof image')),
      );
      return;
    }

    if (joiningDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a joining date')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await uploadImage(_image!);

      UserCredential credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: defaultPassword,
      );

      String uid = credential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': emailController.text.trim(),
        'role': 'resident',
        'pgId': widget.pgId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('residents').doc(uid).set({
        'uid': uid,
        'pgId': widget.pgId,
        'name': nameController.text.trim(),
        'contact': contactController.text.trim(),
        'email': emailController.text.trim(),
        'gender': gender,
        'address': addressController.text.trim(),
        'roomNumber': selectedRoom,
        'rent': rentController.text.trim(),
        'idProof': imageUrl,
        'joiningDate': joiningDate?.toIso8601String().split("T").first,
        'emergencyContact': emergencyContactController.text.trim(),
        'collegeOrWorkspace': collegeOrWorkspaceController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resident added successfully')),
      );

      nameController.clear();
      contactController.clear();
      emailController.clear();
      addressController.clear();
      roomController.clear();
      rentController.clear();
      emergencyContactController.clear();
      collegeOrWorkspaceController.clear();
      setState(() {
        gender = "Male";
        joiningDate = null;
        selectedRoom = null;
        _image = null;
      });
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add resident: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add Resident'),
        backgroundColor: Colors.blue[300],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter Resident Details',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                    labelText: 'Name', border: OutlineInputBorder()),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: contactController,
                decoration: const InputDecoration(
                    labelText: 'Contact', border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Contact is required';
                  }
                  // FIXED: removed the backslash before $
                  if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                    return 'Enter valid 10-digit contact number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  // FIXED: removed the backslash before $
                  if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,4}$')
                      .hasMatch(value)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: gender,
                decoration: const InputDecoration(
                    labelText: 'Gender', border: OutlineInputBorder()),
                items: ['Male', 'Female']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    gender = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(
                    labelText: 'Address', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty
                    ? 'Address is required'
                    : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedRoom,
                decoration: const InputDecoration(
                    labelText: 'Room Number', border: OutlineInputBorder()),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedRoom = newValue!;
                    roomController.text = newValue;
                  });
                },
                validator: (value) => value == null || value.isEmpty
                    ? 'Room number is required'
                    : null,
                items: availableRooms
                    .map((room) =>
                        DropdownMenuItem(value: room, child: Text(room)))
                    .toList(),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: rentController,
                decoration: const InputDecoration(
                    labelText: 'Rent', border: OutlineInputBorder()),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Rent is required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: emergencyContactController,
                decoration: const InputDecoration(
                    labelText: 'Emergency Contact',
                    border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Emergency contact is required';
                  }
                  // FIXED: removed the backslash before $
                  if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                    return 'Enter valid 10-digit emergency contact number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: collegeOrWorkspaceController,
                decoration: const InputDecoration(
                    labelText: 'College or Workspace',
                    border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty
                    ? 'This field is required'
                    : null,
              ),
              const SizedBox(height: 10),
              const Text('Joining Date',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      joiningDate = pickedDate;
                    });
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      hintText: joiningDate == null
                          ? 'Select Date'
                          : '${joiningDate!.day}/${joiningDate!.month}/${joiningDate!.year}',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (_) => joiningDate == null
                        ? 'Please select joining date'
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text('ID Proof',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      enabled: false,
                      decoration: InputDecoration(
                        hintText: _image != null
                            ? _image!.path.split('/').last
                            : 'Upload ID Proof',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.blue),
                    onPressed: _pickImage,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: addResident,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[300],
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Add Resident',
                            style:
                                TextStyle(fontSize: 18, color: Colors.white)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
