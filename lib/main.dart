import 'package:Yurban/services/driver_booking_service.dart';
import 'package:Yurban/views/home.dart';
import 'package:Yurban/views/welcome.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  await GetStorage.init();
  Get.put(DriverBookingService());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = GetStorage();
    final token = storage.read('token');
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Yurban',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      //home: Welcome(),
      home: token != null ? DriverLandingScreen(token: token) : const Welcome(),
    );
  }
}
