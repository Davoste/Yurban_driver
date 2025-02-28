import 'dart:convert';
import 'package:Yurban/constants/constants.dart';
import 'package:Yurban/views/home.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:location/location.dart';

class AuthenticationController extends GetxController {
  final isLoading = false.obs;
  final token = ''.obs;
  final box = GetStorage();

  Future<Map<String, dynamic>> _getCurrentLocation() async {
    Location location = Location();
    LocationData locationData = await location.getLocation();
    return {
      "latitude": locationData.latitude,
      "longitude": locationData.longitude,
    };
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String pin,
    required String county,
    required String sub_county,
  }) async {
    try {
      isLoading.value = true;

      // Fetch the current location
      Map<String, dynamic> location = await _getCurrentLocation();

      var data = {
        'name': name,
        'email': email,
        'password': "password",
        'phone': phone,
        'pin': pin,
        'role': "driver",
        'county': county,
        'sub_county': sub_county,
        "latitude": location["latitude"].toString(),
        "longitude": location["longitude"].toString(),
      };

      var response = await http.post(
        Uri.parse('$baseUrl/appregister'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: data,
      );

      debugPrint("Response Status: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 201) {
        var responseData = json.decode(response.body);
        if (responseData['message'] == "Registration successful") {
          Get.snackbar(
            'Success',
            responseData['message'],
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );

          token.value = responseData['token'];
          box.write('token', token.value);
          //storage.write('token', token);

          Get.offAll(() => DriverLandingScreen(
                token: token.value,
              ));
        }
      } else {
        _handleErrorResponse(response);
      }
    } catch (e) {
      debugPrint("Exception: $e");
      Get.snackbar(
        'Error',
        'Failed to register. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _handleErrorResponse(http.Response response) {
    if (response.body.isNotEmpty) {
      try {
        var responseData = json.decode(response.body);

        if (responseData.containsKey('errors')) {
          Map<String, dynamic> errors = responseData['errors'];
          String errorMessage =
              errors.entries.map((e) => '${e.value.join("\n")}').join("\n\n");

          Get.snackbar(
            'Error',
            errorMessage,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        } else {
          Get.snackbar(
            'Error',
            responseData['message'] ?? 'Unknown error',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } catch (e) {
        debugPrint("JSON Decode Error: $e");
        Get.snackbar(
          'Error',
          'Invalid response from server',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } else {
      Get.snackbar(
        'Error',
        'Empty response from server',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  //login
  Future<void> login({
    required String phone,
    required String pin,
  }) async {
    try {
      isLoading.value = true;

      var data = {
        'phone': phone,
        'pin': pin,
      };

      var response = await http.post(
        Uri.parse('$baseUrl/appdriverlogin'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: data,
      );

      debugPrint("Response Status: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        if (response.statusCode == 200) {
          var responseData = json.decode(response.body);
          if (responseData['message'] == "Login successful") {
            // Show success message
            Get.snackbar(
              'Success',
              responseData['message'],
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );

            // Store token correctly
            token.value = responseData['token'];
            box.write('token', token.value);

            // Navigate to home page
            Get.offAll(() => DriverLandingScreen(
                  token: token.value,
                ));
          }
        }
      } else {
        if (response.body.isNotEmpty) {
          try {
            var responseData = json.decode(response.body);

            if (responseData.containsKey('errors')) {
              Map<String, dynamic> errors = responseData['errors'];

              // Extract error messages and combine them into a single string
              String errorMessage = errors.entries
                  .map((e) =>
                      '${e.value.join("\n")}') // Join multiple error messages for a field
                  .join(
                      "\n\n"); // Separate different fields' errors with spacing

              Get.snackbar(
                'Error',
                errorMessage,
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            } else {
              Get.snackbar(
                'Error',
                jsonDecode(response.body)['message'],
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            }
          } catch (e) {
            debugPrint("JSON Decode Error: $e");
            Get.snackbar(
              'Error',
              'Invalid response from server',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        } else {
          Get.snackbar(
            'Error',
            'Empty response from server',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      debugPrint("Exception: $e");
      Get.snackbar(
        'Error',
        'Failed to Login. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
