import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/booking.dart';
import '../services/driver_booking_service.dart';

class DriverRideTrackingScreen extends StatefulWidget {
  final BookingResponse bookingResponse;
  final LatLng pickup;
  final LatLng destination;

  const DriverRideTrackingScreen({
    super.key,
    required this.bookingResponse,
    required this.pickup,
    required this.destination,
  });

  @override
  State<DriverRideTrackingScreen> createState() =>
      _DriverRideTrackingScreenState();
}

class _DriverRideTrackingScreenState extends State<DriverRideTrackingScreen> {
  final DriverBookingService _bookingService = Get.find<DriverBookingService>();
  final Completer<GoogleMapController> _mapController = Completer();
  Set<Marker> markers = {};
  Map<PolylineId, Polyline> polylines = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    setState(() => isLoading = true);
    try {
      // Set red markers for pickup and destination
      markers.clear(); // Ensure no old markers persist
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: widget.pickup,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Pickup'),
      ));
      markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: widget.destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Destination'),
      ));
      print(
          'Markers set: ${markers.length}, Pickup: ${markers.elementAt(0).icon}, Destination: ${markers.elementAt(1).icon}');

      // Fetch and draw black polyline
      final routePoints =
          await _bookingService.getRouteData(widget.pickup, widget.destination);
      print('Route points fetched: ${routePoints.coordinates.length}');
      setState(() {
        polylines.clear(); // Clear old polylines
        polylines[const PolylineId('route')] = Polyline(
          polylineId: const PolylineId('route'),
          color: Colors.black,
          points: routePoints.coordinates,
          width: 5,
        );
        print(
            'Polylines updated: ${polylines.length}, Points: ${polylines[const PolylineId('route')]!.points.length}');
      });

      // Update camera to fit route after setting markers and polylines
      await _updateCameraToFitRoute();
    } catch (e) {
      print('Error initializing map: $e');
      setState(() {
        polylines.clear();
        polylines[const PolylineId('route')] = Polyline(
          polylineId: const PolylineId('route'),
          color: Colors.black,
          points: [widget.pickup, widget.destination],
          width: 5,
        );
        print(
            'Fallback polyline set: ${polylines.length}, Points: ${polylines[const PolylineId('route')]!.points.length}');
      });
      _showSnackBar('Failed to load route: $e');
      await _updateCameraToFitRoute();
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
          'Ride Tracking',
          style: GoogleFonts.orbitron(
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
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
                CameraPosition(target: widget.pickup, zoom: 13),
            onMapCreated: (controller) {
              _mapController.complete(controller);
              print('Map created, controller completed');
            },
            markers: markers,
            polylines: Set<Polyline>.of(polylines.values),
            mapType: MapType.normal,
            liteModeEnabled: false,
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildRideInfo(),
          ),
          if (isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildRideInfo() => Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking ID: ${widget.bookingResponse.bookingId}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${widget.bookingResponse.status ?? 'N/A'}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            Text(
              'Driver ID: ${widget.bookingResponse.driverId ?? 'Unknown'}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            Text(
              'ETA: ${widget.bookingResponse.estimatedArrival ?? 'N/A'}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      );

  Widget _buildLoadingOverlay() => Container(
        color: Colors.black.withOpacity(0.5),
        child:
            const Center(child: CircularProgressIndicator(color: Colors.white)),
      );

  Future<void> _updateCameraToFitRoute() async {
    try {
      final controller = await _mapController.future;
      final bounds = LatLngBounds(
        southwest: LatLng(
          widget.pickup.latitude < widget.destination.latitude
              ? widget.pickup.latitude
              : widget.destination.latitude,
          widget.pickup.longitude < widget.destination.longitude
              ? widget.pickup.longitude
              : widget.destination.longitude,
        ),
        northeast: LatLng(
          widget.pickup.latitude > widget.destination.latitude
              ? widget.pickup.latitude
              : widget.destination.latitude,
          widget.pickup.longitude > widget.destination.longitude
              ? widget.pickup.longitude
              : widget.destination.longitude,
        ),
      );
      print('Camera bounds: SW ${bounds.southwest}, NE ${bounds.northeast}');
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      print('Camera updated to fit route');
    } catch (e) {
      print('Error fitting route: $e');
    }
  }

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
}
