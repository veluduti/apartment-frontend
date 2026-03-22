import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
//import '../../core/models/service_request_model.dart';
import '../../core/config/app_config.dart';
import '../auth/login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
    .showSnackBar(SnackBar(content: Text(message)));
  }
  late TabController _tabController;

  List pendingUsers = [];
  List historyUsers = [];

  bool isLoading = true;
  String selectedFilter = "ALL";
  String searchQuery = "";
  bool isHistoryLoading = true;
  String? loadingUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      if (_tabController.index == 0) {
        fetchPendingUsers();
      } else {
        fetchHistory();
      }
    });

    fetchPendingUsers();
    fetchHistory();
  }

  @override
  void dispose() {
  _tabController.dispose();
  super.dispose();
}

  String formatDate(String? date) {
    if (date == null) return "";
    final parsed = DateTime.parse(date).toLocal();
    return DateFormat("dd MMM yyyy, hh:mm a").format(parsed);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("authToken");
  }

  Future<void> fetchPendingUsers() async {

    final token = await _getToken();

    if (token == null) {
      _showSnack("Session expired. Please login again.");
      logout();
      return;
    }

    final response = await http.get(
      Uri.parse("${AppConfig.baseUrl}/api/admin/pending-users"),
      headers: {
        "Authorization": "Bearer $token",
        },
    );

    if (response.statusCode != 200) {
       setState(() => isLoading = false); 
      _showSnack("Failed to load data");
      return;
    }

    final data = jsonDecode(response.body);

    setState(() {
      pendingUsers = List<Map<String, dynamic>>.from(data["users"] ?? []);
      isLoading = false;
    });
  }

  Future<void> fetchHistory() async {

    final token = await _getToken();

    if (token == null) {
      _showSnack("Session expired. Please login again.");
      logout();
      return;
    }

    setState(() {
      isHistoryLoading = true;
    });

    final response = await http.get(
      Uri.parse(
          "${AppConfig.baseUrl}/api/admin/history?role=$selectedFilter"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode != 200) {
       setState(() => isHistoryLoading = false);
      _showSnack("Failed to load data");
      return;
    }
    
    final data = jsonDecode(response.body);

    setState(() {
      historyUsers = List<Map<String, dynamic>>.from(data["users"] ?? []);
      isHistoryLoading = false;
    });
  }

  Future<void> approveUser(String id) async {
  if (loadingUserId != null) return;
  setState(() => loadingUserId = id);

  final token = await _getToken();

  if (token == null) {
    setState(() => loadingUserId = null);
    _showSnack("Session expired");
    logout();
    return;
  }

  final response = await http.put(
    Uri.parse("${AppConfig.baseUrl}/api/admin/approve/$id"),
    headers: {
    "Authorization": "Bearer $token",
    },
  );

  if (response.statusCode != 200) {
  _showSnack("Failed to approve user");
  setState(() => loadingUserId = null);
  return; // 🔥 IMPORTANT
}

  setState(() => loadingUserId = null);

  fetchPendingUsers();
  fetchHistory();
}

  void showRejectDialog(String id) {
    final TextEditingController reasonController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text("Reject User"),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Enter rejection reason",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Confirm"),
            onPressed: () async {

              if (reasonController.text.trim().isEmpty) {
                _showSnack("Reason required");
                return;
              }

              final token = await _getToken();

              if (token == null) {
                _showSnack("Session expired");
                logout();
                return;
              }

              final response = await http.put(
                Uri.parse("${AppConfig.baseUrl}/api/admin/reject/$id"),
                headers: {
                  "Authorization": "Bearer $token",
                  "Content-Type": "application/json",
                },
                body: jsonEncode({
                  "reason": reasonController.text.trim(),
                }),
              );

              if (response.statusCode != 200) {
                _showSnack("Failed to reject user");
              }

              Navigator.pop(context);
              fetchPendingUsers();
              fetchHistory();
            },
          ),
        ],
      ),
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  int get pendingCount => pendingUsers.length;

  int get approvedCount =>
      historyUsers.where((u) => u["status"] == "APPROVED").length;

  int get rejectedCount =>
      historyUsers.where((u) => u["status"] == "REJECTED").length;

  Widget summaryCard(String title, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            )
          ],
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
            const SizedBox(height: 6),
            Text(title,
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget buildSummary() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          summaryCard("Pending", pendingCount, Colors.orange),
          const SizedBox(width: 10),
          summaryCard("Approved", approvedCount, Colors.green),
          const SizedBox(width: 10),
          summaryCard("Rejected", rejectedCount, Colors.red),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Admin Panel", style: TextStyle(color: Colors.black)),
            Text(
              "Apartment Dashboard",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1E3A8A),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1E3A8A),
          tabs: const [
            Tab(text: "Pending"),
            Tab(text: "History"),
          ],
        ),
      ),
      body: Column(
        children: [
          buildSummary(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                buildPendingTab(),
                buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPendingTab() {

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (pendingUsers.isEmpty) {
      return const Center(child: Text("No pending users"));
    }

    return RefreshIndicator(
      onRefresh: fetchPendingUsers,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: pendingUsers.length,
        itemBuilder: (context, index) {

        final user = pendingUsers[index];

        return Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 15),
          child: Container(
  padding: const EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(user["name"] ?? "",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(user["role"] ?? "",
              style: const TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),

      const SizedBox(height: 8),

      Text(user["phone"] ?? "",  style: const TextStyle(color: Colors.grey)),

      const SizedBox(height: 12),

      Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: loadingUserId == user["id"]
              ? null
              : () => approveUser(user["id"]),
              child: loadingUserId == user["id"]
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text("Approve"),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: loadingUserId == user["id"]
              ? null
              : () => showRejectDialog(user["id"]),
              child: const Text("Reject"),
            ),
          ),
        ],
      )
    ],
  ),
)

        );
      },
      ),
    );
  }
  

  Widget buildHistoryTab() {

    if (isHistoryLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredUsers = historyUsers.where((user) {
      final name = user["name"].toString().toLowerCase();
      final phone = user["phone"].toString().toLowerCase();
      return name.contains(searchQuery) ||
          phone.contains(searchQuery);
    }).toList();
    

    return Column(
      children: [

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            decoration: InputDecoration(
              labelText: "Search by name or phone",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase();
              });
            },
          ),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ["ALL", "RESIDENT", "WORKER"].map((role) {
            final isSelected = selectedFilter == role;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: ChoiceChip(
                label: Text(role),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    selectedFilter = role;
                  });
                  fetchHistory(); // 🔥 reload
                },
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 10),

        Expanded(
          child: filteredUsers.isEmpty
              ? const Center(child: Text("No history found"))
              : RefreshIndicator(
                onRefresh: fetchHistory,
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {

                    final user = filteredUsers[index];
                    final bool isApproved =
                        user["status"] == "APPROVED";

                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16)),
                      margin:
                          const EdgeInsets.only(bottom: 15),
                      child: ListTile(
                        title: Text(user["name"] ?? "",
                            style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                                "${user["phone"] ?? ""} • ${user["role"] ?? ""}"),
                            const SizedBox(height: 6),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5),
                              decoration: BoxDecoration(
                                color: isApproved
                                    ? Colors.green
                                        .withOpacity(0.15)
                                    : Colors.red
                                        .withOpacity(0.15),
                                borderRadius:
                                    BorderRadius.circular(
                                        20),
                              ),
                              child: Text(
                                user["status"] ?? "",
                                style: TextStyle(
                                  color: isApproved
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(
                          formatDate(user["actionAt"] != null ? user["actionAt"].toString() : null),
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),
        ),
        ),
      ],
    );
  }
}
