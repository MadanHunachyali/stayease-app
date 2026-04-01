import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pg_details_screen.dart';

class PGSearchScreen extends StatefulWidget {
  @override
  _PGSearchScreenState createState() => _PGSearchScreenState();
}

class _PGSearchScreenState extends State<PGSearchScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  String searchText = '';
  Map<String, double> _ratingCache = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          searchText = value.trim().toLowerCase();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _controller,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by Name or Location',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('pgs').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  // 🔴 Display and log actual error
                  print("Firestore error: ${snapshot.error}");
                  return Center(
                    child: Text(
                      'Error loading PGs:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No PGs available'));
                }

                final allDocs = snapshot.data!.docs;

                final filteredDocs = searchText.isEmpty
                    ? allDocs
                    : allDocs.where((doc) {
                        final name = doc.data().toString().contains('pgName')
                            ? doc['pgName'].toString().toLowerCase()
                            : '';
                        final location = doc
                                .data()
                                .toString()
                                .contains('selectedLocation')
                            ? doc['selectedLocation'].toString().toLowerCase()
                            : '';
                        final manualLocation =
                            doc.data().toString().contains('manualLocation')
                                ? doc['manualLocation'].toString().toLowerCase()
                                : '';
                        return name.contains(searchText) ||
                            location.contains(searchText) ||
                            manualLocation.contains(searchText);
                      }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(child: Text('No PGs found'));
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final pg = filteredDocs[index];
                    final pgId = pg.id;
                    final pgName = pg.data().toString().contains('pgName')
                        ? pg['pgName']
                        : 'No Name';
                    final pgLocation =
                        pg.data().toString().contains('selectedLocation')
                            ? pg['selectedLocation']
                            : 'No Location';

                    return FutureBuilder<double>(
                      future: _ratingCache.containsKey(pgId)
                          ? Future.value(_ratingCache[pgId])
                          : getAverageRating(pgId).then((rating) {
                              _ratingCache[pgId] = rating;
                              return rating;
                            }),
                      builder: (context, ratingSnapshot) {
                        final avgRating = ratingSnapshot.data ?? 0.0;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PGDetailsScreen(pgData: pg),
                              ),
                            );
                          },
                          child: Card(
                            margin: EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.home,
                                          color: Colors.blueAccent, size: 28),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          pgName,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on,
                                          color: Colors.grey[700], size: 20),
                                      SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          pgLocation,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    children: List.generate(5, (starIndex) {
                                      double fractional = avgRating - starIndex;
                                      IconData icon;
                                      if (fractional >= 1) {
                                        icon = Icons.star;
                                      } else if (fractional >= 0.5) {
                                        icon = Icons.star_half;
                                      } else {
                                        icon = Icons.star_border;
                                      }
                                      return Icon(
                                        icon,
                                        color: Colors.amber,
                                        size: 28,
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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

  Future<double> getAverageRating(String pgId) async {
    try {
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('pgId', isEqualTo: pgId)
          .get();

      if (reviewsSnapshot.docs.isEmpty) return 0.0;

      final ratings = reviewsSnapshot.docs
          .map((doc) => (doc['rating'] ?? 0).toDouble())
          .toList();

      final average = ratings.reduce((a, b) => a + b) / ratings.length;
      return double.parse(average.toStringAsFixed(1));
    } catch (e) {
      print('Rating fetch error: $e');
      return 0.0;
    }
  }
}
