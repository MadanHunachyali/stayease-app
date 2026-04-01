import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng _selectedLocation = LatLng(12.9716, 77.5946); // Default: Bangalore
  String _selectedAddress = 'Select a location on the map';

  void _onMapTap(LatLng position) async {
    setState(() {
      _selectedLocation = position;
      _selectedAddress = 'Fetching address...';
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        String area = place.subLocality ?? '';
        String city = place.locality ?? '';
        String state = place.administrativeArea ?? '';
        String country = place.country ?? '';

        String fullAddress = [
          if (area.isNotEmpty) area,
          if (city.isNotEmpty) city,
          if (state.isNotEmpty) state,
          if (country.isNotEmpty) country
        ].join(', ');

        setState(() {
          _selectedAddress = fullAddress;
        });
      } else {
        setState(() {
          _selectedAddress = "Address not found";
        });
      }
    } catch (e) {
      print("Geocoding error: $e");
      setState(() {
        _selectedAddress = "Error fetching address";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pick Location')),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedLocation,
                zoom: 12,
              ),
              onTap: _onMapTap,
              markers: {
                Marker(
                  markerId: MarkerId("selected"),
                  position: _selectedLocation,
                ),
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'Selected Address:\n$_selectedAddress',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.check),
        onPressed: () {
          Navigator.pop(context, {
            'latLng': _selectedLocation,
            'address': _selectedAddress,
          });
        },
      ),
    );
  }
}
