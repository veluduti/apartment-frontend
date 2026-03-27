import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/repositories/request_repository.dart';
import '../../core/repositories/session_manager.dart';
import '../../core/services/api_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../chat/chat_screen.dart';
import '../iron/iron_booking_screen.dart';
import '../../screens/auth/worker_list_screen.dart';
import '../../screens/plumber/plumber_booking_screen.dart';
import '../../screens/common/full_image_screen.dart';
import '../../screens/plumber/plumber_quote_view_screen.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ResidentDashboard extends StatefulWidget {
  const ResidentDashboard({super.key});

  @override
  State<ResidentDashboard> createState() =>
      _ResidentDashboardState();
}

class _ResidentDashboardState
    extends State<ResidentDashboard> {

  static const Color primaryColor = Color(0xFF2563EB);
  bool isSubmitting = false;

  late IO.Socket socket;

  late Razorpay _razorpay;
  String? _currentRequestId;

  @override
void initState() {
  super.initState();

  // 🔥 Razorpay
  _razorpay = Razorpay();
  _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
  _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

  // 🔥 INITIAL FETCH
  Future.microtask(() =>
      context.read<RequestRepository>().fetchRequests());

  getFCMToken();

  // ================= SOCKET SETUP =================
  socket = IO.io(
    "http://192.168.1.6:5000", // same as worker
    IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build(),
  );

  socket.connect();

  socket.on("editResponse", (data) {
    if (!mounted) return;

    if (data["residentId"] != SessionManager.userId) return;

    context.read<RequestRepository>().fetchRequests();
  });

  socket.onConnect((_) {
    print("🟢 Resident socket connected");

    socket.emit("registerUser", SessionManager.userId);
  });

  // 🔥 MAIN FIX
  socket.on("requestUpdated", (data) {
    print("📩 Resident received update");

    if (!mounted) return;

    context.read<RequestRepository>().fetchRequests();
  });
}

@override
void dispose() {
  socket.disconnect();
  socket.dispose();
  _razorpay.clear();
  super.dispose();
}

  Future<void> getFCMToken() async {
    FirebaseMessaging messaging =
        FirebaseMessaging.instance;
    await messaging.requestPermission();
    String? token = await messaging.getToken();

    if (token != null) {
      await ApiService.saveToken({
        "userId": SessionManager.userId,
        "token": token,
      });
    }
  }

  // ================= PAYMENT START =================
  Future<void> startPayment(ServiceRequest request) async {
    try {
      _currentRequestId = request.id;

      final response =
          await ApiService.createOrder(request.id);

      print("ORDER RESPONSE: $response");
      if (response["success"] != true) {
        print("Order creation failed");
      return;
      }

      var options = {
        'key': 'rzp_test_SLGQ3H7yonapkM',
        'amount': response["amount"] * 100,
        'name': 'Apartment Service',
        'description': 'Service Payment',
        'order_id': response["orderId"],
        'prefill': {
          'contact': SessionManager.userPhone,
          'name': SessionManager.userName,
        },
      };

      _razorpay.open(options);

    } catch (e) {
      print("Payment error: $e");
    }
  }

  // ================= PAYMENT SUCCESS =================
void _handlePaymentSuccess(
    PaymentSuccessResponse response) async {

  if (_currentRequestId == null) {
    print("Request ID is null");
    return;
  }

  final verifyResponse =
      await ApiService.verifyPayment({
    "razorpay_order_id": response.orderId,
    "razorpay_payment_id": response.paymentId,
    "razorpay_signature": response.signature,
    "requestId": _currentRequestId!, // 🔥 Add !
  });

  if (verifyResponse["success"] == true) {
    context.read<RequestRepository>().fetchRequests();
    print("Payment verified successfully");
  } else {
    print("Payment verification failed");
  }
}

  void _handlePaymentError(
      PaymentFailureResponse response) {
    print("Payment failed: ${response.message}");
  }

  void _handleExternalWallet(
      ExternalWalletResponse response) {
    print("External wallet selected");
  }

  @override
  Widget build(BuildContext context) {

    final repo = context.watch<RequestRepository>();
    final residentName = SessionManager.userName ?? "Resident";

    final today =
        DateFormat('EEEE, dd MMM yyyy')
            .format(DateTime.now());

    final activeRequests =
repo.allRequests.where((r) =>
    r.status == "PENDING" ||
    r.status == "ACCEPTED" ||
    r.status == "VISITED" ||
    r.status == "QUOTED" ||
    r.status == "CONFIRMED" ||
    r.status == "IN_PROGRESS").toList();

    final historyRequests =
        repo.allRequests.where((r) =>
        r.status == "COMPLETED" ||
            r.status == "REJECTED").toList();

    return Scaffold(

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Resident Dashboard",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Colors.black),
            onSelected: (value) {
              if (value == "workers") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const WorkerListScreen(),
                  ),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: "workers",
                child: Text("Worker Details"),
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
              "Welcome, $residentName",
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 4),
            Text(today,
                style: const TextStyle(color: Colors.grey)),

            const SizedBox(height: 30),

            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add),
                label: const Text("Book Required Service"),
                onPressed: () =>
                    openServiceSelector(context),
              ),
            ),

            const SizedBox(height: 35),

            const Text(
              "Active Requests",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            if (activeRequests.isEmpty)
              const Center(child: Text("No active requests"))
            else
              ...activeRequests.map(
                    (r) => RequestCard(request: r),
              ),

            const SizedBox(height: 35),

            const Text(
              "Service History",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            if (historyRequests.isEmpty)
              const EmptyState(text: "No service history")
            else
              ...historyRequests.map(
                    (r) => RequestCard(
                  request: r,
                  showDelete: true,
                )),
          ],
        ),
      ),
    );
  }

  void openServiceSelector(BuildContext context) {

    final services = [
      ServiceType("IRON", Icons.local_laundry_service),
      ServiceType("PLUMBING", Icons.plumbing),
      ServiceType("MAID", Icons.cleaning_services),
      ServiceType("CAR CLEANER", Icons.local_car_wash),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(25),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Apartment Services",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 9,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (_, index) {

                  if (index < services.length) {
                    final service = services[index];

                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        Navigator.pop(context);

                        Future.microtask(() {
                          if (service.name == "PLUMBING") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PlumberBookingScreen(),
                              ),
                            );
                            return;
                          }

                          openServiceForm(context, service.name);
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius:
                          BorderRadius.circular(18),
                        ),
                        padding:
                        const EdgeInsets.symmetric(
                            vertical: 14),
                        child: Column(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [

                            Container(
                              padding:
                              const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: primaryColor
                                    .withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                service.icon,
                                size: 26,
                                color: primaryColor,
                              ),
                            ),

                            const SizedBox(height: 12),

                            Text(
                              service.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius:
                      BorderRadius.circular(18),
                      border: Border.all(
                          color: Colors.grey.shade200),
                    ),
                    child: const Center(
                      child: Text(
                        "Coming Soon",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void openServiceForm(BuildContext context, String serviceType) {

    if (serviceType == "IRON") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const IronBookingScreen(),
        ),
      );
      return;
    }

    final repo = context.read<RequestRepository>();
    final detailsController = TextEditingController();
    String selectedPriority = "MEDIUM";

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text("New $serviceType Request"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              TextField(
                controller: detailsController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Service Details *",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: selectedPriority,
                items: const [
                  DropdownMenuItem(value: "LOW", child: Text("LOW")),
                  DropdownMenuItem(value: "MEDIUM", child: Text("MEDIUM")),
                  DropdownMenuItem(value: "HIGH", child: Text("HIGH")),
                ],
                onChanged: (value) {
                  selectedPriority = value!;
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () async {

                if (detailsController.text.trim().isEmpty) {
                  return;
                }

                await repo.addRequest({
                  "apartmentId": SessionManager.apartmentId,
                  "residentId": SessionManager.userId,
                  "serviceType": serviceType,
                  "details": detailsController.text.trim(),
                  "priority": selectedPriority,
                  "flatId": SessionManager.flatId,
                });

                Navigator.pop(context);
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }
}

///////////////////////////////////////////////////////////////

class ServiceType {
  final String name;
  final IconData icon;
  ServiceType(this.name, this.icon);
}

///////////////////////////////////////////////////////////////

class RequestCard extends StatelessWidget {
  final ServiceRequest request;
  final bool showDelete;

  const RequestCard({
    super.key,
    required this.request,
    this.showDelete = false,
  });

  IconData _getClothIcon(String type) {
  final name = type.toLowerCase();

  if (name.contains("silk saree")) return Icons.dry_cleaning;
  if (name.contains("cotton saree")) return Icons.dry_cleaning;
  if (name.contains("saree")) return Icons.dry_cleaning;

  if (name.contains("kurthi")) return Icons.checkroom;
  if (name.contains("shirt")) return Icons.checkroom;
  if (name.contains("t-shirt")) return Icons.checkroom;
  if (name.contains("tshirt")) return Icons.checkroom;
  if (name.contains("top")) return Icons.checkroom;

  if (name.contains("pant")) return Icons.shopping_bag;

  if (name.contains("bedsheet")) return Icons.bed;
  if (name.contains("curtain")) return Icons.window;
  if (name.contains("pillow")) return Icons.bedroom_parent;

  return Icons.local_laundry_service;
}

  Color _getStatusColor(String status) {
  switch (status) {
    case "PENDING":
      return Colors.orange;

    case "ACCEPTED":
      return Colors.blue;

    case "VISITED":
      return Colors.teal;

    case "QUOTED":
      return Colors.amber;

    case "IN_PROGRESS":
      return Colors.purple;

    case "COMPLETED":
      return Colors.green;

    case "CONFIRMED":
      return Colors.green;

    case "REJECTED":
      return Colors.red;

    default:
      return Colors.grey;
  }
}

  Future<void> _makePhoneCall(String phone) async {
    final Uri url = Uri.parse("tel:$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {

    final repo = context.watch<RequestRepository>();
    final edit = repo.editRequests
    .where((e) => e.requestId == request.id)
    .toList();

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;

    String? rejectionReason = request.reason;

    final rejectLogs = request.logs
        .where((log) => log.newStatus == "REJECTED")
        .toList();

    if ((rejectionReason == null ||
            rejectionReason.isEmpty) &&
        rejectLogs.isNotEmpty) {
      rejectionReason = rejectLogs.last.note;
    }

    final totalClothes = request.ironItems
        .fold(0, (sum, item) => sum + item.quantity);

    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ================= HEADER =================
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text(
  request.serviceType == "PLUMBING"
      ? "Plumbing Service"
      : request.serviceType == "IRON"
          ? "Iron Service"
          : request.serviceType,
  style: text.titleMedium,
),
                if (showDelete)
                  IconButton(
                    icon: const Icon(Icons.delete,
                        color: Colors.red),
                    onPressed: () {
                      repo.hideRequest(
                        request.id,
                        SessionManager.userRole!,
                      );
                    },
                  ),
              ],
            ),

            // After cloth rows

const Divider(height: 16),

// ================= WORKER =================
              if (request.worker != null) ...[
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          colors.primary
                              .withOpacity(0.1),
                      child: const Icon(Icons.person,
                          size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.worker!.name,
                            style: text.bodyLarge
                                ?.copyWith(
                                    fontWeight:
                                        FontWeight.w600),
                          ),
                          if (request.worker!
                                      .phone !=
                                  null &&
                              request.worker!
                                  .phone!
                                  .isNotEmpty)
                            Text(
                              request.worker!
                                  .phone!,
                              style: text.bodyMedium,
                            ),
                        ],
                      ),
                    ),
                    if (request.worker!
                                .phone !=
                            null &&
                        request.worker!
                            .phone!
                            .isNotEmpty)
                      IconButton(
                        icon:
                            const Icon(Icons.call),
                        onPressed: () =>
                            _makePhoneCall(
                                request.worker!
                                    .phone!),
                      ),
                  ],
                ),     
                const Divider(height: 16),
              ],

             // ================= PLUMBING SECTION =================
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

        const Row(
          children: [
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
          style: const TextStyle(fontSize: 13),
        ),

        const SizedBox(height: 10),
        
        if (request.photos != null && request.photos!.isNotEmpty)
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
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        request.photos!.first,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 150,
            color: Colors.grey.shade200,
            child: const Icon(Icons.image_not_supported),
          );
        },
      ),
    ),
  )
