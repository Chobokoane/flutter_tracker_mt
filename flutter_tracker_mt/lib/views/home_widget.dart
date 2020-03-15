import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';


import '../app_colors.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage(String s, {Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State {
  @override
  void dispose() {
    if (_subscribtion != null) {
      _subscribtion.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tracker App"),
      ),
      body: GoogleMap(
          mapType: MapType.hybrid,
          initialCameraPosition: initialLocation,
          markers: Set.of((marker != null) ? [marker] : []),
          circles: Set.of((circle != null) ? [circle] : []),
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          }),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.location_searching),
        onPressed: getCurrentLocation,
      ),
    );
  }


  StreamSubscription _subscribtion;
  Location _locationTracker = Location();
  Marker marker;
  Circle circle;
  GoogleMapController _mapController;
  static final CameraPosition initialLocation = CameraPosition(
    target: LatLng(40.7128, -74.0060),
    zoom: 10.0,

  );

  Future<Uint8List> getMarker() async {
    ByteData byteData = await DefaultAssetBundle.of(context).load(
        "/assets/53-512.png");
    return byteData.buffer.asUint8List();
  }

  void updateMarkerAndCircle(LocationData newLocalData, Uint8List imageData) {
    LatLng latLng = LatLng(newLocalData.latitude, newLocalData.longitude);
    this.setState(() {
      marker = Marker(
          markerId: MarkerId("home"),
          position: latLng,
          rotation: newLocalData.heading,
          draggable: false,
          zIndex: 2,
          flat: true,
          anchor: Offset(0.5, 0.5),
          icon: BitmapDescriptor.fromBytes(imageData));
      circle = Circle(
          circleId: CircleId("car"),
          radius: newLocalData.accuracy,
          zIndex: 1,
          strokeColor: backgroundLightColor,
          center: latLng,
          fillColor: backgroundLightColor.withAlpha(70));
    });
  }

  void getCurrentLocation() async {
    try {
      Uint8List imageData = await getMarker();
      var location = await _locationTracker.getLocation();

      updateMarkerAndCircle(location, imageData);

      if (_subscribtion != null) {
        _subscribtion.cancel();
      }

      _subscribtion =
          _locationTracker.onLocationChanged().listen((newLocalData) {
            if (_mapController != null) {
              _mapController.animateCamera(CameraUpdate.newCameraPosition(
                  new CameraPosition(

                      target: LatLng(
                          newLocalData.latitude, newLocalData.longitude),
                      tilt: 45.0,
                      bearing: 90.0,
                      zoom: 14.00)));
              updateMarkerAndCircle(newLocalData, imageData);
            }
          }
          );
    } on PlatformException catch (e) {
      if (e.code == "PERMISION_DENIED") {
        debugPrint("permision_denied");
      }
    }
  }


}