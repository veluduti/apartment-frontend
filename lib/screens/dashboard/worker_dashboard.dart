import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/repositories/request_repository.dart';
import '../../core/repositories/session_manager.dart';
import '../../core/services/api_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../chat/chat_screen.dart';
import '../../screens/auth/resident_list_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../screens/worker_payment_history_screen.dart';
import '../../screens/plumber/plumber_quote_screen.dart';
import '../../screens/common/full_image_screen.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WorkerDashboard extends StatefulWidget {
  const WorkerDashboard({super.key});

  @override
  State<WorkerDashboard> createState() => _WorkerDashboardState();
}

class _WorkerDashboardState extends State<WorkerDashboard> {

  final Color primaryColor = const Color(0xFF2563EB);

  DateTime selectedDate = DateTime.now();
  late IO.Socket socket;
  int totalLimit = 0;
  int used = 0;
  bool loadingCapacity = false;

  @override
void initState() {
  super.initState();

  if (SessionManager.workerService == "IRON") {
    fetchCapacity();
  }

    // ================= SOCKET SETUP =================
socket = IO.io(
  "http://192.168.1.6:5000", // 🔥 your backend IP
  IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .build(),
);

socket.connect();

socket.onConnect((_) {
  print("🟢 Worker socket connected");

  // Register worker
  socket.emit("registerUser", SessionManager.userId);
});

socket.on("paymentReceived", (data) {

  if (!mounted) return;

  context.read<RequestRepository>().fetchRequests();

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Payment received for a request"),
      backgroundColor: Colors.green,
    ),
  );
});

socket.on("requestUpdated", (data) {

  if (!mounted) return;

  context.read<RequestRepository>().fetchRequests();

});

