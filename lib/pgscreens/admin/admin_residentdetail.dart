import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResidentDetailsScreen extends StatefulWidget {
  final String residentId;
  const ResidentDetailsScreen({Key? key, required this.residentId})
      : super(key: key);

  @override
  State<ResidentDetailsScreen> createState() => _ResidentDetailsScreenState();
}

class _ResidentDetailsScreenState extends State<ResidentDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> residentData = {};
  bool isLoading = true;
  bool isEditing = false;

  final List<String> editableFields = [
    'name',
    'email',
    'contact',
    'address',
    'gender',
    'roomNumber',
    'rent',
  ];

  @override
  void initState() {
    super.initState();
    _fetchResidentData();
  }

  void _fetchResidentData() async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('residents')
          .doc(widget.residentId)
          .get();

      if (doc.exists) {
        setState(() {
          residentData = doc.data()!;
          isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching details: $e')),
      );
    }
  }

  void _updateResidentData() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        await FirebaseFirestore.instance
            .collection('residents')
            .doc(widget.residentId)
            .update(residentData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resident details updated')),
        );
        setState(() => isEditing = false);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating data: $e')),
        );
      }
    }
  }

  Widget _buildDisplayTile(String label, dynamic value, IconData icon) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Icon(icon, color: Colors.blue),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle:
          Text(value?.toString() ?? '-', style: const TextStyle(fontSize: 16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resident Details',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon:
                Icon(isEditing ? Icons.save : Icons.edit, color: Colors.white),
            onPressed: () {
              if (isEditing) {
                _updateResidentData();
              } else {
                setState(() => isEditing = true);
              }
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: isEditing
                  ? Form(
                      key: _formKey,
                      child: ListView(
                        children: editableFields.map((field) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: TextFormField(
                              initialValue:
                                  residentData[field]?.toString() ?? '',
                              decoration: InputDecoration(
                                labelText: field,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onSaved: (val) => residentData[field] = val ?? '',
                            ),
                          );
                        }).toList(),
                      ),
                    )
                  : ListView(
                      children: [
                        _buildDisplayTile(
                            'Name', residentData['name'], Icons.person),
                        _buildDisplayTile(
                            'Email', residentData['email'], Icons.email),
                        _buildDisplayTile(
                            'Contact', residentData['contact'], Icons.phone),
                        _buildDisplayTile(
                            'Address', residentData['address'], Icons.home),
                        _buildDisplayTile('Gender', residentData['gender'],
                            Icons.transgender),
                        _buildDisplayTile('Room Number',
                            residentData['roomNumber'], Icons.meeting_room),
                        _buildDisplayTile(
                            'Rent', residentData['rent'], Icons.currency_rupee),
                        _buildDisplayTile(
                            'PG ID', residentData['pgId'], Icons.domain),
                        _buildDisplayTile('QR Code Data',
                            residentData['qrCodeData'], Icons.qr_code),
                        _buildDisplayTile(
                            'UID', residentData['uid'], Icons.badge),
                        _buildDisplayTile(
                            'Created At',
                            residentData['createdAt']?.toDate(),
                            Icons.calendar_today),
                        const SizedBox(height: 20),
                        if (residentData['idProof'] != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                child: Text(
                                  'ID Proof',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                              ),
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                height: 200,
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    residentData['idProof'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error,
                                            stackTrace) =>
                                        const Center(
                                            child:
                                                Text('Unable to load image')),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
            ),
    );
  }
}
