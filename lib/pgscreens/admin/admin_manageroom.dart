import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoomManagementScreen extends StatefulWidget {
  @override
  _RoomManagementScreenState createState() => _RoomManagementScreenState();
}

class _RoomManagementScreenState extends State<RoomManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _roomNumberController = TextEditingController();
  final TextEditingController _totalBedsController = TextEditingController();

  String? pgId;

  @override
  void initState() {
    super.initState();
    _fetchPgId();
  }

  Future<void> _fetchPgId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        pgId = userDoc['pgId'];
      });
    }
  }

  Future<void> _addRoom() async {
    if (_formKey.currentState!.validate() && pgId != null) {
      final roomNumber = _roomNumberController.text.trim();
      final totalBeds = int.parse(_totalBedsController.text.trim());

      final existingRoom = await FirebaseFirestore.instance
          .collection('rooms')
          .where('pgId', isEqualTo: pgId)
          .where('roomNumber', isEqualTo: roomNumber)
          .get();

      if (existingRoom.docs.isEmpty) {
        await FirebaseFirestore.instance.collection('rooms').add({
          'pgId': pgId,
          'roomNumber': roomNumber,
          'totalBeds': totalBeds,
        });

        _roomNumberController.clear();
        _totalBedsController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Room number already exists.')),
        );
      }
    }
  }

  Stream<QuerySnapshot> _roomsStream() {
    return FirebaseFirestore.instance
        .collection('rooms')
        .where('pgId', isEqualTo: pgId)
        .snapshots();
  }

  Future<int> _getOccupiedBeds(String roomNumber) async {
    final residents = await FirebaseFirestore.instance
        .collection('residents')
        .where('pgId', isEqualTo: pgId)
        .where('roomNumber', isEqualTo: roomNumber)
        .get();
    return residents.docs.length;
  }

  Future<void> _deleteRoom(String roomNumber, DocumentReference roomRef) async {
    final assignedSnapshot = await FirebaseFirestore.instance
        .collection('residents')
        .where('pgId', isEqualTo: pgId)
        .where('roomNumber', isEqualTo: roomNumber)
        .get();
    if (assignedSnapshot.docs.isNotEmpty) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Cannot Delete Room'),
            content: Text('Residents are assigned to this room.'),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      await roomRef.delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (pgId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Room Management')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Room Management'),
        backgroundColor: Colors.blue[300],
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _roomNumberController,
                    decoration: InputDecoration(
                      labelText: 'Room Number',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter room number'
                        : null,
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _totalBedsController,
                    decoration: InputDecoration(
                      labelText: 'Total Beds',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter total beds'
                        : null,
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addRoom,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        'Add Room',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _roomsStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();
                  final rooms = snapshot.data!.docs;

                  // Sort rooms numerically based on roomNumber
                  rooms.sort((a, b) {
                    int roomA = int.tryParse(a['roomNumber']) ?? 0;
                    int roomB = int.tryParse(b['roomNumber']) ?? 0;
                    return roomA.compareTo(roomB);
                  });

                  int totalRooms = rooms.length;
                  int totalBeds = rooms.fold(
                      0, (sum, doc) => sum + (doc['totalBeds'] as int));

                  return FutureBuilder<List<int>>(
                    future: Future.wait(rooms
                        .map((doc) => _getOccupiedBeds(doc['roomNumber']))
                        .toList()),
                    builder: (context, occupiedBedsSnapshot) {
                      if (!occupiedBedsSnapshot.hasData)
                        return CircularProgressIndicator();
                      final occupiedBedsList = occupiedBedsSnapshot.data!;
                      int occupiedBeds =
                          occupiedBedsList.fold(0, (sum, count) => sum + count);

                      int availableBeds = totalBeds - occupiedBeds;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatCard(
                                  'Total Rooms', totalRooms.toString()),
                              _buildStatCard(
                                  'Total Beds', totalBeds.toString()),
                              _buildStatCard(
                                  'Available Beds', availableBeds.toString()),
                            ],
                          ),
                          SizedBox(height: 20),
                          Expanded(
                            child: ListView.builder(
                              itemCount: rooms.length,
                              itemBuilder: (context, index) {
                                final room = rooms[index];
                                final occupied = occupiedBedsList[index];
                                final available = room['totalBeds'] - occupied;
                                return Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  elevation: 4,
                                  margin: EdgeInsets.symmetric(vertical: 8.0),
                                  child: ListTile(
                                    title: Text('Room ${room['roomNumber']}'),
                                    subtitle: Text(
                                        'Beds: ${room['totalBeds']} | Occupied: $occupied | Available: $available'),
                                    trailing: IconButton(
                                      icon:
                                          Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteRoom(
                                          room['roomNumber'], room.reference),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      elevation: 4,
      child: Container(
        width: 100,
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
