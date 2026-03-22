import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../core/config/app_config.dart';
import '../../core/repositories/session_manager.dart';
import 'signup_screen.dart';
import '../dashboard/resident_dashboard.dart';
import '../dashboard/worker_dashboard.dart';
import '../dashboard/admin_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final _formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();

  bool isLoginLoading = false;
  bool isSignupLoading = false;

  List apartments = [];
  String? selectedApartmentId;

  @override
  void initState() {
    super.initState();
    loadApartments();
  }

  bool _validatePhone() {
    final phone = phoneController.text.trim();

    if (phone.isEmpty) {
      _showSnack("Phone number is required");
      return false;
    }

    if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      _showSnack("Enter valid 10-digit phone number");
      return false;
    }

    return true;
  }

  Future<void> login() async {

    if (!_validatePhone()) return;

    if (selectedApartmentId == null) {
      _showSnack("Please select apartment");
      return;
    }

    setState(() => isLoginLoading = true);

    try {
      final phone = phoneController.text.trim();
      final apartmentId = selectedApartmentId!;

      final response = await http.post(
        Uri.parse("${AppConfig.baseUrl}/api/users/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone": phone,
          "apartmentId": apartmentId,
        }),
      );

      final data = jsonDecode(response.body);

      if (data["success"] != true) {
        _showSnack(data["message"]);
        setState(() => isLoginLoading = false);
        return;
      }

      final token = data["token"];
      final user = data["user"];
      final role = user["role"];
      final name = user["name"];
      final userId = user["id"];
      final flatNumber = user["flatNumber"];
      final flatId = user["flatId"];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("authToken", token);
      await prefs.setString("userRole", role);
      await prefs.setString("userName", name);

      SessionManager.setSession(
        id: userId,
        apartmentId: apartmentId,
        userName: name,
        userRole: role.toLowerCase(),
        userPhone: phone,
        flatNumber: flatNumber ?? "",
        flatId: flatId ?? "",
        workerService: user["workerProfile"]?["service"],
      );

      setState(() => isLoginLoading = false);

      if (role == "RESIDENT") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ResidentDashboard()),
        );
      } else if (role == "WORKER") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WorkerDashboard()),
        );
      } else if (role == "ADMIN") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
      }

    } catch (e) {
      _showSnack("Server not reachable");
      setState(() => isLoginLoading = false);
    }
  }

  Future<void> loadApartments() async {
    try {
      final response = await http.get(
        Uri.parse("${AppConfig.baseUrl}/api/apartments/list"),
      );

      final data = jsonDecode(response.body);

      if (data["success"]) {
        setState(() {
          apartments = data["data"] ?? [];

        // 🔥 RESET selection when new data loads
        selectedApartmentId = null;
      });
      }
    } catch (e) {
      _showSnack("Failed to load apartments");
    }
  }

  Future<void> goToSignup() async {

    if (!_validatePhone()) return;

    if (selectedApartmentId == null) {
      _showSnack("Please select apartment");
      return;
    }

    setState(() => isSignupLoading = true);

    try {
      final apartmentId = selectedApartmentId!;

      final response = await http.get(
        Uri.parse(
          "${AppConfig.baseUrl}/api/users/check-user"
          "?phone=${Uri.encodeComponent(phoneController.text.trim())}"
          "&apartmentId=$apartmentId",
        ),
      );

      final data = jsonDecode(response.body);

      if (data["exists"] == true) {
        _showSnack("Account already exists. Please login.");
        setState(() => isSignupLoading = false);
        return;
      }

      setState(() => isSignupLoading = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SignupScreen(
            phoneNumber: phoneController.text.trim(),
          ),
        ),
      );

    } catch (e) {
      _showSnack("Server not reachable");
      setState(() => isSignupLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [

              const Icon(
                Icons.apartment,
                size: 70,
                color: Color(0xFF4F46E5),
              ),

              const SizedBox(height: 16),

              const Text(
                "SmartApartment Services",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Smart Living Simplified",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 40),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      color: Colors.black.withOpacity(0.05),
                    )
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [

                      /// 🔥 DROPDOWN
                     DropdownButtonFormField<String>(
                      isExpanded: true,

                      value: apartments.any((apt) =>
                              apt["id"].toString() == selectedApartmentId)
                          ? selectedApartmentId
                          : null,

                      hint: const Text("Select Apartment"),

                      items: apartments.map<DropdownMenuItem<String>>((apt) {
                        final id = apt["id"].toString(); // ✅ FIXED

                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text(
                            "${apt["name"]} (${apt["code"]})", // ✅ FIXED
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),

                      onChanged: (String? value) {
                        print("Selected Apartment ID: $value"); // debug

                        setState(() {
                          selectedApartmentId = value;
                        });
                      },

                      decoration: InputDecoration(
                        labelText: "Select Apartment",
                        prefixIcon: const Icon(Icons.apartment),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                      const SizedBox(height: 15),

                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Phone number is required";
                          }
                          if (!RegExp(r'^[0-9]{10}$')
                              .hasMatch(value.trim())) {
                            return "Enter valid 10-digit phone number";
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: "Phone Number",
                          counterText: "",
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoginLoading
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    login();
                                  }
                                },
                          child: isLoginLoading
                              ? const CircularProgressIndicator()
                              : const Text("Login"),
                        ),
                      ),

                      const SizedBox(height: 15),

                      TextButton(
                        onPressed: isSignupLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  goToSignup();
                                }
                              },
                        child: isSignupLoading
                            ? const CircularProgressIndicator()
                            : const Text("New user? Create Account"),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}