import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteData {
  final List<LatLng> coordinates;
  final String distance;
  final String duration;

  RouteData({
    required this.coordinates,
    required this.distance,
    required this.duration,
  });
}
