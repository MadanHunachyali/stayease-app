import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../screens/map_screen.dart';
import '../../screens/home_page.dart';
import 'admin_password.dart';

// Image Management Screen
class ImageManagementScreen extends StatefulWidget {
  final List<String> images;
  final Function(List<String>) onImagesUpdated;

  const ImageManagementScreen({
    Key? key,
    required this.images,
    required this.onImagesUpdated,
  }) : super(key: key);

  @override
  _ImageManagementScreenState createState() => _ImageManagementScreenState();
}

class _ImageManagementScreenState extends State<ImageManagementScreen> {
  late List<String> _images;

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.images);
  }

  Future<void> _addImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        _images.addAll(pickedFiles.map((file) => file.path).toList());
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage PG Images'),
        backgroundColor: Colors.blue[400],
        actions: [
          TextButton(
            onPressed: () {
              widget.onImagesUpdated(_images);
              Navigator.pop(context);
            },
            child: const Text(
              'Save',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _images.isEmpty
                ? const Center(child: Text('No images added yet.'))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1,
                    ),
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: _images[index].startsWith('http')
                                    ? NetworkImage(_images[index])
                                        as ImageProvider
                                    : FileImage(File(_images[index])),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 5,
                            right: 5,
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.remove_circle,
                                    color: Colors.white),
                                iconSize: 24,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _removeImage(index),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Add More Images'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _addImages,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminProfileScreen extends StatefulWidget {
  @override
  _AdminProfileScreenState createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final PageController _pageController = PageController();

  String? adminName,
      ownerEmail,
      ownerContact,
      pgName,
      manualLocation,
      selectedLocation,
      price,
      pgId;
  List<dynamic>? facilities;
  List<String>? images;
  List<String> imagesToDelete = [];
  LatLng? _pickedLocation;
  bool isEditing = false;
  bool showImageOptions = false;
  int currentImageIndex = 0;

  final _pgNameController = TextEditingController();
  final _manualLocationController = TextEditingController();
  final _contactController = TextEditingController();
  final _priceController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerContactController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchAdminData();
  }

  Future<void> fetchAdminData() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        final userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();
        final pgDoc =
            await _firestore.collection('pgs').doc(userDoc['pgId']).get();

        if (userDoc.exists && pgDoc.exists) {
          setState(() {
            adminName = userDoc['name'];
            ownerEmail = userDoc['email'];
            ownerContact = pgDoc['ownerContact'];
            pgName = pgDoc['pgName'];
            manualLocation = pgDoc['manualLocation'];
            selectedLocation = pgDoc['selectedLocation'];
            price = pgDoc['price'];
            facilities = pgDoc['facilities'];
            images = List<String>.from(pgDoc['images']);
            pgId = pgDoc['pgId'];

            _pgNameController.text = pgName!;
            _manualLocationController.text = manualLocation!;
            _contactController.text = ownerContact!;
            _priceController.text = price!;
            _ownerNameController.text = adminName!;
            _ownerEmailController.text = ownerEmail!;
            _ownerContactController.text = ownerContact!;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    }
  }

  Future<void> _showImagesManagementScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageManagementScreen(
          images: images ?? [],
          onImagesUpdated: (updatedImages) {
            setState(() {
              images = updatedImages;
            });
          },
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      List<String> newImages = pickedFiles.map((file) => file.path).toList();
      setState(() {
        if (images == null) {
          images = newImages;
        } else {
          images!.addAll(newImages);
        }
      });
    }
  }

  Future<void> _replaceImage(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        // If it's a network image, add it to delete list
        if (images![index].startsWith('http')) {
          imagesToDelete.add(images![index]);
        }
        // Replace the image at the specified index
        images![index] = pickedFile.path;
      });
    }
  }

  Future<void> _removeImage(int index) async {
    setState(() {
      // If it's a network image, add it to delete list for later deletion from storage
      if (images![index].startsWith('http')) {
        imagesToDelete.add(images![index]);
      }
      // Remove the image from the list
      images!.removeAt(index);

      // Adjust current index if needed
      if (currentImageIndex >= images!.length) {
        currentImageIndex = images!.length - 1;
        if (currentImageIndex < 0) currentImageIndex = 0;
      }

      // Update page controller
      if (images!.isNotEmpty) {
        _pageController.jumpToPage(currentImageIndex);
      }
    });
  }

  Future<void> _updateProfile() async {
    try {
      List<String> uploadedImages = [];

      // Delete images that were marked for deletion
      for (String imageUrl in imagesToDelete) {
        try {
          // Extract file path from URL
          String filePath =
              Uri.decodeFull(imageUrl.split('/o/')[1].split('?')[0]);
          await _storage.ref(filePath).delete();
        } catch (e) {
          print('Error deleting image: $e');
        }
      }

      // Upload new images and keep existing URLs
      if (images != null && images!.isNotEmpty) {
        for (var image in images!) {
          if (!image.startsWith('http')) {
            String fileName = Uuid().v4();
            Reference ref =
                FirebaseStorage.instance.ref().child('pg_images/$fileName');
            UploadTask uploadTask = ref.putFile(File(image));
            TaskSnapshot snapshot = await uploadTask;
            String downloadUrl = await snapshot.ref.getDownloadURL();
            uploadedImages.add(downloadUrl);
          } else {
            uploadedImages.add(image);
          }
        }
      }

      await _firestore.collection('pgs').doc(pgId).update({
        'images': uploadedImages,
        'pgName': _pgNameController.text,
        'manualLocation': _manualLocationController.text,
        'contact': _contactController.text,
        'price': _priceController.text,
        'ownerName': _ownerNameController.text,
        'ownerEmail': _ownerEmailController.text,
        'ownerContact': _ownerContactController.text,
        if (selectedLocation != null) 'selectedLocation': selectedLocation,
        if (_pickedLocation != null) ...{
          'latitude': _pickedLocation!.latitude,
          'longitude': _pickedLocation!.longitude,
        },
      });

      // Clear the images to delete list
      imagesToDelete.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile Updated Successfully!')),
      );
      setState(() => isEditing = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  Future<void> _pickCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark place = placemarks[0];
    setState(() {
      selectedLocation = "${place.street}, ${place.locality}, ${place.country}";
      _pickedLocation = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> _pickLocationFromMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapScreen()),
    );

    if (result != null && result is Map) {
      LatLng selected = result['latLng'];
      String address = result['address'];

      setState(() {
        selectedLocation = address;
        _pickedLocation = selected;
      });
    }
  }

  Widget buildCard(String title, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            ...children
          ],
        ),
      ),
    );
  }

  Widget buildImageGallery() {
    if (images == null || images!.isEmpty) {
      return const Center(child: Text('No images uploaded.'));
    }

    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: screenHeight * 0.25,
          child: PageView.builder(
            controller: _pageController,
            itemCount: images!.length,
            onPageChanged: (index) {
              setState(() {
                currentImageIndex = index;
                showImageOptions = false;
              });
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    showImageOptions = !showImageOptions;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: images![index].startsWith('http')
                          ? NetworkImage(images![index]) as ImageProvider
                          : FileImage(File(images![index])),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Image counter indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            images!.length,
            (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: currentImageIndex == index
                    ? Colors.blue
                    : Colors.grey.shade300,
              ),
            ),
          ),
        ),
        if (isEditing && showImageOptions) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.change_circle),
                label: const Text("Change"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                onPressed: () => _replaceImage(currentImageIndex),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.delete),
                label: const Text("Remove"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: images!.length > 1
                    ? () => _removeImage(currentImageIndex)
                    : null, // Disable if it's the last image
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget buildInfoTile(String label, String? value,
      TextEditingController? controller, IconData? icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? Icons.label_important,
              color: Colors.grey[700], size: 20),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            flex: 3,
            child: controller == null
                ? Text(
                    value ?? 'Not Available',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  )
                : TextFormField(
                    controller: controller,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Profile'),
        backgroundColor: Colors.blue[400],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => HomePage(initialIndex: 2)),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: images == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  buildSectionTitle('PG Images'),
                  buildImageGallery(),
                  buildCard('Admin Details', [
                    buildInfoTile('Name', adminName,
                        isEditing ? _ownerNameController : null, Icons.person),
                    buildInfoTile('Email', ownerEmail,
                        isEditing ? _ownerEmailController : null, Icons.email),
                    buildInfoTile(
                        'Contact',
                        ownerContact,
                        isEditing ? _ownerContactController : null,
                        Icons.phone),
                  ]),
                  buildCard('PG Details', [
                    buildInfoTile('PG Name', pgName,
                        isEditing ? _pgNameController : null, Icons.home),
                    buildInfoTile(
                        'Manual Address',
                        manualLocation,
                        isEditing ? _manualLocationController : null,
                        Icons.location_on),
                    isEditing
                        ? Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.my_location),
                                      label: const Text("Use Current Location"),
                                      onPressed: _pickCurrentLocation,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.map),
                                      label: const Text("Pick from Map"),
                                      onPressed: _pickLocationFromMap,
                                    ),
                                  ),
                                ],
                              ),
                              if (selectedLocation != null) ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text("📍 $selectedLocation",
                                      style:
                                          TextStyle(color: Colors.grey[700])),
                                ),
                              ]
                            ],
                          )
                        : buildInfoTile('Selected Location', selectedLocation,
                            null, Icons.location_pin),
                    buildInfoTile(
                        'Price',
                        price,
                        isEditing ? _priceController : null,
                        Icons.attach_money),
                    buildInfoTile(
                        'Facilities', facilities?.join(', '), null, Icons.list),
                  ]),
                  const SizedBox(height: 20),
                  isEditing
                      ? Column(
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.image),
                              label: const Text("Update PG Images"),
                              onPressed: _showImagesManagementScreen,
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.check),
                              label: const Text("Save Changes"),
                              onPressed: _updateProfile,
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.edit),
                              label: const Text("Edit Profile",
                                  style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                              ),
                              onPressed: () => setState(() => isEditing = true),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.lock),
                              label: const Text(
                                "Change Password",
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AdminChangePasswordScreen(), // Make sure this screen is implemented and imported
                                  ),
                                );
                              },
                            ),
                          ],
                        )
                ],
              ),
            ),
    );
  }
}