else
  Container(
    height: 150,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: Colors.grey.shade200,
    ),
    child: const Center(
      child: Icon(Icons.image, size: 40),
    ),
  )
      ],
    ),
  ),

  const SizedBox(height: 8),
],

            // ================= IRON SECTION =================
           if (request.serviceType == "IRON") ...[

  if (request.pickupSlot != null &&
      request.pickupDate != null)
    Row(
      children: [
        const Icon(Icons.schedule, size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            "${DateFormat("dd MMM yyyy").format(request.pickupDate!)} | "
            "${DateFormat("hh:mm a").format(request.pickupSlot!.startTime)} - "
            "${DateFormat("hh:mm a").format(request.pickupSlot!.endTime)}",
            style: text.bodyLarge,
          ),
        ),
      ],
    ),

  const SizedBox(height: 8),

  if (request.pickupSlot != null)
    Text(
      "Type: ${request.pickupSlot!.type}",
      style: text.bodyMedium,
    ),

  const SizedBox(height: 14),

  // ================= CLOTHES SUMMARY =================
  Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: theme.dividerColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 18,
              color: colors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              "CLOTHES SUMMARY",
              style: text.labelLarge?.copyWith(
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
          ],
        ),

        const Divider(height: 16),

        if (request.ironItems.isNotEmpty)
          ...request.ironItems.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getClothIcon(item.clothType),
                      size: 16,
                      color: colors.primary,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      item.clothType,
                      style: text.bodyMedium,
                    ),
                  ),

                  Text(
                    item.quantity.toString(),
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              "No item details available",
              style: text.bodyMedium,
            ),
          ),

        const Divider(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Total Clothes: $totalClothes",
              style: text.bodyLarge,
            ),
            Text(
              "₹${request.totalAmount}",
              style: text.titleMedium?.copyWith(
                color: colors.primary,
              ),
            ),
          ],
        ),
      ],
    ),
  ),

  const SizedBox(height: 12),

  // 🔥🔥 NEW EDIT BUTTON (STEP-1)
  if (request.status == "PENDING" || request.status == "ACCEPTED")
    SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        onPressed: () {
          openEditItemsDialog(context, request);
        },
        child: const Text("Edit Clothes"),
      ),
    ),
],
        
            // ================= REJECTION =================
            if (rejectionReason != null &&
                rejectionReason.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.only(
                        top: 12),
                child: Text(
                  "Rejected Reason: $rejectionReason",
                  style:
                      const TextStyle(
                    color: Colors.red,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),

            const SizedBox(height: 8),

    // ================= EDIT STATUS =================
            if (edit.isNotEmpty) ...[
              const SizedBox(height: 10),

              Builder(
                builder: (_) {
                  final e = edit.first;

                  if (e.status == "PENDING") {
                    return const Text(
                      "Edit Requested ⏳",
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }

                  if (e.status == "APPROVED") {
                    return const Text(
                      "Edit Approved ✅",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }

                  if (e.status == "REJECTED") {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Edit Rejected ❌",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (e.reason != null && e.reason.toString().isNotEmpty)
                          Text(
                            "Reason: ${e.reason}",
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    );
                  }

                  return const SizedBox();
                },
              ),
            ],

            // ================= STATUS + PAID =================
Row(
  children: [

    // LEFT SIDE → STATUS
    Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(request.status)
            .withOpacity(0.15),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        request.status,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color:
              _getStatusColor(request.status),
        ),
      ),
    ),

    const Spacer(),

    // RIGHT SIDE → PAID BADGE
    if (request.payment?.status == "PAID")
      Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.12),
          borderRadius:
              BorderRadius.circular(20),
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
              ),
            ),
          ],
        ),
      ),

    // CHAT ICON
    if ((request.status == "ACCEPTED" ||
     request.status == "VISITED" ||
     request.status == "QUOTED" ||
     request.status == "CONFIRMED" ||
     request.status == "IN_PROGRESS") &&
    request.worker != null)
      IconButton(
        icon: const Icon(
            Icons.chat_bubble_outline),
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
      ),
  ],
),


