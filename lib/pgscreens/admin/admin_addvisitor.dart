import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddVisitorPage extends StatefulWidget {
  @override
  _AddVisitorPageState createState() => _AddVisitorPageState();
}

class _AddVisitorPageState extends State<AddVisitorPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _meetController = TextEditingController();
  final TextEditingController _meetPhoneController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String pgId = '';

  @override
  void initState() {
    super.initState();
    _fetchPgId();
  }

  Future<void> _fetchPgId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        pgId = userDoc['pgId'];
      });
    }
  }

  void _addVisitor() async {
    if (pgId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PG ID not loaded yet')),
      );
      return;
    }

    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _selectedTime != null) {
      await FirebaseFirestore.instance.collection('visitors').add({
        'name': _nameController.text.trim(),
        'contact': _contactController.text.trim(),
        'address': _addressController.text.trim(),
        'whomToMeet': _meetController.text.trim(),
        'meetPhone': _meetPhoneController.text.trim(),
        'roomNo': _roomController.text.trim(),
        'time': DateFormat.jm().format(
          DateTime(0, 0, 0, _selectedTime!.hour, _selectedTime!.minute),
        ),
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'timestamp': FieldValue.serverTimestamp(),
        'pgId': pgId,
      });

      _formKey.currentState!.reset();
      _nameController.clear();
      _contactController.clear();
      _addressController.clear();
      _meetController.clear();
      _meetPhoneController.clear();
      _roomController.clear();
      setState(() {
        _selectedDate = null;
        _selectedTime = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Visitor added successfully')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                _buildTextField(_nameController, 'Visitor Name'),
                _buildContactField(_contactController, 'Contact Number'),
                _buildTextField(_addressController, 'Address'),
                _buildTextField(_meetController, 'Whom to Meet'),
                _buildContactField(_meetPhoneController, 'Whom to Meet Phone'),
                _buildTextField(_roomController, 'Room No'),
                _buildDateTimePicker(
                  'Select Date',
                  _selectedDate == null
                      ? 'Choose Date'
                      : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                  () => _selectDate(context),
                ),
                _buildDateTimePicker(
                  'Select Time',
                  _selectedTime == null
                      ? 'Choose Time'
                      : _selectedTime!.format(context),
                  () => _selectTime(context),
                ),
                SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _addVisitor,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Add Visitor',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (value) => value == null || value.trim().isEmpty
            ? 'Please enter $label'
            : null,
      ),
    );
  }

  Widget _buildContactField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter $label';
          }
          if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) {
            return 'Enter valid 10-digit $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDateTimePicker(String label, String value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            child: Text(value),
          ),
        ),
      ),
    );
  }
}
