import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/api_service.dart';

class WorkerListScreen extends StatefulWidget {
  const WorkerListScreen({super.key});

  @override
  State<WorkerListScreen> createState() => _WorkerListScreenState();
}

class _WorkerListScreenState extends State<WorkerListScreen> {

  String selectedService = "IRON";
  List workers = [];
  bool isLoading = true;

  final services = [
    "IRON",
    "PLUMBING",
    "MAID",
    "CAR_CLEANING"
  ];

  @override
  void initState() {
    super.initState();
    fetchWorkers();
  }

  Future<void> fetchWorkers() async {
    setState(() => isLoading = true);

    final response =
        await ApiService.getWorkersByService(selectedService);
    print("WORKER API RESPONSE:");
    print(response);

    if (response["success"] == true) {
      workers = response["data"];
    } else {
      workers = [];
    }

    setState(() => isLoading = false);
  }

  Future<void> _makePhoneCall(String phone) async {
    final Uri url = Uri.parse("tel:$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Workers"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // 🔽 Service Dropdown
            DropdownButtonFormField<String>(
              value: selectedService,
              items: services
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s),
                      ))
                  .toList(),
              onChanged: (value) {
                selectedService = value!;
                fetchWorkers();
              },
              decoration: const InputDecoration(
                labelText: "Select Service",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            if (isLoading)
              const CircularProgressIndicator()
            else if (workers.isEmpty)
              const Text("No workers available")
            else
              Expanded(
                child: ListView.builder(
                  itemCount: workers.length,
                  itemBuilder: (_, index) {

                    final worker = workers[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(
                          worker["name"],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(worker["phone"]),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.phone,
                            color: Colors.green,
                          ),
                          onPressed: () =>
                              _makePhoneCall(worker["phone"]),
                        ),
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