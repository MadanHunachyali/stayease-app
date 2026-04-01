import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VisitorDetailsScreen extends StatefulWidget {
  final String visitorId;
  const VisitorDetailsScreen({Key? key, required this.visitorId})
      : super(key: key);

  @override
  State<VisitorDetailsScreen> createState() => _VisitorDetailsScreenState();
}

class _VisitorDetailsScreenState extends State<VisitorDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> visitorData = {};
  bool isLoading = true;
  bool isEditing = false;

  final List<String> editableFields = [
    'name',
    'contact',
    'address',
    'whomToMeet',
    'meetPhone',
    'roomNo',
  ];

  @override
  void initState() {
    super.initState();
    _fetchVisitorData();
  }

  void _fetchVisitorData() async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('visitors')
          .doc(widget.visitorId)
          .get();

      if (doc.exists) {
        setState(() {
          visitorData = doc.data()!;
          isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching details: $e')),
      );
    }
  }

  void _updateVisitorData() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        await FirebaseFirestore.instance
            .collection('visitors')
            .doc(widget.visitorId)
            .update(visitorData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visitor details updated')),
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

  Widget _buildTextFormField(String field, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        initialValue: visitorData[field]?.toString() ?? '',
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onSaved: (val) => visitorData[field] = val ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor Details',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon:
                Icon(isEditing ? Icons.save : Icons.edit, color: Colors.white),
            onPressed: () {
              if (isEditing) {
                _updateVisitorData();
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
                        children: [
                          _buildTextFormField('name', 'Visitor Name'),
                          _buildTextFormField('contact', 'Contact Number'),
                          _buildTextFormField('address', 'Address'),
                          _buildTextFormField('whomToMeet', 'Whom to Meet'),
                          _buildTextFormField(
                              'meetPhone', 'Whom to Meet Phone'),
                          _buildTextFormField('roomNo', 'Room No'),
                          const SizedBox(height: 12),
                          _buildDisplayTile('Visit Date', visitorData['date'],
                              Icons.calendar_today),
                          _buildDisplayTile('Visit Time', visitorData['time'],
                              Icons.access_time),
                        ],
                      ),
                    )
                  : ListView(
                      children: [
                        _buildDisplayTile(
                            'Visitor Name', visitorData['name'], Icons.person),
                        _buildDisplayTile('Contact Number',
                            visitorData['contact'], Icons.phone),
                        _buildDisplayTile(
                            'Address', visitorData['address'], Icons.home),
                        _buildDisplayTile('Whom to Meet',
                            visitorData['whomToMeet'], Icons.people),
                        _buildDisplayTile('Whom to Meet Phone',
                            visitorData['meetPhone'], Icons.phone_in_talk),
                        _buildDisplayTile('Room No', visitorData['roomNo'],
                            Icons.meeting_room),
                        _buildDisplayTile('Visit Date', visitorData['date'],
                            Icons.calendar_today),
                        _buildDisplayTile('Visit Time', visitorData['time'],
                            Icons.access_time),
                        _buildDisplayTile(
                            'PG ID', visitorData['pgId'], Icons.domain),
                        _buildDisplayTile(
                            'Visitor ID', widget.visitorId, Icons.badge),
                      ],
                    ),
            ),
    );
  }
}
