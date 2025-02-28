import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/driver_booking_service.dart';

class DriverProfileScreen extends StatelessWidget {
  final String token;

  const DriverProfileScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    final DriverBookingService bookingService =
        Get.find<DriverBookingService>();
    bookingService.setAuthToken(token); //token muhimu

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.orbitron(
            // Futuristic font
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<Map<String, String>>(
          future: _fetchDriverProfile(bookingService),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading profile: ${snapshot.error}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  'No profile data available',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              );
            }

            final driverData = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Driver Profile',
                  style: GoogleFonts.orbitron(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                _buildProfileCard(driverData),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<Map<String, String>> _fetchDriverProfile(
      DriverBookingService bookingService) async {
    try {
      final profileData = await bookingService.fetchDriverProfile();
      return {
        'name': profileData['name'] ?? 'Unknown',
        'phone': profileData['phone'] ?? 'N/A',
        'email': profileData['email'] ?? 'N/A',
        'vehicle': profileData['vehicle'] ?? 'Not assigned',
      };
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }

  Widget _buildProfileCard(Map<String, String> data) => Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileRow(Icons.person, 'Name', data['name']!),
            const SizedBox(height: 16),
            _buildProfileRow(Icons.phone, 'Phone', data['phone']!),
            const SizedBox(height: 16),
            _buildProfileRow(Icons.email, 'Email', data['email']!),
            const SizedBox(height: 16),
            _buildProfileRow(Icons.directions_car, 'Vehicle', data['vehicle']!),
          ],
        ),
      );

  Widget _buildProfileRow(IconData icon, String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}
