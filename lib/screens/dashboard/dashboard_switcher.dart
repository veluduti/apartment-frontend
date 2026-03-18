import 'package:flutter/material.dart';
import 'resident_dashboard.dart';
import 'worker_dashboard.dart';

class DashboardSwitcher extends StatelessWidget {
  const DashboardSwitcher({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Apartment Ecosystem"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // 🔹 Resident Dashboard
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.home),
                label: const Text("Resident Dashboard"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ResidentDashboard(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 Iron Worker Dashboard
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.work),
                label: const Text("Iron Worker Dashboard"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const WorkerDashboard()
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
