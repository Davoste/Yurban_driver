import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/driver_booking_service.dart';
import 'package:Yurban/views/driver_detail.dart';
import 'package:Yurban/views/driver_rides_screen.dart';
import 'package:Yurban/views/driver_tracking_screen.dart';

class DriverLandingScreen extends StatefulWidget {
  final String token;

  const DriverLandingScreen({super.key, required this.token});

  @override
  State<DriverLandingScreen> createState() => _DriverLandingScreenState();
}

class _DriverLandingScreenState extends State<DriverLandingScreen> {
  final DriverBookingService _bookingService = Get.find<DriverBookingService>();
  bool isOnline = false;
  List<Map<String, dynamic>> availableRides = [];
  final Completer<GoogleMapController> _mapController = Completer();
  static const LatLng _sampleLocation = LatLng(-1.292066, 36.821946); // Nairobi
  bool isLoading = false;
  Timer? _rideFetchTimer;

  @override
  void initState() {
    super.initState();
    _bookingService.setAuthToken(widget.token);
    print('DriverLandingScreen token: ${widget.token}');
    _fetchInitialStatus();
  }

  Future<void> _fetchInitialStatus() async {
    setState(() => isLoading = true);
    try {
      print('Fetching initial status with token: ${widget.token}');
      isOnline = false; // Default, will replace with API fetch when available
    } catch (e) {
      _showSnackBar('Error fetching status: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchAvailableRides() async {
    if (!isOnline) return;
    setState(() => isLoading = true);
    try {
      availableRides = await _bookingService.fetchAvailableRides();
      print('Fetched ${availableRides.length} available rides from API');
    } catch (e) {
      _showSnackBar('Error fetching rides: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _startRidePolling() {
    _rideFetchTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && isOnline) _fetchAvailableRides();
    });
  }

  Future<void> _toggleOnlineStatus() async {
    setState(() => isLoading = true);
    try {
      final newStatus = isOnline ? 'offline' : 'online';
      print('Updating status to: $newStatus');
      await _bookingService.updateDriverStatus(newStatus);
      setState(() {
        isOnline = !isOnline;
        if (isOnline) {
          _fetchAvailableRides();
          _startRidePolling();
        } else {
          availableRides.clear();
          _rideFetchTimer?.cancel();
        }
      });
    } catch (e) {
      _showSnackBar('Error updating status: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _acceptRide(
      String bookingId, LatLng pickup, LatLng dropoff) async {
    setState(() => isLoading = true);
    try {
      print('Accepting ride with ID: $bookingId');
      final response = await _bookingService.acceptRide(bookingId);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DriverRideTrackingScreen(
              bookingResponse: response,
              pickup: pickup,
              destination: dropoff,
            ),
          ),
        );
      }
    } catch (e) {
      _showSnackBar('Error accepting ride: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Yurban Driver',
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
      drawer: _buildNavigationDrawer(),
      body: Column(
        children: [
          _buildMapSection(),
          Expanded(child: _buildRideList()),
          _buildStatusButton(),
          if (isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildNavigationDrawer() => Drawer(
        backgroundColor: Colors.black,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.white),
              child: Text(
                'Driver Menu',
                style: GoogleFonts.orbitron(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            _buildDrawerItem(Icons.home, 'Home', () => Get.back()),
            _buildDrawerItem(Icons.person, 'Profile',
                () => Get.to(() => DriverProfileScreen(token: widget.token))),
            _buildDrawerItem(Icons.directions_car, 'My Rides',
                () => Get.to(() => const DriverMyRidesScreen())),
          ],
        ),
      );

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) =>
      ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        onTap: onTap,
        selected: title == 'Home',
        selectedTileColor: Colors.white.withOpacity(0.1),
      );

  Widget _buildMapSection() => Container(
        height: 350,
        child: GoogleMap(
          initialCameraPosition:
              const CameraPosition(target: _sampleLocation, zoom: 13),
          onMapCreated: (controller) => _mapController.complete(controller),
          markers: {
            Marker(
              markerId: const MarkerId('current'),
              position: _sampleLocation,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed),
            ),
          },
          mapType: MapType.normal,
          liteModeEnabled: false,
        ),
      );

  Widget _buildRideList() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Rides',
              style: GoogleFonts.orbitron(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            if (!isOnline)
              Text(
                'Go online to see ride requests',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              )
            else if (availableRides.isEmpty)
              Text(
                'No ride requests available',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: availableRides.length,
                  itemBuilder: (context, index) {
                    final ride = availableRides[index];
                    final pickup =
                        LatLng(ride['pickup']['lat'], ride['pickup']['lng']);
                    final dropoff =
                        LatLng(ride['dropoff']['lat'], ride['dropoff']['lng']);
                    return _buildRideCard(ride, pickup, dropoff);
                  },
                ),
              ),
          ],
        ),
      );

  Widget _buildRideCard(
          Map<String, dynamic> ride, LatLng pickup, LatLng dropoff) =>
      Card(
        elevation: 0, // Flat design
        color: Colors.black.withOpacity(0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ride: ${ride['ride_type']}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pickup: ${pickup.latitude}, ${pickup.longitude}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              Text(
                'Dropoff: ${dropoff.latitude}, ${dropoff.longitude}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              Text(
                'Fare: KSH ${ride['estimated_fare'].toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () =>
                    _acceptRide(ride['booking_id'], pickup, dropoff),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(
                  'Accept',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildStatusButton() => Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _toggleOnlineStatus,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: isOnline ? Colors.white : Colors.black,
            foregroundColor: isOnline ? Colors.black : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.white.withOpacity(0.5)),
            ),
          ),
          child: Text(
            isOnline ? 'Go Offline' : 'Go Online',
            style: GoogleFonts.orbitron(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

  Widget _buildLoadingOverlay() => Container(
        color: Colors.black.withOpacity(0.5),
        child:
            const Center(child: CircularProgressIndicator(color: Colors.white)),
      );

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _rideFetchTimer?.cancel();
    super.dispose();
  }
}
