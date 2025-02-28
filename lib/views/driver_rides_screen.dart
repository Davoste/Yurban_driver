import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/driver_booking_service.dart';

class DriverMyRidesScreen extends StatelessWidget {
  const DriverMyRidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DriverBookingService bookingService =
        Get.find<DriverBookingService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Rides',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[900]!, Colors.grey[800]!],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ride History',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchMyRides(bookingService),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(color: Colors.teal));
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading rides: ${snapshot.error}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'No ride history available',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }

                    final myRides = snapshot.data!;
                    return ListView.builder(
                      itemCount: myRides.length,
                      itemBuilder: (context, index) {
                        final ride = myRides[index];
                        return _buildRideCard(ride);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchMyRides(
      DriverBookingService bookingService) async {
    try {
      final ridesData = await bookingService.fetchDriverRides();
      return ridesData
          .map((ride) => ({
                'id': ride['booking_id'].toString(),
                'type': ride['ride_type'] ?? 'Unknown',
                'fare': (ride['estimated_fare'] as num?)?.toStringAsFixed(2) ??
                    '0.00',
                'date':
                    (ride['created_at'] as String?)?.substring(0, 10) ?? 'N/A',
              }))
          .toList();
    } catch (e) {
      //throw Exception('Failed to fetch rides: $e');
      throw Exception('Failed to fetch rides:');
    }
  }

  Widget _buildRideCard(Map<String, dynamic> ride) => Card(
        elevation: 4,
        color: Colors.grey[850],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ride ID: ${ride['id']}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Type: ${ride['type']}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
              Text(
                'Fare: KSH ${ride['fare']}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
              Text(
                'Date: ${ride['date']}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      );
}
