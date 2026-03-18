// Full Worker Register File (All Fields Required)

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import 'dart:convert';

class RegisterWorkerScreen extends StatefulWidget {
  final String phoneNumber;
  final String apartmentId;

  const RegisterWorkerScreen({
    super.key,
    required this.phoneNumber,
    required this.apartmentId,
  });

  @override
  State<RegisterWorkerScreen> createState() =>
      _RegisterWorkerScreenState();
}

class _RegisterWorkerScreenState
    extends State<RegisterWorkerScreen> {

  static const Color primaryColor = Color(0xFF4F46E5);

  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final addressController = TextEditingController();
  final experienceController = TextEditingController();
  final govtIdController = TextEditingController();

  String? selectedGender;
  String? selectedProfession;

  bool isLoading = false;

  final genderList = ["Male", "Female", "Other"];
  final professionList = [
    "Iron",
    "Plumber",
    "Car Cleaner",
    "Maid"
  ];

  void registerWorker() async {

    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.register()),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": nameController.text.trim(),
          "phone": widget.phoneNumber,
          "role": "WORKER",
          "apartmentId": widget.apartmentId,
          "gender": selectedGender,
          "age": int.parse(ageController.text.trim()),
          "address": addressController.text.trim(),
          "profession": selectedProfession,
          "experience":
          int.parse(experienceController.text.trim()),
          "governmentId": govtIdController.text.trim(),
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
          "Worker Registration",
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

                TextFormField(
                  controller: nameController,
                  validator: (v) =>
                  v == null || v.trim().isEmpty
                      ? "Full Name is required"
                      : null,
                  decoration: _inputDecoration("Full Name"),
                ),

                const SizedBox(height: 18),

                DropdownButtonFormField<String>(
                  value: selectedGender,
                  validator: (v) =>
                  v == null ? "Gender is required" : null,
                  decoration: _inputDecoration("Gender"),
                  items: genderList
                      .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => selectedGender = v),
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                  v == null || v.trim().isEmpty
                      ? "Age is required"
                      : null,
                  decoration: _inputDecoration("Age"),
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: addressController,
                  validator: (v) =>
                  v == null || v.trim().isEmpty
                      ? "Address is required"
                      : null,
                  decoration: _inputDecoration("Permanent Address"),
                ),

                const SizedBox(height: 18),

                DropdownButtonFormField<String>(
                  value: selectedProfession,
                  validator: (v) =>
                  v == null ? "Profession is required" : null,
                  decoration: _inputDecoration("Profession"),
                  items: professionList
                      .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => selectedProfession = v),
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: experienceController,
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                  v == null || v.trim().isEmpty
                      ? "Experience is required"
                      : null,
                  decoration:
                  _inputDecoration("Years of Experience"),
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: govtIdController,
                  validator: (v) =>
                  v == null || v.trim().isEmpty
                      ? "Government ID is required"
                      : null,
                  decoration:
                  _inputDecoration("Government ID Number"),
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
                    isLoading ? null : registerWorker,
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