// ================= QUOTE SUMMARY =================
if (request.serviceType == "PLUMBING" &&
    (request.status == "QUOTED" || request.status == "CONFIRMED")) ...[
  const SizedBox(height: 10),

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

        const Text(
          "Quote Summary",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Visit Charge"),
            Text("₹${request.visitCharge ?? 0}"),
          ],
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Material Charge"),
            Text("₹${request.materialCharge ?? 0}"),
          ],
        ),

        const Divider(),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Total",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              "₹${(request.visitCharge ?? 0) + (request.materialCharge ?? 0)}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    ),
  ),
],


// ================= VIEW QUOTE BUTTON =================
if (request.serviceType == "PLUMBING" &&
    (request.status == "QUOTED" || request.status == "CONFIRMED"))...[
  const SizedBox(height: 14),

  SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      onPressed: () async {

        final updated = await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => PlumberQuoteViewScreen(
    requestId: request.id,
    visitCharge: request.visitCharge ?? 0,
    materialCharge: request.materialCharge ?? 0,
    totalAmount: request.totalAmount,
    note: request.plumberNote ?? "",
    status: request.status,
  ),
  ),
);

if (updated == true) {
  context.read<RequestRepository>().fetchRequests();
}

      },
      child: Text(
  request.status == "QUOTED"
      ? "View Quote"
      : "Quote Approved",
        style: TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  ),
],


