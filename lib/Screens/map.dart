/*

import 'package:flutter/material.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  Position? _currentPosition;
  LatLng _center = const LatLng(0, 0);
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  TextEditingController _destinationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
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

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
      _center = LatLng(position.latitude, position.longitude);
      _markers.add(Marker(
        markerId: MarkerId('current_location'),
        position: _center,
        infoWindow: InfoWindow(title: 'Current Location'),
      ));
    });
    mapController?.animateCamera(CameraUpdate.newLatLng(_center));
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _getDirections() async {
    if (_currentPosition == null) return;

    final destination = _destinationController.text;
    final directions = await _getDirectionsFromApi(
        _currentPosition!, destination);

    setState(() {
      _polylines.add(Polyline(
        polylineId: PolylineId('route'),
        points: directions,
        color: Colors.blue,
        width: 5,
      ));

      if (directions.isNotEmpty) {
        _markers.add(Marker(
          markerId: MarkerId('destination'),
          position: directions.last,
          infoWindow: InfoWindow(title: 'Destination'),
        ));
      }
    });

    mapController?.animateCamera(CameraUpdate.newLatLngBounds(
        _boundsFromLatLngList(directions), 50));
  }

  Future<List<LatLng>> _getDirectionsFromApi(Position start, String destination) async {
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      'YOUR_GOOGLE_MAPS_API_KEY', // Replace with your Google Maps API Key
      PointLatLng(start.latitude, start.longitude),
      PointLatLng(0, 0), // You need to geocode the destination string to get LatLng
      mode: TravelMode.driving,
    );

    if (result.points.isNotEmpty) {
      return result.points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
    }

    return [];
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
        northeast: LatLng(x1!, y1!), southwest: LatLng(x0!, y0!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map Screen'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _destinationController,
              decoration: InputDecoration(
                hintText: 'Enter destination',
                suffixIcon: IconButton(
                  icon: Icon(Icons.directions),
                  onPressed: _getDirections,
                ),
              ),
            ),
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 11.0,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
        ],
      ),
    );
  }
}



*/