socket.on("newRequest", (data) {

  if (!mounted) return;

  context.read<RequestRepository>().fetchRequests();

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("New service request received"),
    ),
  );
});

    Future.microtask(() =>
        context.read<RequestRepository>().fetchRequests());

    getFCMToken();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text(message.notification!.title ?? "Notification"),
            content: Text(message.notification!.body ?? ""),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<RequestRepository>().fetchRequests();
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
void dispose() {
  socket.disconnect();
  socket.dispose();
  super.dispose();
}

  Future<void> fetchCapacity() async {
  setState(() => loadingCapacity = true);

  final formatted =
      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

  final response = await ApiService.getWorkerCapacity(
    workerId: SessionManager.userId!,
    date: formatted,
  );

  if (response["success"]) {
    totalLimit = response["totalLimit"];
    used = response["used"];
  }

  setState(() => loadingCapacity = false);
}

  Future<void> getFCMToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    String? token = await messaging.getToken();

    if (token != null) {
      await ApiService.saveToken({
        "userId": SessionManager.userId,
        "token": token,
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    final repo = context.watch<RequestRepository>();
    final workerName = SessionManager.userName ?? "Worker";

    final pending = repo.allRequests
        .where((r) => r.status == "PENDING")
        .toList();

    final active = repo.allRequests
    .where((r) =>
        r.status == "ACCEPTED" ||
        r.status == "VISITED" ||
        r.status == "QUOTED" ||
        r.status == "CONFIRMED" ||   
        r.status == "IN_PROGRESS")
    .toList();

    final history = repo.allRequests
    .where((r) =>
        r.status == "COMPLETED" ||
        r.status == "CANCELLED" ||
        r.status == "REJECTED")
    .toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
  backgroundColor: Colors.white,
  elevation: 0,
  title: const Text(
  "Worker Dashboard",
  style: TextStyle(
    color: Colors.black,
    fontWeight: FontWeight.w600,
  ),
),
  centerTitle: false,

  // 🔥 ADD THIS PART
  actions: [
    PopupMenuButton<String>(
      icon: const Icon(Icons.menu, color: Colors.black),
      onSelected: (value) {
        if (value == "assigned") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const AssignedResidentsScreen(),
            ),
          );
        }
        if (value == "payments") {
          Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const WorkerPaymentHistoryScreen(),
            ),
          );
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: "assigned",
          child: Text("Assigned Residents"),
        ),
        PopupMenuItem(
          value: "payments",
          child: Text("Payment History"),
        ),
      ],
    ),
  ],
),
      body: RefreshIndicator(
        onRefresh: () => repo.fetchRequests(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

  Text(
    "Welcome, $workerName 👋",
    style: const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
  ),

  const SizedBox(height: 20),

  if (SessionManager.workerService == "IRON")
  Container(
  padding: const EdgeInsets.all(18),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 12,
        offset: const Offset(0, 6),
      )
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Daily Capacity",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),

          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () async {

              final controller =
                  TextEditingController(
                      text: totalLimit.toString());

              final newLimit =
                  await showDialog<String>(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16)),
                  title:
                      const Text("Update Capacity"),
                  content: TextField(
                    controller: controller,
                    keyboardType:
                        TextInputType.number,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context),
                      child:
                          const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(
                              context,
                              controller.text),
                      child:
                          const Text("Save"),
                    ),
                  ],
                ),
              );

              if (newLimit != null) {
                await ApiService.setWorkerCapacity({
                  "workerId":
                      SessionManager.userId,
                  "totalLimit":
                      int.parse(newLimit),
                  "date":
                      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
                });

                fetchCapacity();
              }
            },
          )
        ],
      ),

      const SizedBox(height: 14),

      loadingCapacity
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  "$used / $totalLimit clothes used",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 12),

                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(12),
                  child:
                      LinearProgressIndicator(
                    value: totalLimit == 0
                        ? 0
                        : (used / totalLimit).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor:
                        Colors.grey.shade200,
                    valueColor:
                        AlwaysStoppedAnimation(
  Theme.of(context).colorScheme.primary,
),
                  ),
                ),
              ],
            ),
    ],
  ),
),

  const SizedBox(height: 30), 
  const SectionTitle("New Requests"),
            const SizedBox(height: 15),

            if (pending.isEmpty)
              const EmptyState(text: "No new requests")
            else
              ...pending.map(
  (r) => WorkerCard(
  request: r,
  totalLimit: totalLimit,
  used: used,
  onRefreshCapacity: SessionManager.workerService == "IRON"
      ? fetchCapacity
      : () {},
)
),

            const SizedBox(height: 30),

            const SectionTitle("Active Jobs"),
            const SizedBox(height: 15),

            if (active.isEmpty)
              const EmptyState(text: "No active jobs")
            else
              ...active.map((r) => WorkerCard(request: r,
    totalLimit: totalLimit,
    used: used,
    onRefreshCapacity: fetchCapacity,
  ),
),

            const SizedBox(height: 30),

            const SectionTitle("Completed History"),
            const SizedBox(height: 15),

            if (history.isEmpty)
              const EmptyState(text: "No completed jobs")
            else
              ...history.map((r) => WorkerCard(
  request: r,
  isHistory: true,
  totalLimit: totalLimit,
  used: used,
  onRefreshCapacity: SessionManager.workerService == "IRON"
      ? fetchCapacity
      : () {},
)),
          ],
        ),
      ),
    );
  }
}

///////////////////////////////////////////////////////////////////

class WorkerCard extends StatelessWidget {
  final ServiceRequest request;
  final bool isHistory;
  final int totalLimit;
  final int used;
  final VoidCallback onRefreshCapacity;

  const WorkerCard({
    super.key,
    required this.request,
    this.isHistory = false,
    required this.totalLimit,
    required this.used,
    required this.onRefreshCapacity,
  });

  Color getStatusColor(String status) {
  switch (status) {
    case "PENDING":
      return Colors.orange;

    case "ACCEPTED":
      return Colors.green;

    case "VISITED":
      return Colors.teal;

    case "QUOTED":
      return Colors.amber;

    case "IN_PROGRESS":
      return Colors.purple;

    case "COMPLETED":
      return Colors.blue;

    case "REJECTED":
      return Colors.red;

    default:
      return Colors.grey;
  }
}

