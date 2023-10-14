import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geolocator/geolocator.dart';
 
Future<Position> determinePosition() async {
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
      return Future.error(
        'NoPermission');
    }
  }
  
  if (permission == LocationPermission.deniedForever) {
    return Future.error(
      'NoPermission');
  } 
 
  return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
}
 