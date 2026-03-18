import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'role_selection_screen.dart';
import '../dashboard/resident_dashboard.dart';
import '../dashboard/worker_dashboard.dart';

class OtpScreen extends StatefulWidget {

  final String phoneNumber;
  final String apartmentId;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.apartmentId,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {

  final TextEditingController otpController = TextEditingController();
  bool isLoading = false;

  final String baseUrl = "http://192.168.1.180:5000";

  void verifyOTP() async {

    if (otpController.text.length != 6) {
      _showSnack("Enter valid 6 digit OTP");
      return;
    }

    setState(() => isLoading = true);

    try {

      final checkResponse = await http.get(
        Uri.parse(
          "$baseUrl/api/users/check-user"
          "?phone=${Uri.encodeComponent(widget.phoneNumber)}"
          "&apartmentId=${widget.apartmentId}",
        ),
      );

      final checkData = jsonDecode(checkResponse.body);

      if (checkData["exists"] == false) {

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RoleSelectionScreen(
              phoneNumber: widget.phoneNumber,
              apartmentId: widget.apartmentId,
            ),
          ),
        );

      } else {

        if (checkData["isActive"] == false) {

          _showSnack("Await admin approval");

        } else {

          final loginResponse = await http.post(
            Uri.parse("$baseUrl/api/users/login"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "phone": widget.phoneNumber,
              "apartmentId": widget.apartmentId,
            }),
          );

          final loginData = jsonDecode(loginResponse.body);

          if (loginData["success"] == true) {

            String role = loginData["data"]["role"];

            if (role == "RESIDENT") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const ResidentDashboard(),
                ),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const WorkerDashboard(),
                ),
              );
            }

          } else {
            _showSnack(loginData["message"]);
          }
        }
      }

    } catch (e) {
      _showSnack("Server not reachable");
    }

    setState(() => isLoading = false);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("OTP Verification",
            style: TextStyle(color: Colors.black)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const Icon(Icons.lock,
                    size: 50,
                    color: Color(0xFF1E3A8A)),

                const SizedBox(height: 16),

                Text(
                  "OTP sent to ${widget.phoneNumber}",
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 25),

                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: InputDecoration(
                    labelText: "Enter 6 digit OTP",
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF1E3A8A),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                    onPressed:
                        isLoading ? null : verifyOTP,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text("Verify"),
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