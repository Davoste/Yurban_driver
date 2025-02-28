import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteData {
  final List<LatLng> coordinates;
  final String distance; // e.g., "5.2 km"
  final double distanceValue; // e.g., 5.2 (in km)
  final String duration;

  RouteData({
    required this.coordinates,
    required this.distance,
    required this.distanceValue,
    required this.duration,
  });
}

class BookingResponse {
  final int bookingId;
  final String? status;
  final int? driverId;
  final String? estimatedArrival;

  BookingResponse({
    required this.bookingId,
    this.status,
    this.driverId,
    this.estimatedArrival,
  });

  factory BookingResponse.fromJson(Map<String, dynamic> json) {
    return BookingResponse(
      bookingId: json['booking_id'] as int,
      status: json['status'] as String?,
      driverId: json['driver_id'] as int?,
      estimatedArrival: json['estimated_arrival'] as String?,
    );
  }
}
