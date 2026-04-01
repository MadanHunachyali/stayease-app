import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class LocationPicker extends StatefulWidget {
  @override
  _LocationPickerState createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late GoogleMapController mapController;
  LatLng _selectedLocation = LatLng(37.7749, -122.4194); // Default to SF

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _selectedLocation = LatLng(position.latitude, position.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select Location")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _selectedLocation,
          zoom: 15,
        ),
        onMapCreated: (controller) {
          mapController = controller;
        },
        markers: {
          Marker(
            markerId: MarkerId("selected-location"),
            position: _selectedLocation,
            draggable: true,
            onDragEnd: (newPosition) {
              setState(() {
                _selectedLocation = newPosition;
              });
            },
          ),
        },
        onTap: (newPosition) {
          setState(() {
            _selectedLocation = newPosition;
          });
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.check),
        onPressed: () {
          Navigator.pop(context, _selectedLocation);
        },
      ),
    );
  }
}
