import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/constants.dart';
import '../models/booking.dart';

class DriverBookingService {
  final http.Client _httpClient = http.Client();
  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
    print('DriverBookingService token set: $_authToken');
  }

  Future<List<Map<String, dynamic>>> fetchAvailableRides() async {
    if (_authToken == null) throw Exception('Authentication token not set');
    final url = Uri.parse('$baseUrl/available-rides');
    print('Fetching rides from: $url with token: $_authToken');
    try {
      final response = await _httpClient.get(
        url,
        headers: {'Authorization': 'Bearer $_authToken'},
      );
      print('Fetch rides status: ${response.statusCode}');
      print('Fetch rides body: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to fetch rides: ${response.statusCode} - ${response.body}');
      }
      final List<dynamic> ridesJson = jsonDecode(response.body);
      return ridesJson
          .map((json) => {
                'booking_id': json['booking_id'].toString(),
                'pickup': {
                  'lat': json['pickup']['lat'] as double,
                  'lng': json['pickup']['lng'] as double,
                },
                'dropoff': {
                  'lat': json['dropoff']['lat'] as double,
                  'lng': json['dropoff']['lng'] as double,
                },
                'ride_type': json['ride_type'] as String,
                'estimated_fare': (json['estimated_fare'] as num).toDouble(),
              })
          .toList();
    } catch (e) {
      print('Fetch rides error: $e');
      rethrow;
    }
  }

  Future<BookingResponse> acceptRide(String bookingId) async {
    if (_authToken == null) throw Exception('Authentication token not set');
    final url = Uri.parse('$baseUrl/accept-ride/$bookingId');
    print('Accepting ride at: $url');
    try {
      final response = await _httpClient.post(
        url,
        headers: {'Authorization': 'Bearer $_authToken'},
      );
      print('Accept ride status: ${response.statusCode}');
      print('Accept ride body: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to accept ride: ${response.statusCode} - ${response.body}');
      }
      return BookingResponse.fromJson(jsonDecode(response.body));
    } catch (e) {
      print('Accept ride error: $e');
      rethrow;
    }
  }

  Future<void> updateDriverStatus(String status) async {
    if (_authToken == null) throw Exception('Authentication token not set');
    final url = Uri.parse('$baseUrl/driver/status');
    print('Updating driver status to: $status at $url');
    try {
      final response = await _httpClient.post(
        url,
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': status}),
      );
      print('Update status response status: ${response.statusCode}');
      print('Update status response body: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to update status: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Update status error: $e');
      rethrow;
    }
  }

  Future<RouteData> getRouteData(LatLng origin, LatLng destination) async {
    final url =
        Uri.parse('https://maps.googleapis.com/maps/api/directions/json?'
            'origin=${origin.latitude},${origin.longitude}&'
            'destination=${destination.latitude},${destination.longitude}&'
            'key=$google_api_key');
    print('Fetching route from: $url');
    try {
      final response = await _httpClient.get(url);
      print('Route fetch status: ${response.statusCode}');
      print('Route fetch body: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to fetch route data: ${response.statusCode} - ${response.body}');
      }
      final data = jsonDecode(response.body);
      if (data['routes'].isEmpty) {
        throw Exception('No routes found between origin and destination');
      }
      final route = data['routes'][0]['legs'][0];
      final polylinePoints =
          data['routes'][0]['overview_polyline']['points'] as String?;
      final List<LatLng> coordinates = polylinePoints != null
          ? _decodePoly(polylinePoints)
          : [origin, destination];
      final distanceText = route['distance']['text'] ?? 'Unknown';
      final distanceValue = (route['distance']['value'] as int? ?? 0) /
          1000; // Convert meters to km
      final durationText = route['duration']['text'] ?? 'Unknown';
      return RouteData(
        coordinates: coordinates,
        distance: distanceText,
        distanceValue: distanceValue,
        duration: durationText,
      );
    } catch (e) {
      print('Route fetch error: $e');
      return RouteData(
        coordinates: [origin, destination],
        distance: 'Unknown',
        distanceValue: 0.0,
        duration: 'Unknown',
      );
    }
  }

  Future<Map<String, dynamic>> fetchDriverProfile() async {
    if (_authToken == null) throw Exception('Authentication token not set');
    final url = Uri.parse('$baseUrl/driver/profile');
    print('Fetching driver profile from: $url with token: $_authToken');
    try {
      final response = await _httpClient.get(
        url,
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );
      print('Fetch profile status: ${response.statusCode}');
      print('Fetch profile body: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to fetch profile: ${response.statusCode} - ${response.body}');
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      print('Fetch profile error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchDriverRides() async {
    if (_authToken == null) throw Exception('Authentication token not set');
    final url = Uri.parse('$baseUrl/driver/rides');
    print('Fetching driver rides from: $url with token: $_authToken');
    try {
      final response = await _httpClient.get(
        url,
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );
      print('Fetch rides status: ${response.statusCode}');
      print('Fetch rides body: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to fetch rides: ${response.statusCode} - ${response.body}');
      }
      return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Fetch rides error: $e');
      rethrow;
    }
  }

  List<LatLng> _decodePoly(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    print('Decoded polyline points: ${points.length}');
    return points;
  }
}
