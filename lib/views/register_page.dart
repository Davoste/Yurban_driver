import 'dart:convert';
import 'package:Yurban/controllers/authentication.dart';
import 'package:Yurban/views/login_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _phonecontroller = TextEditingController();
  final TextEditingController _pincontroller = TextEditingController();
  final TextEditingController _namecontroller = TextEditingController();
  final TextEditingController _emailcontroller = TextEditingController();
  final TextEditingController _passwordcontroller = TextEditingController();

  final AuthenticationController _authenticationController =
      Get.put(AuthenticationController());

  String? _selectedCounty;
  String? _selectedSubCounty;
  List<String> _counties = [];
  Map<String, List<String>> _subCounties = {};

  @override
  void initState() {
    super.initState();
    _fetchCounties();
  }

  Future<void> _fetchCounties() async {
    try {
      var response = await http
          .get(Uri.parse("http://35.179.130.132:8000/api/config/counties"));
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          _counties = data.keys.toList();
          _subCounties =
              data.map((key, value) => MapEntry(key, List<String>.from(value)));
        });
      } else {
        print("Failed to fetch counties: ${response.body}");
      }
    } catch (e) {
      print("Error fetching counties: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Register',
                  style: GoogleFonts.poppins(fontSize: size * 0.080),
                ),
                const SizedBox(height: 20),

                /// Name Input
                TextField(
                  controller: _namecontroller,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                /// Email Input
                TextField(
                  controller: _emailcontroller,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                /// Phone Input
                TextField(
                  controller: _phonecontroller,
                  decoration: InputDecoration(
                    labelText: '07xx xxx xxx',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                /// Pin Input
                TextField(
                  controller: _pincontroller,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Pin',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                /// County Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCounty,
                  hint: Text("Select County"),
                  items: _counties
                      .map((county) => DropdownMenuItem(
                            value: county,
                            child: Text(county),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCounty = value;
                      _selectedSubCounty = null;
                    });
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                /// Sub-county Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedSubCounty,
                  hint: Text("Select Sub-county"),
                  items: _selectedCounty != null
                      ? _subCounties[_selectedCounty]!
                          .map((subCounty) => DropdownMenuItem(
                                value: subCounty,
                                child: Text(subCounty),
                              ))
                          .toList()
                      : [],
                  onChanged: (value) {
                    setState(() {
                      _selectedSubCounty = value;
                    });
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                /// Register Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 10),
                  ),
                  onPressed: () async {
                    await _authenticationController.register(
                      name: _namecontroller.text.trim(),
                      email: _emailcontroller.text.trim(),
                      password: _passwordcontroller.text.trim(),
                      phone: _phonecontroller.text.trim(),
                      pin: _pincontroller.text.trim(),
                      county: _selectedCounty ?? '',
                      sub_county: _selectedSubCounty ?? '',
                    );
                  },
                  child: Obx(() {
                    return _authenticationController.isLoading.value
                        ? const Center(
                            child:
                                CircularProgressIndicator(color: Colors.white))
                        : Text(
                            'Register',
                            style: GoogleFonts.poppins(
                                fontSize: size * 0.040, color: Colors.white),
                          );
                  }),
                ),
                const SizedBox(height: 20),

                /// Login Button
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginPage(),
                      ),
                    );
                  },
                  child: Text(
                    'Login',
                    style: GoogleFonts.poppins(
                      fontSize: size * 0.040,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
