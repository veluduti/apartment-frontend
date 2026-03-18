import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import 'dart:convert';

class RegisterResidentScreen extends StatefulWidget {
  final String phoneNumber;
  final String apartmentId;

  const RegisterResidentScreen({
    super.key,
    required this.phoneNumber,
    required this.apartmentId,
  });

  @override
  State<RegisterResidentScreen> createState() =>
      _RegisterResidentScreenState();
}

class _RegisterResidentScreenState
    extends State<RegisterResidentScreen> {

  static const Color primaryColor = Color(0xFF4F46E5);

  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final flatController = TextEditingController();

  bool isLoading = false;

  List blocks = [];
  List flats = [];

  String? selectedBlockId;
  String? selectedFlatId;

  @override
  void initState() {
    super.initState();
    fetchBlocks();
  }

  Future<void> fetchBlocks() async {
    try {
      final response = await http.get(
        Uri.parse(
          "${ApiConfig.baseUrl}/api/blocks?apartmentId=${widget.apartmentId}",
        ),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        setState(() {
          blocks = data["data"];
        });
      }
    } catch (_) {}
  }

  Future<void> fetchFlats(String blockId) async {
    try {
      final response = await http.get(
        Uri.parse(
          "${ApiConfig.baseUrl}/api/flats?blockId=$blockId",
        ),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        setState(() {
          flats = data["data"];
        });
      }
    } catch (_) {}
  }

  void registerResident() async {

    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.register()),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": nameController.text.trim(),
          "phone": widget.phoneNumber,
          "email": emailController.text.trim(),
          "role": "RESIDENT",
          "apartmentId": widget.apartmentId,
          "blockId": selectedBlockId,
          "flatId": selectedFlatId,
          "flatNumber": flatController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Registration submitted. Await admin approval.",
            ),
          ),
        );

        Navigator.of(context)
            .popUntil((route) => route.isFirst);
      } else {
        _showSnack(data["message"]);
      }

    } catch (_) {
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
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Resident Registration",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [

                // Name
                TextFormField(
                  controller: nameController,
                  validator: (v) =>
                  v == null || v.trim().isEmpty
                      ? "Full Name is required"
                      : null,
                  decoration: _inputDecoration("Full Name"),
                ),

                const SizedBox(height: 18),

                // Email
                TextFormField(
                  controller: emailController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return "Email is required";
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                        .hasMatch(v)) {
                      return "Enter valid email";
                    }
                    return null;
                  },
                  decoration: _inputDecoration("Email"),
                ),

                const SizedBox(height: 18),

                // Block
                DropdownButtonFormField<String>(
                  value: selectedBlockId,
                  validator: (v) =>
                  v == null ? "Block is required" : null,
                  decoration: _inputDecoration("Select Block"),
                  items: blocks.map<DropdownMenuItem<String>>((b) {
                    return DropdownMenuItem(
                      value: b["id"],
                      child: Text(b["name"]),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedBlockId = value;
                      selectedFlatId = null;
                      flats = [];
                    });
                    if (value != null) fetchFlats(value);
                  },
                ),

                const SizedBox(height: 18),

                // Flat
                DropdownButtonFormField<String>(
                  value: selectedFlatId,
                  validator: (v) =>
                  v == null ? "Flat is required" : null,
                  decoration: _inputDecoration("Select Flat"),
                  items: flats.map<DropdownMenuItem<String>>((f) {
                    return DropdownMenuItem(
                      value: f["id"],
                      child: Text(f["number"]),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedFlatId = value;
                    });
                  },
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(14),
                      ),
                    ),
                    onPressed:
                    isLoading ? null : registerResident,
                    child: isLoading
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                        : const Text(
                      "Register",
                      style: TextStyle(
                          fontWeight: FontWeight.bold),
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}