// ================= PAYMENT BUTTON =================
if ((request.status == "CONFIRMED" ||
     request.status == "IN_PROGRESS") &&
    request.payment?.status == "PENDING") ...[
  const SizedBox(height: 14),

  SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      onPressed: () {

        final state = context
            .findAncestorStateOfType<_ResidentDashboardState>();

        state?.startPayment(request);

      },
      child: Text(
        "Pay ₹${request.totalAmount}",
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  ),
],

          ],
        ),
      ),
    );
  }

  Future<void> openEditItemsDialog(BuildContext context, ServiceRequest request) async {

  Map<String, int> selectedItems = {};
  Map<String, int> originalItems = {};

  for (var item in request.ironItems) {
    selectedItems[item.clothType] = item.quantity;
    originalItems[item.clothType] = item.quantity;
  }

  // 🔥 FETCH FIRST
  if (SessionManager.apartmentId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Apartment not found")),
    );
    return;
  }
  
  final res = await ApiService.getIronPricing(SessionManager.apartmentId!);

  List<dynamic> pricingList = [];

  if (res["success"] == true) {
    pricingList = res["data"];
  }

  if (res["success"] != true) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Failed to load pricing"),
    ),
  );
  return;
}

final isSubmitting = ValueNotifier<bool>(false);

