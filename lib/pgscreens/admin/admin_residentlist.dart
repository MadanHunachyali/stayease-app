import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_residentdetail.dart'; // Import your detail screen

class ResidentListScreen extends StatefulWidget {
  const ResidentListScreen({Key? key}) : super(key: key);

  @override
  State<ResidentListScreen> createState() => _ResidentListScreenState();
}

class _ResidentListScreenState extends State<ResidentListScreen> {
  bool _isDeleting = false;
  String pgId = '';
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _fetchPGId();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchPGId() async {
    var user = FirebaseAuth.instance.currentUser;
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

  void _confirmDeleteResident(String residentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this resident?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isDeleting = true);
              try {
                await FirebaseFirestore.instance
                    .collection('residents')
                    .doc(residentId)
                    .delete();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Resident deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: \$e')),
                );
              } finally {
                setState(() => _isDeleting = false);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: pgId.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search by name or room',
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black, width: 1.5),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('residents')
                        .where('pgId', isEqualTo: pgId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text('Error fetching data'));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No residents found'));
                      }

                      var allDocs = snapshot.data!.docs;
                      // Apply search filter (name or room number)
                      var filteredDocs = allDocs.where((doc) {
                        final name =
                            (doc['name'] ?? '').toString().toLowerCase();
                        final room =
                            (doc['roomNumber'] ?? '').toString().toLowerCase();
                        final query = _searchText.toLowerCase();
                        return name.contains(query) || room.contains(query);
                      }).toList();

                      if (filteredDocs.isEmpty) {
                        return const Center(
                            child: Text('No matching residents found'));
                      }

                      return ListView.builder(
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          var resident = filteredDocs[index];
                          return Card(
                            color: Colors.grey[200],
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading:
                                  const Icon(Icons.person, color: Colors.blue),
                              title: Text(
                                resident['name'] ?? 'No Name',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                  'Room No: ${resident['roomNumber'] ?? 'N/A'}'),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ResidentDetailsScreen(
                                      residentId: resident.id,
                                    ),
                                  ),
                                );
                              },
                              trailing: _isDeleting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () =>
                                          _confirmDeleteResident(resident.id),
                                    ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
