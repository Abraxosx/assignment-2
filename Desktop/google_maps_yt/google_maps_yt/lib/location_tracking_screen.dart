import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';

class LocationTrackingScreen extends StatefulWidget {
  const LocationTrackingScreen({super.key});

  @override
  LocationTrackingScreenState createState() => LocationTrackingScreenState();
}

class LocationTrackingScreenState extends State<LocationTrackingScreen> {
  GoogleMapController? mapController;
  LatLng _currentPosition = const LatLng(35.590484, 45.464158); // Set initial coordinates here
  bool _isLoading = true;
  final DatabaseReference _locationRef = FirebaseDatabase.instance.ref('locations');

  @override
  void initState() {
    super.initState();
    setState(() {
      _isLoading = false;
    });
  }

  void _determinePosition() async {
    Position position = await _getGeoLocationPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentPosition,
          zoom: 15,
        ),
      ),
    );
  }

  Future<Position> _getGeoLocationPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    // Center the map on the initial coordinates
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentPosition,
          zoom: 15,
        ),
      ),
    );
  }

  void _getChildLocation() {
    _locationRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        final latitude = data['latitude'];
        final longitude = data['longitude'];
        final LatLng newPosition = LatLng(latitude, longitude);
        setState(() {
          _currentPosition = newPosition;
        });
        mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: newPosition,
              zoom: 15,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _determinePosition,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition,
                    zoom: 15,
                  ),
                  mapType: MapType.normal,  // Ensure the map type is set to normal
                  markers: {
                    Marker(
                      markerId: const MarkerId('currentLocation'),
                      position: _currentPosition,
                    ),
                  },
                ),
                Positioned(
                  bottom: 50,
                  left: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Location:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text('Latitude: ${_currentPosition.latitude}'),
                        Text('Longitude: ${_currentPosition.longitude}'),
                        const SizedBox(height: 5),
                        const Text('Additional Information:'),
                        const Text('Place Name: school'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
