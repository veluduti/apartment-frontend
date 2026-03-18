import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/repositories/session_manager.dart';
import '../../core/services/api_service.dart';

class AssignedResidentsScreen extends StatefulWidget {
  const AssignedResidentsScreen({super.key});

  @override
  State<AssignedResidentsScreen> createState() =>
      _AssignedResidentsScreenState();
}

class _AssignedResidentsScreenState
    extends State<AssignedResidentsScreen> {

  List residents = [];
  List filteredResidents = [];
  bool isLoading = true;

  final TextEditingController searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchResidents();
  }

  Future<void> fetchResidents() async {
    final response =
        await ApiService.getAssignedResidents(
            SessionManager.userId!);

    if (response["success"] == true) {
      residents = response["data"];
      filteredResidents = residents;
    }

    setState(() => isLoading = false);
  }

  void filter(String value) {
    setState(() {
      filteredResidents = residents
          .where((r) => r["flatNumber"]
              .toString()
              .toLowerCase()
              .contains(value.toLowerCase()))
          .toList();
    });
  }

  Future<void> call(String phone) async {
    final Uri url = Uri.parse("tel:$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Assigned Residents")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // 🔍 SEARCH BAR
            TextField(
              controller: searchController,
              onChanged: filter,
              decoration: const InputDecoration(
                hintText: "Search by Flat Number",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            if (isLoading)
              const CircularProgressIndicator()
            else if (filteredResidents.isEmpty)
              const Text("No assigned residents")
            else
              Expanded(
                child: ListView.builder(
                  itemCount: filteredResidents.length,
                  itemBuilder: (_, index) {

                    final resident =
                        filteredResidents[index];

                    return Card(
                      margin:
                          const EdgeInsets.only(bottom: 15),
                      child: ListTile(
                        title: Text(
                          "Flat ${resident["flatNumber"]}",
                          style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold),
                        ),
                        subtitle: Text(
                            resident["residentName"]),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.phone,
                            color: Colors.green,
                          ),
                          onPressed: () =>
                              call(resident["residentPhone"]),
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