showDialog(
  context: context,
  builder: (_) {
    return StatefulBuilder(
      builder: (context, setStateDialog) {

        int totalClothes = 0;
        int totalAmount = 0;

        for (var item in pricingList) {
          final name = item["clothType"];
          final price = int.tryParse(item["price"].toString()) ?? 0;
          final qty = selectedItems[name] ?? 0;

          totalClothes += qty;
          totalAmount += qty * price;
        }

        return AlertDialog(
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Edit Clothes",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4),
              Text(
                "Only additional clothes will be sent for approval",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),

          content: SingleChildScrollView(
            child: Column(
              children: [

                /// INFO BOX
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "You can only ADD clothes. Removing is not allowed.",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                /// ITEMS
                ...pricingList.map((item) {
                  final name = item["clothType"];
                  final price =
                      int.tryParse(item["price"].toString()) ?? 0;
                  final qty = selectedItems[name] ?? 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [

                        /// LEFT
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "₹$price • Original: ${originalItems[name] ?? 0}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        /// RIGHT CONTROLS
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.remove,
                                size: 18,
                                color: qty >
                                        (originalItems[name] ?? 0)
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                              onPressed:
                                  qty > (originalItems[name] ?? 0)
                                      ? () {
                                          setStateDialog(() {
                                            selectedItems[name] =
                                                qty - 1;
                                          });
                                        }
                                      : null,
                            ),

                            SizedBox(
                              width: 30,
                              child: Text(
                                qty.toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            IconButton(
                              icon: const Icon(
                                Icons.add,
                                size: 18,
                                color: Colors.blue,
                              ),
                              onPressed: () {
                                setStateDialog(() {
                                  selectedItems[name] = qty + 1;
                                });
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 10),
                const Divider(),

                /// TOTAL
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total: $totalClothes clothes",
                        style: const TextStyle(
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "₹$totalAmount",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// ACTIONS
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            /// 🔥 BUTTON WITH LOADING
            ValueListenableBuilder<bool>(
              valueListenable: isSubmitting,
              builder: (_, loading, __) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize:
                        const Size(double.infinity, 42),
                  ),
                  onPressed: loading
                      ? null
                      : () async {
                          isSubmitting.value = true;

                          try {
                            final items = selectedItems.entries
                                .where((e) => e.value > 0)
                                .map((e) => {
                                      "clothType": e.key,
                                      "quantity": e.value
                                    })
                                .toList();

                            if (items.isEmpty) {
                              isSubmitting.value = false;
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "Select at least one item"),
                                ),
                              );
                              return;
                            }

                            for (var entry
                                in originalItems.entries) {
                              final oldQty = entry.value;
                              final newQty =
                                  selectedItems[entry.key] ?? 0;

                              if (newQty < oldQty) {
                                isSubmitting.value = false;
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "You can only ADD clothes"),
                                  ),
                                );
                                return;
                              }
                            }

                            final response =
                                await ApiService.updateItems({
                              "requestId": request.id,
                              "items": items
                            });

                            if (response["success"]) {
                              if (!context.mounted) return;

                              Navigator.pop(context);
                              context
                                  .read<RequestRepository>()
                                  .fetchRequests();

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "Updated successfully"),
                                ),
                              );
                            } else {
                              isSubmitting.value = false;
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(
                                      response["message"] ??
                                          "Failed"),
                                ),
                              );
                            }
                          } catch (e) {
                            isSubmitting.value = false;
                          }
                        },

                  child: loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<
                                        Color>(
                                    Colors.white),
                          ),
                        )
                      : const Text("Submit for Approval"),
                );
              },
            ),
          ],
        );
      },
    );
   },
);
} 
}
class EmptyState extends StatelessWidget {
  final String text;

  const EmptyState({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.inbox,
            size: 50,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
