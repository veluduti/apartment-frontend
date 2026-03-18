import 'package:flutter/material.dart';
import 'register_resident_screen.dart';
import 'register_worker_screen.dart';

class RoleSelectionScreen extends StatelessWidget {

  final String phoneNumber;
  final String apartmentId;

  const RoleSelectionScreen({
    super.key,
    required this.phoneNumber,
    required this.apartmentId,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Select Role",
            style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const SizedBox(height: 20),

            const Text(
              "Register As",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold),
            ),

            const SizedBox(height: 30),

            _buildOption(
              context,
              icon: Icons.home,
              title: "Resident",
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RegisterResidentScreen(
                      phoneNumber: phoneNumber,
                      apartmentId: apartmentId,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            _buildOption(
              context,
              icon: Icons.work,
              title: "Worker",
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RegisterWorkerScreen(
                      phoneNumber: phoneNumber,
                      apartmentId: apartmentId,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  const Color(0xFF1E3A8A).withOpacity(0.1),
              child: Icon(icon,
                  color: const Color(0xFF1E3A8A)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold),
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}