import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'map_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PGRegistrationScreen extends StatefulWidget {
  @override
  _PGRegistrationScreenState createState() => _PGRegistrationScreenState();
}

class _PGRegistrationScreenState extends State<PGRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _pgNameController = TextEditingController();
  final TextEditingController _manualLocationController =
      TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _ownerEmailController = TextEditingController();
  final TextEditingController _ownerContactController = TextEditingController();
  final TextEditingController _ownerPasswordController =
      TextEditingController();

  List<File> _images = [];
  String? _selectedLocation;
  LatLng? _pickedLocation;
  Map<String, bool> _facilities = {
    'AC': false,
    'Hot Water': false,
    'WiFi': false,
    'Parking': false,
    'Laundry Service': false,
    'Food Service': false,
    'Gym': false,
    'CCTV Surveillance': false,
    'Water Purifier': false,
    'Power Backup': false,
  };

  @override
  void initState() {
    super.initState();
    checkAndRequestLocationPermission();
  }

  Future<void> checkAndRequestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  Future<void> _pickCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String readableAddress = [
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.country
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        setState(() {
          _selectedLocation = readableAddress;
          _pickedLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      print("Error getting current location: $e");
      // Optionally, show a snackbar or alert to the user
    }
  }

  Future<void> _pickLocationFromMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapScreen()),
    );

    if (result != null) {
      LatLng selectedLocation = result['latLng'];
      String selectedAddress = result['address'];

      setState(() {
        _pickedLocation = selectedLocation;
        _selectedLocation = selectedAddress; // Area-level readable address
      });
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _images = pickedFiles.map((file) => File(file.path)).toList();
      });
    }
  }

  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];
    for (var image in _images) {
      String fileName = Uuid().v4();
      Reference ref =
          FirebaseStorage.instance.ref().child('pg_images/$fileName');
      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      imageUrls.add(downloadUrl);
    }
    return imageUrls;
  }

  // Inside _registerPG method
  Future<void> _registerPG() async {
    if (_formKey.currentState!.validate()) {
      try {
        final UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _ownerEmailController.text,
          password: _ownerPasswordController.text,
        );

        String generateCustomPgId(String pgName, String ownerContact) {
          String prefix = pgName.trim().substring(0, 2).toUpperCase();
          String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          String suffix =
              ownerContact.trim().substring(ownerContact.length - 2);
          return "$prefix$timestamp$suffix";
        }

        String pgId = generateCustomPgId(
            _pgNameController.text, _ownerContactController.text);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': _ownerEmailController.text,
          'name': _ownerNameController.text,
          'role': 'admin',
          'pgId': pgId,
        });

        List<String> imageUrls = await _uploadImages();

        await FirebaseFirestore.instance.collection('pgs').doc(pgId).set({
          'pgId': pgId,
          'pgName': _pgNameController.text,
          'manualLocation': _manualLocationController.text,
          'selectedLocation': _selectedLocation,
          'latitude': _pickedLocation?.latitude,
          'longitude': _pickedLocation?.longitude,
          'contact': _contactController.text,
          'price': _priceController.text,
          'facilities': _facilities.entries
              .where((e) => e.value)
              .map((e) => e.key)
              .toList(),
          'ownerName': _ownerNameController.text,
          'ownerEmail': _ownerEmailController.text,
          'ownerContact': _ownerContactController.text,
          'images': imageUrls,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PG Registered Successfully!')),
        );

        Navigator.pop(context);
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration Failed: ${e.message}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _pgNameController.dispose();
    _manualLocationController.dispose();
    _contactController.dispose();
    _priceController.dispose();
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _ownerContactController.dispose();
    _ownerPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register PG'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              buildField(_pgNameController, 'PG Name', Icons.home),
              buildField(_manualLocationController, 'Manual Address',
                  Icons.location_city),
              buildField(_contactController, 'Contact Info', Icons.phone,
                  TextInputType.phone),
              buildField(_priceController, 'Price (per month)',
                  Icons.currency_rupee, TextInputType.number),
              SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Facilities",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ..._facilities.keys.map((facility) {
                return CheckboxListTile(
                  title: Text(facility),
                  value: _facilities[facility],
                  onChanged: (value) {
                    setState(() {
                      _facilities[facility] = value ?? false;
                    });
                  },
                );
              }).toList(),
              buildField(_ownerNameController, 'Owner Name', Icons.person),
              buildField(_ownerEmailController, 'Owner Email', Icons.email,
                  TextInputType.emailAddress),
              buildField(_ownerContactController, 'Owner Contact',
                  Icons.phone_android, TextInputType.phone),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: _ownerPasswordController,
                  obscureText: true,
                  validator: (value) =>
                      value!.isEmpty ? 'Enter Owner Password' : null,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock),
                    labelText: 'Owner Password',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.my_location, color: Colors.black),
                      label: Text(
                        "Use Current Location",
                        style: TextStyle(color: Colors.black),
                      ),
                      onPressed: _pickCurrentLocation,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.black),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.map, color: Colors.black),
                      label: Text(
                        "Pick from Map",
                        style: TextStyle(color: Colors.black),
                      ),
                      onPressed: _pickLocationFromMap,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
              if (_selectedLocation != null) ...[
                SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "📍 $_selectedLocation",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ],
              SizedBox(height: 10),
              OutlinedButton.icon(
                icon: Icon(Icons.image, color: Colors.black),
                label: Text(
                  "Upload Images",
                  style: TextStyle(color: Colors.black),
                ),
                onPressed: _pickImages,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.black),
                ),
              ),
              SizedBox(height: 25),
              ElevatedButton.icon(
                icon: Icon(Icons.check, color: Colors.white),
                label: Text(
                  "Register PG",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: _registerPG,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildField(
      TextEditingController controller, String label, IconData icon,
      [TextInputType type = TextInputType.text]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        validator: (value) {
          if (value!.isEmpty) {
            return 'Enter $label';
          }
          if (label == 'Owner Email' &&
              !RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
            return 'Enter a valid email address';
          }
          if (label.contains('Contact')) {
            if (!RegExp(r'^\d{10}$').hasMatch(value)) {
              return 'Enter a valid 10-digit phone number';
            }
          }
          return null;
        },
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