  @override
Widget build(BuildContext context) {
  final repo = context.read<RequestRepository>();

  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        /// TITLE + DELETE (for history)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              request.serviceType,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            if (isHistory)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete,
                    size: 18, color: Colors.red),
                onPressed: () {
                  repo.hideRequest(
                    request.id,
                    SessionManager.userRole!,
                  );
                },
              ),
          ],
        ),

        const SizedBox(height: 6),
        Divider(height: 1, color: Colors.grey.shade300),
        const SizedBox(height: 8),

        /// DATE
        if (request.pickupDate != null &&
            request.pickupSlot != null)
          Row(
            children: [
              const Icon(Icons.access_time,
                  size: 15, color: Colors.black54),
              const SizedBox(width: 6),
              Text(
                "${DateFormat("dd MMM yyyy").format(request.pickupDate!)} | "
                "${DateFormat("hh:mm a").format(request.pickupSlot!.startTime)} - "
                "${DateFormat("hh:mm a").format(request.pickupSlot!.endTime)}",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

        const SizedBox(height: 4),

        const Text(
          "Type: NORMAL",
          style: TextStyle(
            color: Colors.black54,
            fontSize: 12,
          ),
        ),

        const SizedBox(height: 10),

        /// RESIDENT
        Row(
  children: [
    CircleAvatar(
      radius: 18,
      backgroundColor: Colors.grey.shade200,
      child: const Icon(
        Icons.person,
        size: 18,
        color: Colors.black54,
      ),
    ),
    const SizedBox(width: 8),

    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // 🔹 Name • Flat
          Row(
            children: [
              Flexible(
                child: Text(
                  request.residentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                "•",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black45,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                request.flatNumber ?? "",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),

          const SizedBox(height: 2),

          // 🔹 Phone
          Text(
            request.residentPhone,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    ),
            if (request.residentPhone.isNotEmpty)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.phone,
                    size: 18),
                onPressed: () async {
                  final Uri url =
                      Uri.parse("tel:${request.residentPhone}");
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
              ),
          ],
        ),

        const SizedBox(height: 10),
        Divider(height: 1, color: Colors.grey.shade300),
        const SizedBox(height: 10),

/// PLUMBING DETAILS
if (request.serviceType == "PLUMBING") ...[
  Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300),
      color: Colors.grey.shade50,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
          children: const [
            Icon(Icons.plumbing, size: 18),
            SizedBox(width: 6),
            Text(
              "PLUMBING SERVICE",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (request.problemTitle != null)
          Text(
            request.problemTitle!,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),

        const SizedBox(height: 6),

        Text(
          request.details ?? "",
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 10),

        if (request.photos != null && request.photos!.isNotEmpty) ...[

  const SizedBox(height: 8),

  const Text(
    "Problem Photo",
    style: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 13,
    ),
  ),

  const SizedBox(height: 6),

  GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FullImageScreen(
            imageUrl: request.photos!.first,
          ),
        ),
      );
    },
    child: Stack(
      children: [

        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
  request.photos!.first,
  height: 140,
  width: double.infinity,
  fit: BoxFit.cover,
  errorBuilder: (context, error, stackTrace) {
    return Container(
      height: 140,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.broken_image),
      ),
    );
  },
),
        ),

        Positioned(
          right: 8,
          top: 8,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.zoom_in,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ],
    ),
  ),

  const SizedBox(height: 4),

  const Text(
    "Tap image to view full screen",
    style: TextStyle(
      fontSize: 11,
      color: Colors.grey,
    ),
  ),
]

      ],
    ),
  ),

  const SizedBox(height: 10),
],

        /// CLOTHES BOX
        if (request.serviceType == "IRON")
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.grey.shade400,
              ),
            ),
            child: Column(
              children: [

                ...request.ironItems.map(
                  (item) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor:
                              Colors.grey.shade200,
                          child: const Icon(
                            Icons.checkroom,
                            size: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.clothType,
                            style: const TextStyle(
                                fontSize: 12),
                          ),
                        ),
                        Text(
                          "${item.quantity}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Divider(height: 1, color: Colors.grey.shade300),
                const SizedBox(height: 6),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      //"Total: ${request.confirmedClothes ?? request.ironItems.length}",
                      "Total: ${request.confirmedClothes ?? request.requestedClothes ?? request.ironItems.fold<int>(0, (sum, item) => sum + item.quantity)}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    Text(
                      "₹${request.totalAmount}",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        const SizedBox(height: 10),

        /// ACTION BUTTONS
        if (!isHistory &&
            request.status != "COMPLETED" &&
            request.status != "REJECTED") ...[
          _buildActionButtons(context, repo),
          const SizedBox(height: 8),
        ],

        /// STATUS + CHAT

const SizedBox(height: 10),
Divider(height: 1, color: Colors.grey.shade300),
const SizedBox(height: 10),
      Row(
  children: [

    // ================= STATUS =================
    Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: request.status == "ACCEPTED" ||
                request.status == "IN_PROGRESS"
            ? Theme.of(context)
                .colorScheme
                .primary
                .withOpacity(0.15)
            : getStatusColor(request.status)
                .withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        request.status,
        style: TextStyle(
          fontSize: 12,
          color: getStatusColor(request.status),
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Push right content to end
    const Spacer(),

    // ================= PAID BADGE =================
    if (request.payment?.status == "PAID")
      Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.green,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 14,
            ),
            SizedBox(width: 4),
            Text(
              "PAID",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        
      ),

    // ================= CHAT ICON =================
    if (request.status == "ACCEPTED" ||
    request.status == "VISITED" ||
    request.status == "QUOTED" ||
    request.status == "CONFIRMED" ||
    request.status == "IN_PROGRESS")
      TextButton.icon(
  style: TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(
        horizontal: 10, vertical: 4),
  ),
  icon: const Icon(
    Icons.chat_bubble_outline,
    size: 16,
  ),
  label: const Text(
    "Chat",
    style: TextStyle(fontSize: 12),
  ),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          requestId: request.id,
        ),
      ),
    );
  },
)
  ],
),

