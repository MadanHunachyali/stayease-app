import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/pg_reviews.dart'; // Import the ReviewsScreen

class PGDetailsScreen extends StatefulWidget {
  final QueryDocumentSnapshot pgData;

  PGDetailsScreen({required this.pgData});

  @override
  _PGDetailsScreenState createState() => _PGDetailsScreenState();
}

class _PGDetailsScreenState extends State<PGDetailsScreen> {
  int currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final images = List<String>.from(widget.pgData['images'] ?? []);
    final latitude = widget.pgData['latitude'];
    final longitude = widget.pgData['longitude'];
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pgData['pgName']),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (images.isNotEmpty) ...[
              SizedBox(
                height: screenHeight * 0.25,
                child: PageView.builder(
                  itemCount: images.length,
                  onPageChanged: (index) {
                    setState(() {
                      currentImageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(images[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 10),
              // Dot indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: currentImageIndex == index
                          ? Colors.blue
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            ],
            SizedBox(height: 20),
            buildInfo('🏠 PG Name', widget.pgData['pgName']),
            buildInfo('📍 Location', widget.pgData['selectedLocation']),
            buildInfo('🗺️ Address', widget.pgData['manualLocation']),
            buildInfo('💰 Price', widget.pgData['price']),
            buildInfo('🛏️ Facilities', widget.pgData['facilities']),
            buildInfo('📞 Contact', widget.pgData['contact']),
            Divider(height: 30, thickness: 1),
            Text(
              '👤 Owner Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            buildInfo('🧑 Name', widget.pgData['ownerName']),
            buildInfo('✉️ Email', widget.pgData['ownerEmail']),
            buildInfo('📱 Contact', widget.pgData['ownerContact']),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.directions, color: Colors.white),
                  label: Text("Directions"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => openMap(latitude, longitude),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.reviews, color: Colors.white),
                  label: Text("Reviews"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // Navigate to ReviewsScreen when the button is pressed
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReviewsScreen(pgId: widget.pgData.id),
                      ),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            if (widget.pgData['contact'] != null)
              Center(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.call, color: Colors.white),
                  label: Text("Call Now"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => launch("tel:${widget.pgData['contact']}"),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildInfo(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        '$title: ${value ?? "Not Available"}',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  void openMap(dynamic lat, dynamic lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }
}
