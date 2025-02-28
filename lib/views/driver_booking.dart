import 'dart:convert';
import 'package:http/http.dart' as http;
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
    print('Fetching rides from: $url');
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
                  'lat': json['pickup']['lat'],
                  'lng': json['pickup']['lng']
                },
                'dropoff': {
                  'lat': json['dropoff']['lat'],
                  'lng': json['dropoff']['lng']
                },
                'ride_type': json['ride_type'],
                'estimated_fare': json['estimated_fare'].toDouble(),
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

  Future<http.Response> updateDriverStatus(String status) async {
    if (_authToken == null) throw Exception('Authentication token not set');
    final url = Uri.parse('$baseUrl/driver/status');
    try {
      final response = await _httpClient.post(
        url,
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': status}),
      );
      print('Update status status: ${response.statusCode}');
      print('Update status body: ${response.body}');
      return response;
    } catch (e) {
      print('Update status error: $e');
      rethrow;
    }
  }
}