if (request.status == "CANCELLED" || request.status == "REJECTED") ...[
  const SizedBox(height: 8),
  Builder(
    builder: (context) {

      final rejectLog = request.logs
          .where((l) =>
              l.newStatus == "CANCELLED" ||
              l.newStatus == "REJECTED")
          .toList();

      if (rejectLog.isEmpty) return const SizedBox();

      final reason = rejectLog.last.note;

      if (reason == null || reason.isEmpty) {
        return const SizedBox();
      }

      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  color: Colors.red, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Rejected by resident: $reason",
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  ),

      ],
      ]
    ),
  );
} 

  Widget _buildActionButtons(
      BuildContext context,
      RequestRepository repo) {

    if (request.serviceType == "PLUMBING") {
    return _buildPlumberActions(context, repo);
  }

    if (request.status == "PENDING") {
      return Row(
        children: [

          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
  backgroundColor: Theme.of(context).colorScheme.primary,
  foregroundColor: Colors.white,
  minimumSize: const Size(double.infinity, 48),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  ),
),
              onPressed: () async {

  final response = await ApiService.updateStatus(
    requestId: request.id,
    status: "ACCEPTED",
    userId: SessionManager.userId!,
  );

  if (response["success"] != true) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response["message"] ?? "Unable to accept request",
        ),
      ),
    );

  } else {

    // Refresh requests after successful accept
    context.read<RequestRepository>().fetchRequests();
  }
},
              child: const Text("Accept"),
            ),
          ),

          const SizedBox(width: 10),

         Expanded(
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
  backgroundColor: Colors.red,
  foregroundColor: Colors.white,
  minimumSize: const Size(double.infinity, 48),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  ),
),
    onPressed: () async {

      final reasonController = TextEditingController();

      final reason = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Reject Reason"),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              hintText: "Enter reason",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                context,
                reasonController.text.trim(),
              ),
              child: const Text("Submit"),
            ),
          ],
        ),
      );

      if (reason != null && reason.isNotEmpty) {
        repo.updateStatus(
          request.id,
          "REJECTED",
          userId: SessionManager.userId!,
          reason: reason,   // 🔥 VERY IMPORTANT
        );
      }
    },
    child: const Text("Reject"),
  ),
),
        ],
      );
    }

    if (request.status == "ACCEPTED") {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
  backgroundColor: const Color(0xFF2563EB),
  foregroundColor: Colors.white,
  minimumSize: const Size(double.infinity, 48),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  ),
),
    onPressed: () async {

      final controller = TextEditingController();

      final confirmed = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Confirm Clothes Count"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: "Enter confirmed clothes",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, controller.text),
              child: const Text("Confirm"),
            ),
          ],
        ),
      );

      if (confirmed != null && confirmed.isNotEmpty) {

  final parsed = int.tryParse(confirmed);

  if (parsed == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Enter valid number"),
      ),
    );
    return;
  }

  final remaining = totalLimit - used;

  if (parsed > remaining) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Limit exceeded! Remaining capacity: $remaining clothes",
        ),
      ),
    );
    return;
  }

  final response = await ApiService.updateStatus(
    requestId: request.id,
    status: "IN_PROGRESS",
    userId: SessionManager.userId!,
    confirmedClothes: parsed,
  );

  if (response["success"] == true) {
    context.read<RequestRepository>().fetchRequests();
    onRefreshCapacity();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response["message"] ?? "Failed"),
      ),
    );
  }
}
    },
    child: const Text("Start Work"),
  );
}

    if (request.status == "IN_PROGRESS") {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
  backgroundColor: Colors.purple,
  foregroundColor: Colors.white,
  minimumSize: const Size(double.infinity, 48),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  ),
),
        onPressed: () =>
            repo.updateStatus(
              request.id,
              "COMPLETED",
              userId: SessionManager.userId!,
            ),
        child: const Text("Mark Completed"),
      );
    }

    return const SizedBox();
  }

  Widget _buildPlumberActions(
    BuildContext context,
    RequestRepository repo) {

    if (request.status == "PENDING") {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      onPressed: () async {

        await ApiService.updateStatus(
          requestId: request.id,
          status: "ACCEPTED",
          userId: SessionManager.userId!,
        );

        context.read<RequestRepository>().fetchRequests();

      },
      child: const Text(
        "Accept Job",
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
  );
}


  if (request.status == "ACCEPTED") {
    return SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF2563EB),
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    onPressed: () async {

      await ApiService.updateStatus(
        requestId: request.id,
        status: "VISITED",
        userId: SessionManager.userId!,
      );

      context.read<RequestRepository>().fetchRequests();

    },
    child: const Text(
      "Mark Visited",
      style: TextStyle(
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
);
  }

  if (request.status == "VISITED") {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      onPressed: () {

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlumberQuoteScreen(
              requestId: request.id,
            ),
          ),
        );

      },
      child: const Text(
        "Send Quote",
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
  );
}

  if (request.status == "CONFIRMED") {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      onPressed: () async {

        await ApiService.updateStatus(
          requestId: request.id,
          status: "IN_PROGRESS",
          userId: SessionManager.userId!,
        );

        context.read<RequestRepository>().fetchRequests();

      },
      child: const Text(
        "Start Work",
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
  );
}

  if (request.status == "IN_PROGRESS") {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      onPressed: () {

        repo.updateStatus(
          request.id,
          "COMPLETED",
          userId: SessionManager.userId!,
        );

      },
      child: const Text(
        "Complete Job",
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
  );
}

  return const SizedBox();
}
}

///////////////////////////////////////////////////////////////////

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String text;

  const EmptyState({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 8,
      offset: const Offset(0, 4),
    )
  ],
),
      child: Text(text,
          style: const TextStyle(color: Colors.grey)),
    );
  }
}
