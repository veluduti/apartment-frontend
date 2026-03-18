import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import 'register_resident_screen.dart';
import 'register_worker_screen.dart';

class SignupScreen extends StatelessWidget {

  final String phoneNumber;

  const SignupScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Create Account",
            style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const SizedBox(height: 20),

            const Text(
              "Choose Account Type",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            _buildCard(
              context,
              icon: Icons.home,
              title: "Resident",
              subtitle: "Register as apartment resident",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RegisterResidentScreen(
                      phoneNumber: phoneNumber,
                      apartmentId: AppConfig.apartmentId,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            _buildCard(
              context,
              icon: Icons.work,
              title: "Worker",
              subtitle: "Register as service provider",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RegisterWorkerScreen(
                      phoneNumber: phoneNumber,
                      apartmentId: AppConfig.apartmentId,
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

  Widget _buildCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
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
              radius: 26,
              backgroundColor:
                  const Color(0xFF1E3A8A).withOpacity(0.1),
              child: Icon(icon,
                  size: 26,
                  color: const Color(0xFF1E3A8A)),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: Colors.grey),
                  ),
                ],
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